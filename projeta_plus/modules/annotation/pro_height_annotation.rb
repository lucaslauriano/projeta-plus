# encoding: UTF-8
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../pro_hover_face_util.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProHeightAnnotation
      include ProjetaPlus::Modules::ProHoverFaceUtil

      # Constants
      AVAILABLE_FONTS = ["Century Gothic", "Arial", "Arial Narrow", "Verdana", "Times New Roman"]
      IDENTITY = Geom::Transformation.new
      CM_TO_INCHES_CONVERSION_FACTOR = 2.54
      
      # Key codes for compatibility
      VK_UP = 38 unless defined?(VK_UP)
      VK_DOWN = 40 unless defined?(VK_DOWN)
      VK_LEFT = 37 unless defined?(VK_LEFT)
      VK_RIGHT = 39 unless defined?(VK_RIGHT)
      VK_CONTROL = 17 unless defined?(VK_CONTROL)
      VK_ADD = 107 unless defined?(VK_ADD)
      VK_SUBTRACT = 109 unless defined?(VK_SUBTRACT)

      def self.get_defaults
        {
          scale: Sketchup.read_default("HeightAnnotation", "scale", ProjetaPlus::Modules::ProSettingsUtils.get_scale).to_i,
          height_z_cm: Sketchup.read_default("HeightAnnotation", "height_z", ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm).to_s,
          font: Sketchup.read_default("HeightAnnotation", "font", ProjetaPlus::Modules::ProSettingsUtils.get_font),
          show_usage: convert_to_boolean(Sketchup.read_default("HeightAnnotation", "show_usage", false))
        }
      end

      def self.convert_to_boolean(value)
        case value
        when true, false
          value
        when String
          case value.to_s.strip.downcase
          when "true", "sim", "yes", "1", "on"
            true
          when "false", "não", "no", "0", "off", ""
            false
          else
            !!value
          end
        when Numeric
          value != 0
        when nil
          false
        else
          !!value
        end
      end

      def self.start_interactive_annotation(args)
        if Sketchup.active_model.nil?
          return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") }
        end
        Sketchup.active_model.select_tool(InteractiveHeightAnnotationTool.new(args))
        { success: true, message: ProjetaPlus::Localization.t("messages.height_tool_activated") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_activating_tool") + ": #{e.message}" }
      end

      class InteractiveHeightAnnotationTool
        include ProjetaPlus::Modules::ProHoverFaceUtil
        
        def initialize(args)
          @args = args
          @scale = args['scale'].to_i
          @height_z = args['height_z_cm'].to_f / CM_TO_INCHES_CONVERSION_FACTOR
          @font = args['font'].to_s
          @show_usage = ProjetaPlus::Modules::ProHeightAnnotation.convert_to_boolean(args['show_usage'])
          
          @text_height = 2.mm * @scale
          @base_margin = (1 * @scale).cm / CM_TO_INCHES_CONVERSION_FACTOR
          @preview_points = []
          @text_preview = nil
          
          # Load last used position, rotation, and offset
          @rotation_90 = Sketchup.read_default("HeightAnnotation", "rotation_90", "false") == "true"
          @relative_position = Sketchup.read_default("HeightAnnotation", "relative_position", 0).to_i
          @offset_multiplier = Sketchup.read_default("HeightAnnotation", "offset_multiplier", 1.0).to_f
          
          # Save settings
          Sketchup.write_default("HeightAnnotation", "scale", @scale)
          Sketchup.write_default("HeightAnnotation", "height_z", args['height_z_cm'])
          Sketchup.write_default("HeightAnnotation", "font", @font)
          Sketchup.write_default("HeightAnnotation", "show_usage", @show_usage.to_s)
        end

        def activate
          positions = ["CIMA", "DIREITA", "BAIXO", "ESQUERDA"]
          rotation_text = @rotation_90 ? "90°" : "0°"
          Sketchup.set_status_text("Pos: #{positions[@relative_position]} | Rot: #{rotation_text} | Offset: x#{@offset_multiplier} | +/- ajusta offset", SB_PROMPT)
        end

        def deactivate(view)
          view.invalidate
        end

        def onMouseMove(flags, x, y, view)
          update_hover(view, x, y)
          @valid_pick = @hover_face && @path
          calculate_preview if @hover_face && @hover_face.valid?
          view.invalidate
        end

        def calculate_preview
          return unless @hover_face && @path
          
          # Find component/group that contains the attribute
          holder = nil
          height_value = nil
          
          # Traverse the path backwards to find the first object with attribute
          @path.reverse.each do |entity|
            if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
              temp_value = entity.get_attribute("dynamic_attributes", "a003_altura")
              if temp_value.nil? && entity.is_a?(Sketchup::ComponentInstance)
                temp_value = entity.definition.get_attribute("dynamic_attributes", "a003_altura")
              end
              
              if temp_value
                holder = entity
                height_value = temp_value
                break
              end
            end
          end
          
          return unless height_value
          
          value_cm = height_value.to_f * CM_TO_INCHES_CONVERSION_FACTOR
          height_text = if value_cm == 0.0
                          "PISO"
                        else
                          (value_cm.round(1) == value_cm.round(0)) ? "H#{value_cm.round(0)}" : "H#{value_cm.round(1)}"
                        end
          
          # Include usage if enabled
          if @show_usage && holder
            usage_value = holder.get_attribute("dynamic_attributes", "c002b_uso")
            if usage_value.nil? && holder.is_a?(Sketchup::ComponentInstance)
              usage_value = holder.definition.get_attribute("dynamic_attributes", "c002b_uso")
            end
            
            if usage_value && !usage_value.to_s.strip.empty?
              @text_preview = "#{usage_value}\n#{height_text}"
              @has_usage = true
              @usage_text = usage_value.to_s
              @height_text = height_text
            else
              @text_preview = height_text
              @has_usage = false
            end
          else
            @text_preview = height_text
            @has_usage = false
          end

          # Use face bounding box for positioning
          bb = hover_extents
          
          # Calculate margin with offset multiplier
          current_margin = @base_margin * @offset_multiplier
          
          # Calculate position based on selected direction
          case @relative_position
          when 0  # Top
            text_position = Geom::Point3d.new(bb.center.x, bb.max.y + current_margin, @height_z)
          when 1  # Right
            text_position = Geom::Point3d.new(bb.max.x + current_margin, bb.center.y, @height_z)
          when 2  # Bottom
            text_position = Geom::Point3d.new(bb.center.x, bb.min.y - current_margin, @height_z)
          when 3  # Left
            text_position = Geom::Point3d.new(bb.min.x - current_margin, bb.center.y, @height_z)
          end
          
          letter_size = @text_height
          
          # Calculate preview size based on usage or height only
          if @has_usage && @usage_text && @height_text
            # With usage - two lines
            usage_width = @usage_text.length * letter_size
            height_width = @height_text.length * letter_size
            individual_height = letter_size * 1.2
            preview_spacing = letter_size * 0.1
            
            if @rotation_90
              # 90°: Rotated text - preview should be NARROW and TALL
              approx_width = individual_height * 2 + preview_spacing
              approx_height = [usage_width, height_width].max
            else
              # 0°: Normal text - preview WIDE and SHORT
              approx_width = [usage_width, height_width].max
              approx_height = (individual_height * 2) + preview_spacing
            end
          else
            # Height only - original behavior
            if @rotation_90
              # Rotated 90° - preview TALL
              approx_width = letter_size * 1.2
              approx_height = @text_preview.length * letter_size * 0.7
            else
              # Normal (0°) - preview WIDE
              approx_width = @text_preview.length * letter_size * 0.7
              approx_height = letter_size * 1.2
            end
          end
          
          # Preview at exact position where text will be created
          @preview_points = [
            Geom::Point3d.new(text_position.x - approx_width/2, text_position.y - approx_height/2, text_position.z),
            Geom::Point3d.new(text_position.x + approx_width/2, text_position.y - approx_height/2, text_position.z),
            Geom::Point3d.new(text_position.x + approx_width/2, text_position.y + approx_height/2, text_position.z),
            Geom::Point3d.new(text_position.x - approx_width/2, text_position.y + approx_height/2, text_position.z)
          ]
          
          # Save position for use on click
          @final_text_position = text_position
        end

        def draw(view)
          draw_hover(view)
          
          # Draw text preview
          if @preview_points && @preview_points.length == 4 && @text_preview
            view.drawing_color = Sketchup::Color.new(128, 57, 101)  # #803965
            view.line_stipple = "-"
            
            # Calculate line thickness based on zoom
            view_size = view.vpheight
            zoom_factor = view.camera.height / view_size
            line_width = [2, (zoom_factor * 10).to_i].max
            view.line_width = line_width
            
            view.draw(GL_LINE_LOOP, @preview_points)
          end
        end

        def onLButtonDown(flags, x, y, view)
          return unless @hover_face && @path
          
          # Find component/group that contains the attribute
          holder = nil
          height_value = nil
          
          @path.reverse.each do |entity|
            if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
              temp_value = entity.get_attribute("dynamic_attributes", "a003_altura")
              if temp_value.nil? && entity.is_a?(Sketchup::ComponentInstance)
                temp_value = entity.definition.get_attribute("dynamic_attributes", "a003_altura")
              end
              
              if temp_value
                holder = entity
                height_value = temp_value
                break
              end
            end
          end
          
          unless height_value
            puts "⚠️ 'a003_altura' not found in face hierarchy"
            return
          end

          value_cm = height_value.to_f * CM_TO_INCHES_CONVERSION_FACTOR
          height_text = if value_cm == 0.0
                          "PISO"
                        else
                          (value_cm.round(1) == value_cm.round(0)) ? "H#{value_cm.round(0)}" : "H#{value_cm.round(1)}"
                        end
          
          # Include usage if enabled
          has_usage = false
          usage_text = nil
          if @show_usage && holder
            usage_value = holder.get_attribute("dynamic_attributes", "c002b_uso")
            if usage_value.nil? && holder.is_a?(Sketchup::ComponentInstance)
              usage_value = holder.definition.get_attribute("dynamic_attributes", "c002b_uso")
            end
            
            if usage_value && !usage_value.to_s.strip.empty?
              has_usage = true
              usage_text = usage_value.to_s
            end
          end

          model = Sketchup.active_model
          model.start_operation("Imprimir Altura", true)

          pos = @final_text_position

          grp = model.entities.add_group
          tag = model.layers["-ANOTACAO-TECNICO"] || model.layers.add("-ANOTACAO-TECNICO")
          grp.layer = tag

          if has_usage
            # Create usage text (first line)
            grp_usage = grp.entities.add_group
            grp_usage.entities.add_3d_text(usage_text, TextAlignCenter, @font, false, false, @text_height)
            center_usage = grp_usage.bounds.center
            
            # Create height text (second line)
            grp_height = grp.entities.add_group
            grp_height.entities.add_3d_text(height_text, TextAlignCenter, @font, false, false, @text_height)
            center_height = grp_height.bounds.center
            
            # Positioning depends on rotation
            spacing = @text_height * 1.5
            
            if @rotation_90
              # For 90° rotation: position side by side BEFORE rotation
              pos_usage = Geom::Point3d.new(pos.x - spacing/2, pos.y, pos.z)
              pos_height = Geom::Point3d.new(pos.x + spacing/2, pos.y, pos.z)
            else
              # For 0°: position one on top of other
              pos_usage = Geom::Point3d.new(pos.x, pos.y + spacing/2, pos.z)
              pos_height = Geom::Point3d.new(pos.x, pos.y - spacing/2, pos.z)
            end
            
            # Apply positioning
            vec_usage = pos_usage - center_usage
            grp_usage.transform!(Geom::Transformation.translation(vec_usage))
            
            vec_height = pos_height - center_height
            grp_height.transform!(Geom::Transformation.translation(vec_height))
            
            # Apply rotation
            if @rotation_90
              pos_final_usage = grp_usage.bounds.center
              rotation_usage = Geom::Transformation.rotation(pos_final_usage, Geom::Vector3d.new(0, 0, 1), Math::PI/2)
              grp_usage.transform!(rotation_usage)
              
              pos_final_height = grp_height.bounds.center
              rotation_height = Geom::Transformation.rotation(pos_final_height, Geom::Vector3d.new(0, 0, 1), Math::PI/2)
              grp_height.transform!(rotation_height)
            end
            
            # Apply black color
            [grp_usage, grp_height].each do |subgrp|
              subgrp.entities.grep(Sketchup::Face).each { |f| f.material = f.back_material = 'black' }
            end
          else
            # Create only height text
            grp.entities.add_3d_text(height_text, TextAlignCenter, @font, false, false, @text_height)
            center_text = grp.bounds.center
            vec = pos - center_text
            grp.transform!(Geom::Transformation.translation(vec))
            
            # Apply rotation if necessary
            if @rotation_90
              pos_final = grp.bounds.center
              rotation = Geom::Transformation.rotation(pos_final, Geom::Vector3d.new(0, 0, 1), Math::PI/2)
              grp.transform!(rotation)
            end
            
            grp.entities.grep(Sketchup::Face).each { |f| f.material = f.back_material = 'black' }
          end
          
          calculate_preview if @hover_face
          view.invalidate

          model.commit_operation
        end

        def onKeyDown(key, repeat, flags, view)
          case key
          when 27  # ESC
            Sketchup.active_model.select_tool(nil)
          when VK_UP  # Arrow up
            @relative_position = 0
            Sketchup.write_default("HeightAnnotation", "relative_position", @relative_position)
            calculate_preview if @hover_face
            update_status_text
            view.invalidate
          when VK_RIGHT  # Arrow right
            @relative_position = 1
            Sketchup.write_default("HeightAnnotation", "relative_position", @relative_position)
            calculate_preview if @hover_face
            update_status_text
            view.invalidate
          when VK_DOWN  # Arrow down
            @relative_position = 2
            Sketchup.write_default("HeightAnnotation", "relative_position", @relative_position)
            calculate_preview if @hover_face
            update_status_text
            view.invalidate
          when VK_LEFT  # Arrow left
            @relative_position = 3
            Sketchup.write_default("HeightAnnotation", "relative_position", @relative_position)
            calculate_preview if @hover_face
            update_status_text
            view.invalidate
          when VK_CONTROL  # Ctrl - toggle between 0° and 90°
            @rotation_90 = !@rotation_90
            Sketchup.write_default("HeightAnnotation", "rotation_90", @rotation_90.to_s)
            calculate_preview if @hover_face
            update_status_text
            view.invalidate
          when 107, 187, VK_ADD  # + - increase offset
            @offset_multiplier = [@offset_multiplier + 0.5, 5.0].min
            Sketchup.write_default("HeightAnnotation", "offset_multiplier", @offset_multiplier)
            calculate_preview if @hover_face
            update_status_text
            view.invalidate
          when 109, 189, VK_SUBTRACT  # - - decrease offset
            @offset_multiplier = [@offset_multiplier - 0.5, 0.5].max
            Sketchup.write_default("HeightAnnotation", "offset_multiplier", @offset_multiplier)
            calculate_preview if @hover_face
            update_status_text
            view.invalidate
          end
        end
        
        def update_status_text
          positions = ["CIMA", "DIREITA", "BAIXO", "ESQUERDA"]
          rotation_text = @rotation_90 ? "90°" : "0°"
          Sketchup.set_status_text("Pos: #{positions[@relative_position]} | Rot: #{rotation_text} | Offset: x#{@offset_multiplier} | +/- ajusta offset", SB_PROMPT)
        end
      end

    end # module ProHeightAnnotation
  end # module Modules
end # module ProjetaPlus

