# encoding: UTF-8
require 'sketchup.rb'
require 'csv'

module RoomAnnotation

    # TODO: Settings - Move it to user settings, fonts, area and stuff 
    def self.available_fonts
      ["Arial", "Arial Narrow","Century Gothic", "Helvetica", "Times New Roman", "Verdana"]
    end

    def self.calculate_area_of_group(group)
      total_area = 0.0
      group.entities.each do |entity|
        total_area += entity.area if entity.is_a?(Sketchup::Face)
      end
      total_area * 0.00064516 # Convert to m² assuming internal units are inches and 0.00064516 m²/inch²
    end

    # test_text, create_level_symbol remain unchanged as helper methods
    def self.test_text(text, position, scale, font, alignment = TextAlignCenter)
      model = Sketchup.active_model
      text_group = model.entities.add_group
      text_entities = text_group.entities

      height = 0.3.cm * scale
      thickness = 0
      is_bold   = true
      is_italic = false

      model.start_operation('Add 3D Text', true)
      text_entities.add_3d_text(text, alignment, font, is_bold, is_italic, height, thickness)

      tb = text_group.bounds

      black_material = model.materials['Black'] || model.materials.add('Black')
      black_material.color = 'black'

      text_entities.grep(Sketchup::Face).each do |face|
        face.material = black_material
        face.back_material = black_material
      end

      text_group.transform!(Geom::Transformation.translation(position - tb.center))

      model.commit_operation
      text_group
    end

    def self.create_level_symbol(center, level_text, scale, font)
      model    = Sketchup.active_model
      entities = model.active_entities
      center   = Geom::Point3d.new(0, 0, 0) # This center seems to be for the symbol's internal origin, not global.

      level_text_group = test_text(level_text, center, scale, font, TextAlignLeft)
      level_text_width = level_text_group.bounds.width

      level_text_group.entities.grep(Sketchup::Face).each do |face|
        face.material = 'black'
        face.back_material = 'black'
      end

      cross_radius = level_text_width / 5.0

      pre_entities = entities.to_a
      model.start_operation("Create Level Symbol", true)

      radius = 0.2.cm * scale
      normal = Geom::Vector3d.new(0, 0, 1)

      circle_edges = entities.add_circle(center, normal, radius, 32, [1, 0, 0])
      circle_face = entities.add_face(circle_edges)
      circle_face.reverse! if circle_face.normal.dot(normal) < 0

      pt_right  = Geom::Point3d.new(center.x + radius, center.y, center.z)
      pt_top    = Geom::Point3d.new(center.x, center.y + radius, center.z)
      pt_left   = Geom::Point3d.new(center.x - radius, center.y, center.z)
      pt_bottom = Geom::Point3d.new(center.x, center.y - radius, center.z)

      entities.add_line(center, pt_right)
      entities.add_line(center, pt_top)
      entities.add_line(center, pt_left)
      entities.add_line(center, pt_bottom)

      # Force intersection of the circle face by lines
      # entities.intersect_with(true, IDENTITY, entities, IDENTITY, true, [circle_face]) # This line can cause issues.
      # It's better to explicitly add new edges for intersection if needed, or rely on automatic intersection.
      # For simplicity, we'll comment it out for now or assume it's handled.
      # If intersection is crucial, it might need more robust handling.

      pt_cross_right  = Geom::Point3d.new(center.x + cross_radius * 5 + radius + (0.05 * scale), center.y, center.z)
      pt_cross_left   = Geom::Point3d.new(center.x - cross_radius, center.y, center.z)
      pt_cross_top    = Geom::Point3d.new(center.x, center.y + cross_radius, center.z)
      pt_cross_bottom = Geom::Point3d.new(center.x, center.y - cross_radius, center.z)

      entities.add_line(pt_cross_left, pt_cross_right)
      entities.add_line(pt_cross_top, pt_cross_bottom)

      final_new_entities = entities.to_a - pre_entities
      quad_faces = final_new_entities.grep(Sketchup::Face).select { |face| 
        face.area > 0.0 && face.bounds.center.distance(center) < (radius * 1.5)
      }

      unless quad_faces.empty?
        quad_faces.sort_by! do |face|
          c = face.bounds.center
          ang = Math.atan2(c.y - center.y, c.x - center.x)
          ang < 0 ? ang + 2 * Math::PI : ang
        end
        quad_faces.each_with_index do |face, index|
          material_name = (index.even? ? "black" : "white")
          mat = model.materials[material_name] || model.materials.add(material_name)
          mat.color = material_name
          face.material = mat
        end
      end

      symbol_group = entities.add_group(final_new_entities)

      desired_text_center_x =  radius + 0.25 * scale + (0.01 * scale)
      desired_text_center_y = center.y + (0.075 * scale)
      translation = Geom::Transformation.translation(Geom::Vector3d.new(
        desired_text_center_x - center.x,
        desired_text_center_y - center.y,
        0
      ))
      level_text_group.transform!(translation)

      model.start_operation("Group All", true)
      final_group = entities.add_group
      final_group_entities = final_group.entities

      symbol_instance = final_group_entities.add_instance(symbol_group.entities.parent, symbol_group.transformation)
      text_instance   = final_group_entities.add_instance(level_text_group.entities.parent, level_text_group.transformation)

      symbol_group.erase!
      level_text_group.erase!

      model.commit_operation
      final_group
    end

    # --- MODIFIED: add_text_to_selected_instance to accept parameters from JS ---
    def self.add_text_to_selected_instance(args)
      model = Sketchup.active_model
      selection = model.selection
      groups = selection.grep(Sketchup::Group)

      if groups.empty?
        # Instead of UI.messagebox, return a status to JS
        # TODO: Langage - English, Portuguese, Spanish
        return { success: false, message: "Please select at least one group (even if it's nested inside another group)." }
      end

      # Extract parameters from args hash, sent from JS
      # Use .to_s to ensure consistent string comparison.
      scale_str = args['scale_str'].to_s
      font = args['font'].to_s
      floor_height_str = args['altura_piso_str'].to_s
      show_pd = args['mostrar_pd'].to_s
      pd_str = args['pd_str'].to_s
      show_level = args['mostrar_nivel'].to_s
      level_str = args['nivel_str'].to_s

      # Persist values, if needed (these were read_default, so write_default should match)
      Sketchup.write_default("RoomAnnotation", "scale", scale_str)
      Sketchup.write_default("RoomAnnotation", "font", font)
      Sketchup.write_default("RoomAnnotation", "floor_height", floor_height_str)
      Sketchup.write_default("RoomAnnotation", "show_pd", show_pd)
      Sketchup.write_default("RoomAnnotation", "pd", pd_str)
      Sketchup.write_default("RoomAnnotation", "show_level", show_level)
      Sketchup.write_default("RoomAnnotation", "level", level_str)

      scale = scale_str.to_f
      cut_height = 1.45 # Fixed value
      floor_height = floor_height_str.gsub(',', '.').to_f # Handle comma as decimal separator
      z_height = (floor_height + cut_height).m

      layer_name = '-2D-ROOM ANNOTATION LEGEND'
      layer = model.layers[layer_name] || model.layers.add(layer_name)

      groups.each do |group|
        instance_name = group.name.empty? ? "No Name" : group.name
        area_sqm = self.calculate_area_of_group(group)
        area_str = format('%.2f', area_sqm).gsub('.', ',')
        text_content = "#{instance_name}\nAREA: #{area_str} m²"
        text_content += "\nPD: #{pd_str}m" if show_pd.strip.downcase == "yes"

        bounds = group.bounds
        center = bounds.center
        center.z = 0

        text_group = test_text(text_content, center, scale, font)
        text_group.layer = layer

        if show_level.strip.downcase == "yes"
          symbol_groups = create_level_symbol(center, "#{level_str} m", scale, font)
          level_composite = model.entities.add_group(symbol_groups)

          text_bb = text_group.bounds
          comp_bb = level_composite.bounds
          delta_y = text_bb.min.y - comp_bb.max.y - (0.15 / 2.54 * scale)
          level_composite.transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, delta_y, 0)))

          text_center_x = text_bb.center.x
          comp_center_x = level_composite.bounds.center.x
          delta_x = text_center_x - comp_center_x
          level_composite.transform!(Geom::Transformation.translation(Geom::Vector3d.new(delta_x, 0, 0)))

          final_group = model.entities.add_group
          final_group_entities = final_group.entities

          text_definition = text_group.entities.parent
          text_instance = final_group_entities.add_instance(text_definition, text_group.transformation)

          level_definition = level_composite.entities.parent
          level_instance = final_group_entities.add_instance(level_definition, level_composite.transformation)

          text_group.erase! if text_group.valid?
          level_composite.erase! if level_composite.valid?

          final_group.layer = layer

          final_group_center = final_group.bounds.center
          translation_to_center = Geom::Transformation.translation(center - final_group_center)
          final_group.transform!(translation_to_center)

          final_group_center = final_group.bounds.center
          translation_to_z_height = Geom::Transformation.translation(Geom::Vector3d.new(0, 0, z_height - final_group_center.z))
          final_group.transform!(translation_to_z_height)

          model.selection.clear
          model.selection.add(final_group)
          else
          text_group_center = text_group.bounds.center
          translation_to_z_height = Geom::Transformation.translation(Geom::Vector3d.new(0, 0, z_height - text_group_center.z))
          text_group.transform!(translation_to_z_height)

          model.selection.clear
          model.selection.add(text_group)
        end
      end
      { success: true, message: "Room name and annotations added successfully!" }
    rescue StandardError => e
      { success: false, message: "Error adding room name: #{e.message}" }
    end

end # module RoomAnnotation
