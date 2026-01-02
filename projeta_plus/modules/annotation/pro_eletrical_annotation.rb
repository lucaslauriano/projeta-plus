# encoding: UTF-8
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../pro_hover_face_util.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProEletricalAnnotation
      include ProjetaPlus::Modules::ProHoverFaceUtil

      AVAILABLE_FONTS = ["Century Gothic", "Arial", "Arial Narrow", "Verdana", "Times New Roman"].freeze
      CM_TO_INCHES_CONVERSION_FACTOR = 2.54
      ORIGIN = Geom::Point3d.new(0, 0, 0) unless defined?(ORIGIN)

      # Keycodes
      VK_LEFT = 37; VK_UP = 38; VK_RIGHT = 39; VK_DOWN = 40
      VK_SHIFT = 16; VK_CTRL = 17; VK_ESC = 27; VK_ENTER = 13
      VK_ADD = 107; 
      VK_SUBTRACT = 109;
      VK_PLUS = 187; 
      VK_MINUS = 189
      VK_LEFT_MAC = 123; VK_UP_MAC = 126; VK_RIGHT_MAC = 124; VK_DOWN_MAC = 125

      class << self
        def convert_to_boolean(value)
          case value
          when true, false then value
          when String
            case value.to_s.strip.downcase
            when 'true', 'sim', 'yes', '1', 'on' then true
            when 'false', 'não', 'nao', 'no', '0', 'off', '' then false
            else !!value
            end
          when Numeric then value != 0
          when nil then false
          else !!value
          end
        end

        def get_defaults
          {
            scale: Sketchup.read_default('EletricalAnnotation', 'scale', ProjetaPlus::Modules::ProSettingsUtils.get_scale).to_i,
            height_z_cm: Sketchup.read_default('EletricalAnnotation', 'height_z', ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm).to_s,
            font: Sketchup.read_default('EletricalAnnotation', 'font', ProjetaPlus::Modules::ProSettingsUtils.get_font),
            show_usage: convert_to_boolean(Sketchup.read_default('EletricalAnnotation', 'show_usage', false))
          }
        end

        def start_interactive_annotation(args, dialog = nil)
          return { success: false, message: ProjetaPlus::Localization.t('messages.no_model_open') } if Sketchup.active_model.nil?
          Sketchup.active_model.select_tool(InteractiveEletricalAnnotationTool.new(args, dialog))
          { success: true, message: ProjetaPlus::Localization.t('messages.height_tool_activated') }
        rescue => e
          { success: false, message: ProjetaPlus::Localization.t('messages.error_activating_tool') + ": #{e.message}" }
        end
      end

      class InteractiveEletricalAnnotationTool
        include ProjetaPlus::Modules::ProHoverFaceUtil

        def initialize(args = {}, dialog = nil)
          @args = args || {}
          @dialog = dialog
          @scale = (@args['scale'] || ProjetaPlus::Modules::ProSettingsUtils.get_scale).to_i
          @height_z = (@args['height_z_cm'] || ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm).to_f / CM_TO_INCHES_CONVERSION_FACTOR
          @font = (@args['font'] || ProjetaPlus::Modules::ProSettingsUtils.get_font).to_s
          @show_usage = !!(@args['show_usage'].to_s =~ /^(true|1|sim|yes|on)$/i)
          @text_height = 2.mm * @scale
          @line_spacing_factor = Sketchup.read_default('EletricalAnnotation', 'line_spacing', 0.3).to_f
          @base_margin = (0.5 * @scale).cm / CM_TO_INCHES_CONVERSION_FACTOR
          @rotation_90 = Sketchup.read_default('EletricalAnnotation', 'rotation_90', 'false') == 'true'
          @relative_position = Sketchup.read_default('EletricalAnnotation', 'relative_position', 0).to_i
          @offset_multiplier = Sketchup.read_default('EletricalAnnotation', 'offset_multiplier', 1.0).to_f
          @phase = :waiting_for_face
          @hover_face = nil
          @path = nil
          @bb = nil
          @preview_points = []
          @confirmed_position = nil
          @last_esc_at = Time.at(0)
          @layout_mode = :vertical
          @__text_cache = {}
        end

        def activate
          set_status('Selecione uma face. ESC duas vezes para sair.')
        end

        def deactivate(view)
          view.invalidate
        end

        def onCancel(reason, view)
          handle_escape(view)
        end

        def handle_escape(view)
          now = Time.now
          if (now - @last_esc_at) <= 0.7
            Sketchup.active_model.select_tool(nil)
          else
            @phase = :waiting_for_face
            @confirmed_position = nil
            @preview_points.clear
            set_status('Selecione uma face. ESC duas vezes para sair.')
            view.invalidate
          end
          @last_esc_at = now
        end

        def onMouseMove(flags, x, y, view)
          update_hover(view, x, y)
          return unless @hover_face && @hover_face.valid?
          @path ||= (@hover_face ? @hover_face.path : nil) rescue @path
          @bb = hover_extents
          calculate_preview if @phase == :adjusting
          view.invalidate
        end

        def onLButtonDown(flags, x, y, view)
          update_hover(view, x, y)
          return unless @hover_face && @hover_face.valid?

          if @phase == :waiting_for_face
            @phase = :adjusting
            @bb = hover_extents
            calculate_preview
            set_status('Ajuste com setas e +/-. Ctrl rotaciona. Shift troca layout. Clique novamente ou Enter confirma.')
            view.invalidate
            return
          end

          if @phase == :adjusting
            create_annotation
            restart_flow(view)
          end
        end

        def restart_flow(view)
          @phase = :waiting_for_face
          @confirmed_position = nil
          @preview_points.clear
          set_status('Posicionado. Clique outra face ou ESC.')
          view.invalidate
        end

        def get_text_alignment
          
          if @rotation_90
            case @relative_position
            when 0
              TextAlignLeft
            when 1
              TextAlignCenter
            when 2
              TextAlignRight
            when 3
              TextAlignCenter
            else
              TextAlignCenter
            end
          else
            case @relative_position
            when 0
              TextAlignCenter
            when 1
              TextAlignLeft
            when 2
              TextAlignCenter
            when 3
              TextAlignRight
            else
              TextAlignCenter
            end
          end
        end

        def create_temp_text_group(parent, lines_array)
          g = parent.entities.add_group
          alignment = get_text_alignment
          
          full_text = lines_array.join("\n")
          
          g.entities.add_3d_text(
            full_text, 
            alignment, 
            @font, 
            false,
            false,
            @text_height,
            0.0,
            0.0,
            true,
            @line_spacing_factor
          )

          if @rotation_90
            pivot = g.bounds.center
            rot = Geom::Transformation.rotation(pivot, Geom::Vector3d.new(0, 0, 1), Math::PI / 2)
            g.transform!(rot)
          end
          
          g
        end

        def calculate_position_with_text_bounds(text_bounds)
          return nil unless @bb && text_bounds
          
          margin = @base_margin * @offset_multiplier
          
          cx = @bb.center.x
          cy = @bb.center.y
          cz = @height_z

          text_width = text_bounds.width
          text_height = text_bounds.height

          case @relative_position
          when 0
            offset_distance = (text_height / 2.0) + margin
            Geom::Point3d.new(cx, @bb.max.y + offset_distance, cz)
          when 1
            offset_distance = (text_width / 2.0) + margin
            Geom::Point3d.new(@bb.max.x + offset_distance, cy, cz)
          when 2
            offset_distance = (text_height / 2.0) + margin
            Geom::Point3d.new(cx, @bb.min.y - offset_distance, cz)
          when 3
            offset_distance = (text_width / 2.0) + margin
            Geom::Point3d.new(@bb.min.x - offset_distance, cy, cz)
          else
            offset_distance = (text_height / 2.0) + margin
            Geom::Point3d.new(cx, @bb.max.y + offset_distance, cz)
          end
        end

        def calculate_preview
          return unless @phase == :adjusting
          model = Sketchup.active_model
          ents = model.active_entities
          temp_group = ents.add_group

          begin
            holder, height_value = find_height_holder(@path)
            return unless height_value

            vcm = height_value.to_f * CM_TO_INCHES_CONVERSION_FACTOR
            height_text = vcm.zero? ? 'PISO' : ((vcm.round(1) == vcm.round(0)) ? "H#{vcm.round(0)}" : "H#{vcm.round(1)}")

            usage_text = nil
            if @show_usage && holder
              uv = holder.get_attribute('dynamic_attributes', 'c002b_uso') ||
                  (holder.is_a?(Sketchup::ComponentInstance) ? holder.definition.get_attribute('dynamic_attributes', 'c002b_uso') : nil)
              usage_text = uv.to_s.strip unless uv.nil? || uv.to_s.strip.empty?
            end

            lines = []
            if usage_text
              if @layout_mode == :vertical
                lines = [usage_text, height_text]
              else
                lines = ["#{usage_text}-#{height_text}"]
              end
            else
              lines = [height_text]
            end

            g = create_temp_text_group(temp_group, lines)

            text_bounds = g.bounds
            base_pos = calculate_position_with_text_bounds(text_bounds)
            
            g.transform!(Geom::Transformation.translation(base_pos - g.bounds.center))

            bb = g.bounds
            @preview_points = [
              Geom::Point3d.new(bb.min.x, bb.min.y, bb.min.z),
              Geom::Point3d.new(bb.max.x, bb.min.y, bb.min.z),
              Geom::Point3d.new(bb.max.x, bb.max.y, bb.min.z),
              Geom::Point3d.new(bb.min.x, bb.max.y, bb.min.z)
            ]
            @confirmed_position = base_pos

          rescue => e
            puts "Erro em calculate_preview: #{e.class} - #{e.message}"
          ensure
            temp_group.erase! if temp_group&.valid?
          end
        end

        def draw(view)
          draw_hover(view)
          if @preview_points && @preview_points.length == 4
            view.drawing_color = Sketchup::Color.new(128, 57, 101)
            view.line_stipple = "-"
            view_size = view.vpheight
            zoom_factor = view.camera.height / (view_size.zero? ? 1 : view_size)
            view.line_width = [2, (zoom_factor * 10).to_i].max
            view.draw(GL_LINE_LOOP, @preview_points)
          end
        end

        def create_annotation
          return unless @confirmed_position
          model = Sketchup.active_model
          model.start_operation('Imprimir Altura', true)
          
          begin
            holder, height_value = find_height_holder(@path)
            return unless height_value

            vcm = height_value.to_f * CM_TO_INCHES_CONVERSION_FACTOR
            height_text = vcm.zero? ? 'PISO' : ((vcm.round(1) == vcm.round(0)) ? "H#{vcm.round(0)}" : "H#{vcm.round(1)}")

            usage_text = nil
            if @show_usage && holder
              uv = holder.get_attribute('dynamic_attributes', 'c002b_uso') ||
                  (holder.is_a?(Sketchup::ComponentInstance) ? holder.definition.get_attribute('dynamic_attributes', 'c002b_uso') : nil)
              usage_text = uv.to_s.strip unless uv.nil? || uv.to_s.strip.empty?
            end

            tag_name = '-ANOTACAO-TECNICO'
            tag = model.layers[tag_name] || model.layers.add(tag_name)
            grp_main = model.entities.add_group
            grp_main.layer = tag

            lines = []
            if usage_text
              if @layout_mode == :vertical
                lines = [usage_text, height_text]
              else
                lines = ["#{usage_text} - #{height_text}"]
              end
            else
              lines = [height_text]
            end

            g = create_temp_text_group(grp_main, lines)

            text_bounds = g.bounds
            base_pos = calculate_position_with_text_bounds(text_bounds)

            g.transform!(Geom::Transformation.translation(base_pos - g.bounds.center))

            colorize_safe(g)

          rescue => e
            if @dialog
              error_msg = "Erro ao criar anotação: #{e.class} - #{e.message}".gsub("'", "\\\\'")
              @dialog.execute_script("showMessage('#{error_msg}', 'error');")
            end
          ensure
            model.commit_operation
          end
        end

        def colorize_safe(group)
          return unless group && group.valid?
          
          group.entities.each do |entity|
            if entity.is_a?(Sketchup::Group)
              colorize_safe(entity)
            elsif entity.is_a?(Sketchup::Face)
              begin
                entity.material = entity.back_material = 'black'
              rescue
              end
            end
          end
        end

        def find_height_holder(path)
          return [nil, nil] unless path && path.is_a?(Array)
          path.reverse_each do |entity|
            if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
              val = entity.get_attribute('dynamic_attributes', 'a003_altura')
              if val.nil? && entity.is_a?(Sketchup::ComponentInstance)
                val = entity.definition.get_attribute('dynamic_attributes', 'a003_altura')
              end
              return [entity, val] if val
            end
          end
          [nil, nil]
        end

        def onKeyDown(key, repeat, flags, view)
          case key
          when VK_ESC
            handle_escape(view)
            return
          when VK_CTRL
            @rotation_90 = !@rotation_90
            Sketchup.write_default('EletricalAnnotation', 'rotation_90', @rotation_90.to_s)
          when VK_SHIFT
            @layout_mode = (@layout_mode == :vertical) ? :horizontal : :vertical
          when VK_ENTER
            create_annotation
            restart_flow(view)
            return
          when VK_ADD, VK_PLUS
            if flags & COPY_MODIFIER_MASK != 0
              @line_spacing_factor = [@line_spacing_factor + 0.1, 2.0].min
              Sketchup.write_default('EletricalAnnotation', 'line_spacing', @line_spacing_factor)
            else
              @offset_multiplier = [@offset_multiplier + 0.5, 5.0].min
              Sketchup.write_default('EletricalAnnotation', 'offset_multiplier', @offset_multiplier)
            end
          when VK_SUBTRACT, VK_MINUS
            if flags & COPY_MODIFIER_MASK != 0
              @line_spacing_factor = [@line_spacing_factor - 0.1, 0.0].max
              Sketchup.write_default('EletricalAnnotation', 'line_spacing', @line_spacing_factor)
            else
              @offset_multiplier = [@offset_multiplier - 0.5, 0.5].max
              Sketchup.write_default('EletricalAnnotation', 'offset_multiplier', @offset_multiplier)
            end
          when VK_UP, VK_UP_MAC
            @relative_position = 0
            Sketchup.write_default('EletricalAnnotation', 'relative_position', @relative_position)
          when VK_RIGHT, VK_RIGHT_MAC
            @relative_position = 1
            Sketchup.write_default('EletricalAnnotation', 'relative_position', @relative_position)
          when VK_DOWN, VK_DOWN_MAC
            @relative_position = 2
            Sketchup.write_default('EletricalAnnotation', 'relative_position', @relative_position)
          when VK_LEFT, VK_LEFT_MAC
            @relative_position = 3
            Sketchup.write_default('EletricalAnnotation', 'relative_position', @relative_position)
          else
            return
          end

          calculate_preview if @phase == :adjusting
          update_status_text
          view.invalidate
        end

        def update_status_text
          positions = ['CIMA', 'DIREITA', 'BAIXO', 'ESQUERDA']
          
          alignment_text = case get_text_alignment
                          when TextAlignLeft then 'ESQ'
                          when TextAlignRight then 'DIR'
                          when TextAlignCenter then 'CENTRO'
                          else 'CENTRO'
                          end
          
          rotation_text = @rotation_90 ? '90°' : '0°'
          layout_text = (@layout_mode == :vertical) ? 'Vertical' : 'Lateral'
          Sketchup.set_status_text("Pos: #{positions[@relative_position]} (#{alignment_text}) | Rot: #{rotation_text} | Layout: #{layout_text} | Offset: x#{@offset_multiplier} | Espaç: #{(@line_spacing_factor * 100).round}%", SB_PROMPT)
        end

        def set_status(msg)
          Sketchup.set_status_text(msg, SB_PROMPT)
        end

        def getExtents
          hover_extents
        end
      end
    end
  end
end