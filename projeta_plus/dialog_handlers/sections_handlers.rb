# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/inteli-skt/sections/pro_sections.rb'

module ProjetaPlus
  module DialogHandlers
    class SectionsHandler < BaseHandler

      def register_callbacks
        register_sections_callbacks
      end

      private

      def register_sections_callbacks

        # GET - Buscar todas as seções
        @dialog.add_action_callback("getSections") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.get_sections
            send_json_response("handleGetSectionsResult", result)
          rescue => e
            error_result = handle_error(e, "get sections")
            send_json_response("handleGetSectionsResult", error_result)
          end
          nil
        end

        # ADD - Adicionar nova seção
        @dialog.add_action_callback("addSection") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProSections.add_section(params)
            send_json_response("handleAddSectionResult", result)
          rescue => e
            error_result = handle_error(e, "add section")
            send_json_response("handleAddSectionResult", error_result)
          end
          nil
        end

        # UPDATE - Atualizar seção existente
        @dialog.add_action_callback("updateSection") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            name = params['name']
            result = ProjetaPlus::Modules::ProSections.update_section(name, params)
            send_json_response("handleUpdateSectionResult", result)
          rescue => e
            error_result = handle_error(e, "update section")
            send_json_response("handleUpdateSectionResult", error_result)
          end
          nil
        end

        # DELETE - Remover seção
        @dialog.add_action_callback("deleteSection") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            name = params['name']
            result = ProjetaPlus::Modules::ProSections.delete_section(name)
            send_json_response("handleDeleteSectionResult", result)
          rescue => e
            error_result = handle_error(e, "delete section")
            send_json_response("handleDeleteSectionResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("createStandardSections") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.create_standard_sections
            send_json_response("handleCreateStandardSectionsResult", result)
          rescue => e
            error_result = handle_error(e, "create standard sections")
            send_json_response("handleCreateStandardSectionsResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("createAutoViews") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProSections.create_auto_views(params)
            send_json_response("handleCreateAutoViewsResult", result)
          rescue => e
            error_result = handle_error(e, "create auto views")
            send_json_response("handleCreateAutoViewsResult", error_result)
          end
          nil
        end

        @dialog.add_action_callback("createIndividualSection") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProSections.create_individual_section(params)
            send_json_response("handleCreateIndividualSectionResult", result)
          rescue => e
            error_result = handle_error(e, "create individual section")
            send_json_response("handleCreateIndividualSectionResult", error_result)
          end
          nil
        end

        # SAVE TO JSON
        @dialog.add_action_callback("saveSectionsToJson") do |action_context, json_payload|
          begin
            data = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProSections.save_to_json(data)
            send_json_response("handleSaveSectionsToJsonResult", result)
          rescue => e
            error_result = handle_error(e, "save sections to JSON")
            send_json_response("handleSaveSectionsToJsonResult", error_result)
          end
          nil
        end

        # LOAD FROM JSON
        @dialog.add_action_callback("loadSectionsFromJson") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.load_from_json
            send_json_response("handleLoadSectionsFromJsonResult", result)
          rescue => e
            error_result = handle_error(e, "load sections from JSON")
            send_json_response("handleLoadSectionsFromJsonResult", error_result)
          end
          nil
        end

        # LOAD DEFAULT
        @dialog.add_action_callback("loadDefaultSections") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.load_default_data
            send_json_response("handleLoadDefaultSectionsResult", result)
          rescue => e
            error_result = handle_error(e, "load default sections")
            send_json_response("handleLoadDefaultSectionsResult", error_result)
          end
          nil
        end

        # LOAD FROM FILE
        @dialog.add_action_callback("loadSectionsFromFile") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.load_from_file
            send_json_response("handleLoadSectionsFromFileResult", result)
          rescue => e
            error_result = handle_error(e, "load sections from file")
            send_json_response("handleLoadSectionsFromFileResult", error_result)
          end
          nil
        end

        # IMPORT TO MODEL
        @dialog.add_action_callback("importSectionsToModel") do |action_context, json_payload|
          begin
            data = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProSections.import_to_model(data)
            send_json_response("handleImportSectionsToModelResult", result)
          rescue => e
            error_result = handle_error(e, "import sections to model")
            send_json_response("handleImportSectionsToModelResult", error_result)
          end
          nil
        end

        # GET SECTIONS SETTINGS - Obter configurações de seções
        @dialog.add_action_callback("getSectionsSettings") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.get_sections_settings
            send_json_response("handleGetSectionsSettingsResult", result)
          rescue => e
            error_result = handle_error(e, "get sections settings")
            send_json_response("handleGetSectionsSettingsResult", error_result)
          end
          nil
        end

        # SAVE SECTIONS SETTINGS - Salvar configurações de seções
        @dialog.add_action_callback("saveSectionsSettings") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProSections.save_sections_settings(params)
            send_json_response("handleSaveSectionsSettingsResult", result)
          rescue => e
            error_result = handle_error(e, "save sections settings")
            send_json_response("handleSaveSectionsSettingsResult", error_result)
          end
          nil
        end

        # GET AVAILABLE STYLES FOR SECTIONS - Obter estilos disponíveis
        @dialog.add_action_callback("getAvailableStylesForSections") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.get_available_styles_for_sections
            send_json_response("handleGetAvailableStylesForSectionsResult", result)
          rescue => e
            error_result = handle_error(e, "get available styles for sections")
            send_json_response("handleGetAvailableStylesForSectionsResult", error_result)
          end
          nil
        end

        # GET AVAILABLE LAYERS FOR SECTIONS - Obter camadas disponíveis
        @dialog.add_action_callback("getAvailableLayersForSections") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.get_available_layers_for_sections
            send_json_response("handleGetAvailableLayersForSectionsResult", result)
          rescue => e
            error_result = handle_error(e, "get available layers for sections")
            send_json_response("handleGetAvailableLayersForSectionsResult", error_result)
          end
          nil
        end

        # APPLY CURRENT STYLE TO SECTIONS - Aplicar estilo atual
        @dialog.add_action_callback("applyCurrentStyleToSections") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.apply_current_style_to_sections
            send_json_response("handleApplyCurrentStyleToSectionsResult", result)
          rescue => e
            error_result = handle_error(e, "apply current style to sections")
            send_json_response("handleApplyCurrentStyleToSectionsResult", error_result)
          end
          nil
        end

        # GET CURRENT ACTIVE LAYERS - Obter camadas ativas atuais
        @dialog.add_action_callback("getCurrentActiveLayers") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.get_current_active_layers
            send_json_response("handleGetCurrentActiveLayersResult", result)
          rescue => e
            error_result = handle_error(e, "get current active layers")
            send_json_response("handleGetCurrentActiveLayersResult", error_result)
          end
          nil
        end

        # GET CURRENT ACTIVE LAYERS FILTERED - Obter camadas ativas filtradas
        @dialog.add_action_callback("getCurrentActiveLayersFiltered") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            available_layers = params['availableLayers'] || []
            result = ProjetaPlus::Modules::ProSections.get_current_active_layers_filtered(available_layers)
            send_json_response("handleGetCurrentActiveLayersFilteredResult", result)
          rescue => e
            error_result = handle_error(e, "get current active layers filtered")
            send_json_response("handleGetCurrentActiveLayersFilteredResult", error_result)
          end
          nil
        end

        # ADD GROUP - Adicionar novo grupo
        @dialog.add_action_callback("addSectionsGroup") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProSections.add_group(params)
            send_json_response("handleAddSectionsGroupResult", result)
          rescue => e
            error_result = handle_error(e, "add sections group")
            send_json_response("handleAddSectionsGroupResult", error_result)
          end
          nil
        end

        # UPDATE GROUP - Atualizar grupo
        @dialog.add_action_callback("updateSectionsGroup") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            id = params['id']
            result = ProjetaPlus::Modules::ProSections.update_group(id, params)
            send_json_response("handleUpdateSectionsGroupResult", result)
          rescue => e
            error_result = handle_error(e, "update sections group")
            send_json_response("handleUpdateSectionsGroupResult", error_result)
          end
          nil
        end

        # DELETE GROUP - Remover grupo
        @dialog.add_action_callback("deleteSectionsGroup") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            id = params['id']
            result = ProjetaPlus::Modules::ProSections.delete_group(id)
            send_json_response("handleDeleteSectionsGroupResult", result)
          rescue => e
            error_result = handle_error(e, "delete sections group")
            send_json_response("handleDeleteSectionsGroupResult", error_result)
          end
          nil
        end

        # ADD SEGMENT - Adicionar segmento
        @dialog.add_action_callback("addSectionsSegment") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            group_id = params['groupId']
            result = ProjetaPlus::Modules::ProSections.add_segment(group_id, params)
            send_json_response("handleAddSectionsSegmentResult", result)
          rescue => e
            error_result = handle_error(e, "add sections segment")
            send_json_response("handleAddSectionsSegmentResult", error_result)
          end
          nil
        end

        # UPDATE SEGMENT - Atualizar segmento
        @dialog.add_action_callback("updateSectionsSegment") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            group_id = params['groupId']
            segment_id = params['id']
            result = ProjetaPlus::Modules::ProSections.update_segment(group_id, segment_id, params)
            send_json_response("handleUpdateSectionsSegmentResult", result)
          rescue => e
            error_result = handle_error(e, "update sections segment")
            send_json_response("handleUpdateSectionsSegmentResult", error_result)
          end
          nil
        end

        # DELETE SEGMENT - Remover segmento
        @dialog.add_action_callback("deleteSectionsSegment") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            group_id = params['groupId']
            segment_id = params['id']
            result = ProjetaPlus::Modules::ProSections.delete_segment(group_id, segment_id)
            send_json_response("handleDeleteSectionsSegmentResult", result)
          rescue => e
            error_result = handle_error(e, "delete sections segment")
            send_json_response("handleDeleteSectionsSegmentResult", error_result)
          end
          nil
        end

        # DUPLICATE SCENES WITH SEGMENT - Duplicar cenas com segmento
        @dialog.add_action_callback("duplicateScenesWithSegment") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProSections.duplicate_scenes_with_segment(params)
            send_json_response("handleDuplicateScenesWithSegmentResult", result)
          rescue => e
            error_result = handle_error(e, "duplicate scenes with segment")
            send_json_response("handleDuplicateScenesWithSegmentResult", error_result)
          end
          nil
        end

        # GET MODEL SCENES - Obter cenas do modelo
        @dialog.add_action_callback("getModelScenes") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.get_model_scenes
            send_json_response("handleGetModelScenesResult", result)
          rescue => e
            error_result = handle_error(e, "get model scenes")
            send_json_response("handleGetModelScenesResult", error_result)
          end
          nil
        end

      end

    end
  end
end
