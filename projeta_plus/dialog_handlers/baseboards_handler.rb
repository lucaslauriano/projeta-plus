# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/baseboards/pro_baseboards.rb'

module ProjetaPlus
  module DialogHandlers
    class BaseboardsHandler < BaseHandler

      def register_callbacks
        register_baseboards_callbacks
      end

      private

      def register_baseboards_callbacks

        # GET - Buscar estrutura de blocos
        @dialog.add_action_callback("getBaseboardsBlocks") do |action_context|
          begin
            result = ProjetaPlus::Modules::Baseboards.get_blocks_structure
            @dialog.execute_script("window.handleGetBaseboardsBlocksResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message, groups: [] }
            @dialog.execute_script("window.handleGetBaseboardsBlocksResult(#{error_result.to_json})")
          end
          nil
        end

        # IMPORT - Importar bloco
        @dialog.add_action_callback("importBaseboardsBlock") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            block_path = params['path'] || params[:path]
            result = ProjetaPlus::Modules::Baseboards.import_block(block_path)
            @dialog.execute_script("window.handleImportBaseboardsBlockResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleImportBaseboardsBlockResult(#{error_result.to_json})")
          end
          nil
        end

        # OPEN FOLDER - Abrir pasta de blocos
        @dialog.add_action_callback("openBaseboardsBlocksFolder") do |action_context|
          begin
            result = ProjetaPlus::Modules::Baseboards.open_blocks_folder
            @dialog.execute_script("window.handleOpenBaseboardsFolderResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleOpenBaseboardsFolderResult(#{error_result.to_json})")
          end
          nil
        end

      end

    end
  end
end

