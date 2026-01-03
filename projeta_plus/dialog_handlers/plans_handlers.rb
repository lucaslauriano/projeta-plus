# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/inteli-skt/plans/pro_plans.rb'

module ProjetaPlus
  module DialogHandlers
    class PlansHandler < BaseHandler

      def register_callbacks
        register_plans_callbacks
      end

      private

      def register_plans_callbacks

        # GET - Buscar todas as plantas
        @dialog.add_action_callback("getPlans") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProPlans.get_plans
            send_json_response("handleGetPlansResult", result)
          rescue => e
            error_result = handle_error(e, "get plans")
            send_json_response("handleGetPlansResult", error_result)
          end
          nil
        end

        # ADD - Adicionar nova planta
        @dialog.add_action_callback("addPlan") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProPlans.add_plan(params)
            send_json_response("handleAddPlanResult", result)
          rescue => e
            error_result = handle_error(e, "add plan")
            send_json_response("handleAddPlanResult", error_result)
          end
          nil
        end

        # UPDATE - Atualizar planta existente
        @dialog.add_action_callback("updatePlan") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            name = params['name']
            result = ProjetaPlus::Modules::ProPlans.update_plan(name, params)
            send_json_response("handleUpdatePlanResult", result)
          rescue => e
            error_result = handle_error(e, "update plan")
            send_json_response("handleUpdatePlanResult", error_result)
          end
          nil
        end

        # DELETE - Remover planta
        @dialog.add_action_callback("deletePlan") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            name = params['name']
            result = ProjetaPlus::Modules::ProPlans.delete_plan(name)
            send_json_response("handleDeletePlanResult", result)
          rescue => e
            error_result = handle_error(e, "delete plan")
            send_json_response("handleDeletePlanResult", error_result)
          end
          nil
        end

        # APPLY CONFIG - Aplicar configuração a uma planta
        @dialog.add_action_callback("applyPlanConfig") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            name = params['name']
            code = params['code']
            config = params['config']
            result = ProjetaPlus::Modules::ProPlans.apply_plan_config(name, config)
            send_json_response("handleApplyPlanConfigResult", result)
          rescue => e
            error_result = handle_error(e, "apply plan config")
            send_json_response("handleApplyPlanConfigResult", error_result)
          end
          nil
        end

        # GET AVAILABLE STYLES
        @dialog.add_action_callback("getAvailableStylesPlans") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProPlans.get_available_styles
            send_json_response("handleGetAvailableStylesPlansResult", result)
          rescue => e
            error_result = handle_error(e, "get available styles")
            send_json_response("handleGetAvailableStylesPlansResult", error_result)
          end
          nil
        end

        # GET AVAILABLE LAYERS
        @dialog.add_action_callback("getAvailableLayersPlans") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProPlans.get_available_layers
            send_json_response("handleGetAvailableLayersPlansResult", result)
          rescue => e
            error_result = handle_error(e, "get available layers")
            send_json_response("handleGetAvailableLayersPlansResult", error_result)
          end
          nil
        end

        # GET VISIBLE LAYERS
        @dialog.add_action_callback("getVisibleLayersPlans") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProPlans.get_visible_layers
            send_json_response("handleGetVisibleLayersPlansResult", result)
          rescue => e
            error_result = handle_error(e, "get visible layers")
            send_json_response("handleGetVisibleLayersPlansResult", error_result)
          end
          nil
        end

        # GET CURRENT STATE
        @dialog.add_action_callback("getCurrentStatePlans") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProPlans.get_current_state
            send_json_response("handleGetCurrentStatePlansResult", result)
          rescue => e
            error_result = handle_error(e, "get current state")
            send_json_response("handleGetCurrentStatePlansResult", error_result)
          end
          nil
        end

        # SAVE TO JSON
        @dialog.add_action_callback("savePlansToJson") do |action_context, json_payload|
          begin
            data = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProPlans.save_to_json(data)
            send_json_response("handleSavePlansToJsonResult", result)
          rescue => e
            error_result = handle_error(e, "save plans to JSON")
            send_json_response("handleSavePlansToJsonResult", error_result)
          end
          nil
        end

        # LOAD FROM JSON
        @dialog.add_action_callback("loadPlansFromJson") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProPlans.load_from_json
            send_json_response("handleLoadPlansFromJsonResult", result)
          rescue => e
            error_result = handle_error(e, "load plans from JSON")
            send_json_response("handleLoadPlansFromJsonResult", error_result)
          end
          nil
        end

        # LOAD DEFAULT
        @dialog.add_action_callback("loadDefaultPlans") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProPlans.load_default_data
            send_json_response("handleLoadDefaultPlansResult", result)
          rescue => e
            error_result = handle_error(e, "load default plans")
            send_json_response("handleLoadDefaultPlansResult", error_result)
          end
          nil
        end

        # LOAD FROM FILE
        @dialog.add_action_callback("loadPlansFromFile") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProPlans.load_from_file
            send_json_response("handleLoadPlansFromFileResult", result)
          rescue => e
            error_result = handle_error(e, "load plans from file")
            send_json_response("handleLoadPlansFromFileResult", error_result)
          end
          nil
        end

        # ========================================
        # LEVELS MANAGEMENT
        # ========================================

        # GET LEVELS
        @dialog.add_action_callback("getLevels") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProPlans.get_levels
            send_json_response("handleGetLevelsResult", result)
          rescue => e
            error_result = handle_error(e, "get levels")
            send_json_response("handleGetLevelsResult", error_result)
          end
          nil
        end

        # ADD LEVEL
        @dialog.add_action_callback("addLevel") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            height_str = params['height']
            result = ProjetaPlus::Modules::ProPlans.add_level(height_str)
            send_json_response("handleAddLevelResult", result)
          rescue => e
            error_result = handle_error(e, "add level")
            send_json_response("handleAddLevelResult", error_result)
          end
          nil
        end

        # REMOVE LEVEL
        @dialog.add_action_callback("removeLevel") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            number = params['number']
            result = ProjetaPlus::Modules::ProPlans.remove_level(number)
            send_json_response("handleRemoveLevelResult", result)
          rescue => e
            error_result = handle_error(e, "remove level")
            send_json_response("handleRemoveLevelResult", error_result)
          end
          nil
        end

        # CREATE BASE SCENE
        @dialog.add_action_callback("createBaseScene") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            number = params['number']
            result = ProjetaPlus::Modules::ProPlans.create_base_scene(number)
            send_json_response("handleCreateBaseSceneResult", result)
          rescue => e
            error_result = handle_error(e, "create base scene")
            send_json_response("handleCreateBaseSceneResult", error_result)
          end
          nil
        end

        # CREATE CEILING SCENE
        @dialog.add_action_callback("createCeilingScene") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            number = params['number']
            result = ProjetaPlus::Modules::ProPlans.create_ceiling_scene(number)
            send_json_response("handleCreateCeilingSceneResult", result)
          rescue => e
            error_result = handle_error(e, "create ceiling scene")
            send_json_response("handleCreateCeilingSceneResult", error_result)
          end
          nil
        end

      end

    end
  end
end
