# projeta_plus/commands.rb
require "sketchup.rb"
require "json"

module ProjetaPlus
  module Commands
    VERCEL_APP_BASE_URL = "https://projeta-plus-html.vercel.app".freeze 

    # Just a main dialog for the dashboard
    @@main_dashboard_dialog = nil

    # New method to open the main dashboard HtmlDialog
    # It always points to the base dashboard route on Vercel.
    def self.open_main_dashboard_html_dialog
      # If the dialog already exists and is visible, just bring it to the front.
      if @@main_dashboard_dialog && @@main_dashboard_dialog.visible?
        puts "[ProjetaPlus Dialog] Main dialog already open. Bringing to front."
        @@main_dashboard_dialog.show
        return
      end

      # Creates a new HtmlDialog for the dashboard
      puts "[ProjetaPlus Dialog] Creating new main dialog for the Dashboard with URL: #{VERCEL_APP_BASE_URL}/dashboard"
      @@main_dashboard_dialog = ::UI::HtmlDialog.new({
        :dialog_title => "Projeta Plus Dashboard",
        :preferences_key => "com.projeta_plus.main_dashboard_dialog", # Unique key
        :resizable => true,
        :width => 430, # Adjust initial size for a dashboard
        :height => 768,
        :max_width => 430, # Adjust initial size for a dashboard
        :max_height => 768,
        :min_width => 430,
        :min_height => 600
      })

      # Enables bidirectional communication JavaScript <-> Ruby
      if @@main_dashboard_dialog.respond_to?(:enable_javascript_access_host_scheme)
        @@main_dashboard_dialog.enable_javascript_access_host_scheme(true)
      elsif @@main_dashboard_dialog.respond_to?(:enable_javascript_access)
        @@main_dashboard_dialog.enable_javascript_access(true)
      elsif @@main_dashboard_dialog.respond_to?(:javascript_access=)
        @@main_dashboard_dialog.javascript_access = true
      end

      # Loads the URL of your Next.js dashboard on Vercel
      @@main_dashboard_dialog.set_url("#{VERCEL_APP_BASE_URL}/dashboard")

      # Callback to show message box from JavaScript
      @@main_dashboard_dialog.add_action_callback("showMessageBox") do |action_context, message_from_js|
        model_name = Sketchup.active_model.path
        model_name = File.basename(model_name) if model_name && !model_name.empty? # Pega só o nome do arquivo
        model_name = "[Nenhum Modelo Salvo]" if model_name.empty? || model_name.nil?

        puts "[ProjetaPlus Ruby] Recebido do JS: #{message_from_js} '#{model_name}'"

        ::UI.messagebox(message_from_js, MB_OK, "Mensagem do App Vercel")
        nil # Retorna nil para o SketchUp
      end

      # Callback to request model name from JavaScript
      @@main_dashboard_dialog.add_action_callback("requestModelName") do |action_context|
        model_name = Sketchup.active_model.path # Pega o caminho completo do arquivo
        model_name = File.basename(model_name) if model_name && !model_name.empty? # Pega só o nome do arquivo
        model_name = "[Nenhum Modelo Salvo]" if model_name.empty? || model_name.nil?

        puts "[ProjetaPlus Ruby] Solicitado nome do modelo. Enviando: '#{model_name}' para o JS."
        
        @@main_dashboard_dialog.execute_script("window.receiveModelNameFromRuby('#{model_name.gsub("'", "\'")}');")
        nil
      end

      # Callback to load room annotation defaults from SketchUp
      @@main_dashboard_dialog.add_action_callback("loadRoomAnnotationDefaults") do |action_context|
        defaults = {
          scale: Sketchup.read_default("RoomAnnotation", "scale", "25"),
          font: Sketchup.read_default("RoomAnnotation", "font", "Century Gothic"),
          floor_height: Sketchup.read_default("RoomAnnotation", "floor_height", "0,00"),
          show_pd: Sketchup.read_default("RoomAnnotation", "show_pd", "Sim"),
          pd: Sketchup.read_default("RoomAnnotation", "pd", "0,00"),
          show_level: Sketchup.read_default("RoomAnnotation", "show_level", "Sim"),
          level: Sketchup.read_default("RoomAnnotation", "level", "0,00")
        }
        
        puts "[ProjetaPlus Ruby] Loading room annotation defaults: #{defaults.inspect}"
        
        @@main_dashboard_dialog.execute_script("window.handleRoomDefaults(#{JSON.generate(defaults)});")
        nil
      end

      # Callback to load section annotation defaults from SketchUp
      @@main_dashboard_dialog.add_action_callback("loadSectionAnnotationDefaults") do |action_context|
        defaults = {
          line_height_cm: Sketchup.read_default("SectionAnnotation", "line_height_cm", "145"),
          scale_factor: Sketchup.read_default("SectionAnnotation", "scale_factor", "25")
        }
        
        puts "[ProjetaPlus Ruby] Loading section annotation defaults: #{defaults.inspect}"
        
        @@main_dashboard_dialog.execute_script("window.handleSectionDefaults(#{JSON.generate(defaults)});")
        nil
      end

      # STANDARD: Generic Action Callback to execute Ruby extension functions
      # Called by JS: window.sketchup.send_action('executeExtensionFunction', JSON.stringify({ module_name: '...', function_name: '...', args: {} }));
      @@main_dashboard_dialog.add_action_callback("executeExtensionFunction") do |action_context, json_payload|
        result = {} # Hash to store the operation result
        begin
          payload = JSON.parse(json_payload)
          module_name_str = payload['module_name']
          function_name = payload['function_name']
          args = payload['args']

          target_module = module_name_str.split('::').inject(Object) { |o, c| o.const_get(c) }

          if target_module.respond_to?(function_name)
            puts "[ProjetaPlus Ruby] Executing #{module_name_str}.#{function_name} with arguments: #{args.inspect}"
            result = target_module.send(function_name, args)
          else
            result = { success: false, message: "Ruby function '#{function_name}' not found in module '#{module_name_str}'." }
            puts "[ProjetaPlus Ruby] Error: #{result[:message]}"
          end
        rescue JSON::ParserError => e
          result = { success: false, message: "JSON parse error in payload: #{e.message}" }
          puts "[ProjetaPlus Ruby] #{result[:message]}"
        rescue NameError => e
          result = { success: false, message: "Reference error (module/function not found): #{e.message}" }
          puts "[ProjetaPlus Ruby] #{result[:message]}"
        rescue StandardError => e
          result = { success: false, message: "Unexpected error during execution: #{e.message} \n#{e.backtrace.join("\n")}" }
          puts "[ProjetaPlus Ruby] #{result[:message]}"
        end
        # Always send the result back to JavaScript
        @@main_dashboard_dialog.execute_script("window.handleRubyResponse(#{JSON.generate(result)});")
        nil
      end

      # Defines the callback for when the dialog is closed by the user (X or Esc)
      @@main_dashboard_dialog.set_on_closed { @@main_dashboard_dialog = nil; puts "[ProjetaPlus Dialog] Main dialog closed." }

      @@main_dashboard_dialog.show # Displays the dialog
    end

    # Generic helper method to create UI::Command instances.
    # No longer used to open individual HtmlDialogs, but for the Dashboard command.
    def self.create_command(name:, tooltip:, icon:, &block)
      command = ::UI::Command.new(name, &block)
      icon_path = File.join(ProjetaPlus::PATH, 'projeta_plus', 'icons', icon)
      command.small_icon = icon_path
      command.large_icon = icon_path
      command.tooltip = tooltip
      command.status_bar_text = tooltip
      command
    end

    # NEW: Command to open the main Dashboard
    def self.open_main_dashboard_command
      create_command(
        name: "Projeta Plus Dashboard",
        tooltip: "Opens the main Projeta Plus control panel",
        icon: "button1.png" # Using existing icon
      ) do
        self.open_main_dashboard_html_dialog # Calls the method that opens the main dialog
      end
    end

    # The logout command remains (if you want a logout button on the SketchUp toolbar)
    def self.logout_command
      command = ::UI::Command.new("Projeta Plus Logout (Remote App)") do
        ::UI.messagebox("User logout is now managed by the remote application on Vercel (via Clerk). Please manage your session directly there, or close and reopen the application for a new login.", MB_OK, "Projeta Plus")
      end
      icon_path = File.join(ProjetaPlus::PATH, 'projeta_plus', 'icons', "button2.png")
      command.small_icon = icon_path
      command.large_icon = icon_path
      command.tooltip = "Remote App Logout Instructions"
      command.status_bar_text = "Remote App Logout Instructions"
      command
    end

  end # module Commands
end # module ProjetaPlus