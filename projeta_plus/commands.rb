# encoding: UTF-8
require 'json'
require "sketchup.rb"
require_relative 'localization.rb'

module ProjetaPlus
  module Commands
    @@main_dashboard_dialog = nil
    
    def self.open_main_dashboard_command
      cmd = ::UI::Command.new(ProjetaPlus::Localization.t("plugin_name")) do
        open_main_dashboard
      end
      cmd.tooltip = ProjetaPlus::Localization.t("plugin_name")
      #cmd.status_bar_text = ProjetaPlus::Localization.t("plugin_name")
      cmd.large_icon = cmd.small_icon = File.join(ProjetaPlus::PATH, 'projeta_plus', 'icons', 'logo.png')
      cmd
    end

    def self.open_main_dashboard
      if @@main_dashboard_dialog
        @@main_dashboard_dialog.bring_to_front
        return
      end

      @@main_dashboard_dialog = ::UI::HtmlDialog.new(
        dialog_title: ProjetaPlus::Localization.t("plugin_name"),
        preferences_key: "projeta_plus_main_dialog",
        scrollable: true,
        resizable: true,
        width: 356,
        min_width: 356,
        height: 700,
        min_height: 700,
        left: 200,
        top: 200
      )

      # DEV_MODE: This URL will be automatically replaced during build
      @@main_dashboard_dialog.set_url("http://localhost:3000/")

      # Register all handlers using the new architecture
      furniture_handler = register_dialog_handlers
      
      @@main_dashboard_dialog.set_on_closed do
        furniture_handler&.detach_selection_observer
        @@main_dashboard_dialog = nil
      end
      @@main_dashboard_dialog.show
    end

    def self.recreate_toolbar
      existing_toolbar = ::UI.toolbar(ProjetaPlus::UI::TOOLBAR_NAME)
      if existing_toolbar
        existing_toolbar.hide
        existing_toolbar = nil
      end

      ProjetaPlus::UI.create_toolbar
    end
    
    private
    
    def self.register_dialog_handlers
      
      # Initialize all handlers
      settings_handler = ProjetaPlus::DialogHandlers::SettingsHandler.new(@@main_dashboard_dialog)
      model_handler = ProjetaPlus::DialogHandlers::ModelHandler.new(@@main_dashboard_dialog)
      furniture_handler = ProjetaPlus::DialogHandlers::FurnitureHandler.new(@@main_dashboard_dialog)
      annotation_handler = ProjetaPlus::DialogHandlers::AnnotationHandler.new(@@main_dashboard_dialog)
      extension_handler = ProjetaPlus::DialogHandlers::ExtensionHandler.new(@@main_dashboard_dialog)
      layers_handler = ProjetaPlus::DialogHandlers::LayersHandler.new(@@main_dashboard_dialog)
      eletrical_handler = ProjetaPlus::DialogHandlers::EletricalHandler.new(@@main_dashboard_dialog)
      lightning_handler = ProjetaPlus::DialogHandlers::LightningHandler.new(@@main_dashboard_dialog)
      baseboards_handler = ProjetaPlus::DialogHandlers::BaseboardsHandler.new(@@main_dashboard_dialog)
      custom_components_handler = ProjetaPlus::DialogHandlers::CustomComponentsHandler.new(@@main_dashboard_dialog)
      scenes_handler = ProjetaPlus::DialogHandlers::ScenesHandler.new(@@main_dashboard_dialog)
      plans_handler = ProjetaPlus::DialogHandlers::PlansHandler.new(@@main_dashboard_dialog)
      sections_handler = ProjetaPlus::DialogHandlers::SectionsHandler.new(@@main_dashboard_dialog)
      details_handler = ProjetaPlus::DialogHandlers::DetailsHandler.new(@@main_dashboard_dialog)
      electrical_reports_handler = ProjetaPlus::DialogHandlers::ElectricalReportsHandler.new(@@main_dashboard_dialog)
      lightning_reports_handler = ProjetaPlus::DialogHandlers::LightningReportsHandler.new(@@main_dashboard_dialog)
      baseboard_reports_handler = ProjetaPlus::DialogHandlers::BaseboardReportsHandler.new(@@main_dashboard_dialog)
      coatings_reports_handler = ProjetaPlus::DialogHandlers::CoatingsReportsHandler.new(@@main_dashboard_dialog)
      
      # Register all callbacks
      settings_handler.register_callbacks
      model_handler.register_callbacks
      furniture_handler.register_callbacks
      annotation_handler.register_callbacks
      extension_handler.register_callbacks
      layers_handler.register_callbacks
      eletrical_handler.register_callbacks
      lightning_handler.register_callbacks
      baseboards_handler.register_callbacks
      custom_components_handler.register_callbacks
      scenes_handler.register_callbacks
      plans_handler.register_callbacks
      sections_handler.register_callbacks
      details_handler.register_callbacks
      electrical_reports_handler.register_callbacks
      lightning_reports_handler.register_callbacks
      baseboard_reports_handler.register_callbacks
      coatings_reports_handler.register_callbacks
      
      furniture_handler
    end

  end # module Commands
end # module ProjetaPlus
