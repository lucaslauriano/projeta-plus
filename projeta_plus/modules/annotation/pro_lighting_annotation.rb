# encoding: UTF-8
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../pro_hover_face_util.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProLightingAnnotation

      PREVIEW_COLOR = "#803965"
      CM_TO_INCHES_CONVERSION_FACTOR = 2.54

      def self.get_defaults
        {
          circuit_text: Sketchup.read_default("LightingCircuit", "text", "C1")
        }
      end

      def self.start_interactive_annotation(args)
        if Sketchup.active_model.nil?
          return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") }
        end

        Sketchup.active_model.select_tool(InteractiveCircuitAnnotationTool.new(args))
        { success: true, message: ProjetaPlus::Localization.t("messages.circuit_tool_activated") }

      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_activating_tool") + ": #{e.message}" }
      end

      def self.process_circuit_annotation(face, path, args)
        model = Sketchup.active_model
        return { success: false, message: "Invalid face reference" } unless face && face.valid?
        return { success: false, message: "Invalid path" } unless path && path.is_a?(Array)

        text       = args['circuit_text'].to_s
        scale      = ProjetaPlus::Modules::ProSettingsUtils.get_scale
        height_z_cm = ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm
        font       = ProjetaPlus::Modules::ProSettingsUtils.get_font
        text_color = ProjetaPlus::Modules::ProSettingsUtils.get_text_color

        return { success: false, message: "Text cannot be empty" } if text.empty?
        return { success: false, message: "Font cannot be empty" } if font.empty?

        Sketchup.write_default("LightingCircuit", "text", text)
        Sketchup.write_default("LightingCircuit", "scale", scale)
        Sketchup.write_default("LightingCircuit", "height_z", height_z_cm)
        Sketchup.write_default("LightingCircuit", "font", font)
        Sketchup.write_default("LightingCircuit", "text_color", text_color)

        height_z    = height_z_cm.to_f / CM_TO_INCHES_CONVERSION_FACTOR
        text_height = 3.mm * scale
        margin      = (0.5 * scale).cm / CM_TO_INCHES_CONVERSION_FACTOR

        return { success: false, message: "Invalid text height: #{text_height}" } if text_height <= 0 || text_height > 100.mm

        bb = hover_extents_for_face(face, path)
        return { success: false, message: "Invalid bounding box" } unless bb && bb.valid?

        position = Geom::Point3d.new(bb.center.x, bb.max.y + margin, height_z)

        text_group = model.entities.add_group
        tag_name = "-ANOTACAO-ILUMINACAO CIRCUITOS"
        tag = model.layers[tag_name] || model.layers.add(tag_name)
        text_group.layer = tag

        create_simple_text(text_group, text, position, text_height, text_color)

        model.selection.clear
        model.selection.add(text_group)

        { success: true, message: ProjetaPlus::Localization.t("messages.circuit_annotation_success") }

      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_adding_circuit_annotation") + ": #{e.message}" }
      end

      def self.create_simple_text(group, text, position, height, color)
        return if text.empty?

        width = text.length * height * 0.6
        half_width = width / 2.0
        half_height = height / 2.0

        pt1 = Geom::Point3d.new(position.x - half_width, position.y - half_height, position.z)
        pt2 = Geom::Point3d.new(position.x + half_width, position.y - half_height, position.z)
        pt3 = Geom::Point3d.new(position.x + half_width, position.y + half_height, position.z)
        pt4 = Geom::Point3d.new(position.x - half_width, position.y + half_height, position.z)

        face = group.entities.add_face([pt1, pt2, pt3, pt4])
        face.material = color if face
        face.back_material = color if face

        start_pt = Geom::Point3d.new(position.x - half_width, position.y, position.z + height/4)
        end_pt   = Geom::Point3d.new(position.x + half_width, position.y, position.z + height/4)
        group.entities.add_line(start_pt, end_pt)
      end

      def self.hover_extents_for_face(face, path)
        return Geom::BoundingBox.new unless face && face.valid?

        tr = Geom::Transformation.new
        path.each do |e|
          tr *= e.transformation if e.respond_to?(:transformation)
          break if e == face
        end

        bb = face.bounds
        min_point = bb.min.transform(tr)
        max_point = bb.max.transform(tr)

        newbb = Geom::BoundingBox.new
        newbb.add(min_point)
        newbb.add(max_point)
        newbb

      rescue
        Geom::BoundingBox.new
      end

      class InteractiveCircuitAnnotationTool
        include ProjetaPlus::Modules::ProHoverFaceUtil

        VK_LEFT = 37;   VK_UP = 38;     VK_RIGHT = 39;   VK_DOWN = 40
        VK_ENTER = 13;  VK_ESC = 27
        VK_LEFT_MAC = 123; VK_UP_MAC = 126; VK_RIGHT_MAC = 124; VK_DOWN_MAC = 125

        def initialize(args)
          @args = args
          @text = args['circuit_text'].to_s

          @font = ProjetaPlus::Modules::ProSettingsUtils.get_font
          @color = ProjetaPlus::Modules::ProSettingsUtils.get_text_color
          @scale = ProjetaPlus::Modules::ProSettingsUtils.get_scale
          @height_z_cm = ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm
          @height_z = @height_z_cm.to_f / CM_TO_INCHES_CONVERSION_FACTOR

          @text_height = 3.mm * @scale
          @base_margin_cm = 0.8
          @margin_base = (@base_margin_cm * @scale).cm / CM_TO_INCHES_CONVERSION_FACTOR
          @margin = @margin_base

          @relative_position = 0
          @preview_points = []
          @phase = :waiting_for_face
          @face_bb = nil
          @confirmed_position = nil
          @hover_face = nil
          @path = nil
          @bb = nil

          @last_esc_at = Time.at(0)
        end

        def activate
          Sketchup.set_status_text(ProjetaPlus::Localization.t("commands.circuit_annotation_instructions"), SB_PROMPT)
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
            @face_bb = nil
            @confirmed_position = nil
            @preview_points.clear
            Sketchup.set_status_text("Selecione uma face. ESC duas vezes para sair.", SB_PROMPT)
            view.invalidate
          end
          @last_esc_at = now
        end

        def deactivate(view)
          view.invalidate
        end

        def onMouseMove(flags, x, y, view)
          update_hover(view, x, y)
          return view.invalidate if @phase == :waiting_for_face

          calculate_preview
          view.invalidate
        end

        def calculate_preview
          return unless @phase == :adjusting
          bb = @face_bb
          return unless bb

          position = case @relative_position
            when 0 then Geom::Point3d.new(bb.center.x, bb.max.y + @margin, @height_z)
            when 1 then Geom::Point3d.new(bb.max.x + @margin, bb.center.y, @height_z)
            when 2 then Geom::Point3d.new(bb.center.x, bb.min.y - @margin, @height_z)
            when 3 then Geom::Point3d.new(bb.min.x - @margin, bb.center.y, @height_z)
          end

          @confirmed_position = position
          tam = @text_height
          w = @text.length * tam * 0.6
          h = tam

          @preview_points = [
            Geom::Point3d.new(position.x - w/2, position.y - h/2, position.z),
            Geom::Point3d.new(position.x + w/2, position.y - h/2, position.z),
            Geom::Point3d.new(position.x + w/2, position.y + h/2, position.z),
            Geom::Point3d.new(position.x - w/2, position.y + h/2, position.z)
          ]
        end

        def draw(view)
          draw_hover(view) if @phase == :waiting_for_face
          return unless @preview_points.length == 4

          view.drawing_color = Sketchup::Color.new(PREVIEW_COLOR)
          view.line_stipple = "-"
          view.line_width = 2
          view.draw(GL_LINE_LOOP, @preview_points)
        end

        def onLButtonDown(flags, x, y, view)
          return unless @hover_face && @bb

          if @phase == :waiting_for_face
            @face_bb = @bb
            @phase = :adjusting
            calculate_preview
            Sketchup.set_status_text("Ajuste com setas e +/-. Enter/Click confirma. ESC cancela.", SB_PROMPT)
            view.invalidate
            return
          end

          if @phase == :adjusting
            create_text(@confirmed_position)
            restart_flow(view)
          end
        end

        def create_text(position)
          return unless position
          model = Sketchup.active_model
          text_group = model.entities.add_group
          tag_name = "-ANOTACAO-ILUMINACAO CIRCUITOS"
          tag = model.layers[tag_name] || model.layers.add(tag_name)
          text_group.layer = tag

          texto_3d = text_group.entities.add_3d_text(
            @text, TextAlignCenter, @font, false, false,
            @text_height, 0.0, 0.0, true
          )

          center_text = text_group.bounds.center
          vector_move = position - center_text
          text_group.transform!(Geom::Transformation.translation(vector_move))

          text_group.entities.grep(Sketchup::Face).each do |face|
            face.material = @color
            face.back_material = @color
          end
        end

        def restart_flow(view)
          @phase = :waiting_for_face
          @face_bb = nil
          @confirmed_position = nil
          @preview_points.clear
          Sketchup.set_status_text("Posicionado. Clique outra face ou ESC.", SB_PROMPT)
          view.invalidate
        end

        def onKeyDown(key, repeat, flags, view)
          case key
          when VK_ESC
            handle_escape(view)
            return
          end

          return unless @phase == :adjusting

          if key == ?+.ord || key == 187
            @margin += @margin_base * 0.2
            calculate_preview
            view.invalidate
            return
          end

          if key == ?-.ord || key == 189
            @margin = [@margin - @margin_base * 0.2, @margin_base * 0.2].max
            calculate_preview
            view.invalidate
            return
          end

          case key
          when VK_UP, VK_UP_MAC      then @relative_position = 0
          when VK_RIGHT, VK_RIGHT_MAC then @relative_position = 1
          when VK_DOWN, VK_DOWN_MAC   then @relative_position = 2
          when VK_LEFT, VK_LEFT_MAC   then @relative_position = 3
          when VK_ENTER
            create_text(@confirmed_position)
            restart_flow(view)
            return
          else
            return
          end

          calculate_preview
          view.invalidate
        end
      end
    end
  end
end
