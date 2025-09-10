# projeta_plus/main.rb
require "sketchup.rb"

unless defined?(ProjetaPlus) && defined?(ProjetaPlus::PATH)
  module ProjetaPlus
    PATH = File.dirname(__FILE__).freeze
  end
end

# Modules (load settings first as other modules depend on it)
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'pro_settings.rb')

# --- NOVO: Carrega o módulo de localização ---
begin
  require File.join(ProjetaPlus::PATH, 'projeta_plus', 'localization.rb')
rescue => e
  puts "[ProjetaPlus] Warning: Could not load localization module: #{e.message}"
end
# --- FIM NOVO ---

require File.join(ProjetaPlus::PATH, 'projeta_plus', 'commands.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'pro_room_annotation.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'pro_section_annotation.rb')

# UI
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'core.rb')


puts "PROJETA PLUS main.rb loaded. All components prepared for activation."

# --- NOVO: Carrega o idioma padrão ao iniciar o plugin ---
begin
  if defined?(Sketchup) && Sketchup.respond_to?(:on_extension_load)
    Sketchup.on_extension_load("PROJETA PLUS") do
      # Lê a configuração de idioma salvo, ou usa o padrão
      begin
        if defined?(ProjetaPlus::Settings) && defined?(ProjetaPlus::Localization)
          initial_language = ProjetaPlus::Settings.read("Language", ProjetaPlus::Settings::DEFAULT_LANGUAGE)
          ProjetaPlus::Localization.load_translations(initial_language)
        end
      rescue => e
        puts "[ProjetaPlus] Error loading translations: #{e.message}"
      end
    end
  else
    # Fallback for older SketchUp versions
    begin
      if defined?(ProjetaPlus::Settings) && defined?(ProjetaPlus::Localization)
        initial_language = ProjetaPlus::Settings.read("Language", ProjetaPlus::Settings::DEFAULT_LANGUAGE)
        ProjetaPlus::Localization.load_translations(initial_language)
      end
    rescue => e
      puts "[ProjetaPlus] Error loading translations: #{e.message}"
    end
  end
rescue => e
  puts "[ProjetaPlus] Error in extension load setup: #{e.message}"
end
# --- FIM NOVO ---