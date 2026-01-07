# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module ProSectionsPersistence
      extend self

      # ========================================
      # CONSTANTES
      # ========================================
      
      PLUGIN_PATH = File.dirname(__FILE__)
      JSON_DATA_PATH = File.join(PLUGIN_PATH, 'json_data')
      DEFAULT_DATA_FILE = File.join(JSON_DATA_PATH, 'sections_data.json')
      USER_DATA_FILE = File.join(JSON_DATA_PATH, 'user_sections_data.json')

      # ========================================
      # MÉTODOS DE PERSISTÊNCIA
      # ========================================

      def save_to_json(json_data)
        ensure_json_directory
        File.write(USER_DATA_FILE, JSON.pretty_generate(json_data))
        
        { success: true, message: "Configurações salvas com sucesso", path: USER_DATA_FILE }
      rescue StandardError => e
        log_error("save_to_json", e)
        { success: false, message: "Erro ao salvar configurações: #{e.message}" }
      end

      def load_from_json
        file_to_load = File.exist?(USER_DATA_FILE) ? USER_DATA_FILE : DEFAULT_DATA_FILE
        
        unless File.exist?(file_to_load)
          return { success: false, message: "Arquivo não encontrado", data: { 'groups' => [] } }
        end
        
        content = File.read(file_to_load)
        content = remove_bom(content)
        
        # Se o arquivo estiver vazio, usar arquivo padrão
        if content.strip.empty?
          if file_to_load == USER_DATA_FILE && File.exist?(DEFAULT_DATA_FILE)
            content = File.read(DEFAULT_DATA_FILE)
            content = remove_bom(content)
          else
            return { success: true, data: { 'groups' => [] }, message: "Arquivo vazio" }
          end
        end
        
        data = JSON.parse(content)
        
        { success: true, data: data, message: "Configurações carregadas" }
      rescue JSON::ParserError => e
        # Se erro no user file, tentar o default
        if file_to_load == USER_DATA_FILE && File.exist?(DEFAULT_DATA_FILE)
          begin
            content = File.read(DEFAULT_DATA_FILE)
            content = remove_bom(content)
            data = JSON.parse(content)
            return { success: true, data: data, message: "Carregado do arquivo padrão" }
          rescue
            # Se default também falhar, retornar vazio
          end
        end
        log_error("load_from_json - JSON inválido", e)
        { success: false, message: "JSON inválido: #{e.message}", data: { 'groups' => [] } }
      rescue StandardError => e
        log_error("load_from_json", e)
        { success: false, message: "Erro ao carregar: #{e.message}", data: { 'groups' => [] } }
      end

      def load_default_data
        unless File.exist?(DEFAULT_DATA_FILE)
          return { success: false, message: "Arquivo padrão não encontrado", data: { groups: [] } }
        end
        
        content = File.read(DEFAULT_DATA_FILE)
        content = remove_bom(content)
        data = JSON.parse(content)
        
        # Salvar como arquivo do usuário
        ensure_json_directory
        File.write(USER_DATA_FILE, JSON.pretty_generate(data))
        
        { success: true, data: data, message: "Dados padrão carregados" }
      rescue StandardError => e
        log_error("load_default_data", e)
        { success: false, message: "Erro: #{e.message}", data: { groups: [] } }
      end

      def load_from_file
        file_path = ::UI.openpanel("Selecionar arquivo JSON", "", "JSON|*.json||")
        return cancelled_operation unless file_path
        
        content = File.read(file_path)
        content = remove_bom(content)
        data = JSON.parse(content)
        
        { success: true, data: data, message: "Arquivo carregado com sucesso" }
      rescue StandardError => e
        log_error("load_from_file", e)
        { success: false, message: "Erro ao carregar: #{e.message}", data: { groups: [] } }
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

      # Retorno para operação cancelada
      def cancelled_operation
        { success: false, message: "Operação cancelada pelo usuário" }
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

