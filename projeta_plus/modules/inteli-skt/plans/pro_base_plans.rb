# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module ProBasePlans

      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================

      # Paths para arquivos JSON e estilos
      PLUGIN_PATH = File.dirname(__FILE__)
      JSON_DATA_PATH = File.join(PLUGIN_PATH, 'json_data')
      STYLES_PATH = File.join(File.dirname(PLUGIN_PATH), 'styles')
      DEFAULT_DATA_FILE = File.join(JSON_DATA_PATH, 'base_plans.json')
      USER_BASE_PLANS_FILE = File.join(JSON_DATA_PATH, 'user_base_plans.json')
      USER_PLANS_DATA_FILE = File.join(JSON_DATA_PATH, 'user_plans_data.json')

      # ========================================
      # MÉTODOS PÚBLICOS
      # ========================================

      # Retorna as configurações das plantas base
      def self.get_base_plans
        begin
          plans_data = []
          source_file = nil
          
          # Prioridade 1: user_base_plans.json (arquivo dedicado)
          if File.exist?(USER_BASE_PLANS_FILE)
            puts "Carregando base plans de: #{USER_BASE_PLANS_FILE}"
            content = File.read(USER_BASE_PLANS_FILE)
            content = remove_bom(content)
            data = JSON.parse(content, symbolize_names: true)
            plans_data = data[:plans] || []
            source_file = USER_BASE_PLANS_FILE
          end
          
          # Prioridade 2: Fallback para user_plans_data.json
          if plans_data.empty? && File.exist?(USER_PLANS_DATA_FILE)
            puts "Fallback para: #{USER_PLANS_DATA_FILE}"
            content = File.read(USER_PLANS_DATA_FILE)
            content = remove_bom(content)
            data = JSON.parse(content, symbolize_names: true)
            
            # Procurar pelas configurações de base e forro no array de plans
            if data[:plans] && data[:plans].is_a?(Array)
              base_config = data[:plans].find { |p| p[:id] == 'planta_baixa' || p[:id] == 'base' }
              forro_config = data[:plans].find { |p| p[:id] == 'planta_cobertura' || p[:id] == 'forro' || p[:id] == 'ceiling' }
              
              if base_config
                plans_data << {
                  id: 'base',
                  name: 'Base',
                  style: base_config[:style] || 'PRO_PLANTAS',
                  activeLayers: base_config[:activeLayers] || ['Layer0']
                }
              end
              
              if forro_config
                plans_data << {
                  id: 'forro',
                  name: 'Forro',
                  style: forro_config[:style] || 'PRO_PLANTAS',
                  activeLayers: forro_config[:activeLayers] || ['Layer0']
                }
              end
            end
            source_file = USER_PLANS_DATA_FILE
          end
          
          # Prioridade 3: Fallback para base_plans.json
          if plans_data.empty? && File.exist?(DEFAULT_DATA_FILE)
            puts "Fallback para: #{DEFAULT_DATA_FILE}"
            content = File.read(DEFAULT_DATA_FILE)
            content = remove_bom(content)
            data = JSON.parse(content, symbolize_names: true)
            plans_data = data[:plans] || []
            source_file = DEFAULT_DATA_FILE
          end
          
          # Se ainda estiver vazio, criar padrão
          if plans_data.empty?
            puts "Criando configurações padrão"
            ensure_json_directory
            plans_data = [
              {
                id: 'base',
                name: 'Base',
                style: 'PRO_PLANTAS',
                activeLayers: ['Layer0']
              },
              {
                id: 'forro',
                name: 'Forro',
                style: 'PRO_PLANTAS',
                activeLayers: ['Layer0']
              }
            ]
            
            # Salvar padrão no user_base_plans.json
            default_data = { plans: plans_data }
            File.write(USER_BASE_PLANS_FILE, JSON.pretty_generate(default_data))
            source_file = USER_BASE_PLANS_FILE
          end
          
          puts "Base plans carregadas de #{source_file}: #{plans_data.map { |p| p[:id] }.join(', ')}"
          
          {
            success: true,
            plans: plans_data,
            message: "Configurações carregadas com sucesso"
          }
        rescue => e
          puts "Erro ao carregar base plans: #{e.message}"
          puts e.backtrace.join("\n")
          {
            success: false,
            message: "Erro ao carregar configurações: #{e.message}",
            plans: []
          }
        end
      end

      # Salva as configurações das plantas base
      def self.save_base_plans(params)
        begin
          plans = params['plans'] || params[:plans]
          
          unless plans
            return {
              success: false,
              message: "Parâmetro 'plans' não fornecido"
            }
          end
          
          ensure_json_directory
          
          # Salvar no user_base_plans.json (arquivo dedicado)
          data = { plans: plans }
          File.write(USER_BASE_PLANS_FILE, JSON.pretty_generate(data))
          
          puts "Base plans salvas com sucesso em: #{USER_BASE_PLANS_FILE}"
          
          # TAMBÉM atualizar o user_plans_data.json se existir
          if File.exist?(USER_PLANS_DATA_FILE)
            begin
              puts "Tentando sincronizar com user_plans_data.json..."
              content = File.read(USER_PLANS_DATA_FILE)
              content = remove_bom(content)
              existing_data = JSON.parse(content, symbolize_names: true)
              
              puts "Dados existentes: #{existing_data.keys.inspect}"
              puts "Plans atuais: #{existing_data[:plans].inspect}"
              
              # Garantir que o array de plans existe
              existing_data[:plans] ||= []
              
              # Atualizar ou adicionar as configurações de base e forro
              plans.each do |new_plan|
                plan_id = new_plan['id'] || new_plan[:id]
                
                puts "Processando plano: #{plan_id}"
                
                # Mapear IDs para os IDs usados no user_plans_data.json
                target_id = case plan_id
                when 'base'
                  'planta_baixa'
                when 'forro', 'ceiling'
                  'planta_cobertura'
                else
                  plan_id
                end
                
                puts "Target ID: #{target_id}"
                
                # Encontrar ou criar a entrada no array de plans
                existing_plan_index = existing_data[:plans].find_index { |p| p[:id] == target_id }
                
                plan_config = {
                  id: target_id,
                  name: new_plan['name'] || new_plan[:name] || (plan_id == 'base' ? 'Base' : 'Forro'),
                  style: new_plan['style'] || new_plan[:style] || 'PRO_PLANTAS',
                  cameraType: 'topo_ortogonal',
                  activeLayers: new_plan['activeLayers'] || new_plan[:activeLayers] || ['Layer0']
                }
                
                if existing_plan_index
                  # Atualizar existente
                  puts "Atualizando plano existente no índice #{existing_plan_index}"
                  existing_data[:plans][existing_plan_index] = plan_config
                else
                  # Adicionar novo
                  puts "Adicionando novo plano"
                  existing_data[:plans] << plan_config
                end
              end
              
              puts "Plans finais: #{existing_data[:plans].length} planos"
              
              # Salvar de volta no arquivo
              File.write(USER_PLANS_DATA_FILE, JSON.pretty_generate(existing_data))
              puts "user_plans_data.json atualizado com sucesso!"
            rescue => sync_error
              puts "Aviso: Não foi possível sincronizar com user_plans_data.json: #{sync_error.message}"
              puts sync_error.backtrace.join("\n")
              # Não falhar se não conseguir sincronizar
            end
          else
            puts "Arquivo user_plans_data.json não existe: #{USER_PLANS_DATA_FILE}"
          end
          
          {
            success: true,
            message: "Configurações salvas com sucesso!"
          }
        rescue => e
          puts "Erro ao salvar base plans: #{e.message}"
          puts e.backtrace.join("\n")
          {
            success: false,
            message: "Erro ao salvar configurações: #{e.message}"
          }
        end
      end

      # Retorna estilos disponíveis da pasta styles
      def self.get_available_styles_for_base_plans
        begin
          styles = []
          
          if Dir.exist?(STYLES_PATH)
            Dir.glob(File.join(STYLES_PATH, '*.style')).each do |file_path|
              style_name = File.basename(file_path, '.style')
              styles << style_name
            end
            puts "Estilos encontrados: #{styles.join(', ')}"
          else
            puts "Pasta de estilos não encontrada: #{STYLES_PATH}"
          end
          
          # Fallback: usar os do modelo se nenhum arquivo foi encontrado
          if styles.empty?
            model = Sketchup.active_model
            if model
              model.styles.each { |style| styles << style.name }
              puts "Usando estilos do modelo: #{styles.join(', ')}"
            end
          end
          
          {
            success: true,
            styles: styles.sort
          }
        rescue => e
          puts "Erro ao carregar estilos: #{e.message}"
          puts e.backtrace.join("\n")
          {
            success: false,
            message: "Erro ao carregar estilos: #{e.message}",
            styles: []
          }
        end
      end

      # Retorna todas as camadas do modelo
      def self.get_available_layers_for_base_plans
        begin
          model = Sketchup.active_model
          
          unless model
            return {
              success: false,
              message: "Nenhum modelo ativo",
              layers: []
            }
          end
          
          layers = []
          model.layers.each { |layer| layers << layer.name }
          
          puts "Camadas encontradas: #{layers.join(', ')}"
          
          {
            success: true,
            layers: layers.sort
          }
        rescue => e
          puts "Erro ao carregar camadas: #{e.message}"
          puts e.backtrace.join("\n")
          {
            success: false,
            message: "Erro ao carregar camadas: #{e.message}",
            layers: []
          }
        end
      end

      # Retorna as camadas atualmente ativas
      def self.get_current_active_layers
        begin
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo", layers: [] } unless model
          
          active_layers = []
          model.layers.each do |layer|
            active_layers << layer.name if layer.visible?
          end
          
          {
            success: true,
            layers: active_layers,
            message: "Camadas ativas capturadas"
          }
        rescue => e
          puts "Erro ao capturar camadas: #{e.message}"
          {
            success: false,
            message: "Erro ao capturar camadas: #{e.message}",
            layers: []
          }
        end
      end

      # Retorna as camadas ativas que existem na lista disponível
      def self.get_current_active_layers_filtered(available_layers)
        begin
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo", layers: [] } unless model
          
          active_layers = []
          model.layers.each do |layer|
            # Incluir apenas se estiver ativa E estiver na lista de camadas disponíveis
            if layer.visible? && available_layers.include?(layer.name)
              active_layers << layer.name
            end
          end
          
          {
            success: true,
            layers: active_layers,
            message: "Camadas ativas capturadas e filtradas"
          }
        rescue => e
          puts "Erro ao capturar camadas: #{e.message}"
          {
            success: false,
            message: "Erro ao capturar camadas: #{e.message}",
            layers: []
          }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS (auxiliares)
      # ========================================

      private

      def self.ensure_json_directory
        Dir.mkdir(JSON_DATA_PATH) unless Dir.exist?(JSON_DATA_PATH)
      end

      def self.remove_bom(content)
        content.sub("\xEF\xBB\xBF".force_encoding("UTF-8"), '')
      end

    end
  end
end

