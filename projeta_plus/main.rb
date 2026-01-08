# projeta_plus/main.rb
require "sketchup.rb"

unless defined?(ProjetaPlus) && defined?(ProjetaPlus::PATH)
  module ProjetaPlus
    PATH = File.dirname(__FILE__).freeze
  end
end

# Modules (load settings first as other modules depend on it)
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'settings', 'pro_settings.rb')
puts "[ProjetaPlus Debug] ProSettings loaded: #{defined?(ProjetaPlus::Modules::ProSettings)}"

# load localization module
begin
  require File.join(ProjetaPlus::PATH, 'projeta_plus', 'localization.rb')
rescue => e
  puts "[ProjetaPlus] Warning: Could not load localization module: #{e.message}"
end

# Load generic blocks module (used by electrical, lightning, baseboards)
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'pro_blocks.rb')

# Inteli-Skt Modules
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'inteli-skt', 'shared', 'pro_view_configs_base.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'inteli-skt', 'layers', 'pro_layers.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'inteli-skt', 'scenes', 'pro_scenes.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'inteli-skt', 'plans', 'pro_plans.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'inteli-skt', 'sections', 'pro_sections.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'inteli-skt', 'details', 'pro_details.rb')

# Dialog Handlers (load before commands as commands depend on them)
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'base_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'settings_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'model_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'furniture_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'annotation_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'extension_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'layers_handlers.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'eletrical_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'lightning_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'baseboards_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'custom_components_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'scenes_handlers.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'plans_handlers.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'sections_handlers.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'details_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'electrical_reports_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'lightning_reports_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'baseboard_reports_handler.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'dialog_handlers', 'coatings_reports_handler.rb')

# Commands (now uses the handlers)
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'commands.rb')

# Annotation Modules
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'pro_hover_face_util.rb') 
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'annotation', 'pro_room_annotation.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'annotation', 'pro_section_annotation.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'annotation', 'pro_ceiling_annotation.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'annotation', 'pro_lighting_annotation.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'annotation', 'pro_circuit_connection.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'annotation', 'pro_eletrical_annotation.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'annotation', 'pro_view_annotation.rb')
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'modules', 'annotation', 'pro_component_updater.rb')


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
