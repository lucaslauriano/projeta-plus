# encoding: UTF-8
require 'sketchup.rb'
require 'csv'

module FM_Extensions

  module Nomeambiente

      def self.fontes_disponiveis
        # macOS compatible fonts
        if Sketchup.platform == :platform_osx
          ["Arial", "Helvetica", "Times New Roman", "Verdana", "Geneva", "Monaco"]
        else
          ["Arial", "Arial Narrow", "Century Gothic", "Helvetica", "Times New Roman", "Verdana"]
        end
      end

      def self.calculate_area_of_group(group)
        total_area = 0.0
        group.entities.each do |entity|
          total_area += entity.area if entity.is_a?(Sketchup::Face)
        end
        total_area * 0.00064516
      end

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

        # Create or get black material
        black_material = model.materials['Black']
        unless black_material
          black_material = model.materials.add('Black')
          black_material.color = Sketchup::Color.new(0, 0, 0)
        end

        text_entities.grep(Sketchup::Face).each do |face|
          face.material = black_material
          face.back_material = black_material
        end

        text_group.transform!(Geom::Transformation.translation(position - tb.center))

        model.commit_operation
        text_group
      end

      def self.create_nivel_symbol(center, nivel_text, scale, font)
        model    = Sketchup.active_model
        entities = model.active_entities
        center   = Geom::Point3d.new(0, 0, 0)

        nivel_text_group = test_text(nivel_text, center, scale, font, TextAlignLeft)
        level_text_width = nivel_text_group.bounds.width

        # Apply black material to text faces
        black_material = model.materials['Black']
        unless black_material
          black_material = model.materials.add('Black')
          black_material.color = Sketchup::Color.new(0, 0, 0)
        end
        
        nivel_text_group.entities.grep(Sketchup::Face).each do |face|
          face.material = black_material
          face.back_material = black_material
        end

        cross_radius = level_text_width / 5.0

        pre_entities = entities.to_a
        model.start_operation("Criar Símbolo de Nível", true)

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

        # Força a divisão da face do círculo pelas linhas
        entities.intersect_with(true, IDENTITY, entities, IDENTITY, true, [circle_face])

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
            if index.even?
              # Black material
              mat = model.materials['Black']
              unless mat
                mat = model.materials.add('Black')
                mat.color = Sketchup::Color.new(0, 0, 0)
              end
            else
              # White material
              mat = model.materials['White']
              unless mat
                mat = model.materials.add('White')
                mat.color = Sketchup::Color.new(255, 255, 255)
              end
            end
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
        nivel_text_group.transform!(translation)

        model.start_operation("Agrupar tudo", true)
        final_group = entities.add_group
        final_group_entities = final_group.entities

        symbol_instance = final_group_entities.add_instance(symbol_group.entities.parent, symbol_group.transformation)
        text_instance   = final_group_entities.add_instance(nivel_text_group.entities.parent, nivel_text_group.transformation)

        symbol_group.erase!
        nivel_text_group.erase!

        model.commit_operation
        final_group
      end

      def self.add_text_to_selected_instance
        model = Sketchup.active_model
        return unless model
        
        selection = model.selection
        grupos = selection.grep(Sketchup::Group)

        if grupos.empty?
          UI.messagebox("Por favor, selecione pelo menos um grupo (mesmo que esteja dentro de outro grupo).")
          return
        end

        last_scale = Sketchup.read_default("Nomeambiente", "scale", 25) || 25
        last_scale = last_scale.to_s
        last_font  = Sketchup.read_default("Nomeambiente", "font", "Century Gothic")
        last_pd    = Sketchup.read_default("Nomeambiente", "pd", "2,60")
        last_nivel = Sketchup.read_default("Nomeambiente", "nivel", "0,00")
        last_altura_piso  = Sketchup.read_default("Nomeambiente", "altura_piso", "0,00")

        last_mostrar_pd    = Sketchup.read_default("Nomeambiente", "mostrar_pd", "Sim")
        last_mostrar_nivel = Sketchup.read_default("Nomeambiente", "mostrar_nivel", "Sim")

        prompts  = ["Escala do Texto:", "Fonte:", "Altura Piso (Z) (m):", "Mostrar PD?", "PD (m):", "Mostrar Nível?", "Nível Piso:"]
        defaults = [last_scale.to_s, last_font.to_s, last_altura_piso.to_s, last_mostrar_pd.to_s, last_pd.to_s, last_mostrar_nivel.to_s, last_nivel.to_s]

        lists = ["", fontes_disponiveis.join("|"), "", "Sim|Não", "", "Sim|Não", ""]

        input = UI.inputbox(prompts, defaults, lists, "Definir Escala, Fonte, Alturas, PD e Nível")
        return if input.nil?

        scale_str, font, altura_piso_str, mostrar_pd, pd_str, mostrar_nivel, nivel_str = input

        Sketchup.write_default("Nomeambiente", "mostrar_pd", mostrar_pd)
        Sketchup.write_default("Nomeambiente", "mostrar_nivel", mostrar_nivel)
        Sketchup.write_default("Nomeambiente", "scale", scale_str)
        Sketchup.write_default("Nomeambiente", "font", font)
        Sketchup.write_default("Nomeambiente", "pd", pd_str)
        Sketchup.write_default("Nomeambiente", "nivel", nivel_str)
        Sketchup.write_default("Nomeambiente", "altura_piso", altura_piso_str)

        scale = scale_str.to_f
        if scale <= 0
          UI.messagebox("Escala deve ser um número positivo.")
          return
        end
        
        altura_corte = 1.45
        altura_piso = altura_piso_str.gsub(',', '.').to_f
        z_height = (altura_piso + altura_corte).m

        layer_name = '-2D-LEGENDA AMBIENTE'
        layer = model.layers[layer_name]
        unless layer
          layer = model.layers.add(layer_name)
        end

        grupos.each do |grupo|
          instance_name = grupo.name.empty? ? "Sem Nome" : grupo.name
          area_m2 = self.calculate_area_of_group(grupo)
          area_str = format('%.2f', area_m2).gsub('.', ',')
          texto = "#{instance_name}\nÁREA: #{area_str} m²"
          texto += "\nPD: #{pd_str}m" if mostrar_pd.strip.downcase == "sim"

          bounds = grupo.bounds
          center = bounds.center
          center.z = 0

          begin
            text_group = test_text(texto, center, scale, font)
            text_group.layer = layer if text_group && text_group.valid?
          rescue => e
            puts "Error creating text for group #{grupo.name}: #{e.message}"
            next
          end

          if mostrar_nivel.strip.downcase == "sim"
            begin
              simbolo_groups = create_nivel_symbol(center, "#{nivel_str} m", scale, font)
              nivel_composite = model.entities.add_group(simbolo_groups) if simbolo_groups

            text_bb = text_group.bounds
            comp_bb = nivel_composite.bounds
            delta_y = text_bb.min.y - comp_bb.max.y - (0.15 / 2.54 * scale)
            nivel_composite.transform!(Geom::Transformation.translation(Geom::Vector3d.new(0, delta_y, 0)))

            text_center_x = text_bb.center.x
            comp_center_x = nivel_composite.bounds.center.x
            delta_x = text_center_x - comp_center_x
            nivel_composite.transform!(Geom::Transformation.translation(Geom::Vector3d.new(delta_x, 0, 0)))

            # Cria grupo final diretamente no model.entities
            final_group = model.entities.add_group
            final_group_entities = final_group.entities


            # Copia as entidades do texto
            text_def = text_group.entities.parent
            text_inst = final_group_entities.add_instance(text_def, text_group.transformation)

            # Copia as entidades do símbolo
            nivel_def = nivel_composite.entities.parent
            nivel_inst = final_group_entities.add_instance(nivel_def, nivel_composite.transformation)

            # Remove os grupos temporários
            text_group.erase! if text_group.valid?
            nivel_composite.erase! if nivel_composite.valid?

            # Define camada
            final_group.layer = layer

            final_group_center = final_group.bounds.center
            translation_to_center = Geom::Transformation.translation(center - final_group_center)
            final_group.transform!(translation_to_center)

            final_group_center = final_group.bounds.center
            translation_to_z_height = Geom::Transformation.translation(Geom::Vector3d.new(0, 0, z_height - final_group_center.z))
            final_group.transform!(translation_to_z_height)

            model.selection.clear
            model.selection.add(final_group)
            rescue => e
              puts "Error creating level symbol for group #{grupo.name}: #{e.message}"
            end
          else
            text_group_center = text_group.bounds.center
            translation_to_z_height = Geom::Transformation.translation(Geom::Vector3d.new(0, 0, z_height - text_group_center.z))
            text_group.transform!(translation_to_z_height)

            model.selection.clear
            model.selection.add(text_group)
          end
        end
      end

  end

  ##################

  module Anotacaocorte

    # Solicita duas entradas do usuário e retorna os valores informados
    def self.get_user_input(prompt1, default_value1, prompt2, default_value2)
      prompts = [prompt1, prompt2]
      defaults = [default_value1.to_s, default_value2.to_s]
      lists = ["", ""]
      UI.inputbox(prompts, defaults, lists, "Configurações de Anotação de Corte")
    end

    # Cria um triângulo preto para indicar as pontas das linhas de corte
    def self.create_black_triangle(entities, position, orientation, scale_factor)
      size = (1 / 2.54) * scale_factor  # Tamanho do triângulo em polegadas ajustado pelo fator de escala
      half_size = size / 2.0
    
      # Definir os vértices do triângulo
      pt1 = [0, -half_size, 0]
      pt2 = [0, half_size, 0]
      pt3 = [size / 4, 0, 0]
    
      # Criar um grupo para o triângulo
      triangle_group = entities.add_group
    
      # Adicionar o triângulo ao grupo
      face = triangle_group.entities.add_face(pt1, pt2, pt3)
    
      # Definir a cor preta para o triângulo
      model = Sketchup.active_model
      black_material = model.materials['Black']
      unless black_material
        black_material = model.materials.add('Black')
        black_material.color = Sketchup::Color.new(0, 0, 0)
      end
      
      face.material = black_material
      face.back_material = black_material
    
      # Criar a transformação para orientar e posicionar o triângulo
      transformation = Geom::Transformation.new(position) *
                       Geom::Transformation.rotation(Geom::Point3d.new(0, 0, 0),
                                                       Geom::Vector3d.new(0, 0, 1),
                                                       Math.atan2(orientation.y, orientation.x))
      triangle_group.transform!(transformation)
    
      triangle_group
    end
    
    # Cria o texto 3D e o agrupa junto às linhas, utilizando o parâmetro entities
    def self.create_text(entities, position, text, font_size, scale_factor)
      # Cria um grupo para o texto como filho do grupo recebido
      text_group = entities.add_group
    
      # Adicionar o texto 3D ao grupo - usar fonte compatível com macOS
      font_name = Sketchup.platform == :platform_osx ? "Arial" : "Century Gothic"
      text_entity = text_group.entities.add_3d_text(text.upcase, TextAlignLeft, font_name,
                                                    false, false, font_size * scale_factor, 0, 0, true, 0)
    
      # Aplicar material preto ao texto
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
      
      # Obter as dimensões do grupo de texto para centralização
      text_bounds = text_group.bounds
      text_width  = text_bounds.width
      text_height = text_bounds.height
    
      # Transformação para centralizar o texto dentro do grupo
      translation = Geom::Transformation.new([-text_width / 2.0, -text_height / 2.0, 0])
      text_group.transform!(translation)
    
      # Posicionar o grupo de texto na posição desejada (z definida como 0 para alinhamento relativo)
      text_translation = Geom::Transformation.new(position)
      text_group.transform!(text_translation)
    
      text_group
    end
    
    # Desenha uma linha composta por traços e pontos entre dois pontos
    def self.draw_dashed_dotted_line(entities, start_point, end_point, dash_length, dot_diameter, gap_length)
      # Calcular o vetor da linha e o comprimento total
      vector = Geom::Vector3d.new(end_point[0] - start_point[0],
                                  end_point[1] - start_point[1],
                                  end_point[2] - start_point[2])
      length = vector.length
      unit_vector = vector.normalize
    
      # Vetor perpendicular para os dots (no plano XY)
      perpendicular_vector = Geom::Vector3d.new(0, 0, 1)
    
      current_position = start_point
      while length > 0
        # Adicionar o traço
        dash_end = [current_position[0] + unit_vector.x * dash_length,
                    current_position[1] + unit_vector.y * dash_length,
                    current_position[2] + unit_vector.z * dash_length]
        entities.add_line(current_position, dash_end)
        
        length -= dash_length
        current_position = dash_end
    
        # Adicionar o ponto
        dot_center = [current_position[0] + unit_vector.x * (gap_length / 2.0),
                      current_position[1] + unit_vector.y * (gap_length / 2.0),
                      current_position[2] + unit_vector.z * (gap_length / 2.0)]
        
        # Criar um círculo para o dot e a face correspondente
        dot_circle = entities.add_circle(dot_center, perpendicular_vector, dot_diameter / 2.0)
        entities.add_face(dot_circle)
        
        length -= dot_diameter
        current_position = [dot_center[0] + unit_vector.x * (gap_length / 2.0),
                            dot_center[1] + unit_vector.y * (gap_length / 2.0),
                            dot_center[2] + unit_vector.z * (gap_length / 2.0)]
        length -= gap_length
      end
    end
    
    # Cria as linhas de anotações a partir dos planos de corte presentes no modelo
    def self.create_lines_from_section_planes
      model = Sketchup.active_model
      return unless model
      
      entities = model.entities
    
      # Obter todos os planos de corte do modelo
      section_planes = entities.grep(Sketchup::SectionPlane)
      if section_planes.empty?
        UI.messagebox("Não há planos de corte no modelo.")
        return
      end
    
      # Obter as dimensões do modelo para delimitar as linhas
      model_bb = model.bounds
    
      # Solicitar ao usuário a altura das anotações (em cm) e o fator de escala
      user_inputs = get_user_input('Altura das Anotações (em cm): ', '145', 'Escala: ', '25')
      return if user_inputs.nil? || user_inputs[0].to_f <= 0 || user_inputs[1].to_f <= 0
    
      line_height_cm = user_inputs[0].to_f
      scale_factor  = user_inputs[1].to_f
      line_height   = line_height_cm / 2.54  # Converter cm para polegadas
    
      # Criar um grupo para todas as linhas de corte
      all_lines_group = entities.add_group
      all_lines_group.name = "Todas as Linhas de Corte"
    
      # Adicionar o grupo à camada de anotações de cortes
      layer_name = '-2D-LEGENDA CORTES'
      layer = model.layers[layer_name]
      unless layer
        layer = model.layers.add(layer_name)
      end
      all_lines_group.layer = layer
    
      # Parâmetros para o estilo da linha (traço, ponto e espaço)
      dash_length = 20 / 2.54  # 20 cm convertidos para polegadas (ajuste conforme necessário)
      dot_diameter = 1 / 2.54  # 1 cm convertido para polegadas
      gap_length = 10 / 2.54   # 10 cm convertido para polegadas
    
      section_planes.each do |entity|
        begin
          # Obter a orientação do plano de corte
          plane = entity.get_plane
          orientation = Geom::Vector3d.new(plane[0], plane[1], plane[2])
    
        # Ignorar planos horizontais (vertical é quando z.abs > 0.9)
        if orientation.z.abs > 0.9
          next
        end
    
        # Posição do plano de corte
        position = entity.bounds.center
    
        # Criar um grupo individual para a linha (o texto ficará agrupado junto)
        line_group = all_lines_group.entities.add_group
        line_group.name = "Linha de Corte - #{position.inspect}"
    
        # Determinar a direção da linha com base na orientação
        if orientation.y.abs > orientation.x.abs
          # Linha horizontal no sentido X
          line_start = [model_bb.min.x - (scale_factor / 2.54), position.y, 0]
          line_end   = [model_bb.max.x + (scale_factor / 2.54), position.y, 0]
          text_offset_direction = :x
        else
          # Linha vertical no sentido Y
          line_start = [position.x, model_bb.min.y - (scale_factor / 2.54), 0]
          line_end   = [position.x, model_bb.max.y + (scale_factor / 2.54), 0]
          text_offset_direction = :y
        end
    
        # Desenha a linha de corte com estilo traço-ponto
        draw_dashed_dotted_line(line_group.entities, line_start, line_end, dash_length, dot_diameter, gap_length)
    
        # Cria os triângulos nas pontas da linha
        create_black_triangle(line_group.entities, line_start, orientation, scale_factor)
        create_black_triangle(line_group.entities, line_end, orientation, scale_factor)
    
        # Calcula o tamanho base do texto para os endpoints
        text_height = (0.3 / 2.54)  # Tamanho base da fonte em polegadas
        afas_text = text_height * scale_factor
    
        # Cria o texto para cada ponta, utilizando z = 0 (o grupo será depois deslocado)
        if text_offset_direction == :x
          create_text(line_group.entities, [line_start[0], line_start[1] - afas_text * orientation.y, 0],
                      entity.name || "Sem nome", text_height, scale_factor)
          create_text(line_group.entities, [line_end[0], line_end[1] - afas_text * orientation.y, 0],
                      entity.name || "Sem nome", text_height, scale_factor)
        else
          create_text(line_group.entities, [line_start[0] - afas_text * orientation.x, line_start[1], 0],
                      entity.name || "Sem nome", text_height, scale_factor)
          create_text(line_group.entities, [line_end[0] - afas_text * orientation.x, line_end[1], 0],
                      entity.name || "Sem nome", text_height, scale_factor)
        end
    
        # Posicionar o grupo da linha na altura especificada
        transformation = Geom::Transformation.new([0, 0, line_height])
        line_group.transform!(transformation)
        line_group.layer = layer
        rescue => e
          puts "Error processing section plane #{entity.inspect}: #{e.message}"
        end
      end
    
      UI.messagebox("Anotações de Corte criadas com sucesso!")
    end
    
  end  # module Anotacaocorte

  ##################
  
  # Criação da Toolbar e dos comandos

  toolbar = UI::Toolbar.new('FM - Anotações')

  # Botão para o comando "Nome do Ambiente"
  cmd_nomeambiente = UI::Command.new('Nome do Ambiente') {
    Nomeambiente.add_text_to_selected_instance
  }
  icon_nomeambiente = File.join(File.dirname(__FILE__), 'icones', 'nomeambiente.png')
  cmd_nomeambiente.small_icon = icon_nomeambiente
  cmd_nomeambiente.large_icon = icon_nomeambiente
  cmd_nomeambiente.tooltip = 'Nome do Ambiente'
  cmd_nomeambiente.status_bar_text = 'Adiciona automaticamente o nome do ambiente de acordo com a instância do piso.'
  toolbar.add_item(cmd_nomeambiente)

  # Botão para o comando "Anotação de Cortes"
  cmd_anotacao_cortes = UI::Command.new('Anotação de Cortes') {
    Anotacaocorte.create_lines_from_section_planes
  }
  icon_anotacao_cortes = File.join(File.dirname(__FILE__), 'icones', 'anotacaocorte.png')
  if File.exist?(icon_anotacao_cortes)
    cmd_anotacao_cortes.small_icon = icon_anotacao_cortes
    cmd_anotacao_cortes.large_icon = icon_anotacao_cortes
  else
    UI.messagebox("Ícone não encontrado: #{icon_anotacao_cortes}")
  end
  cmd_anotacao_cortes.tooltip = 'Anotação de Cortes'
  cmd_anotacao_cortes.status_bar_text = 'Adiciona automaticamente as marcações de corte de seção.'
  toolbar.add_item(cmd_anotacao_cortes)

  toolbar.show

end  # module FM_Extensions
