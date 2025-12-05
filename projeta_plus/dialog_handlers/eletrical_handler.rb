# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/eletrical/pro_eletrical.rb'

module ProjetaPlus
  module DialogHandlers
    class EletricalHandler < BaseHandler

      def register_callbacks
        register_eletrical_callbacks
      end

      private

      def register_eletrical_callbacks

        # GET - Buscar estrutura de blocos
        @dialog.add_action_callback("getElectricalBlocks") do |action_context|
          begin
            result = ProjetaPlus::Modules::Electrical.get_blocks_structure
            @dialog.execute_script("window.handleGetElectricalBlocksResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message, groups: [] }
            @dialog.execute_script("window.handleGetElectricalBlocksResult(#{error_result.to_json})")
          end
          nil
        end

        # IMPORT - Importar bloco
        @dialog.add_action_callback("importElectricalBlock") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            block_path = params['path'] || params[:path]
            result = ProjetaPlus::Modules::Electrical.import_block(block_path)
            @dialog.execute_script("window.handleImportElectricalBlockResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleImportElectricalBlockResult(#{error_result.to_json})")
          end
          nil
        end

        # OPEN FOLDER - Abrir pasta de blocos
        @dialog.add_action_callback("openElectricalBlocksFolder") do |action_context|
          begin
            result = ProjetaPlus::Modules::Electrical.open_blocks_folder
            @dialog.execute_script("window.handleOpenElectricalFolderResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleOpenElectricalFolderResult(#{error_result.to_json})")
          end
          nil
        end
      end
    end
  end
end

