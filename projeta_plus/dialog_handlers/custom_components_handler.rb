# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/pro_blocks.rb'

module ProjetaPlus
  module DialogHandlers
    class CustomComponentsHandler < BaseHandler

      def register_callbacks
        register_custom_components_callbacks
      end

      private

      def register_custom_components_callbacks

        # UPLOAD - Upload de componente customizado
        @dialog.add_action_callback("uploadCustomComponent") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            
            # Abrir diálogo para selecionar arquivo
            file_path = UI.openpanel("Selecionar Componente .skp", "", "SketchUp Files|*.skp||")
            
            if file_path
              category = params['category'] || 'Geral'
              result = ProjetaPlus::Modules::BlocksManager.upload_custom_component(file_path, category)
              @dialog.execute_script("window.handleUploadCustomComponentResult(#{result.to_json})")
            else
              result = { success: false, message: "Nenhum arquivo selecionado" }
              @dialog.execute_script("window.handleUploadCustomComponentResult(#{result.to_json})")
            end
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleUploadCustomComponentResult(#{error_result.to_json})")
          end
          nil
        end

        # DELETE - Remover componente customizado
        @dialog.add_action_callback("deleteCustomComponent") do |action_context, json_payload|
          begin
            params = JSON.parse(json_payload)
            block_path = params['path'] || params[:path]
            result = ProjetaPlus::Modules::BlocksManager.delete_custom_component(block_path)
            @dialog.execute_script("window.handleDeleteCustomComponentResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleDeleteCustomComponentResult(#{error_result.to_json})")
          end
          nil
        end

        # GET CUSTOM - Listar componentes customizados
        @dialog.add_action_callback("getCustomComponents") do |action_context|
          begin
            custom_groups = ProjetaPlus::Modules::BlocksManager.load_custom_blocks
            result = {
              success: true,
              groups: custom_groups
            }
            @dialog.execute_script("window.handleGetCustomComponentsResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message, groups: [] }
            @dialog.execute_script("window.handleGetCustomComponentsResult(#{error_result.to_json})")
          end
          nil
        end

        # OPEN CUSTOM FOLDER - Abrir pasta de componentes customizados
        @dialog.add_action_callback("openCustomComponentsFolder") do |action_context|
          begin
            custom_path = ProjetaPlus::Modules::BlocksManager.get_custom_components_path
            
            # Criar pasta se não existir
            FileUtils.mkdir_p(custom_path) unless File.directory?(custom_path)
            
            # Abrir pasta
            if Sketchup.platform == :platform_win
              win_path = custom_path.tr('/', '\\')
              ::UI.openURL("file:///#{win_path}")
            else
              ::UI.openURL("file://#{custom_path}")
            end
            
            result = { success: true, message: "Pasta de componentes customizados aberta" }
            @dialog.execute_script("window.handleOpenCustomFolderResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleOpenCustomFolderResult(#{error_result.to_json})")
          end
          nil
        end

        # SYNC FOLDER - Sincronizar pasta local
        @dialog.add_action_callback("syncCustomComponentsFolder") do |action_context|
          begin
            # Abrir diálogo para selecionar pasta
            folder_path = UI.select_directory(
              title: "Selecionar Pasta com Componentes",
              directory: ""
            )
            
            if folder_path
              result = sync_folder(folder_path)
              @dialog.execute_script("window.handleSyncFolderResult(#{result.to_json})")
            else
              result = { success: false, message: "Nenhuma pasta selecionada" }
              @dialog.execute_script("window.handleSyncFolderResult(#{result.to_json})")
            end
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleSyncFolderResult(#{error_result.to_json})")
          end
          nil
        end

      end
      
      # Sincroniza pasta selecionada com componentes customizados
      def sync_folder(source_folder)
        begin
          custom_path = ProjetaPlus::Modules::BlocksManager.get_custom_components_path
          FileUtils.mkdir_p(custom_path)
          
          synced_count = 0
          
          # Copiar todos os arquivos .skp
          Dir.glob("#{source_folder}/**/*.skp").each do |file_path|
            relative_path = file_path.sub("#{source_folder}/", '')
            dest_path = File.join(custom_path, relative_path)
            
            # Criar diretório de destino se necessário
            FileUtils.mkdir_p(File.dirname(dest_path))
            
            # Copiar arquivo
            FileUtils.cp(file_path, dest_path)
            synced_count += 1
          end
          
          {
            success: true,
            message: "#{synced_count} componente(s) sincronizado(s)",
            count: synced_count
          }
        rescue => e
          {
            success: false,
            message: "Erro ao sincronizar pasta: #{e.message}"
          }
        end
      end

    end
  end
end

