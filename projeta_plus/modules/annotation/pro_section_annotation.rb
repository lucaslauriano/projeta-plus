# encoding: UTF-8
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb' # Certifique-se que pro_settings.rb está carregado
require_relative '../settings/pro_settings_utils.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProSectionAnnotation

      DEFAULT_SECTION_LINE_HEIGHT_CM = ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm
      DEFAULT_SECTION_SCALE_FACTOR = ProjetaPlus::Modules::ProSettingsUtils.get_scale.to_s
      DEFAULT_SECTION_SCALE = 2.54

      def self.get_defaults
        {
          line_height_cm: Sketchup.read_default("SectionAnnotation", "line_height_cm", DEFAULT_SECTION_LINE_HEIGHT_CM),
          scale_factor: Sketchup.read_default("SectionAnnotation", "scale_factor", DEFAULT_SECTION_SCALE_FACTOR)
        }
      end

      def self.create_black_triangle(entities, position, orientation, scale_factor)
        size = (1 / DEFAULT_SECTION_SCALE) * scale_factor 
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
      
      def self.create_text(entities, position, text, font_size, scale_factor)
        model = Sketchup.active_model
        text_group = entities.add_group
        
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

    def self.draw_dashed_dotted_line(entities, start_point, end_point, dash_length, dot_diameter, gap_length)
      vector = Geom::Vector3d.new(end_point[0] - start_point[0], end_point[1] - start_point[1], end_point[2] - start_point[2])
      total_length = vector.length
      unit_vector = vector.normalize
      perpendicular_vector = Geom::Vector3d.new(0, 0, 1)
      
      current_position = start_point
      remaining_length = total_length
      
      while remaining_length > 0
        # Desenha o traço longo
        if remaining_length >= dash_length
          dash_end = [current_position[0] + unit_vector.x * dash_length,
                      current_position[1] + unit_vector.y * dash_length,
                      current_position[2] + unit_vector.z * dash_length]
          entities.add_line(current_position, dash_end)
          current_position = dash_end
          remaining_length -= dash_length
        else
          # Traço final menor
          dash_end = [current_position[0] + unit_vector.x * remaining_length,
                      current_position[1] + unit_vector.y * remaining_length,
                      current_position[2] + unit_vector.z * remaining_length]
          entities.add_line(current_position, dash_end)
          break
        end
        
        # Gap antes do ponto
        if remaining_length >= gap_length
          current_position = [current_position[0] + unit_vector.x * gap_length,
                              current_position[1] + unit_vector.y * gap_length,
                              current_position[2] + unit_vector.z * gap_length]
          remaining_length -= gap_length
        else
          break
        end
        
        # Desenha o ponto (círculo)
        if remaining_length > 0
          dot_circle = entities.add_circle(current_position, perpendicular_vector, dot_diameter / 2.0)
          entities.add_face(dot_circle)
        end
        
        # Gap após o ponto
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
      
      # Interactive tool class for section annotation
      class InteractiveSectionAnnotationTool
        
        def initialize
          # Não precisa mais de args do frontend
        end

        def activate
          Sketchup.set_status_text(ProjetaPlus::Localization.t("messages.section_annotation_prompt"), SB_PROMPT)
          @view = Sketchup.active_model.active_view
        end

        def deactivate(view)
          view.invalidate
        end

        def onLButtonDown(flags, x, y, view)
          model = Sketchup.active_model
          
          # Pick entity at click location
          picked_entity = view.pick_helper(x, y)
          picked_entity.do_pick(x, y)
          entity = picked_entity.best_picked
          
          # Check if clicked on a group or component
          unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
            ::UI.messagebox(ProjetaPlus::Localization.t("messages.click_on_group_component_for_section"), MB_OK, ProjetaPlus::Localization.t("plugin_name"))
            return
          end
          
          model.start_operation(ProjetaPlus::Localization.t("commands.section_annotation_operation_name"), true)
          
          # Create annotations centered on the clicked group/component
          result = ProjetaPlus::Modules::ProSectionAnnotation.create_lines_for_entity(nil, entity)

          if result[:success]
            model.commit_operation
            ::UI.messagebox(result[:message], MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          else
            model.abort_operation
            ::UI.messagebox(result[:message], MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          end
          
          Sketchup.active_model.select_tool(nil) # Deactivate tool after click
        rescue StandardError => e
          model.abort_operation if model
          ::UI.messagebox("#{ProjetaPlus::Localization.t("messages.unexpected_error")}: #{e.message}", MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          Sketchup.active_model.select_tool(nil)
        end

        def onKeyDown(key, repeat, flags, view)
          Sketchup.active_model.select_tool(nil) if key == 27 # ESC key
        end
      end

      # Start interactive section annotation (called from frontend)
      def self.start_interactive_annotation(args = nil)
        if Sketchup.active_model.nil?
          return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") }
        end
        Sketchup.active_model.select_tool(InteractiveSectionAnnotationTool.new)
        { success: true, message: ProjetaPlus::Localization.t("messages.section_tool_activated") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_activating_tool") + ": #{e.message}" }
      end

      # Create section lines for a specific entity (called from interactive tool)
      def self.create_lines_for_entity(args, entity)
        model = Sketchup.active_model
        entities = model.entities
      
        # Mensagens traduzidas
        no_planes_msg = ProjetaPlus::Localization.t("messages.section_annotation_error_no_plane")
        invalid_values_msg = ProjetaPlus::Localization.t("messages.invalid_section_annotation_values")
        section_success_msg = ProjetaPlus::Localization.t("messages.section_annotation_success")
        
        section_planes = entities.grep(Sketchup::SectionPlane)
        if section_planes.empty?
          return { success: false, message: no_planes_msg }
        end
      
        # Usa valores fixos do módulo (não vem mais do frontend)
        line_height_cm = DEFAULT_SECTION_LINE_HEIGHT_CM.to_f
        scale_factor = DEFAULT_SECTION_SCALE_FACTOR.to_f
        
        line_height = line_height_cm / DEFAULT_SECTION_SCALE # Converter cm para polegadas
      
        # Use the entity's bounding box for positioning
        entity_bounds = entity.bounds
        entity_center = entity_bounds.center
        
        # Extend lines beyond the entity bounds
        extend_distance = (scale_factor / DEFAULT_SECTION_SCALE) * 2 # Extend lines beyond entity
        bb = Geom::BoundingBox.new
        bb.add([entity_bounds.min.x - extend_distance, entity_bounds.min.y - extend_distance, entity_bounds.min.z])
        bb.add([entity_bounds.max.x + extend_distance, entity_bounds.max.y + extend_distance, entity_bounds.max.z])
        
        layer_name = '-2D-LEGENDA CORTES'
        layer = model.layers.add(layer_name)

        all_lines_group = entities.add_group
        all_lines_group.name = ProjetaPlus::Localization.t("commands.all_section_lines_group_name")
        all_lines_group.layer = layer
      
        # Constantes para o estilo de linha (padrão arquitetônico muito visível - 100% maior)
        dash_length = 20 / DEFAULT_SECTION_SCALE;     # Traço longo muito visível (50mm - dobrado)
        dot_diameter = 0.4 / DEFAULT_SECTION_SCALE;   # Ponto muito grande e visível (5mm de diâmetro - dobrado)
        gap_length = 0.4 / DEFAULT_SECTION_SCALE      # Espaçamento muito maior para legibilidade (10mm - dobrado)
        font_size = (0.3 / DEFAULT_SECTION_SCALE)

        section_planes.each_with_index do |entity, i|
          plane = entity.get_plane
          orientation = Geom::Vector3d.new(plane[0], plane[1], plane[2])
      
          if orientation.z.abs > 0.9 # Ignora planos de corte horizontais
            next
          end
      
          position = entity.bounds.center
      
          line_group = all_lines_group.entities.add_group
          line_group.name = "#{ProjetaPlus::Localization.t("commands.section_line_group_name")} - #{entity.name || position.inspect}"
      
          # Determina as extremidades da linha baseadas no centro do grupo/componente
          if orientation.y.abs > orientation.x.abs
            # Plano mais alinhado com Y - linha horizontal passando pelo centro
            line_start = [bb.min.x - (scale_factor / DEFAULT_SECTION_SCALE), position.y, 0]
            line_end   = [bb.max.x + (scale_factor / DEFAULT_SECTION_SCALE), position.y, 0]
            text_offset_direction = :x
          else
            # Plano mais alinhado com X - linha vertical passando pelo centro
            line_start = [position.x, bb.min.y - (scale_factor / DEFAULT_SECTION_SCALE), 0]
            line_end   = [position.x, bb.max.y + (scale_factor / DEFAULT_SECTION_SCALE), 0]
            text_offset_direction = :y
          end
      
          draw_dashed_dotted_line(line_group.entities, line_start, line_end, dash_length, dot_diameter, gap_length)
          create_black_triangle(line_group.entities, line_start, orientation, scale_factor)
          create_black_triangle(line_group.entities, line_end, orientation, scale_factor)
          
          label = entity.name.empty? ? ProjetaPlus::Localization.t("messages.section_label_default_name").gsub("%{number}", (i+1).to_s) : entity.name
          afas_text = font_size * scale_factor
      
          # Posiciona o texto nas extremidades
          if text_offset_direction == :x
            create_text(line_group.entities, [line_start[0], line_start[1] - afas_text * orientation.y, 0],
                        label, font_size, scale_factor)
            create_text(line_group.entities, [line_end[0], line_end[1] - afas_text * orientation.y, 0],
                        label, font_size, scale_factor)
          else
            create_text(line_group.entities, [line_start[0] - afas_text * orientation.x, line_start[1], 0],
                        label, font_size, scale_factor)
            create_text(line_group.entities, [line_end[0] - afas_text * orientation.x, line_end[1], 0],
                        label, font_size, scale_factor)
          end
          
          # Move o grupo para a altura final
          line_group.transform!(Geom::Transformation.new([0, 0, line_height]))
          line_group.layer = layer
        end
        
        { success: true, message: section_success_msg }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_creating_section_annotations") + ": #{e.message}" }
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
      
        line_height = line_height_cm / DEFAULT_SECTION_SCALE # Converter cm para polegadas (unidade interna do SketchUp)
      
        model.start_operation(ProjetaPlus::Localization.t("commands.section_annotation_operation_name"), true)
        
        bb = Geom::BoundingBox.new
        selection.each { |e| bb.add(e.bounds) } # Bounding box da seleção para determinar a extensão das linhas
        
        layer_name = '-2D-LEGENDA CORTES'
        layer      = model.layers.add(layer_name)

        all_lines_group = entities.add_group
        all_lines_group.name = ProjetaPlus::Localization.t("commands.all_section_lines_group_name")
        all_lines_group.layer = layer
      
        # Constantes para o estilo de linha (valores muito maiores - 100% de aumento)
        dash_length = 50.mm # Traço muito longo e visível (50mm - dobrado)
        dot_diameter = 5.mm # Ponto muito grande e visível (5mm - dobrado)
        gap_length = 5.mm # Espaçamento muito maior (5mm - dobrado)

        font_size = (0.3 / DEFAULT_SECTION_SCALE) # Base para o tamanho do texto (em polegadas)

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
            line_start = [bb.min.x - (scale_factor / DEFAULT_SECTION_SCALE), position.y, 0] # Adiciona um offset para que a linha saia um pouco da seleção
            line_end   = [bb.max.x + (scale_factor / DEFAULT_SECTION_SCALE), position.y, 0]
            text_offset_direction = :x
          else
            # Plano de corte mais alinhado com o eixo X (corte "vertical" no modelo)
            line_start = [position.x, bb.min.y - (scale_factor / DEFAULT_SECTION_SCALE), 0]
            line_end   = [position.x, bb.max.y + (scale_factor / DEFAULT_SECTION_SCALE), 0]
            text_offset_direction = :y
          end
      
          draw_dashed_dotted_line(line_group.entities, line_start, line_end, dash_length, dot_diameter, gap_length)
          create_black_triangle(line_group.entities, line_start, orientation, scale_factor)
          create_black_triangle(line_group.entities, line_end, orientation, scale_factor)
          
          label = entity.name.empty? ? ProjetaPlus::Localization.t("messages.section_label_default_name").gsub("%{number}", (i+1).to_s) : entity.name
          afas_text = font_size * scale_factor # Offset do texto
      
          # Posiciona o texto nas extremidades
          if text_offset_direction == :x
            create_text(line_group.entities, [line_start[0], line_start[1] - afas_text * orientation.y, 0],
                        label, font_size, scale_factor)
            create_text(line_group.entities, [line_end[0], line_end[1] - afas_text * orientation.y, 0],
                        label, font_size, scale_factor)
          else
            create_text(line_group.entities, [line_start[0] - afas_text * orientation.x, line_start[1], 0],
                        label, font_size, scale_factor)
            create_text(line_group.entities, [line_end[0] - afas_text * orientation.x, line_end[1], 0],
                        label, font_size, scale_factor)
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