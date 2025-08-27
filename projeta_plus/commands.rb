# projeta_plus/commands.rb
require "sketchup.rb"

module ProjetaPlus
  module Commands
    # URL base da sua aplicação Next.js na Vercel
    VERCEL_APP_BASE_URL = "https://projeta-plus-html.vercel.app".freeze

    # Hash para armazenar referências a cada HtmlDialog de conteúdo aberto, um por botão.
    # A chave será o ID do botão (ex: 'button1'), o valor será a instância do HtmlDialog.
    @@button_html_dialogs = {}

    # Método auxiliar para criar/reutilizar um HtmlDialog para um botão específico.
    # @param button_id [String] Um ID único para o diálogo (ex: 'button1', 'button2').
    # @param initial_path [String] O caminho inicial dentro da sua aplicação Vercel (ex: '/', '/button1').
    # @param dialog_title [String] O título da janela do diálogo.
    def self.open_button_html_dialog(button_id, initial_path = '/', dialog_title = "Projeta Plus")
      # Se o diálogo para este botão já existe e está visível, apenas traga-o para a frente.
      if @@button_html_dialogs[button_id] && @@button_html_dialogs[button_id].visible?
        puts "[ProjetaPlus Dialog] Diálogo para '#{button_id}' já aberto. Trazendo para a frente."
        @@button_html_dialogs[button_id].show
        # Opcional: Se quiser que o diálogo sempre re-navegue para o initial_path ao reabrir,
        # descomente a linha abaixo. Útil se o usuário navegou para outra parte do seu app.
        # @@button_html_dialogs[button_id].set_url("#{VERCEL_APP_BASE_URL}#{initial_path}")
        return
      end

      # Cria um novo HtmlDialog para este botão.
      puts "[ProjetaPlus Dialog] Criando novo diálogo para '#{button_id}' com URL: #{VERCEL_APP_BASE_URL}"
      dialog = ::UI::HtmlDialog.new({
        :dialog_title => dialog_title,
        :preferences_key => "com.projeta_plus.dialog_#{button_id}", # Chave única para persistir tamanho/posição
        :resizable => true,
        :width => 800,
        :height => 600,
        :min_width => 400,
        :min_height => 300
      })

      # Habilita comunicação bidirecional JavaScript <-> Ruby
      # Try different method names for SketchUp 2025
      if dialog.respond_to?(:enable_javascript_access_host_scheme)
        dialog.enable_javascript_access_host_scheme(true)
      elsif dialog.respond_to?(:enable_javascript_access)
        dialog.enable_javascript_access(true)
      elsif dialog.respond_to?(:javascript_access=)
        dialog.javascript_access = true
      end

      # Define a URL remota da sua aplicação Next.js na Vercel
      dialog.set_url("#{VERCEL_APP_BASE_URL}")

      # Adiciona um callback para o JavaScript chamar o Ruby (exemplo)
      # No seu Next.js, você faria: window.sketchup.send_action('logMessage', 'Mensagem do JS');
      dialog.add_action_callback("logMessage") do |action_context, message|
        puts "[ProjetaPlus JS Message] #{message}"
        nil
      end

      # Armazena a referência para este diálogo de botão.
      @@button_html_dialogs[button_id] = dialog

      # Define o callback para quando o diálogo é fechado pelo usuário (X ou Esc)
      dialog.set_on_closed { @@button_html_dialogs[button_id] = nil; puts "[ProjetaPlus Dialog] Diálogo para '#{button_id}' fechado." }

      dialog.show # Exibe o diálogo
    end

    # Método auxiliar para criar uma instância de UI::Command.
    # @param name [String] O nome exibido no item de menu ou tooltip.
    # @param tooltip [String] O texto do tooltip.
    # @param icon [String] O nome do arquivo do ícone.
    # @param button_id [String] ID único para identificar o diálogo deste botão.
    # @param initial_path [String] O caminho no app Vercel a ser carregado (ex: '/', '/button1').
    # @param dialog_title [String] Título da janela do diálogo.
    def self.create_command(name:, tooltip:, icon:, button_id:, initial_path: '/', dialog_title: "Projeta Plus")
      command = ::UI::Command.new(name) do
        # Cada botão abre/reutiliza seu próprio HtmlDialog, carregando a URL da Vercel.
        self.open_button_html_dialog(button_id, initial_path, dialog_title)
      end
      # Configuração do ícone, tooltip, etc.
      icon_path = File.join(ProjetaPlus::PATH, 'projeta_plus', 'icons', icon)
      command.small_icon = icon_path
      command.large_icon = icon_path
      command.tooltip = tooltip
      command.status_bar_text = tooltip
      command
    end

    # Comando para o Botão Um
    def self.button_one_command
      create_command(
        name: "Botão Um - Vercel App",
        tooltip: "Abre o Projeta Plus UI na Vercel (Botão 1)",
        icon: "button1.png",
        button_id: "button1", # ID único para este diálogo
        initial_path: "/button1", # Exemplo: sua_app.vercel.app/button1
        dialog_title: "Projeta Plus - Botão 1"
      )
    end

    # Comando para o Botão Dois
    def self.button_two_command
      create_command(
        name: "Botão Dois - Vercel App",
        tooltip: "Abre o Projeta Plus UI na Vercel (Botão 2)",
        icon: "button2.png",
        button_id: "button2", # ID único para este diálogo
        initial_path: "/button2", # Exemplo: sua_app.vercel.app/button2
        dialog_title: "Projeta Plus - Botão 2"
      )
    end

    # O comando de logout agora é apenas um exemplo de como você pode instruir o usuário
    # ou, se o seu app Vercel tiver um endpoint para isso, você poderia chamá-lo.
    # def self.logout_command
    #   command = ::UI::Command.new("Logout Projeta Plus (App Remoto)") do
    #     ::UI.messagebox("O logout de usuário agora é gerenciado pelo aplicativo remoto na Vercel (via Clerk). Por favor, gerencie sua sessão diretamente lá, ou feche e reabra o aplicativo para um novo login.", MB_OK, "Projeta Plus")
    #     # Se você tivesse um endpoint de logout ou uma função JS no seu app Vercel, você poderia chamá-lo aqui.
    #     # Ex: self.open_button_html_dialog("logout_view", "/logout", "Projeta Plus - Logout")
    #   end
    #   icon_path = File.join(ProjetaPlus::PATH, 'projeta_plus', 'icons', "unlock_icon.png")
    #   command.small_icon = icon_path
    #   command.large_icon = icon_path
    #   command.tooltip = "Instruções de Logout do App Remoto"
    #   command.status_bar_text = "Instruções de Logout do App Remoto"
    #   command
    # end

  end # module Commands
end # module ProjetaPlus