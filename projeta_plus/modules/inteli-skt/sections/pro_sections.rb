# encoding: UTF-8
require 'sketchup.rb'
require 'json'
require_relative '../shared/pro_view_configs_base.rb'
require_relative 'pro_sections_persistence.rb'
require_relative 'pro_sections_settings.rb'
require_relative 'pro_sections_groups.rb'

module ProjetaPlus
  module Modules
    module ProSections
      extend ProjetaPlus::Modules::ProViewConfigsBase
      
      # ========================================
      # SETTINGS AND CONSTANTS
      # ========================================

      ENTITY_NAME = "sections"
      SETTINGS_KEY = "sections_settings"
      
      # Distances and offsets
      EXTEND_DISTANCE = -100.cm
      CAMERA_DISTANCE = 500.cm
      
      # Prefixes and nomenclature
      LAYER_PREFIX = "-CORTES-"
      AUTO_VIEW_LETTERS = %w[a b c d]
      STANDARD_SECTIONS = %w[a b c d]

      # Paths para arquivos JSON
      PLUGIN_PATH = File.dirname(__FILE__)
      JSON_DATA_PATH = File.join(PLUGIN_PATH, 'json_data')
      STYLES_PATH = File.join(File.dirname(PLUGIN_PATH), 'styles')
      DEFAULT_DATA_FILE = File.join(JSON_DATA_PATH, 'sections_data.json')
      USER_DATA_FILE = File.join(JSON_DATA_PATH, 'user_sections_data.json')
      SETTINGS_FILE = File.join(JSON_DATA_PATH, 'sections_settings.json')

      # ========================================
      # MÉTODOS PÚBLICOS - DELEGAÇÃO
      # ========================================

      # Retorna as configurações de seções do JSON (com grupos e segmentos)
      def self.get_sections
        result = ProSectionsPersistence.load_from_json
        if result[:success]
          { success: true, data: result[:data], message: "Seções carregadas" }
        else
          { success: false, message: result[:message], data: { 'groups' => [] } }
        end
      rescue StandardError => e
        log_error("get_sections", e)
        { success: false, message: "Erro ao carregar seções: #{e.message}", data: { 'groups' => [] } }
      end

      # Delegação para persistência
      def self.save_to_json(json_data)
        ProSectionsPersistence.save_to_json(json_data)
      end

      def self.load_from_json
        ProSectionsPersistence.load_from_json
      end

      def self.load_default_data
        ProSectionsPersistence.load_default_data
      end

      def self.load_from_file
        ProSectionsPersistence.load_from_file
      end

      # Delegação para settings
      def self.get_sections_settings
        ProSectionsSettings.get_sections_settings
      end

      def self.save_sections_settings(params)
        ProSectionsSettings.save_sections_settings(params)
      end

      def self.get_available_styles_for_sections
        ProSectionsSettings.get_available_styles_for_sections
      end

      def self.get_available_layers_for_sections
        ProSectionsSettings.get_available_layers_for_sections
      end

      def self.apply_current_style_to_sections
        ProSectionsSettings.apply_current_style_to_sections
      end

      def self.get_current_active_layers
        ProSectionsSettings.get_current_active_layers
      end

      def self.get_current_active_layers_filtered(available_layers)
        ProSectionsSettings.get_current_active_layers_filtered(available_layers)
      end

      # Delegação para grupos
      def self.add_group(params)
        ProSectionsGroups.add_group(params)
      end

      def self.update_group(id, params)
        ProSectionsGroups.update_group(id, params)
      end

      def self.delete_group(id)
        ProSectionsGroups.delete_group(id)
      end

      def self.add_segment(group_id, params)
        ProSectionsGroups.add_segment(group_id, params)
      end

      def self.update_segment(group_id, segment_id, params)
        ProSectionsGroups.update_segment(group_id, segment_id, params)
      end

      def self.delete_segment(group_id, segment_id)
        ProSectionsGroups.delete_segment(group_id, segment_id)
      end

      def self.duplicate_scenes_with_segment(params)
        ProSectionsGroups.duplicate_scenes_with_segment(params)
      end

      def self.get_model_scenes
        ProSectionsGroups.get_model_scenes
      end

      # ========================================
      # MÉTODOS DE CRIAÇÃO da seçãoS (Botões Iniciais)
      # ========================================

      # Cria cortes padrões (A, B, C, D)
      def self.create_standard_sections
        model = Sketchup.active_model
        bounds = model.bounds
        center = bounds.center

        sections_config = standard_sections_config(bounds, center)

        model.start_operation("Criar Seções Padrões", true)

        # Criar layer única para todos os cortes padrões
        layer = create_or_get_layer(model, "#{LAYER_PREFIX}GERAIS")

        created = []
        sections_config.each do |name, config|
          remove_section_and_page(model, name)
          
          sp = create_section_plane(model, name, config[:position], config[:direction])
          
          # Atribuir a mesma layer para todos os cortes
          sp.layer = layer
          
          # Criar cena alinhada ao corte
          create_aligned_scene(model, sp, config[:position], config[:direction])
          
          created << name
        end

        model.commit_operation

        {
          success: true,
          message: "Seções padrões (#{created.join(', ')}) criados com sucesso",
          count: created.length
        }
      rescue StandardError => e
        model.abort_operation if model
        log_error("create_standard_sections", e)
        { success: false, message: "Erro ao criar cortes padrões: #{e.message}" }
      end

      def self.create_auto_views(params = {})
        model = Sketchup.active_model
        sel = model.selection.first

        return { success: false, message: "Selecione um objeto para criar os cortes" } unless sel

        # Pegar nome do ambiente dos parâmetros vindos do frontend
        ambiente = (params['environmentName'] || params[:environmentName]).to_s.strip.downcase
        return invalid_input("Nome do ambiente é obrigatório") if ambiente.empty?

        prefixo = ambiente.upcase  # Maiúsculo apenas para a layer
        bb = sel.bounds
        center = bb.center

        sections_config = standard_sections_config(bb, center)

        model.start_operation("Criar Seções por Ambiente", true)

        # Criar layer para o ambiente (maiúsculo)
        layer = create_or_get_layer(model, "#{LAYER_PREFIX}#{prefixo}")

        created = []
        sections_config.each do |letter, config|
          # Nome da cena em minúsculo
          nome_final = "#{ambiente}_#{letter}"
          
          remove_section_and_page(model, nome_final)

          sp = create_section_plane(model, nome_final, config[:position], config[:direction])
          sp.layer = layer
          
          # Criar cena alinhada ao corte
          create_aligned_scene(model, sp, config[:position], config[:direction])
          
          created << nome_final
        end

        model.commit_operation

        {
          success: true,
          message: "Seções por ambiente criadas para #{ambiente}: #{created.join(', ')}",
          count: created.length
        }
      rescue StandardError => e
        model.abort_operation if model
        log_error("create_auto_views", e)
        { success: false, message: "Erro ao criar seções por ambiente: #{e.message}" }
      end

      # Cria corte individual
      def self.create_individual_section(params)
        model = Sketchup.active_model
        params = normalize_params(params)
        
        direction_type = params[:direction_type]
        name = params[:name]

        return invalid_input("Tipo de direção e nome são obrigatórios") unless direction_type && name

        bounds = model.bounds
        center = bounds.center

        config = direction_configs(bounds, center)[direction_type.downcase]
        return invalid_input("Tipo de direção inválido") unless config

        model.start_operation("Criar Seção Individual", true)

        remove_section_and_page(model, name)

        sp = create_section_plane(model, name, config[:position], config[:direction])
        
        # Criar cena alinhada ao corte
        create_aligned_scene(model, sp, config[:position], config[:direction])

        model.commit_operation

        {
          success: true,
          message: "Seção '#{name}' criado com sucesso",
          section: build_section_config(sp)
        }
      rescue StandardError => e
        model.abort_operation if model
        log_error("create_individual_section", e)
        { success: false, message: "Erro ao criar corte individual: #{e.message}" }
      end

      # ========================================
      # MÉTODOS PRIVADOS (core)
      # ========================================

      private

      # Cria um section plane
      def self.create_section_plane(model, name, position, direction)
        pos_point = Geom::Point3d.new(*position)
        dir_vector = Geom::Vector3d.new(*direction)
        
        sp = model.entities.add_section_plane(pos_point, dir_vector)
        sp.name = name
        sp
      end

      # Cria uma cena alinhada ao section plane
      def self.create_aligned_scene(model, section_plane, position, direction)
        page = model.pages.add(section_plane.name)
        page.use_section_planes = true
        
        model.pages.selected_page = page
        section_plane.activate
        
        # Alinhar câmera ao plano da seção
        align_camera_to_section(model, direction)
        
        # Aplicar configurações salvas (estilo e camadas)
        apply_saved_settings_to_scene(model)
        
        # CRÍTICO: Atualizar a página para salvar o estado da câmera
        page.update
        
        page
      end

      # Aplica as configurações salvas (estilo e camadas) à cena atual
      def self.apply_saved_settings_to_scene(model)
        settings_result = ProSectionsSettings.get_sections_settings
        return unless settings_result[:success]
        
        settings = settings_result[:settings]
        
        # Aplicar estilo se definido (usando método do ProViewConfigsBase)
        if settings['style'] && !settings['style'].empty?
          apply_style(settings['style'])
        end
        
        # Aplicar camadas ativas se definidas (usando método do ProViewConfigsBase)
        if settings['activeLayers'] && settings['activeLayers'].any?
          apply_layers_visibility(settings['activeLayers'])
        end
      rescue StandardError => e
        log_error("apply_saved_settings_to_scene", e)
        # Não falhar a criação da cena se houver erro ao aplicar configurações
      end

      # Alinha a câmera para olhar diretamente para o plano da seção
      def self.align_camera_to_section(model, direction)
        view = model.active_view
        
        # Eye: direção invertida multiplicada por -1000 (posição absoluta)
        eye = [direction[0] * -1000, direction[1] * -1000, direction[2] * -1000]
        
        # Target: origem absoluta [0, 0, 0]
        target = [0, 0, 0]
        
        # Up: sempre Z para cima
        up = [0, 0, 1]
        
        # Criar nova câmera e atribuir à view (igual ao código original)
        view.camera = Sketchup::Camera.new(eye, target, up, true)
        view.camera.perspective = false
        
        # Zoom extents para enquadrar o modelo
        view.zoom_extents
      end

      # Constrói configuração de uma seção
      def self.build_section_config(section_plane)
        plane = section_plane.get_plane
        normal = Geom::Vector3d.new(plane[0], plane[1], plane[2])
        position = Geom::Point3d.new(0, 0, 0).offset(normal, plane[3])
        
        {
          id: section_plane.entityID.to_s,
          name: section_plane.name.empty? ? "Section_#{section_plane.entityID}" : section_plane.name,
          position: position.to_a,
          direction: normal.to_a,
          active: section_plane.active?
        }
      end

      # ========================================
      # MÉTODOS AUXILIARES
      # ========================================

      # Normaliza parâmetros (aceita strings e símbolos)
      def self.normalize_params(params)
        {
          id: params['id'] || params[:id],
          name: params['name'] || params[:name],
          style: params['style'] || params[:style],
          activeLayers: params['activeLayers'] || params[:activeLayers] || [],
          direction_type: params['directionType'] || params[:directionType] || params['direction_type'] || params[:direction_type]
        }
      end

      # Remove seção e página associada
      def self.remove_section_and_page(model, name)
        # Remove section plane
        sp = find_section_by_name(model, name)
        model.entities.erase_entities(sp) if sp
        
        # Remove página
        page = model.pages.find { |p| p.name == name }
        model.pages.erase(page) if page
      end

      # Busca seção por nome (case insensitive)
      def self.find_section_by_name(model, name)
        model.entities.grep(Sketchup::SectionPlane)
          .find { |sp| sp.name.casecmp(name.to_s).zero? }
      end

      # Cria ou obtém layer existente
      def self.create_or_get_layer(model, name)
        model.layers[name] || model.layers.add(name)
      end

      # Standard sections configuration
      def self.standard_sections_config(bounds, center)
        {
          'a' => { 
            position: [center.x, bounds.max.y + EXTEND_DISTANCE, center.z], 
            direction: [0, 1, 0] 
          },
          'b' => { 
            position: [bounds.max.x + EXTEND_DISTANCE, center.y, center.z], 
            direction: [1, 0, 0] 
          },
          'c' => { 
            position: [center.x, bounds.min.y - EXTEND_DISTANCE, center.z], 
            direction: [0, -1, 0] 
          },
          'd' => { 
            position: [bounds.min.x - EXTEND_DISTANCE, center.y, center.z], 
            direction: [-1, 0, 0] 
          }
        }
      end

      # Direction configurations (same as standard sections but with descriptive names)
      def self.direction_configs(bounds, center)
        {
          'front' => { 
            position: [center.x, bounds.max.y + EXTEND_DISTANCE, center.z], 
            direction: [0, 1, 0] 
          },
          'frente' => { 
            position: [center.x, bounds.max.y + EXTEND_DISTANCE, center.z], 
            direction: [0, 1, 0] 
          },
          'right' => { 
            position: [bounds.max.x + EXTEND_DISTANCE, center.y, center.z], 
            direction: [1, 0, 0] 
          },
          'direita' => { 
            position: [bounds.max.x + EXTEND_DISTANCE, center.y, center.z], 
            direction: [1, 0, 0] 
          },
          'back' => { 
            position: [center.x, bounds.min.y - EXTEND_DISTANCE, center.z], 
            direction: [0, -1, 0] 
          },
          'voltar' => { 
            position: [center.x, bounds.min.y - EXTEND_DISTANCE, center.z], 
            direction: [0, -1, 0] 
          },
          'left' => { 
            position: [bounds.min.x - EXTEND_DISTANCE, center.y, center.z], 
            direction: [-1, 0, 0] 
          },
          'esquerda' => { 
            position: [bounds.min.x - EXTEND_DISTANCE, center.y, center.z], 
            direction: [-1, 0, 0] 
          }
        }
      end

      # Retorno para input inválido
      def self.invalid_input(reason)
        { success: false, message: reason }
      end

      # Log de erros (apenas em modo debug)
      def self.log_error(context, error)
        return unless defined?(Sketchup) && Sketchup.respond_to?(:debug_mode?) && Sketchup.debug_mode?
        
        timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        puts "[#{timestamp}] #{context}: #{error.message}"
        puts error.backtrace.first(5).join("\n") if error.backtrace
      end

    end
  end
end
