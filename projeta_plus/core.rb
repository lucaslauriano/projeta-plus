# projeta_plus/core.rb
require "sketchup.rb"
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'localization.rb') # Certifique-se que Localization está carregado

module ProjetaPlus
  module UI
    TOOLBAR_NAME = ProjetaPlus::Localization.t("plugin_name") + " Toolbar".freeze # Traduzindo o nome da Toolbar

    def self.create_toolbar
      toolbar = ::UI::Toolbar.new(TOOLBAR_NAME)

      toolbar.add_item(ProjetaPlus::Commands.open_main_dashboard_command)
      toolbar.add_item(ProjetaPlus::Commands.logout_command)

    
      toolbar.show
    end
  end

  # Removido o Sketchup.on_extension_load daqui, pois já foi adicionado no main.rb
  # para garantir que o idioma é carregado antes da criação da toolbar.
  # (Se for importante que a toolbar seja criada *após* o idioma ser carregado,
  # o evento 'Sketchup.on_extension_load' no main.rb já cuida disso).
  # Para SketchUp 2017+ pode ser Sketchup.extensions.load_extension("nome do seu extension.rb")
  # para que o create_toolbar seja chamado.
  # Ou simplesmente:
  ProjetaPlus::UI.create_toolbar
end