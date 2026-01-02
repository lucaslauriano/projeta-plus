# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module ProSectionsSettings
      extend self

      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================

      PLUGIN_PATH = File.dirname(__FILE__)
      JSON_DATA_PATH = File.join(PLUGIN_PATH, 'json_data')
      STYLES_PATH = File.join(File.dirname(PLUGIN_PATH), 'styles')
      SETTINGS_FILE = File.join(JSON_DATA_PATH, 'sections_settings.json')

      # ========================================
      # MÉTODOS DE CONFIGURAÇÕES
      # ========================================

      # Retorna as configurações de estilos e camadas
      def get_sections_settings
        begin
          settings = {}
          
          if File.exist?(SETTINGS_FILE)
            content = File.read(SETTINGS_FILE)
            content = remove_bom(content)
            settings = JSON.parse(content)
          else
            # Configurações padrão
            settings = {
              'style' => 'PRO_VISTAS',
              'activeLayers' => []
            }
          end
          
          {
            success: true,
            settings: settings,
            message: "Configurações carregadas"
          }
        rescue StandardError => e
          log_error("get_sections_settings", e)
          {
            success: false,
            message: "Erro ao carregar configurações: #{e.message}",
            settings: { 'style' => 'PRO_VISTAS', 'activeLayers' => [] }
          }
        end
      end

      # Salva as configurações de estilos e camadas
      def save_sections_settings(params)
        begin
          settings = {
            'style' => params['style'] || params[:style] || 'PRO_VISTAS',
            'activeLayers' => params['activeLayers'] || params[:activeLayers] || []
          }
          
          ensure_json_directory
          File.write(SETTINGS_FILE, JSON.pretty_generate(settings))
          
          {
            success: true,
            message: "Configurações salvas com sucesso",
            settings: settings
          }
        rescue StandardError => e
          log_error("save_sections_settings", e)
          {
            success: false,
            message: "Erro ao salvar configurações: #{e.message}"
          }
        end
      end

      # Retorna estilos disponíveis da pasta styles
      def get_available_styles_for_sections
        begin
          styles = []
          
          puts "STYLES_PATH: #{STYLES_PATH}"
          puts "Dir.exist?(STYLES_PATH): #{Dir.exist?(STYLES_PATH)}"
          
          if Dir.exist?(STYLES_PATH)
            Dir.glob(File.join(STYLES_PATH, '*.style')).each do |file_path|
              style_name = File.basename(file_path, '.style')
              styles << style_name
              puts "Estilo encontrado: #{style_name}"
            end
          end
          
          puts "Total de estilos encontrados: #{styles.length}"
          
          # Fallback: usar os do modelo se nenhum arquivo foi encontrado
          if styles.empty?
            model = Sketchup.active_model
            if model
              model.styles.each { |style| styles << style.name }
              puts "Usando estilos do modelo: #{styles.length}"
            end
          end
          
          {
            success: true,
            styles: styles.sort
          }
        rescue StandardError => e
          log_error("get_available_styles_for_sections", e)
          {
            success: false,
            message: "Erro ao carregar estilos: #{e.message}",
            styles: []
          }
        end
      end

      # Retorna todas as camadas do modelo
      def get_available_layers_for_sections
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
          
          puts "Total de camadas encontradas: #{layers.length}"
          puts "Camadas: #{layers.join(', ')}"
          
          {
            success: true,
            layers: layers.sort
          }
        rescue StandardError => e
          log_error("get_available_layers_for_sections", e)
          {
            success: false,
            message: "Erro ao carregar camadas: #{e.message}",
            layers: []
          }
        end
      end

      # Aplica o estilo atual do modelo
      def apply_current_style_to_sections
        begin
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model
          
          current_style = model.styles.selected_style
          return { success: false, message: "Nenhum estilo selecionado" } unless current_style
          
          {
            success: true,
            style: current_style.name,
            message: "Estilo atual capturado"
          }
        rescue StandardError => e
          log_error("apply_current_style_to_sections", e)
          {
            success: false,
            message: "Erro ao capturar estilo: #{e.message}"
          }
        end
      end

      # Retorna as camadas atualmente ativas
      def get_current_active_layers
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
        rescue StandardError => e
          log_error("get_current_active_layers", e)
          {
            success: false,
            message: "Erro ao capturar camadas: #{e.message}",
            layers: []
          }
        end
      end

      # Retorna as camadas ativas que existem na lista disponível
      # Isso garante que apenas camadas válidas sejam selecionadas
      def get_current_active_layers_filtered(available_layers)
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
        rescue StandardError => e
          log_error("get_current_active_layers_filtered", e)
          {
            success: false,
            message: "Erro ao capturar camadas: #{e.message}",
            layers: []
          }
        end
      end

      private

      # Garante que diretório JSON existe
      def ensure_json_directory
        Dir.mkdir(JSON_DATA_PATH) unless Dir.exist?(JSON_DATA_PATH)
      end

      # Remove BOM de UTF-8
      def remove_bom(content)
        content.sub("\xEF\xBB\xBF".force_encoding("UTF-8"), '')
      end

      # Log de erros (apenas em modo debug)
      def log_error(context, error)
        return unless defined?(Sketchup) && Sketchup.respond_to?(:debug_mode?) && Sketchup.debug_mode?
        
        timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        puts "[#{timestamp}] #{context}: #{error.message}"
        puts error.backtrace.first(5).join("\n") if error.backtrace
      end

    end
  end
end

