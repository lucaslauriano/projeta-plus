# projeta_plus/core.rb
require "sketchup.rb"
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'localization.rb') # Certifique-se que Localization está carregado

module ProjetaPlus
  module UI
    TOOLBAR_NAME = ProjetaPlus::Localization.t("plugin_name") + " Toolbar" # Traduzindo o nome da Toolbar

    def self.create_toolbar
      toolbar = ::UI::Toolbar.new(TOOLBAR_NAME)
      
      toolbar.add_item(ProjetaPlus::Commands.open_main_dashboard_command)
      toolbar.add_item(ProjetaPlus::Commands.logout_command)

      toolbar.show
    end
  end

  ProjetaPlus::UI.create_toolbar
end