# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'

module ProjetaPlus
  module DialogHandlers
    class ExtensionHandler < BaseHandler
      
      def register_callbacks
        register_execute_extension_function
      end
      
      private
      
      def register_execute_extension_function
        @dialog.add_action_callback("executeExtensionFunction") do |action_context, json_payload|
          result = execute_module_function(json_payload)
          send_json_response("handleRubyResponse", result)
          nil
        end
      end
      
      def execute_module_function(json_payload)
        begin
          payload = JSON.parse(json_payload)
          module_name_str = payload['module_name']
          function_name = payload['function_name']
          args = payload['args']

          validate_module_access(module_name_str)
          
          target_module = resolve_module(module_name_str)
          
          if target_module.respond_to?(function_name)
            log("Executing #{module_name_str}.#{function_name} with arguments: #{args.inspect}")
            result = target_module.send(function_name, args)
            format_result_messages(result)
          else
            message = ProjetaPlus::Localization.t("messages.function_not_found").gsub("%{function}", function_name).gsub("%{module}", module_name_str)
            log("Error: #{message}")
            { success: false, message: message }
          end
        rescue JSON::ParserError => e
          handle_error(e, "JSON parsing")
        rescue NameError => e
          handle_error(e, "module reference")
        rescue SecurityError => e
          handle_error(e, "security check")
        rescue StandardError => e
          error_result = handle_error(e, "extension function execution")
          error_result[:message] += "\n#{e.backtrace.join("\n")}"
          error_result
        end
      end
      
      def validate_module_access(module_name_str)
        unless module_name_str =~ /^ProjetaPlus::Modules::/ || module_name_str =~ /^ProjetaPlus::/
          raise SecurityError, "Access denied to module '#{module_name_str}'"
        end
      end
      
      def resolve_module(module_name_str)
        module_name_str.split('::').inject(Object) { |o, c| o.const_get(c) }
      end
      
      def format_result_messages(result)
        if result[:success]
          result[:message] = ProjetaPlus::Localization.t("messages.success_prefix") + ": #{result[:message]}" unless result[:message].start_with?("Success:")
        else
          result[:message] = ProjetaPlus::Localization.t("messages.error_prefix") + ": #{result[:message]}" unless result[:message].start_with?("Error:")
        end
        result
      end
      
    end
  end
end
