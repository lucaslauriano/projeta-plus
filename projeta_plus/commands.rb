require "sketchup.rb"

module ProjetaPlus
  # Este módulo define todos os comandos (ações) que os botões ou itens de menu do plugin podem acionar.
  module Commands
    # Método auxiliar para criar uma instância de UI::Command.
    # Isso promove a reutilização e configuração consistente de comandos.
    # @param name [String] O nome exibido no item de menu ou tooltip.
    # @param tooltip [String] O texto do tooltip exibido ao passar o mouse sobre o botão.
    # @param icon [String] O nome do arquivo do ícone (ex: 'button1.png'). O SketchUp espera isso relativo à raiz do plugin.
    # @param &block [Proc] O bloco de código a ser executado quando o comando é ativado.
    # @return [UI::Command] Um novo objeto UI::Command.
    def self.create_command(name:, tooltip:, icon:, &block)
      command = ::UI::Command.new(name) do
        # Inicia uma operação de 'undo'. Isso permite que os usuários desfaçam as ações do seu plugin.
        Sketchup.active_model.start_operation(name, true)
        begin
          block.call # Executa a lógica real do comando
        rescue StandardError => e
          # Exibe uma caixa de mensagem em caso de erro, útil para depuração.
          ::UI.messagebox("Error: #{e.message}\n#{e.backtrace.join("\n")}")
        ensure
          # Confirma a operação de 'undo'.
          Sketchup.active_model.commit_operation
        end
      end
      # Para ícones, o SketchUp espera o caminho relativo ao diretório principal do plugin.
      # Se os ícones estiverem em `projeta_plus/icons/`, o caminho é `projeta_plus/icons/nome_do_icone.png`.
      icon_path = File.join(ProjetaPlus::PATH, 'projeta_plus', 'icons', icon)
      command.small_icon = icon_path
      command.large_icon = icon_path
      command.tooltip = tooltip
      command.status_bar_text = tooltip # Aparece na barra de status do SketchUp
      command
    end

    # Comando para o Botão Um: Exibe "Hello World 1".
    def self.button_one_command
      create_command(
        name: "Button One Action",
        tooltip: "Displays Hello World 1",
        icon: "button1.png"
        
      ) do
        ::UI.messagebox("Hello World 1!")
      end
    end

    # Comando para o Botão Dois: Exibe "Hello World 2".
    def self.button_two_command
      create_command(
        name: "Button Two Action",
        tooltip: "Displays Hello World 2",
        icon: "button2.png"
      ) do
        ::UI.messagebox("Hello World 2!, lucas")
      end
    end

    # Comando para o Botão Três: Exibe "Hello World 3".
    def self.button_three_command
      create_command(
        name: "Button Three Action",
        tooltip: "Displays Hello World 3",
        icon: "button3.png"
      ) do
        ::UI.messagebox("Hello World 3!")
      end
    end

    # Comando para o Botão Quatro: Exibe "Hello World 4".
    def self.button_four_command
      create_command(
        name: "Button Four Action",
        tooltip: "Displays Hello World 4",
        icon: "button4.png"
      ) do
        ::UI.messagebox("Hello World 4!")
      end
    end

    # Comando para o Botão Cinco: Exibe "Hello World 5".
    def self.button_five_command
      create_command(
        name: "Button Five Action",
        tooltip: "Displays Hello World 5",
        icon: "button5.png"
      ) do
        ::UI.messagebox("Hello World 5!")
      end
    end
  end # module Commands
end # module ProjetaPlus