require "sketchup.rb"

module ProjetaPlus
  # Este módulo lida com a criação da interface do usuário principal e lógica de inicialização.
  module UI
    # Define uma constante para o nome da barra de ferramentas.
    TOOLBAR_NAME = "Projeta Plus Toolbar".freeze

    # Método para criar e exibir a barra de ferramentas do plugin.
    def self.create_toolbar
      toolbar = ::UI::Toolbar.new(TOOLBAR_NAME)

      # Adiciona botões à barra de ferramentas.
      # Cada botão está associado a um comando específico definido em ProjetaPlus::Commands.
      toolbar.add_item(ProjetaPlus::Commands.button_one_command)
      toolbar.add_item(ProjetaPlus::Commands.button_two_command)
      toolbar.add_item(ProjetaPlus::Commands.button_three_command)
      toolbar.add_item(ProjetaPlus::Commands.button_four_command)
      toolbar.add_item(ProjetaPlus::Commands.button_five_command)

      # Mostra a barra de ferramentas. Se já estiver visível, apenas a traz para a frente.
      toolbar.show
    end
  end # module UI

  # Este bloco será executado quando `core.rb` é carregado pelo `main.rb`.
  # Ele registra um callback que será executado *depois* que o SketchUp
  # terminar de carregar todos os arquivos da extensão.
  if defined?(Sketchup) && Sketchup.respond_to?(:on_extension_load)
    Sketchup.on_extension_load("PROJETA PLUS") do
      # Neste ponto, ProjetaPlus::Commands já DEVE estar definido
      # porque `main.rb` carregou `commands.rb` antes de `core.rb`.
      ProjetaPlus::UI.create_toolbar
    end
  else
    # Fallback para SketchUp mais antigo ou para cenários onde on_extension_load não se aplica.
    # Esta linha seria executada imediatamente quando core.rb fosse carregado.
    ProjetaPlus::UI.create_toolbar
  end
end # module ProjetaPlus