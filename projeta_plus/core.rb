require "sketchup.rb"

module ProjetaPlus
  module UI
    TOOLBAR_NAME = "Projeta+ Toolbar".freeze

    def self.create_toolbar
      toolbar = ::UI::Toolbar.new(TOOLBAR_NAME)

      toolbar.add_item(ProjetaPlus::Commands.open_main_dashboard_command)
      toolbar.add_item(ProjetaPlus::Commands.logout_command)

      toolbar.add_separator

      toolbar.show
    end
  end

  if defined?(Sketchup) && Sketchup.respond_to?(:on_extension_load)
    Sketchup.on_extension_load("PROJETA PLUS") do
      ProjetaPlus::UI.create_toolbar
    end
  else
    ProjetaPlus::UI.create_toolbar
  end
end