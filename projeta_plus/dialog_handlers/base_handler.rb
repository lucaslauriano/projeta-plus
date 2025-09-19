# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module DialogHandlers
    # Base class for all dialog handlers
    class BaseHandler
      
      def initialize(dialog)
        @dialog = dialog
      end
      
      protected
      
      # Helper method to execute JavaScript safely
      def execute_script(script)
        @dialog.execute_script(script)
      end
      
      # Helper method to send JSON response to frontend
      def send_json_response(callback_name, data)
        execute_script("window.#{callback_name}(#{JSON.generate(data)});")
      end
      
      # Helper method to handle errors consistently
      def handle_error(error, context = "operation")
        error_msg = "Error in #{context}: #{error.message}"
        puts "[ProjetaPlus Ruby] #{error_msg}"
        { success: false, message: error_msg }
      end
      
      # Helper method to log operations
      def log(message)
        puts "[ProjetaPlus Ruby] #{message}"
      end
      
    end
  end
end
