# encoding: UTF-8
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../pro_hover_face_util.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProLightingAnnotation

      # Constants
      PREVIEW_COLOR = "#803965"
      CM_TO_INCHES_CONVERSION_FACTOR = 2.54

      def self.get_defaults
        {
          circuit_text: Sketchup.read_default("LightingCircuit", "text", "C1"),
          circuit_scale: Sketchup.read_default("LightingCircuit", "scale", ProjetaPlus::Modules::ProSettingsUtils.get_scale),
          circuit_height_cm: Sketchup.read_default("LightingCircuit", "height_z", ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm),
          circuit_font: Sketchup.read_default("LightingCircuit", "font", ProjetaPlus::Modules::ProSettingsUtils.get_font),
          circuit_text_color: Sketchup.read_default("LightingCircuit", "text_color", ProjetaPlus::Modules::ProSettingsUtils.get_text_color)
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
        
        # Validate inputs
        return { success: false, message: "Invalid face reference" } unless face && face.valid?
        return { success: false, message: "Invalid path" } unless path && path.is_a?(Array)
        
        # Extract parameters from frontend args
        text = args['circuit_text'].to_s
        scale = args['circuit_scale'].to_f
        height_z_cm = args['circuit_height_cm'].to_s
        font = args['circuit_font'].to_s
        text_color = args['circuit_text_color'].to_s
        
        # Validate text is not empty
        return { success: false, message: "Text cannot be empty" } if text.empty?
        
        # Validate font is not empty
        return { success: false, message: "Font cannot be empty" } if font.empty?

        # Save preferences for next use
        Sketchup.write_default("LightingCircuit", "text", text)
        Sketchup.write_default("LightingCircuit", "scale", scale)
        Sketchup.write_default("LightingCircuit", "height_z", height_z_cm)
        Sketchup.write_default("LightingCircuit", "font", font)
        Sketchup.write_default("LightingCircuit", "text_color", text_color)

        height_z = height_z_cm.to_f / CM_TO_INCHES_CONVERSION_FACTOR # cm → inches
        text_height = 3.mm * scale
        base_margin_cm = 0.5 # base margin in cm
        margin = (base_margin_cm * scale).cm / CM_TO_INCHES_CONVERSION_FACTOR
        
        # Validate text height is reasonable
        if text_height <= 0 || text_height > 100.mm
          return { success: false, message: "Invalid text height: #{text_height}" }
        end

        # Get the object that contains the face (parent group or component)
        begin
          holder = face.parent.instances[0] rescue face.parent
        rescue StandardError => e
          holder = face.parent
        end

        # Use face bounding box for positioning
        bb = hover_extents_for_face(face, path)
        
        # Validate bounding box is valid
        return { success: false, message: "Invalid bounding box" } unless bb && bb.valid?
        
        # Calculate position based on selected direction (default: top)
        begin
          position = Geom::Point3d.new(bb.center.x, bb.max.y + margin, height_z)
        rescue StandardError => e
          return { success: false, message: "Error calculating position: #{e.message}" }
        end

        # Create text group and add simple text geometry
        begin
          # Create empty group first
          text_group = model.entities.add_group
          
          # Apply tag to group
          tag_name = "-ANOTACAO-ILUMINACAO CIRCUITOS"
          tag = model.layers[tag_name] || model.layers.add(tag_name)
          text_group.layer = tag
          
          # Validate group is valid before adding text
          unless text_group && text_group.valid?
            return { success: false, message: "Text group became invalid after creation" }
          end
          
          # Create simple text using lines instead of 3D text
          create_simple_text(text_group, text, position, text_height, text_color)
          
        rescue StandardError => e
          return { success: false, message: "Error creating text: #{e.message}" }
        end

        # Text is already positioned correctly, just select it
        begin
          # Validate text group is still valid
          return { success: false, message: "Text group became invalid" } unless text_group && text_group.valid?
          
          model.selection.clear
          model.selection.add(text_group)
        rescue StandardError => e
          return { success: false, message: "Error selecting text: #{e.message}" }
        end
        
        { success: true, message: ProjetaPlus::Localization.t("messages.circuit_annotation_success") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_adding_circuit_annotation") + ": #{e.message}" }
      end

      # Create simple text using basic geometry
      def self.create_simple_text(group, text, position, height, color)
        return if text.empty?
        
        # Create a simple rectangle as text placeholder
        width = text.length * height * 0.6
        half_width = width / 2.0
        half_height = height / 2.0
        
        # Define rectangle points
        pt1 = Geom::Point3d.new(position.x - half_width, position.y - half_height, position.z)
        pt2 = Geom::Point3d.new(position.x + half_width, position.y - half_height, position.z)
        pt3 = Geom::Point3d.new(position.x + half_width, position.y + half_height, position.z)
        pt4 = Geom::Point3d.new(position.x - half_width, position.y + half_height, position.z)
        
        # Create rectangle face
        face = group.entities.add_face([pt1, pt2, pt3, pt4])
        
        # Apply color
        if face
          face.material = color
          face.back_material = color
        end
        
        # Add text label as a simple line
        if text.length > 0
          # Create a simple line to represent text
          start_pt = Geom::Point3d.new(position.x - half_width, position.y, position.z + height/4)
          end_pt = Geom::Point3d.new(position.x + half_width, position.y, position.z + height/4)
          line = group.entities.add_line(start_pt, end_pt)
        end
      end

      # Helper method to get hover extents for a face
      def self.hover_extents_for_face(face, path)
        # Validate face is still valid
        return Geom::BoundingBox.new unless face && face.valid?
        
        # Get accumulated transformation for global coordinates
        tr = Geom::Transformation.new
        path.each do |e|
          next unless e && e.valid? # Skip deleted elements
          # Double-check face is still valid before accessing transformation
          next unless face && face.valid?
          tr *= e.transformation if e.respond_to?(:transformation)
          break if e == face
        end
        
        # Transform face bounds to global coordinates
        begin
          bb = face.bounds
          # Create a new bounding box with transformed points
          min_point = bb.min.transform(tr)
          max_point = bb.max.transform(tr)
          bb = Geom::BoundingBox.new
          bb.add(min_point)
          bb.add(max_point)
          bb
        rescue StandardError => e
          # If face becomes invalid during bounds access, return empty bounding box
          Geom::BoundingBox.new
        end
      end

      # Interactive tool for circuit annotation
      class InteractiveCircuitAnnotationTool
        include ProjetaPlus::Modules::ProHoverFaceUtil
        
        def initialize(args)
          @args = args
          @valid_pick = false
          @relative_position = 0 # 0=top, 1=right, 2=bottom, 3=left
          @preview_points = []
        end
        
        def activate
          Sketchup.set_status_text(ProjetaPlus::Localization.t("commands.circuit_annotation_instructions"), SB_PROMPT)
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
          return unless @hover_face && @path && @hover_face.valid?
          
          # Use face bounding box for positioning
          bb = hover_extents
          
          # Extract parameters for calculations
          text = @args['circuit_text'].to_s
          scale = @args['circuit_scale'].to_f
          height_z_cm = @args['circuit_height_cm'].to_s
          height_z = height_z_cm.to_f / CM_TO_INCHES_CONVERSION_FACTOR # cm → inches
          text_height = 3.mm * scale
          base_margin_cm = 0.5
          margin = (base_margin_cm * scale).cm / CM_TO_INCHES_CONVERSION_FACTOR
          
          # Calculate position based on selected direction
          case @relative_position
          when 0  # Top
            position = Geom::Point3d.new(bb.center.x, bb.max.y + margin, height_z)
          when 1  # Right
            position = Geom::Point3d.new(bb.max.x + margin, bb.center.y, height_z)
          when 2  # Bottom
            position = Geom::Point3d.new(bb.center.x, bb.min.y - margin, height_z)
          when 3  # Left
            position = Geom::Point3d.new(bb.min.x - margin, bb.center.y, height_z)
          end
          
          # Create preview points (rectangle for text)
          letter_size = text_height
          approx_width = text.length * letter_size * 0.6
          approx_height = letter_size
          
          @preview_points = [
            Geom::Point3d.new(position.x - approx_width/2, position.y - approx_height/2, position.z),
            Geom::Point3d.new(position.x + approx_width/2, position.y - approx_height/2, position.z),
            Geom::Point3d.new(position.x + approx_width/2, position.y + approx_height/2, position.z),
            Geom::Point3d.new(position.x - approx_width/2, position.y + approx_height/2, position.z)
          ]
        end
        
        def draw(view)
          draw_hover(view)
          
          # Draw text preview
          if @preview_points.length == 4
            view.drawing_color = Sketchup::Color.new(PREVIEW_COLOR)
            view.line_stipple = "-"
            view.line_width = 2
            
            # Draw preview rectangle
            view.draw(GL_LINE_LOOP, @preview_points)
            
            # Draw preview text in center
            center = Geom::Point3d.new(
              (@preview_points[0].x + @preview_points[2].x) / 2,
              (@preview_points[0].y + @preview_points[2].y) / 2,
              @preview_points[0].z
            )
            
            view.draw_text(center, @args['circuit_text'].to_s, {
              font: @args['circuit_font'].to_s,
              size: 12,
              bold: false,
              align: TextAlignLeft,
              color: PREVIEW_COLOR
            })
          end
        end
        
        def onLButtonDown(flags, x, y, view)
          return unless @valid_pick && @hover_face && @hover_face.valid?
          
          model = Sketchup.active_model
          model.start_operation(ProjetaPlus::Localization.t("commands.circuit_annotation_operation_name"), true)
          
          result = ProjetaPlus::Modules::ProLightingAnnotation.process_circuit_annotation(@hover_face, @path, @args)
          if result[:success]
            model.commit_operation
            ::UI.messagebox(ProjetaPlus::Localization.t("messages.circuit_annotation_success"), MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          else
            model.abort_operation
            ::UI.messagebox(result[:message], MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          end
          Sketchup.active_model.select_tool(nil)
        rescue StandardError => e
          model.abort_operation
          ::UI.messagebox("#{ProjetaPlus::Localization.t("messages.unexpected_error")}: #{e.message}", MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          Sketchup.active_model.select_tool(nil)
        end
        
        def onKeyDown(key, repeat, flags, view)
          case key
          when 27  # ESC
            Sketchup.active_model.select_tool(nil)
          when VK_UP  # Arrow up - position on top
            @relative_position = 0
            calculate_preview if @hover_face
            Sketchup.set_status_text("Text positioned ABOVE the face", SB_PROMPT)
            view.invalidate
          when VK_RIGHT  # Arrow right - position on right
            @relative_position = 1
            calculate_preview if @hover_face
            Sketchup.set_status_text("Text positioned to the RIGHT of the face", SB_PROMPT)
            view.invalidate
          when VK_DOWN  # Arrow down - position below
            @relative_position = 2
            calculate_preview if @hover_face
            Sketchup.set_status_text("Text positioned BELOW the face", SB_PROMPT)
            view.invalidate
          when VK_LEFT  # Arrow left - position on left
            @relative_position = 3
            calculate_preview if @hover_face
            Sketchup.set_status_text("Text positioned to the LEFT of the face", SB_PROMPT)
            view.invalidate
          end
        end
      end
    end
  end
end
