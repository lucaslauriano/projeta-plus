# projeta_plus/localization.rb
require 'sketchup.rb'
begin
  require 'yaml' # Para ler os arquivos YAML
rescue LoadError => e
  puts "[ProjetaPlus Localization] Warning: YAML library not available: #{e.message}"
end

module ProjetaPlus
  module Localization
    @@translations = {}
    @@current_language = nil

    # Carrega as traduções para o idioma especificado.
    # @param lang_code [String] O código do idioma (ex: "en", "pt-BR").
    def self.load_translations(lang_code)
      lang_file = File.join(ProjetaPlus::PATH, 'projeta_plus', 'lang', "#{lang_code}.yml")

      unless File.exist?(lang_file)
        puts "[ProjetaPlus Localization] Warning: Language file not found for '#{lang_code}'. Falling back to 'en'."
        lang_code = ProjetaPlus::Settings::DEFAULT_LANGUAGE # Fallback
        lang_file = File.join(ProjetaPlus::PATH, 'projeta_plus', 'lang', "#{lang_code}.yml")
        unless File.exist?(lang_file)
          puts "[ProjetaPlus Localization] Error: Default language file 'en.yml' not found."
          return # Cannot load translations
        end
      end

      begin
        if defined?(YAML)
          @@translations = YAML.load_file(lang_file)
          @@current_language = lang_code
          puts "[ProjetaPlus Localization] Loaded translations for '#{lang_code}'."
        else
          puts "[ProjetaPlus Localization] Warning: YAML not available, translations disabled."
          @@translations = {}
        end
      rescue StandardError => e
        puts "[ProjetaPlus Localization] Error loading translations from #{lang_file}: #{e.message}"
        @@translations = {} # Clear translations on error
      end
    end

    # Retorna a string traduzida para a chave fornecida.
    # @param key [String] A chave da string a ser traduzida (ex: "toolbar.main_dashboard").
    # @return [String] A string traduzida ou a chave se não for encontrada.
    def self.t(key)
      return key if @@translations.empty? # Se não há traduções carregadas, retorna a chave

      parts = key.split('.')
      value = @@translations
      
      parts.each do |part|
        if value.is_a?(Hash) && value.key?(part)
          value = value[part]
        else
          return key # Chave não encontrada
        end
      end

      value.is_a?(String) ? value : key # Retorna a string ou a chave se o valor não for string
    end

    # Retorna o idioma atualmente carregado.
    def self.current_language
      @@current_language
    end

    # Define o idioma e recarrega as traduções.
    def self.set_language(lang_code)
      self.load_translations(lang_code)
    end
  end
end