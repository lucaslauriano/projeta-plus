# projeta_plus/commands.rb
require "sketchup.rb"

module ProjetaPlus
  module Commands
    VERCEL_APP_BASE_URL = "https://projeta-plus-html.vercel.app".freeze # Seu domínio na Vercel

    @@button_html_dialogs = {}

    def self.open_button_html_dialog(button_id, initial_path = '/', dialog_title = "Projeta Plus")
      # ... (Código existente para verificar se o diálogo já está aberto e reutilizá-lo)
      if @@button_html_dialogs[button_id] && @@button_html_dialogs[button_id].visible?
        @@button_html_dialogs[button_id].show
        return
      end

      puts "[ProjetaPlus Dialog] Criando novo diálogo para '#{button_id}' com URL: #{VERCEL_APP_BASE_URL}"
      dialog = ::UI::HtmlDialog.new({
        :dialog_title => dialog_title,
        :preferences_key => "com.projeta_plus.dialog_#{button_id}",
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

      dialog.set_url("#{VERCEL_APP_BASE_URL}")

      # --- NOVOS CALLBACKS AQUI ---
      # 1. Callback para receber uma mensagem do JS e exibir no MessageBox do SketchUp
      dialog.add_action_callback("showMessageBox") do |action_context, message_from_js|
        puts "[ProjetaPlus Ruby] Recebido do JS: #{message_from_js}"
        ::UI.messagebox(message_from_js, MB_OK, "Mensagem do App Vercel")
        nil # Retorna nil para o SketchUp
      end

      # 2. Callback para o JS solicitar o nome do modelo ativo do SketchUp
      dialog.add_action_callback("requestModelName") do |action_context|
        model_name = Sketchup.active_model.path # Pega o caminho completo do arquivo
        model_name = File.basename(model_name) if model_name && !model_name.empty? # Pega só o nome do arquivo
        model_name = "[Nenhum Modelo Salvo]" if model_name.empty? || model_name.nil?

        puts "[ProjetaPlus Ruby] Solicitado nome do modelo. Enviando: '#{model_name}' para o JS."
        
        dialog.execute_script("window.receiveModelNameFromRuby('#{model_name.gsub("'", "\'")}');")
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