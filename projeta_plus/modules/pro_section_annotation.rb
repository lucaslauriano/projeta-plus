# encoding: UTF-8
require 'sketchup.rb'
require_relative 'pro_settings.rb' # Certifique-se que pro_settings.rb está carregado
require_relative 'pro_settings_utils.rb'
require_relative '../localization.rb'

module ProjetaPlus
  module Modules
    module ProSectionAnnotation


      DEFAULT_SECTION_LINE_HEIGHT_CM = ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm
      DEFAULT_SECTION_SCALE_FACTOR = ProjetaPlus::Modules::ProSettingsUtils.get_scale.to_s


      def self.get_defaults
        {
          line_height_cm: Sketchup.read_default("SectionAnnotation", "line_height_cm", DEFAULT_SECTION_LINE_HEIGHT_CM),
          scale_factor: Sketchup.read_default("SectionAnnotation", "scale_factor", DEFAULT_SECTION_SCALE_FACTOR)
        }
      end

      def self.create_black_triangle(entities, position, orientation, scale_factor)
        size = (1 / 2.54) * scale_factor 
        half_size = size / 2.0
      
        pt1 = [0, -half_size, 0]
        pt2 = [0, half_size, 0]
        pt3 = [size / 4, 0, 0]
      
        triangle_group = entities.add_group
        
        face = triangle_group.entities.add_face(pt1, pt2, pt3)
        face.material = 'black'
        face.back_material = 'black'
      
        # Cria a transformação para posicionar e rotacionar o triângulo
        # A rotação é em torno do eixo Z, alinhando com a orientação do plano de corte
        transformation = Geom::Transformation.new(position) *
                         Geom::Transformation.rotation(ORIGIN, Z_AXIS, Math.atan2(orientation.y, orientation.x))
        triangle_group.transform!(transformation)
      
        triangle_group
      end
      
      # Adaptação de FM_Extensions::Anotacaocorte.create_text
      def self.create_text(entities, position, text, font_size, scale_factor)
        model = Sketchup.active_model
        text_group = entities.add_group
        
        # Pega a fonte padrão das configurações globais ou usa um fallback
        font = ProjetaPlus::Modules::ProSettings.read("font", ProjetaPlus::Modules::ProSettings::DEFAULT_FONT)
        
        # O 3D Text no SketchUp usa TRUE para bold, FALSE para italic, e um valor para height
        text_group.entities.add_3d_text(text.upcase, TextAlignLeft, font,
                                                      false, false, font_size * scale_factor, 0, 0, true, 0)
        
        # Coloca material preto no texto 3D
        black_material = model.materials['Black'] || model.materials.add('Black')
        black_material.color = 'black'
        text_group.entities.grep(Sketchup::Face).each do |entity|
          entity.material = black_material
          entity.back_material = black_material
        end
        
        text_bounds = text_group.bounds
        # Centraliza o texto no ponto de inserção
        translation = Geom::Transformation.new([-text_bounds.width / 2.0, -text_bounds.height / 2.0, 0])
        text_group.transform!(translation)
        
        text_translation = Geom::Transformation.new(position)
        text_group.transform!(text_translation)
      
        text_group
      end
      
      # Adaptação de FM_Extensions::Anotacaocorte.draw_dashed_dotted_line
      def self.draw_dashed_dotted_line(entities, start_point, end_point, dash_length, dot_diameter, gap_length)
        vector = Geom::Vector3d.new(end_point[0] - start_point[0],
                                    end_point[1] - start_point[1],
                                    end_point[2] - start_point[2])
        length = vector.length
        unit_vector = vector.normalize
      
        perpendicular_vector = Geom::Vector3d.new(0, 0, 1) # Usado para desenhar o círculo do ponto
      
        current_position = start_point
        while length > 0
          # Desenha o traço
          dash_end = [current_position[0] + unit_vector.x * dash_length,
                      current_position[1] + unit_vector.y * dash_length,
                      current_position[2] + unit_vector.z * dash_length]
          entities.add_line(current_position, dash_end)
          
          length -= dash_length
          current_position = dash_end
      
          # Desenha o ponto (círculo) no meio do gap
          dot_center = [current_position[0] + unit_vector.x * (gap_length / 2.0),
                        current_position[1] + unit_vector.y * (gap_length / 2.0),
                        current_position[2] + unit_vector.z * (gap_length / 2.0)]
          
          dot_circle_edges = entities.add_circle(dot_center, perpendicular_vector, dot_diameter / 2.0)
          entities.add_face(dot_circle_edges) # Adiciona uma face para o ponto
          
          length -= dot_diameter
          current_position = [dot_center[0] + unit_vector.x * (gap_length / 2.0),
                              dot_center[1] + unit_vector.y * (gap_length / 2.0),
                              dot_center[2] + unit_vector.z * (gap_length / 2.0)]
          length -= gap_length
        end
      end
      
      # Este método será chamado pelo `executeExtensionFunction` do Next.js
      # Adaptação de FM_Extensions::Anotacaocorte.processar_anotacoes (e create_lines_from_section_planes)
      def self.create_lines_from_section_planes(args)
        model = Sketchup.active_model
        entities = model.entities
      
        # Mensagens traduzidas
        no_planes_msg = ProjetaPlus::Localization.t("messages.section_annotation_error_no_plane")
        no_selection_msg = ProjetaPlus::Localization.t("messages.no_object_selected_for_section")
        invalid_values_msg = ProjetaPlus::Localization.t("messages.invalid_section_annotation_values")
        section_success_msg = ProjetaPlus::Localization.t("messages.section_annotation_success")
        
        section_planes = entities.grep(Sketchup::SectionPlane)
        if section_planes.empty?
          return { success: false, message: no_planes_msg }
        end

        selection = model.selection
        if selection.empty?
          return { success: false, message: no_selection_msg }
        end
      
        # Extrai parâmetros dos args do frontend
        # Assegura que os valores são numéricos e positivos
        line_height_cm_str = args['line_height_cm'].to_s.tr(',', '.')
        scale_factor_str  = args['scale_factor'].to_s.tr(',', '.')
        
        line_height_cm = line_height_cm_str.to_f
        scale_factor = scale_factor_str.to_f

        # Persist module-specific values
        Sketchup.write_default("SectionAnnotation", "line_height_cm", line_height_cm_str)
        Sketchup.write_default("SectionAnnotation", "scale_factor", scale_factor_str)

        if line_height_cm <= 0 || scale_factor <= 0
          return { success: false, message: invalid_values_msg }
        end
      
        line_height = line_height_cm / 2.54 # Converter cm para polegadas (unidade interna do SketchUp)
      
        model.start_operation(ProjetaPlus::Localization.t("commands.section_annotation_operation_name"), true)
        
        bb = Geom::BoundingBox.new
        selection.each { |e| bb.add(e.bounds) } # Bounding box da seleção para determinar a extensão das linhas
        
        layer_name = '-2D-LEGENDA CORTES'
        layer      = model.layers.add(layer_name)

        all_lines_group = entities.add_group
        all_lines_group.name = ProjetaPlus::Localization.t("commands.all_section_lines_group_name")
        all_lines_group.layer = layer
      
        # Constantes para o estilo de linha (valores em polegadas)
        dash_length = 10.mm # Convertendo mm para polegadas
        dot_diameter = 0.5.mm # Convertendo mm para polegadas
        gap_length = 2.mm # Convertendo mm para polegadas

        font_size = (0.3 / 2.54) # Base para o tamanho do texto (em polegadas)

        section_planes.each_with_index do |entity, i|
          plane = entity.get_plane
          orientation = Geom::Vector3d.new(plane[0], plane[1], plane[2])
      
          if orientation.z.abs > 0.9 # Ignora planos de corte horizontais (que estariam no plano XY)
            next
          end
      
          position = entity.bounds.center # Centro do plano de corte
      
          line_group = all_lines_group.entities.add_group
          line_group.name = "#{ProjetaPlus::Localization.t("commands.section_line_group_name")} - #{entity.name || position.inspect}"
      
          # Determina as extremidades da linha de corte com base na orientação do plano e bounding box da seleção
          if orientation.y.abs > orientation.x.abs
            # Plano de corte mais alinhado com o eixo Y (corte "horizontal" no modelo)
            line_start = [bb.min.x - (scale_factor / 2.54), position.y, 0] # Adiciona um offset para que a linha saia um pouco da seleção
            line_end   = [bb.max.x + (scale_factor / 2.54), position.y, 0]
            text_offset_direction = :x
          else
            # Plano de corte mais alinhado com o eixo X (corte "vertical" no modelo)
            line_start = [position.x, bb.min.y - (scale_factor / 2.54), 0]
            line_end   = [position.x, bb.max.y + (scale_factor / 2.54), 0]
            text_offset_direction = :y
          end
      
          draw_dashed_dotted_line(line_group.entities, line_start, line_end, dash_length, dot_diameter, gap_length)
          create_black_triangle(line_group.entities, line_start, orientation, scale_factor)
          create_black_triangle(line_group.entities, line_end, orientation, scale_factor)
          
          letra = entity.name.empty? ? ProjetaPlus::Localization.t("messages.section_label_default_name").gsub("%{number}", (i+1).to_s) : entity.name
          afas_text = font_size * scale_factor # Offset do texto
      
          # Posiciona o texto nas extremidades
          if text_offset_direction == :x
            create_text(line_group.entities, [line_start[0], line_start[1] - afas_text * orientation.y, 0],
                        letra, font_size, scale_factor)
            create_text(line_group.entities, [line_end[0], line_end[1] - afas_text * orientation.y, 0],
                        letra, font_size, scale_factor)
          else
            create_text(line_group.entities, [line_start[0] - afas_text * orientation.x, line_start[1], 0],
                        letra, font_size, scale_factor)
            create_text(line_group.entities, [line_end[0] - afas_text * orientation.x, line_end[1], 0],
                        letra, font_size, scale_factor)
          end
          
          # Move o grupo de linha e texto para a altura final (line_height)
          line_group.transform!(Geom::Transformation.new([0, 0, line_height]))
          line_group.layer = layer
        end
        
        model.commit_operation
        { success: true, message: section_success_msg }
      rescue StandardError => e
        model.abort_operation
        { success: false, message: ProjetaPlus::Localization.t("messages.error_creating_section_annotations") + ": #{e.message}" }
      end
    end # module ProSectionAnnotation
  end # module Modules
end # module ProjetaPlus