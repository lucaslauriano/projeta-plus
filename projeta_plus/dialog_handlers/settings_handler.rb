# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'

module ProjetaPlus
  module DialogHandlers
    class SettingsHandler < BaseHandler
      
      def register_callbacks
        register_request_all_settings
        register_load_global_settings
        register_change_language
        register_update_setting
        register_select_folder_path
      end
      
      private
      
      def register_request_all_settings
        @dialog.add_action_callback("requestAllSettings") do |action_context|
          begin
            if defined?(ProjetaPlus::Modules::ProSettings)
              all_settings = ProjetaPlus::Modules::ProSettings.get_all_settings
              log("Requested all settings. Sending settings data to JS.")
              send_json_response("receiveAllSettingsFromRuby", all_settings)
            else
              error_data = { error: "Settings module not available" }
              log("Error: Settings module not available")
              send_json_response("receiveAllSettingsFromRuby", error_data)
            end
          rescue => e
            error_data = { error: "Error retrieving settings: #{e.message}" }
            log("Error retrieving settings: #{e.message}")
            send_json_response("receiveAllSettingsFromRuby", error_data)
          end
          nil
        end
      end
      
      def register_load_global_settings
        @dialog.add_action_callback("loadGlobalSettings") do |action_context|
          settings = ProjetaPlus::Modules::ProSettings.get_all_settings
          log("Loading global settings: #{settings.inspect}")
          send_json_response("handleGlobalSettings", settings)
          nil
        end
      end
      
      def register_change_language
        @dialog.add_action_callback("changeLanguage") do |action_context, lang_code|
          begin
            available_languages = ProjetaPlus::Modules::ProSettings.get_available_language_codes
            if available_languages.include?(lang_code)
              ProjetaPlus::Modules::ProSettings.write("Language", lang_code)
              ProjetaPlus::Localization.set_language(lang_code)
              
              ProjetaPlus::Commands.recreate_toolbar
              
              execute_script("window.languageChanged('#{lang_code}');")
              log("Language changed to: #{lang_code}, toolbar recreated")
            else
              log("Invalid language code: #{lang_code}")
            end
          rescue => e
            log("Error changing language: #{e.message}")
          end
          nil
        end
      end
      
      def register_update_setting
        @dialog.add_action_callback("updateSetting") do |action_context, json_payload|
          begin
            args = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProSettings.update_setting(args)
            log("Setting updated: #{args.inspect} -> #{result.inspect}")
            send_json_response("handleSettingUpdate", result)
          rescue => e
            error_result = handle_error(e, "update setting")
            send_json_response("handleSettingUpdate", error_result)
          end
          nil
        end
      end
      
      def register_select_folder_path
        @dialog.add_action_callback("selectFolderPath") do |action_context, json_payload|
          begin
            args = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProSettings.select_folder_path(args)
            log("Folder selected: #{args.inspect} -> #{result.inspect}")
            send_json_response("handleFolderSelection", result)
          rescue => e
            error_result = handle_error(e, "folder selection")
            send_json_response("handleFolderSelection", error_result)
          end
          nil
        end
      end
      
    end
  end
end
