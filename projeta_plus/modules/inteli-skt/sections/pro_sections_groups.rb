# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module ProSectionsGroups
      extend self

      # ========================================
      # CONSTANTES
      # ========================================
      
      PLUGIN_PATH = File.dirname(__FILE__)
      JSON_DATA_PATH = File.join(PLUGIN_PATH, 'json_data')
      STYLES_PATH = File.join(File.dirname(PLUGIN_PATH), 'styles')
      DEFAULT_DATA_FILE = File.join(JSON_DATA_PATH, 'sections_data.json')
      USER_DATA_FILE = File.join(JSON_DATA_PATH, 'user_sections_data.json')

      # ========================================
      # MÉTODOS DE GRUPOS
      # ========================================

      def add_group(params)
        require_relative 'pro_sections_persistence'
        result = ProjetaPlus::Modules::ProSectionsPersistence.load_from_json
        return result unless result[:success]

        data = result[:data]
        data['groups'] ||= []

        new_group = {
          'id' => params['id'] || params[:id] || Time.now.to_i.to_s,
          'name' => params['name'] || params[:name] || 'Novo Grupo',
          'segments' => []
        }

        data['groups'] << new_group

        save_result = ProjetaPlus::Modules::ProSectionsPersistence.save_to_json(data)
        return save_result unless save_result[:success]

        { success: true, message: "Grupo adicionado com sucesso", group: new_group }
      rescue StandardError => e
        log_error("add_group", e)
        { success: false, message: "Erro ao adicionar grupo: #{e.message}" }
      end

      def update_group(id, params)
        require_relative 'pro_sections_persistence'
        result = ProjetaPlus::Modules::ProSectionsPersistence.load_from_json
        return result unless result[:success]

        data = result[:data]
        groups = data['groups'] || []

        group = groups.find { |g| g['id'] == id }
        return { success: false, message: "Grupo não encontrado" } unless group

        group['name'] = params['name'] || params[:name] if params['name'] || params[:name]

        save_result = ProjetaPlus::Modules::ProSectionsPersistence.save_to_json(data)
        return save_result unless save_result[:success]

        { success: true, message: "Grupo atualizado com sucesso" }
      rescue StandardError => e
        log_error("update_group", e)
        { success: false, message: "Erro ao atualizar grupo: #{e.message}" }
      end

      def delete_group(id)
        require_relative 'pro_sections_persistence'
        result = ProjetaPlus::Modules::ProSectionsPersistence.load_from_json
        return result unless result[:success]

        data = result[:data]
        groups = data['groups'] || []

        group = groups.find { |g| g['id'] == id }
        return { success: false, message: "Grupo não encontrado" } unless group

        groups.delete(group)
        data['groups'] = groups

        save_result = ProjetaPlus::Modules::ProSectionsPersistence.save_to_json(data)
        return save_result unless save_result[:success]

        { success: true, message: "Grupo removido com sucesso" }
      rescue StandardError => e
        log_error("delete_group", e)
        { success: false, message: "Erro ao remover grupo: #{e.message}" }
      end

      # ========================================
      # MÉTODOS DE SEGMENTOS
      # ========================================

      def add_segment(group_id, params)
        require_relative 'pro_sections_persistence'
        result = ProjetaPlus::Modules::ProSectionsPersistence.load_from_json
        return result unless result[:success]

        data = result[:data]
        groups = data['groups'] || []

        group = groups.find { |g| g['id'] == group_id }
        return { success: false, message: "Grupo não encontrado" } unless group

        group['segments'] ||= []

        new_segment = {
          'id' => params['id'] || params[:id] || Time.now.to_i.to_s,
          'name' => params['name'] || params[:name] || 'Novo Corte',
          'code' => params['code'] || params[:code] || '',
          'style' => params['style'] || params[:style] || 'PRO_VISTAS',
          'activeLayers' => params['activeLayers'] || params[:activeLayers] || []
        }

        group['segments'] << new_segment

        save_result = ProjetaPlus::Modules::ProSectionsPersistence.save_to_json(data)
        return save_result unless save_result[:success]

        { success: true, message: "Segmento adicionado com sucesso", segment: new_segment }
      rescue StandardError => e
        log_error("add_segment", e)
        { success: false, message: "Erro ao adicionar segmento: #{e.message}" }
      end

      # Atualiza segmento existente
      def update_segment(group_id, segment_id, params)
        require_relative 'pro_sections_persistence'
        result = ProjetaPlus::Modules::ProSectionsPersistence.load_from_json
        return result unless result[:success]

        data = result[:data]
        groups = data['groups'] || []

        group = groups.find { |g| g['id'] == group_id }
        return { success: false, message: "Grupo não encontrado" } unless group

        segment = (group['segments'] || []).find { |s| s['id'] == segment_id }
        return { success: false, message: "Segmento não encontrado" } unless segment

        segment['name'] = params['name'] || params[:name] if params['name'] || params[:name]
        segment['code'] = params['code'] || params[:code] if params.key?('code') || params.key?(:code)
        segment['style'] = params['style'] || params[:style] if params['style'] || params[:style]
        segment['activeLayers'] = params['activeLayers'] || params[:activeLayers] if params['activeLayers'] || params[:activeLayers]

        save_result = ProjetaPlus::Modules::ProSectionsPersistence.save_to_json(data)
        return save_result unless save_result[:success]

        { success: true, message: "Segmento atualizado com sucesso" }
      rescue StandardError => e
        log_error("update_segment", e)
        { success: false, message: "Erro ao atualizar segmento: #{e.message}" }
      end

      # Remove segmento
      def delete_segment(group_id, segment_id)
        require_relative 'pro_sections_persistence'
        result = ProjetaPlus::Modules::ProSectionsPersistence.load_from_json
        return result unless result[:success]

        data = result[:data]
        groups = data['groups'] || []

        group = groups.find { |g| g['id'] == group_id }
        return { success: false, message: "Grupo não encontrado" } unless group

        segment = (group['segments'] || []).find { |s| s['id'] == segment_id }
        return { success: false, message: "Segmento não encontrado" } unless segment

        group['segments'].delete(segment)

        save_result = ProjetaPlus::Modules::ProSectionsPersistence.save_to_json(data)
        return save_result unless save_result[:success]

        { success: true, message: "Segmento removido com sucesso" }
      rescue StandardError => e
        log_error("delete_segment", e)
        { success: false, message: "Erro ao remover segmento: #{e.message}" }
      end

      # ========================================
      # DUPLICAÇÃO DE CENAS
      # ========================================

      # Duplica cenas selecionadas aplicando sufixo e configurações do segmento
      def duplicate_scenes_with_segment(params)
        require_relative '../shared/pro_view_configs_base'
        
        model = Sketchup.active_model
        
        scene_names = params['sceneNames'] || params[:sceneNames] || []
        segment_code = params['code'] || params[:code] || ''
        segment_style = params['style'] || params[:style] || ''
        segment_layers = params['activeLayers'] || params[:activeLayers] || []

        return invalid_input("Nenhuma cena selecionada") if scene_names.empty?
        return invalid_input("Code do segmento é obrigatório") if segment_code.empty?

        model.start_operation("Duplicar Cenas com Variação", true)

        created_scenes = []
        scene_names.each do |scene_name|
          # Encontrar a cena original
          original_page = model.pages.find { |p| p.name == scene_name }
          next unless original_page

          # Nome da nova cena com sufixo
          new_scene_name = "#{scene_name}_#{segment_code}"

          # Remover se já existir
          existing_page = model.pages.find { |p| p.name == new_scene_name }
          model.pages.erase(existing_page) if existing_page

          # Selecionar a cena original para copiar suas configurações
          model.pages.selected_page = original_page

          # Criar nova cena
          new_page = model.pages.add(new_scene_name)
          
          # Copiar configurações da cena original
          new_page.use_camera = original_page.use_camera?
          new_page.use_hidden = original_page.use_hidden?
          new_page.use_hidden_layers = original_page.use_hidden_layers?
          new_page.use_hidden_objects = original_page.use_hidden_objects?
          new_page.use_rendering_options = original_page.use_rendering_options?
          new_page.use_section_planes = original_page.use_section_planes?
          new_page.use_shadow_info = original_page.use_shadow_info?
          new_page.use_style = original_page.use_style?
          new_page.use_axes = original_page.use_axes?

          # Aplicar as configurações do segmento
          model.pages.selected_page = new_page
          
          # Aplicar estilo
          if segment_style && !segment_style.empty?
            apply_style(segment_style)
          end
          
          # Aplicar camadas
          if segment_layers && segment_layers.any?
            apply_layers_visibility(segment_layers)
          end

          # Atualizar a página com as novas configurações
          new_page.update

          created_scenes << new_scene_name
        end

        model.commit_operation

        {
          success: true,
          message: "#{created_scenes.length} cenas duplicadas com sucesso",
          count: created_scenes.length,
          scenes: created_scenes
        }
      rescue StandardError => e
        model.abort_operation if model
        log_error("duplicate_scenes_with_segment", e)
        { success: false, message: "Erro ao duplicar cenas: #{e.message}" }
      end

      # Retorna lista de cenas (pages) do modelo
      def get_model_scenes
        model = Sketchup.active_model
        
        return { success: false, message: "Nenhum modelo ativo", scenes: [] } unless model

        scenes = []
        model.pages.each do |page|
          scenes << {
            'name' => page.name,
            'label' => page.label,
            'description' => page.description
          }
        end

        {
          success: true,
          scenes: scenes,
          message: "Cenas carregadas"
        }
      rescue StandardError => e
        log_error("get_model_scenes", e)
        { success: false, message: "Erro ao carregar cenas: #{e.message}", scenes: [] }
      end

      private

      # Retorno para input inválido
      def invalid_input(reason)
        { success: false, message: reason }
      end

      # Log de erros (apenas em modo debug)
      def log_error(context, error)
        return unless defined?(Sketchup) && Sketchup.respond_to?(:debug_mode?) && Sketchup.debug_mode?
        
        timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        puts "[#{timestamp}] #{context}: #{error.message}"
        puts error.backtrace.first(5).join("\n") if error.backtrace
      end

      # Aplica estilo ao modelo
      def apply_style(style_name)
        model = Sketchup.active_model
        
        # Primeiro tentar carregar da pasta styles
        style_file_path = File.join(STYLES_PATH, "#{style_name}.style")
        
        if File.exist?(style_file_path)
          begin
            model.styles.add_style(style_file_path, true)
            imported_style = model.styles.find { |s| s.name == style_name }
            model.styles.selected_style = imported_style if imported_style
            return
          rescue => e
            puts "Erro ao importar estilo #{style_name}: #{e.message}"
          end
        end
        
        # Fallback: buscar estilo já existente no modelo
        style = model.styles.find { |s| s.name == style_name }
        model.styles.selected_style = style if style
      end

      # Aplica visibilidade de camadas
      def apply_layers_visibility(active_layers)
        model = Sketchup.active_model
        
        # Ocultar todas as camadas primeiro
        model.layers.each { |layer| layer.visible = false }
        
        # Mostrar apenas as camadas ativas
        active_layers.each do |layer_name|
          layer = model.layers.find { |l| l.name == layer_name }
          layer.visible = true if layer
        end
      end

    end
  end
end

