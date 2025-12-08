# encoding: UTF-8
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../../localization.rb'
require_relative '../pro_hover_face_util.rb'

module ProjetaPlus
  module Modules
    module ProSectionAnnotation
      include ProjetaPlus::Modules::ProHoverFaceUtil
      
      CM_TO_INCHES_CONVERSION_FACTOR = 2.54
      
      def self.get_defaults
        {
          line_height_cm: Sketchup.read_default("SectionAnnotation", "line_height_cm", ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm),
          scale_factor: Sketchup.read_default("SectionAnnotation", "scale_factor", ProjetaPlus::Modules::ProSettingsUtils.get_scale)
        }
      end
      
      def self.create_black_triangle(entities, position, orientation, scale_factor)
        size = (1.5 / CM_TO_INCHES_CONVERSION_FACTOR) * scale_factor
        half_size = size / 2.0
        pt1 = [0, -half_size, 0]
        pt2 = [0, half_size, 0]
        pt3 = [size / 4, 0, 0]
        
        triangle_group = entities.add_group
        face = triangle_group.entities.add_face(pt1, pt2, pt3)
        face.material = 'black'
        face.back_material = 'black'
        
        transformation = Geom::Transformation.new(position) *
                        Geom::Transformation.rotation(ORIGIN, Z_AXIS, Math.atan2(orientation.y, orientation.x))
        triangle_group.transform!(transformation)
        triangle_group
      end
      
      def self.create_text(entities, position, text, font_size, scale_factor, rotation_angle = 0)
        model = Sketchup.active_model
        text_group = entities.add_group
        font = ProjetaPlus::Modules::ProSettings.read("font", ProjetaPlus::Modules::ProSettings::DEFAULT_FONT)
        
        text_group.entities.add_3d_text(text.upcase, TextAlignLeft, font,
                                       false, false, font_size * scale_factor, 0, 0, true, 0)
        
        black_material = model.materials['Black'] || model.materials.add('Black')
        black_material.color = 'black'
        
        text_group.entities.grep(Sketchup::Face).each do |entity|
          entity.material = black_material
          entity.back_material = black_material
        end
        
        text_bounds = text_group.bounds
        translation = Geom::Transformation.new([-text_bounds.width / 2.0, -text_bounds.height / 2.0, 0])
        text_group.transform!(translation)
        
        # Apply rotation if necessary
        if rotation_angle != 0
          rotation = Geom::Transformation.rotation(ORIGIN, Z_AXIS, rotation_angle)
          text_group.transform!(rotation)
        end
        
        text_translation = Geom::Transformation.new(position)
        text_group.transform!(text_translation)
        text_group
      end
      
      def self.draw_dashed_dotted_line(entities, start_point, end_point, dash_length, dot_diameter, gap_length)
        model = Sketchup.active_model
        black_material = model.materials['Black'] || model.materials.add('Black')
        black_material.color = 'black'
        
        vector = Geom::Vector3d.new(end_point[0] - start_point[0], end_point[1] - start_point[1], end_point[2] - start_point[2])
        total_length = vector.length
        unit_vector = vector.normalize
        perpendicular_vector = Geom::Vector3d.new(0, 0, 1)
        current_position = start_point
        remaining_length = total_length
        
        while remaining_length > 0
          if remaining_length >= dash_length
            dash_end = [current_position[0] + unit_vector.x * dash_length,
                       current_position[1] + unit_vector.y * dash_length,
                       current_position[2] + unit_vector.z * dash_length]
            line = entities.add_line(current_position, dash_end)
            line.material = black_material if line.respond_to?(:material)
            current_position = dash_end
            remaining_length -= dash_length
          else
            dash_end = [current_position[0] + unit_vector.x * remaining_length,
                       current_position[1] + unit_vector.y * remaining_length,
                       current_position[2] + unit_vector.z * remaining_length]
            line = entities.add_line(current_position, dash_end)
            line.material = black_material if line.respond_to?(:material)
            break
          end
          
          if remaining_length >= gap_length
            current_position = [current_position[0] + unit_vector.x * gap_length,
                               current_position[1] + unit_vector.y * gap_length,
                               current_position[2] + unit_vector.z * gap_length]
            remaining_length -= gap_length
          else
            break
          end
          
          if remaining_length > 0
            dot_circle = entities.add_circle(current_position, perpendicular_vector, dot_diameter / 2.0)
            dot_face = entities.add_face(dot_circle)
            dot_face.material = black_material
            dot_face.back_material = black_material
          end
          
          if remaining_length >= gap_length
            current_position = [current_position[0] + unit_vector.x * gap_length,
                               current_position[1] + unit_vector.y * gap_length,
                               current_position[2] + unit_vector.z * gap_length]
            remaining_length -= gap_length
          else
            break
          end
        end
      end
      
      class InteractiveSectionAnnotationTool
        include ProjetaPlus::Modules::ProHoverFaceUtil
        
        def initialize
          @valid_pick = false
          @target_entity = nil
        end
        
        def activate
          Sketchup.set_status_text(ProjetaPlus::Localization.t("messages.section_annotation_prompt"), SB_PROMPT)
          @view = Sketchup.active_model.active_view
        end
        
        def deactivate(view)
          view.invalidate
        end
        
        def onMouseMove(flags, x, y, view)
          update_hover(view, x, y)
          @target_entity = resolve_target_entity
          @valid_pick = !@target_entity.nil?
          view.invalidate
        end
        
        def draw(view)
          draw_hover(view)
        end
        
        def onLButtonDown(flags, x, y, view)
          unless @valid_pick
            ::UI.messagebox(ProjetaPlus::Localization.t("messages.click_on_group_component_for_section"), MB_OK, ProjetaPlus::Localization.t("plugin_name"))
            return
          end
          
          model = Sketchup.active_model
          model.start_operation(ProjetaPlus::Localization.t("commands.section_annotation_operation_name"), true)
          
          result = ProjetaPlus::Modules::ProSectionAnnotation.create_lines_for_entity(nil, @target_entity)
          
          if result[:success]
            model.commit_operation
            ::UI.messagebox(result[:message], MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          else
            model.abort_operation
            ::UI.messagebox(result[:message], MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          end
          
          Sketchup.active_model.select_tool(nil)
        rescue StandardError => e
          model.abort_operation if model
          ::UI.messagebox("#{ProjetaPlus::Localization.t("messages.unexpected_error")}: #{e.message}", MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          Sketchup.active_model.select_tool(nil)
        end
        
        def onKeyDown(key, repeat, flags, view)
          Sketchup.active_model.select_tool(nil) if key == 27
        end
        
        private
        
        def resolve_target_entity
          return nil unless @hover_face && @path
          
          group_or_component = @path.find do |entity|
            entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
          end
          return group_or_component if group_or_component
          
          owner = @hover_face.parent
          owner = owner.parent if owner.respond_to?(:parent)
          return owner if owner.is_a?(Sketchup::Group) || owner.is_a?(Sketchup::ComponentInstance)
          
          if owner.respond_to?(:instances)
            instance = owner.instances.find { |inst| inst.is_a?(Sketchup::ComponentInstance) }
            return instance if instance
          end
          
          nil
        end
      end
      
      def self.start_interactive_annotation(args = nil)
        if Sketchup.active_model.nil?
          return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") }
        end
        
        Sketchup.active_model.select_tool(InteractiveSectionAnnotationTool.new)
        { success: true, message: ProjetaPlus::Localization.t("messages.section_tool_activated") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_activating_tool") + ": #{e.message}" }
      end
      
      def self.create_lines_for_entity(args, entity)
        model = Sketchup.active_model
        entities = model.entities
        
        no_planes_msg = ProjetaPlus::Localization.t("messages.section_annotation_error_no_plane")
        invalid_values_msg = ProjetaPlus::Localization.t("messages.invalid_section_annotation_values")
        section_success_msg = ProjetaPlus::Localization.t("messages.section_annotation_success")
        
        section_planes = entities.grep(Sketchup::SectionPlane)
        if section_planes.empty?
          return { success: false, message: no_planes_msg }
        end
        
        line_height_cm = ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm.to_f
        scale_factor = ProjetaPlus::Modules::ProSettingsUtils.get_scale
        line_height = line_height_cm / CM_TO_INCHES_CONVERSION_FACTOR
        
        entity_bounds = entity.bounds
        entity_center = entity_bounds.center
        
        # OFFSET DA MARCAÇÃO - adjust this value to control how much the line extends from the object
        extend_distance = (scale_factor / CM_TO_INCHES_CONVERSION_FACTOR) * 1
        
        bb = Geom::BoundingBox.new
        bb.add([entity_bounds.min.x - extend_distance, entity_bounds.min.y - extend_distance, entity_bounds.min.z])
        bb.add([entity_bounds.max.x + extend_distance, entity_bounds.max.y + extend_distance, entity_bounds.max.z])
        
        layer_name = '-ANOTAÇÃO-SECAO'
        layer = model.layers.add(layer_name)
        
        all_lines_group = entities.add_group
        all_lines_group.name = ProjetaPlus::Localization.t("commands.all_section_lines_group_name")
        all_lines_group.layer = layer
        
        # TAMANHOS DO TRACEJADO - follow the scale
        dash_length = (1 / CM_TO_INCHES_CONVERSION_FACTOR) * scale_factor
        dot_diameter = (0.03 / CM_TO_INCHES_CONVERSION_FACTOR) * scale_factor
        gap_length = (0.2 / CM_TO_INCHES_CONVERSION_FACTOR) * scale_factor
        font_size = (0.3 / CM_TO_INCHES_CONVERSION_FACTOR)
        
        section_planes.each_with_index do |entity, i|
          plane = entity.get_plane
          orientation = Geom::Vector3d.new(plane[0], plane[1], plane[2])
          
          if orientation.z.abs > 0.9
            next
          end
          
          position = entity.bounds.center
          line_group = all_lines_group.entities.add_group
          line_group.name = "#{ProjetaPlus::Localization.t("commands.section_line_group_name")} - #{entity.name || position.inspect}"
          
          # EXTENSÃO DA LINHA - multiplier to control the size of the ends
          line_extension = (scale_factor / CM_TO_INCHES_CONVERSION_FACTOR) * 1
          
          # Adjustment to avoid overlap with triangles
          # The line should start AFTER the first triangle and end BEFORE the second
          triangle_size = (1.5 / CM_TO_INCHES_CONVERSION_FACTOR) * scale_factor
          triangle_width = triangle_size / 4.0  # Triangle width (its base)
          safety_gap = triangle_width * 1.2  # A bit of extra margin
          
          if orientation.y.abs > orientation.x.abs
            # Position of triangles at the ends
            triangle_start_pos = [bb.min.x - line_extension, position.y, 0]
            triangle_end_pos = [bb.max.x + line_extension, position.y, 0]
            # Line starts after the first triangle and ends before the second
            line_start = [bb.min.x - line_extension + safety_gap, position.y, 0]
            line_end = [bb.max.x + line_extension - safety_gap, position.y, 0]
            text_offset_direction = :x
          else
            # Position of triangles at the ends
            triangle_start_pos = [position.x, bb.min.y - line_extension, 0]
            triangle_end_pos = [position.x, bb.max.y + line_extension, 0]
            # Line starts after the first triangle and ends before the second
            line_start = [position.x, bb.min.y - line_extension + safety_gap, 0]
            line_end = [position.x, bb.max.y + line_extension - safety_gap, 0]
            text_offset_direction = :y
          end
          
          # First create the triangles
          create_black_triangle(line_group.entities, triangle_start_pos, orientation, scale_factor)
          create_black_triangle(line_group.entities, triangle_end_pos, orientation, scale_factor)
          
          # Then draw the line between them
          draw_dashed_dotted_line(line_group.entities, line_start, line_end, dash_length, dot_diameter, gap_length)
          
          label = entity.name.empty? ? ProjetaPlus::Localization.t("messages.section_label_default_name").gsub("%{number}", (i+1).to_s) : entity.name
          afas_text = font_size * scale_factor
          
          # Determine rotation angle based on orientation
          rotation_angle = 0
          if text_offset_direction == :y
            # Vertical section - rotate 90 degrees
            rotation_angle = Math::PI / 2
          end
          
          if text_offset_direction == :x
            create_text(line_group.entities, [triangle_start_pos[0], triangle_start_pos[1] - afas_text * orientation.y, 0],
                       label, font_size, scale_factor, rotation_angle) 
            create_text(line_group.entities, [triangle_end_pos[0], triangle_end_pos[1] - afas_text * orientation.y, 0],
                       label, font_size, scale_factor, rotation_angle)
          else
            create_text(line_group.entities, [triangle_start_pos[0] - afas_text * orientation.x, triangle_start_pos[1], 0],
                       label, font_size, scale_factor, rotation_angle)
            create_text(line_group.entities, [triangle_end_pos[0] - afas_text * orientation.x, triangle_end_pos[1], 0],
                       label, font_size, scale_factor, rotation_angle)
          end
          
          line_group.transform!(Geom::Transformation.new([0, 0, line_height]))
          line_group.layer = layer
        end
        
        { success: true, message: section_success_msg }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_creating_section_annotations") + ": #{e.message}" }
      end
    end
  end
end
