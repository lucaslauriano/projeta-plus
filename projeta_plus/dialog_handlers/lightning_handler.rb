# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/lightning/pro_lightning.rb'

module ProjetaPlus
  module DialogHandlers
    class LightningHandler < BaseHandler

      def register_callbacks
        register_lightning_callbacks
      end

      private

      def register_lightning_callbacks

        # GET - Buscar estrutura de blocos
        @dialog.add_action_callback("getLightningBlocks") do |action_context|
          begin
            result = ProjetaPlus::Modules::Lightning.get_blocks_structure
            @dialog.execute_script("window.handleGetLightningBlocksResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message, groups: [] }
            @dialog.execute_script("window.handleGetLightningBlocksResult(#{error_result.to_json})")
          end
          nil
        end

        # IMPORT - Importar bloco
        @dialog.add_action_callback("importLightningBlock") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            block_path = params['path'] || params[:path]
            result = ProjetaPlus::Modules::Lightning.import_block(block_path)
            @dialog.execute_script("window.handleImportLightningBlockResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleImportLightningBlockResult(#{error_result.to_json})")
          end
          nil
        end

        # OPEN FOLDER - Abrir pasta de blocos
        @dialog.add_action_callback("openLightningBlocksFolder") do |action_context|
          begin
            result = ProjetaPlus::Modules::Lightning.open_blocks_folder
            @dialog.execute_script("window.handleOpenLightningFolderResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleOpenLightningFolderResult(#{error_result.to_json})")
          end
          nil
        end

      end

    end
  end
end

