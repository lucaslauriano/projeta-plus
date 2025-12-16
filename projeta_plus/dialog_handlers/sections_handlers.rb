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

        # CREATE STANDARD SECTIONS - Criar cortes padrões (A, B, C, D)
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

        # CREATE AUTO VIEWS - Criar vistas automáticas
        @dialog.add_action_callback("createAutoViews") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProSections.create_auto_views
            send_json_response("handleCreateAutoViewsResult", result)
          rescue => e
            error_result = handle_error(e, "create auto views")
            send_json_response("handleCreateAutoViewsResult", error_result)
          end
          nil
        end

        # CREATE INDIVIDUAL SECTION - Criar corte individual
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

      end

    end
  end
end
