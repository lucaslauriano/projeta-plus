# projeta_plus/commands.rb
require "sketchup.rb"
require "json"
require File.join(ProjetaPlus::PATH, 'projeta_plus', 'localization.rb') # Certifique-se que Localization está carregado

module ProjetaPlus
  module Commands
    VERCEL_APP_BASE_URL = "https://projeta-plus-html.vercel.app".freeze 

    @@main_dashboard_dialog = nil

    def self.open_main_dashboard_html_dialog
      if @@main_dashboard_dialog && @@main_dashboard_dialog.visible?
        puts "[ProjetaPlus Dialog] Main dialog already open. Bringing to front."
        @@main_dashboard_dialog.show
        return
      end

      puts "[ProjetaPlus Dialog] Creating new main dialog for the Dashboard with URL: #{VERCEL_APP_BASE_URL}/dashboard"
      @@main_dashboard_dialog = ::UI::HtmlDialog.new({
        :dialog_title => ProjetaPlus::Localization.t("plugin_name") + " Dashboard", # Traduzindo o título
        :preferences_key => "com.projeta_plus.main_dashboard_dialog",
        :resizable => true,
        :width => 430,
        :height => 768,
        :max_width => 430,
        :max_height => 768,
        :min_width => 430,
        :min_height => 600
      })

      if @@main_dashboard_dialog.respond_to?(:enable_javascript_access_host_scheme)
        @@main_dashboard_dialog.enable_javascript_access_host_scheme(true)
      elsif @@main_dashboard_dialog.respond_to?(:enable_javascript_access)
        @@main_dashboard_dialog.enable_javascript_access(true)
      elsif @@main_dashboard_dialog.respond_to?(:javascript_access=)
        @@main_dashboard_dialog.javascript_access = true
      end

      @@main_dashboard_dialog.set_url("#{VERCEL_APP_BASE_URL}/dashboard")

      @@main_dashboard_dialog.add_action_callback("showMessageBox") do |action_context, message_from_js|
        model_name = Sketchup.active_model.path
        model_name = File.basename(model_name) if model_name && !model_name.empty?
        model_name = "[#{ProjetaPlus::Localization.t("messages.no_model_saved")}]" if model_name.empty? || model_name.nil? # Traduzido
        puts "[ProjetaPlus Ruby] Received from JS: #{message_from_js} '#{model_name}'"
        ::UI.messagebox(message_from_js, MB_OK, ProjetaPlus::Localization.t("messages.app_message_title")) # Traduzido
        nil
      end

      @@main_dashboard_dialog.add_action_callback("requestModelName") do |action_context|
        model_name = Sketchup.active_model.path
        model_name = File.basename(model_name) if model_name && !model_name.empty?
        model_name = "[#{ProjetaPlus::Localization.t("messages.no_model_saved")}]" if model_name.empty? || model_name.nil? # Traduzido
        puts "[ProjetaPlus Ruby] Requested model name. Sending: '#{model_name}' to JS."
        @@main_dashboard_dialog.execute_script("window.receiveModelNameFromRuby('#{model_name.gsub("'", "\'")}');")
        nil
      end

      # Callback to get all current settings from SketchUp
      @@main_dashboard_dialog.add_action_callback("requestAllSettings") do |action_context|
        begin
          if defined?(ProjetaPlus::Settings)
            all_settings = ProjetaPlus::Settings.get_all_settings
            puts "[ProjetaPlus Ruby] Requested all settings. Sending settings data to JS."
            @@main_dashboard_dialog.execute_script("window.receiveAllSettingsFromRuby(#{JSON.generate(all_settings)});")
          else
            error_msg = "Settings module not available"
            puts "[ProjetaPlus Ruby] Error: #{error_msg}"
            @@main_dashboard_dialog.execute_script("window.receiveAllSettingsFromRuby({error: '#{error_msg}'});")
          end
        rescue => e
          error_msg = "Error retrieving settings: #{e.message}"
          puts "[ProjetaPlus Ruby] #{error_msg}"
          @@main_dashboard_dialog.execute_script("window.receiveAllSettingsFromRuby({error: '#{error_msg}'});")
        end
        nil
      end

      @@main_dashboard_dialog.add_action_callback("loadRoomAnnotationDefaults") do |action_context|
        defaults = ProjetaPlus::Modules::ProRoomAnnotation.get_defaults
        puts "[ProjetaPlus Ruby] Loading room annotation defaults: #{defaults.inspect}"
        @@main_dashboard_dialog.execute_script("window.handleRoomDefaults(#{JSON.generate(defaults)});")
        nil
      end

      @@main_dashboard_dialog.add_action_callback("loadSectionAnnotationDefaults") do |action_context|
        defaults = ProjetaPlus::Modules::ProSectionAnnotation.get_defaults
        puts "[ProjetaPlus Ruby] Loading section annotation defaults: #{defaults.inspect}"
        @@main_dashboard_dialog.execute_script("window.handleSectionDefaults(#{JSON.generate(defaults)});")
        nil
      end

      # Callback para carregar TODAS as configurações globais
      @@main_dashboard_dialog.add_action_callback("loadGlobalSettings") do |action_context|
        settings = ProjetaPlus::Settings.get_all_settings
        puts "[ProjetaPlus Ruby] Loading global settings: #{settings.inspect}"
        @@main_dashboard_dialog.execute_script("window.handleGlobalSettings(#{JSON.generate(settings)});")
        nil
      end
      
      # NOVO: Callback para alterar o idioma globalmente no SketchUp
      @@main_dashboard_dialog.add_action_callback("changeLanguage") do |action_context, lang_code|
        begin
          # Validate language code using Settings module
          available_languages = ProjetaPlus::Settings.get_available_language_codes
          if available_languages.include?(lang_code)
            # Update language settings and translations
            ProjetaPlus::Settings.write("Language", lang_code)
            ProjetaPlus::Localization.set_language(lang_code)
            
            # Update only the language button text, don't recreate toolbar
            ProjetaPlus::Commands.update_language_button_text
            
            # Notify frontend that language was changed
            @@main_dashboard_dialog.execute_script("window.languageChanged('#{lang_code}');")
            puts "[ProjetaPlus Ruby] Language changed to: #{lang_code}, toolbar updated"
          else
            puts "[ProjetaPlus Ruby] Invalid language code: #{lang_code}"
          end
        rescue => e
          puts "[ProjetaPlus Ruby] Error changing language: #{e.message}"
        end
        nil
      end

      # PADRÃO: Generic Action Callback para executar funções de extensão Ruby
      @@main_dashboard_dialog.add_action_callback("executeExtensionFunction") do |action_context, json_payload|
        result = {}
        begin
          payload = JSON.parse(json_payload)
          module_name_str = payload['module_name']
          function_name = payload['function_name']
          args = payload['args']

          if module_name_str !~ /^ProjetaPlus::/ 
            raise SecurityError, "Access denied to module '#{module_name_str}'"
          end

          target_module = module_name_str.split('::').inject(Object) { |o, c| o.const_get(c) }

          if target_module.respond_to?(function_name)
            puts "[ProjetaPlus Ruby] Executing #{module_name_str}.#{function_name} with arguments: #{args.inspect}"
            result = target_module.send(function_name, args)
            # Adapta a mensagem de sucesso para o idioma atual se for uma mensagem genérica
            result[:message] = ProjetaPlus::Localization.t("messages.success_prefix") + ": #{result[:message]}" if result[:success]
            result[:message] = ProjetaPlus::Localization.t("messages.error_prefix") + ": #{result[:message]}" unless result[:success]

          else
            result = { success: false, message: ProjetaPlus::Localization.t("messages.function_not_found").gsub("%{function}", function_name).gsub("%{module}", module_name_str) } # Traduzido
            puts "[ProjetaPlus Ruby] Error: #{result[:message]}"
          end
        rescue JSON::ParserError => e
          result = { success: false, message: ProjetaPlus::Localization.t("messages.json_parse_error") + ": #{e.message}" } # Traduzido
          puts "[ProjetaPlus Ruby] #{result[:message]}"
        rescue NameError => e
          result = { success: false, message: ProjetaPlus::Localization.t("messages.reference_error") + ": #{e.message}" } # Traduzido
          puts "[ProjetaPlus Ruby] #{result[:message]}"
        rescue SecurityError => e
          result = { success: false, message: ProjetaPlus::Localization.t("messages.security_error") + ": #{e.message}" } # Traduzido
          puts "[ProjetaPlus Ruby] #{result[:message]}"
        rescue StandardError => e
          result = { success: false, message: ProjetaPlus::Localization.t("messages.unexpected_error") + ": #{e.message} \n#{e.backtrace.join("\n")}" } # Traduzido
          puts "[ProjetaPlus Ruby] #{result[:message]}"
        end
        @@main_dashboard_dialog.execute_script("window.handleRubyResponse(#{JSON.generate(result)});")
        nil
      end

      @@main_dashboard_dialog.set_on_closed { @@main_dashboard_dialog = nil; puts "[ProjetaPlus Dialog] Main dialog closed." }
      @@main_dashboard_dialog.show
    end

    def self.create_command(name:, tooltip:, icon:, &block)
      command = ::UI::Command.new(name, &block)
      icon_path = File.join(ProjetaPlus::PATH, 'projeta_plus', 'icons', icon)
      command.small_icon = icon_path
      command.large_icon = icon_path
      command.tooltip = tooltip
      command.status_bar_text = tooltip
      command
    end

    def self.open_main_dashboard_command
      create_command(
        name: ProjetaPlus::Localization.t("toolbar.main_dashboard"), # Traduzido
        tooltip: ProjetaPlus::Localization.t("toolbar.main_dashboard_tooltip"), # Adicione tooltip no YAML
        icon: "button1.png"
      ) do
        self.open_main_dashboard_html_dialog
      end
    end

    def self.logout_command
      command = ::UI::Command.new(ProjetaPlus::Localization.t("toolbar.logout")) do # Traduzido
        ::UI.messagebox(ProjetaPlus::Localization.t("messages.logout_info"), MB_OK, ProjetaPlus::Localization.t("plugin_name")) # Traduzido
      end
      icon_path = File.join(ProjetaPlus::PATH, 'projeta_plus', 'icons', "button2.png")
      command.small_icon = icon_path
      command.large_icon = icon_path
      command.tooltip = ProjetaPlus::Localization.t("toolbar.logout_tooltip") # Adicione tooltip no YAML
      command.status_bar_text = ProjetaPlus::Localization.t("toolbar.logout_tooltip") # Adicione tooltip no YAML
      command
    end

    # Store the language command for updates
    @@language_command = nil
    
    # Language indicator command - shows current language and allows switching
    def self.language_indicator_command
      current_language = get_current_language_display
      
      @@language_command = ::UI::Command.new(current_language) do
        # Show language selection dialog or cycle through languages
        cycle_language
      end
      
      # No icon for language indicator - just text
      @@language_command.tooltip = "Current Language: #{current_language} (click to change)"
      @@language_command.status_bar_text = "Language: #{current_language}"
      @@language_command
    end

    # Get current language display text (EN, pt-BR, ES)
    def self.get_current_language_display
      if defined?(ProjetaPlus::Settings) && defined?(ProjetaPlus::Localization)
        current_lang = ProjetaPlus::Settings.read("Language", ProjetaPlus::Settings::DEFAULT_LANGUAGE)
        case current_lang
        when "en"
          "EN"
        when "pt-BR"
          "pt-BR"
        when "es"
          "ES"
        else
          current_lang.upcase
        end
      else
        "EN"
      end
    end

    # Update language button text without recreating toolbar
    def self.update_language_button_text
      if @@language_command
        current_language = get_current_language_display
        # Update the command text and tooltip
        @@language_command.menu_text = current_language
        @@language_command.tooltip = "Current Language: #{current_language} (click to change)"
        @@language_command.status_bar_text = "Language: #{current_language}"
      end
    end

    # Cycle through available languages
    def self.cycle_language
      if defined?(ProjetaPlus::Settings) && defined?(ProjetaPlus::Localization)
        current_lang = ProjetaPlus::Settings.read("Language", ProjetaPlus::Settings::DEFAULT_LANGUAGE)
        available_languages = ProjetaPlus::Settings.get_available_language_codes
        
        current_index = available_languages.index(current_lang) || 0
        next_index = (current_index + 1) % available_languages.length
        new_language = available_languages[next_index]
        
        # Update the language setting
        ProjetaPlus::Settings.write("Language", new_language)
        ProjetaPlus::Localization.load_translations(new_language)
        
        # Update only the language button text, don't recreate toolbar
        update_language_button_text
        
        # Show confirmation message
        language_name = ProjetaPlus::Settings.get_language_name_by_code(new_language)
        ::UI.messagebox("Language changed to: #{language_name}", MB_OK, "Projeta Plus")
        
        puts "[ProjetaPlus] Language changed to: #{new_language}"
      end
    end


    # Recreate toolbar to reflect language changes
    def self.recreate_toolbar
      # Remove existing toolbar if it exists
      if defined?(ProjetaPlus::UI::TOOLBAR_NAME)
        existing_toolbar = ::UI.toolbar(ProjetaPlus::UI::TOOLBAR_NAME)
        existing_toolbar.hide if existing_toolbar
      end
      
      # Recreate the toolbar with updated language
      ProjetaPlus::UI.create_toolbar
    end

  end # module Commands
end # module ProjetaPlus