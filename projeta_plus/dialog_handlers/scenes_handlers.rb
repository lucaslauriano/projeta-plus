# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/inteli-skt/scenes/pro_scenes.rb'

module ProjetaPlus
  module DialogHandlers
    class ScenesHandler < BaseHandler

      def register_callbacks
        register_scenes_callbacks
      end

      private

      def register_scenes_callbacks

        # GET - Buscar todas as cenas
        @dialog.add_action_callback("getScenes") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProScenes.get_scenes
            send_json_response("handleGetScenesResult", result)
          rescue => e
            error_result = handle_error(e, "get scenes")
            send_json_response("handleGetScenesResult", error_result)
          end
          nil
        end

        # ADD - Adicionar nova cena
        @dialog.add_action_callback("addScene") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProScenes.add_scene(params)
            send_json_response("handleAddSceneResult", result)
          rescue => e
            error_result = handle_error(e, "add scene")
            send_json_response("handleAddSceneResult", error_result)
          end
          nil
        end

        # UPDATE - Atualizar cena existente
        @dialog.add_action_callback("updateScene") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            name = params['name']
            result = ProjetaPlus::Modules::ProScenes.update_scene(name, params)
            send_json_response("handleUpdateSceneResult", result)
          rescue => e
            error_result = handle_error(e, "update scene")
            send_json_response("handleUpdateSceneResult", error_result)
          end
          nil
        end

        # DELETE - Remover cena
        @dialog.add_action_callback("deleteScene") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            name = params['name']
            result = ProjetaPlus::Modules::ProScenes.delete_scene(name)
            send_json_response("handleDeleteSceneResult", result)
          rescue => e
            error_result = handle_error(e, "delete scene")
            send_json_response("handleDeleteSceneResult", error_result)
          end
          nil
        end

        # APPLY CONFIG - Aplicar configuração a uma cena
        @dialog.add_action_callback("applySceneConfig") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            name = params['name']
            config = params['config']
            result = ProjetaPlus::Modules::ProScenes.apply_scene_config(name, config)
            send_json_response("handleApplySceneConfigResult", result)
          rescue => e
            error_result = handle_error(e, "apply scene config")
            send_json_response("handleApplySceneConfigResult", error_result)
          end
          nil
        end

        # GET AVAILABLE STYLES
        @dialog.add_action_callback("getAvailableStyles") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProScenes.get_available_styles
            send_json_response("handleGetAvailableStylesResult", result)
          rescue => e
            error_result = handle_error(e, "get available styles")
            send_json_response("handleGetAvailableStylesResult", error_result)
          end
          nil
        end

        # GET AVAILABLE LAYERS
        @dialog.add_action_callback("getAvailableLayers") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProScenes.get_available_layers
            send_json_response("handleGetAvailableLayersResult", result)
          rescue => e
            error_result = handle_error(e, "get available layers")
            send_json_response("handleGetAvailableLayersResult", error_result)
          end
          nil
        end

        # GET VISIBLE LAYERS
        @dialog.add_action_callback("getVisibleLayers") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProScenes.get_visible_layers
            send_json_response("handleGetVisibleLayersResult", result)
          rescue => e
            error_result = handle_error(e, "get visible layers")
            send_json_response("handleGetVisibleLayersResult", error_result)
          end
          nil
        end

        # GET CURRENT STATE
        @dialog.add_action_callback("getCurrentState") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProScenes.get_current_state
            send_json_response("handleGetCurrentStateResult", result)
          rescue => e
            error_result = handle_error(e, "get current state")
            send_json_response("handleGetCurrentStateResult", error_result)
          end
          nil
        end

        # SAVE TO JSON
        @dialog.add_action_callback("saveScenesToJson") do |action_context, json_payload|
          begin
            data = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProScenes.save_to_json(data)
            send_json_response("handleSaveScenesToJsonResult", result)
          rescue => e
            error_result = handle_error(e, "save scenes to JSON")
            send_json_response("handleSaveScenesToJsonResult", error_result)
          end
          nil
        end

        # LOAD FROM JSON
        @dialog.add_action_callback("loadScenesFromJson") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProScenes.load_from_json
            send_json_response("handleLoadScenesFromJsonResult", result)
          rescue => e
            error_result = handle_error(e, "load scenes from JSON")
            send_json_response("handleLoadScenesFromJsonResult", error_result)
          end
          nil
        end

        # LOAD DEFAULT
        @dialog.add_action_callback("loadDefaultScenes") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProScenes.load_default_data
            send_json_response("handleLoadDefaultScenesResult", result)
          rescue => e
            error_result = handle_error(e, "load default scenes")
            send_json_response("handleLoadDefaultScenesResult", error_result)
          end
          nil
        end

        # LOAD FROM FILE
        @dialog.add_action_callback("loadScenesFromFile") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProScenes.load_from_file
            send_json_response("handleLoadScenesFromFileResult", result)
          rescue => e
            error_result = handle_error(e, "load scenes from file")
            send_json_response("handleLoadScenesFromFileResult", error_result)
          end
          nil
        end

      end

    end
  end
end
