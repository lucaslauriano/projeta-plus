# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'

module ProjetaPlus
  module DialogHandlers
    class ModelHandler < BaseHandler
      
      def register_callbacks
        register_show_message_box
        register_request_model_name
      end
      
      private
      
      def register_show_message_box
        @dialog.add_action_callback("showMessageBox") do |action_context, message_from_js|
          model_name = get_current_model_name
          log("Received from JS: #{message_from_js} '#{model_name}'")
          ::UI.messagebox(message_from_js, MB_OK, ProjetaPlus::Localization.t("messages.app_message_title"))
          nil
        end
      end
      
      def register_request_model_name
        @dialog.add_action_callback("requestModelName") do |action_context|
          model_name = get_current_model_name
          log("Requested model name. Sending: '#{model_name}' to JS.")
          execute_script("window.receiveModelNameFromRuby('#{model_name.gsub("'", "\'")}');")
          nil
        end
      end
      
      def get_current_model_name
        model_name = Sketchup.active_model.path
        model_name = File.basename(model_name) if model_name && !model_name.empty?
        model_name = "[#{ProjetaPlus::Localization.t("messages.no_model_saved")}]" if model_name.empty? || model_name.nil?
        model_name
      end
      
    end
  end
end
