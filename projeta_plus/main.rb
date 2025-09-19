# projeta_plus/main.rb
require "sketchup.rb"

unless defined?(ProjetaPlus) && defined?(ProjetaPlus::PATH)
  module ProjetaPlus
    PATH = File.dirname(__FILE__).freeze
  end
end

# Modules (load settings first as other modules depend on it)
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'pro_settings.rb')
puts "[ProjetaPlus Debug] ProSettings loaded: #{defined?(ProjetaPlus::Modules::ProSettings)}"

# load localization module
begin
  require File.join(ProjetaPlus::PATH, 'projeta_plus', 'localization.rb')
rescue => e
  puts "[ProjetaPlus] Warning: Could not load localization module: #{e.message}"
end

# Dialog Handlers (load before commands as commands depend on them)
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'base_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'settings_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'model_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'annotation_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'extension_handler.rb')

# Commands (now uses the handlers)
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'commands.rb')

# Annotation Modules
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'pro_hover_face_util.rb') 
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'pro_room_annotation.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'pro_section_annotation.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'pro_ceiling_annotation.rb')

# UI
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'core.rb')


puts "PROJETA PLUS main.rb loaded. All components prepared for activation."

begin
  if defined?(Sketchup) && Sketchup.respond_to?(:on_extension_load)
    Sketchup.on_extension_load("PROJETA PLUS") do
      begin
        if defined?(ProjetaPlus::Modules::ProSettings) && defined?(ProjetaPlus::Localization)
          initial_language = ProjetaPlus::Modules::ProSettings.read("Language", ProjetaPlus::Modules::ProSettings::DEFAULT_LANGUAGE)
          ProjetaPlus::Localization.load_translations(initial_language)
        end
      rescue => e
        puts "[ProjetaPlus] Error loading translations: #{e.message}"
      end
    end
  else
    # Fallback for older SketchUp versions
    begin
      if defined?(ProjetaPlus::Modules::ProSettings) && defined?(ProjetaPlus::Localization)
        initial_language = ProjetaPlus::Modules::ProSettings.read("Language", ProjetaPlus::Modules::ProSettings::DEFAULT_LANGUAGE)
        ProjetaPlus::Localization.load_translations(initial_language)
      end
    rescue => e
      puts "[ProjetaPlus] Error loading translations: #{e.message}"
    end
  end
rescue => e
  puts "[ProjetaPlus] Error in extension load setup: #{e.message}"
end
