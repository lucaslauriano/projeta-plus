# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/inteli-skt/details/pro_details.rb'

module ProjetaPlus
  module DialogHandlers
    class DetailsHandler < BaseHandler
      
      def register_callbacks
        register_details_callbacks
      end
      
      private
      
      def register_details_callbacks
        # Criar detalhamento de marcenaria
        @dialog.add_action_callback("createCarpentryDetail") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProDetails.create_carpentry_detail
            send_json_response("handleCreateCarpentryDetailResult", result)
          rescue => e
            error_result = handle_error(e, "create carpentry detail")
            send_json_response("handleCreateCarpentryDetailResult", error_result)
          end
          nil
        end

        # Criar detalhamento geral (todas as camadas)
        @dialog.add_action_callback("createGeneralDetails") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProDetails.create_general_details
            send_json_response("handleCreateGeneralDetailsResult", result)
          rescue => e
            error_result = handle_error(e, "create general details")
            send_json_response("handleCreateGeneralDetailsResult", error_result)
          end
          nil
        end

        # Obter lista de estilos
        @dialog.add_action_callback("getStyles") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProDetails.get_styles
            send_json_response("handleGetStylesResult", result)
          rescue => e
            error_result = handle_error(e, "get styles")
            send_json_response("handleGetStylesResult", error_result)
          end
          nil
        end

        # Duplicar cena com novo estilo
        @dialog.add_action_callback("duplicateScene") do |action_context, json_payload|
          begin
            result = ProjetaPlus::Modules::ProDetails.duplicate_scene(json_payload)
            send_json_response("handleDuplicateSceneResult", result)
          rescue => e
            error_result = handle_error(e, "duplicate scene")
            send_json_response("handleDuplicateSceneResult", error_result)
          end
          nil
        end

        # Alternar vista (câmera isométrica)
        @dialog.add_action_callback("togglePerspective") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProDetails.toggle_perspective
            send_json_response("handleTogglePerspectiveResult", result)
          rescue => e
            error_result = handle_error(e, "toggle perspective")
            send_json_response("handleTogglePerspectiveResult", error_result)
          end
          nil
        end
      end
      
    end
  end
end
