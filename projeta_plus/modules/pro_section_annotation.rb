# encoding: UTF-8
require 'sketchup.rb'
require 'csv'

module SectionAnnotation

  # get_user_input - This method will be removed as input will come from JS
  # create_black_triangle, create_text, draw_dashed_dotted_line remain unchanged as helper methods
  def self.create_black_triangle(entities, position, orientation, scale_factor)
    size = (1 / 2.54) * scale_factor  # Triangle size in inches adjusted by scale factor
    half_size = size / 2.0
  
    pt1 = [0, -half_size, 0]
    pt2 = [0, half_size, 0]
    pt3 = [size / 4, 0, 0]
  
    triangle_group = entities.add_group
  
    face = triangle_group.entities.add_face(pt1, pt2, pt3)
  
    # Define black color for triangle
    model = Sketchup.active_model
    black_material = model.materials['Black']
    unless black_material
      black_material = model.materials.add('Black')
      black_material.color = Sketchup::Color.new(0, 0, 0)
    end
    
    face.material = black_material
    face.back_material = black_material
  
    transformation = Geom::Transformation.new(position) *
                      Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0),
                                                      Geom::Vector3d.new(0, 0, 1),
                                                      Math.atan2(orientation.y, orientation.x))
    triangle_group.transform!(transformation)
  
    triangle_group
  end
  
  def self.create_text(entities, position, text, font_size, scale_factor)
    text_group = entities.add_group
  
    # Add 3D text to group - use macOS compatible font
    font_name = Sketchup.platform == :platform_osx ? "Arial" : "Century Gothic"
    text_entity = text_group.entities.add_3d_text(text.upcase, TextAlignLeft, font_name,
                                                  false, false, font_size * scale_factor, 0, 0, true, 0)
  
    # Apply black material to text
    model = Sketchup.active_model
    black_material = model.materials['Black']
    unless black_material
      black_material = model.materials.add('Black')
      black_material.color = Sketchup::Color.new(0, 0, 0)
    end
    
    text_group.entities.each do |entity|
      if entity.is_a?(Sketchup::Face)
        entity.material = black_material
        entity.back_material = black_material
      end
    end
    
    text_bounds = text_group.bounds
    text_width  = text_bounds.width
    text_height = text_bounds.height
  
    translation = Geom::Transformation.new([-text_width / 2.0, -text_height / 2.0, 0])
    text_group.transform!(translation)
  
    text_translation = Geom::Transformation.new(position)
    text_group.transform!(text_translation)
  
    text_group
  end
  
  def self.draw_dashed_dotted_line(entities, start_point, end_point, dash_length, dot_diameter, gap_length)
    vector = Geom::Vector3d.new(end_point[0] - start_point[0],
                                end_point[1] - start_point[1],
                                end_point[2] - start_point[2])
    length = vector.length
    unit_vector = vector.normalize
  
    perpendicular_vector = Geom::Vector3d.new(0, 0, 1)
  
    current_position = start_point
    while length > 0
      dash_end = [current_position[0] + unit_vector.x * dash_length,
                  current_position[1] + unit_vector.y * dash_length,
                  current_position[2] + unit_vector.z * dash_length]
      entities.add_line(current_position, dash_end)
      
      length -= dash_length
      current_position = dash_end
  
      dot_center = [current_position[0] + unit_vector.x * (gap_length / 2.0),
                    current_position[1] + unit_vector.y * (gap_length / 2.0),
                    current_position[2] + unit_vector.z * (gap_length / 2.0)]
      
      dot_circle = entities.add_circle(dot_center, perpendicular_vector, dot_diameter / 2.0)
      entities.add_face(dot_circle)
      
      length -= dot_diameter
      current_position = [dot_center[0] + unit_vector.x * (gap_length / 2.0),
                          dot_center[1] + unit_vector.y * (gap_length / 2.0),
                          current_position[2] + unit_vector.z * (gap_length / 2.0)] # Adjusted for `unit_capital` typo
      length -= gap_length
    end
  end
  
  # --- MODIFIED: create_lines_from_section_planes to accept parameters from JS ---
  def self.create_lines_from_section_planes(args)
    model = Sketchup.active_model
    return { success: false, message: "No active model found." } unless model
    
    entities = model.entities
  
    section_planes = entities.grep(Sketchup::SectionPlane)
    if section_planes.empty?
      return { success: false, message: "No section planes in the model. Please create one before using this function." }
    end
  
    # Extract parameters from args hash, sent from JS
    line_height_cm = args['line_height_cm'].to_f
    scale_factor  = args['scale_factor'].to_f

    if line_height_cm <= 0 || scale_factor <= 0
      return { success: false, message: "Annotation Height and Scale must be positive values." }
    end

    # Persist values to SketchUp defaults
    Sketchup.write_default("SectionAnnotation", "line_height_cm", args['line_height_cm'].to_s)
    Sketchup.write_default("SectionAnnotation", "scale_factor", args['scale_factor'].to_s)
  
    line_height   = line_height_cm / 2.54  # Convert cm to inches (1 inch = 2.54 cm)
  
    all_lines_group = entities.add_group
    all_lines_group.name = "All Section Lines"
  
    layer_name = '-2D-SECTION ANNOTATION LEGEND'
    layer = model.layers[layer_name]
    unless layer
      layer = model.layers.add(layer_name)
    end
    all_lines_group.layer = layer
  
    dash_length = 20 / 2.54
    dot_diameter = 1 / 2.54
    gap_length = 10 / 2.54
  
    model_bb = model.bounds # Get model bounds only once
    section_planes.each do |entity|
      begin
        plane = entity.get_plane
        orientation = Geom::Vector3d.new(plane[0], plane[1], plane[2])
  
      if orientation.z.abs > 0.9 # Check for horizontal planes
        next
      end
  
      position = entity.bounds.center
  
      line_group = all_lines_group.entities.add_group
      line_group.name = "Section Line - #{entity.name || position.inspect}"
  
      if orientation.y.abs > orientation.x.abs
        line_start = [model_bb.min.x - (scale_factor / 2.54), position.y, 0]
        line_end   = [model_bb.max.x + (scale_factor / 2.54), position.y, 0]
        text_offset_direction = :x
      else
        line_start = [position.x, model_bb.min.y - (scale_factor / 2.54), 0]
        line_end   = [position.x, model_bb.max.y + (scale_factor / 2.54), 0]
        text_offset_direction = :y
      end
  
      draw_dashed_dotted_line(line_group.entities, line_start, line_end, dash_length, dot_diameter, gap_length)
  
      create_black_triangle(line_group.entities, line_start, orientation, scale_factor)
      create_black_triangle(line_group.entities, line_end, orientation, scale_factor)
  
      text_height = (0.3 / 2.54)
      offset_text = text_height * scale_factor
  
      if text_offset_direction == :x
        create_text(line_group.entities, [line_start[0], line_start[1] - offset_text * orientation.y, 0],
                    entity.name || "No name", text_height, scale_factor)
        create_text(line_group.entities, [line_end[0], line_end[1] - offset_text * orientation.y, 0],
                    entity.name || "No name", text_height, scale_factor)
      else
        create_text(line_group.entities, [line_start[0] - offset_text * orientation.x, line_start[1], 0],
                    entity.name || "No name", text_height, scale_factor)
        create_text(line_group.entities, [line_end[0] - offset_text * orientation.x, line_end[1], 0],
                    entity.name || "No name", text_height, scale_factor)
      end
  
      transformation = Geom::Transformation.new([0, 0, line_height])
      line_group.transform!(transformation)
      line_group.layer = layer
      rescue => e
        puts "Error processing section plane #{entity.inspect}: #{e.message}"
      end
    end
  
    { success: true, message: "Section Annotations created successfully!" }
  rescue StandardError => e
    { success: false, message: "Error creating section annotations: #{e.message}" }
  end
  
end  # module SectionAnnotation

# --- REMOVED THE TOOLBAR CREATION BLOCK FROM HERE ---
# (The toolbar will be created by ProjetaPlus::UI in projeta_plus/core.rb)