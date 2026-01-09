require "sketchup.rb"
require_relative 'localization.rb'

module ProjetaPlus
  module UI
    TOOLBAR_NAME = ProjetaPlus::Localization.t("plugin_name")

    def self.create_toolbar
      toolbar = ::UI::Toolbar.new(TOOLBAR_NAME)
      menu    = ::UI.menu("Plugins")

      dashboard_command = ProjetaPlus::Commands.open_main_dashboard_command
      toolbar.add_item(dashboard_command)
      menu.add_item(dashboard_command)

      lib_scripts_command = ProjetaPlus::Commands.open_lib_scripts_command
      toolbar.add_item(lib_scripts_command)
      menu.add_item(lib_scripts_command)

      toolbar.show
    end
  end

  ProjetaPlus::UI.create_toolbar
end