# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/inteli-skt/pro_layers.rb'

module ProjetaPlus
  module DialogHandlers
    class LayersHandler < BaseHandler
      
      def register_callbacks
        register_layers_callbacks
      end
      
      private
      
      def register_layers_callbacks
        @dialog.add_action_callback("addFolder") do |action_context, json_payload|
          begin
            args = JSON.parse(json_payload)
            folder_name = args['folderName']
            result = ProjetaPlus::Modules::ProLayers.add_folder(folder_name)
            send_json_response("handleAddFolderResult", result)
          rescue => e
            error_result = handle_error(e, "add folder")
            send_json_response("handleAddFolderResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("addTag") do |action_context, json_payload|
          begin
            args = JSON.parse(json_payload)
            tag_name = args['name']
            color = args['color']
            folder = args['folder']
            
            result = ProjetaPlus::Modules::ProLayers.add_tag(tag_name, color, folder)
            send_json_response("handleAddTagResult", result)
          rescue => e
            error_result = handle_error(e, "add tag")
            send_json_response("handleAddTagResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("getLayers") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProLayers.get_layers
            send_json_response("handleGetLayersResult", result)
          rescue => e
            error_result = handle_error(e, "get layers")
            send_json_response("handleGetLayersResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("importLayers") do |action_context, json_payload|
          begin
            result = ProjetaPlus::Modules::ProLayers.import_layers(json_payload)
            send_json_response("handleImportLayersResult", result)
          rescue => e
            error_result = handle_error(e, "import layers")
            send_json_response("handleImportLayersResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("deleteLayer") do |action_context, layer_name|
          begin
            result = ProjetaPlus::Modules::ProLayers.delete_layer(layer_name)
            send_json_response("handleDeleteLayerResult", result)
          rescue => e
            error_result = handle_error(e, "delete layer")
            send_json_response("handleDeleteLayerResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("toggleVisibility") do |action_context, json_payload|
          begin
            args = JSON.parse(json_payload)
            name = args['name']
            visible = args['visible']
            
            result = ProjetaPlus::Modules::ProLayers.toggle_visibility(name, visible)
            send_json_response("handleToggleVisibilityResult", result)
          rescue => e
            error_result = handle_error(e, "toggle visibility")
            send_json_response("handleToggleVisibilityResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("saveToJson") do |action_context, json_payload|
          begin
            result = ProjetaPlus::Modules::ProLayers.save_to_json(json_payload)
            send_json_response("handleSaveToJsonResult", result)
          rescue => e
            error_result = handle_error(e, "save to JSON")
            send_json_response("handleSaveToJsonResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("loadFromJson") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProLayers.load_from_json
            send_json_response("handleLoadFromJsonResult", result)
          rescue => e
            error_result = handle_error(e, "load from JSON")
            send_json_response("handleLoadFromJsonResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("loadFromFile") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProLayers.load_from_file
            send_json_response("handleLoadFromFileResult", result)
          rescue => e
            error_result = handle_error(e, "load from file")
            send_json_response("handleLoadFromFileResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("getJsonPath") do |action_context|
          begin
            path = ProjetaPlus::Modules::ProLayers.get_json_path
            send_json_response("handleGetJsonPathResult", { success: true, path: path })
          rescue => e
            error_result = handle_error(e, "get JSON path")
            send_json_response("handleGetJsonPathResult", error_result)
          end
          nil
        end
      end
      
    end
  end
end