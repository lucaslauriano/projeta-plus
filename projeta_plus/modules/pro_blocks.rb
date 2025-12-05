# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    # Módulo genérico para gerenciar blocos de componentes
    module BlocksManager

      # ========================================
      # MÉTODOS GENÉRICOS
      # ========================================

      # Retorna a estrutura de pastas e blocos disponíveis
      def self.get_blocks_structure(components_path)
        begin
          unless File.directory?(components_path)
            return {
              success: false,
              message: "Diretório de componentes não encontrado: #{components_path}",
              groups: []
            }
          end

          groups = []

          # Obter subpastas
          subfolders = Dir.entries(components_path)
                          .select { |entry| File.directory?(File.join(components_path, entry)) && !(entry == '.' || entry == '..') }
                          .sort_by { |entry| entry == "Geral" ? "" : entry }

          subfolders.each do |subfolder|
            subfolder_path = File.join(components_path, subfolder)
            skp_files = Dir.entries(subfolder_path)
                           .select { |file| File.extname(file).downcase == ".skp" }
                           .sort

            # Obter nomes dos blocos sem extensão
            items = skp_files.map do |file|
              {
                id: File.basename(file, ".skp"),
                name: File.basename(file, ".skp"),
                path: File.join(subfolder, file)
              }
            end

            next if items.empty?

            groups << {
              id: subfolder.downcase.gsub(/[^a-z0-9]+/, '-'),
              title: subfolder,
              items: items
            }
          end

          {
            success: true,
            groups: groups,
            components_path: components_path
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar estrutura de blocos: #{e.message}",
            groups: []
          }
        end
      end

      # Importa um bloco para o modelo
      def self.import_block(block_path, components_path)
        begin
          full_path = File.join(components_path, block_path)

          unless File.exist?(full_path)
            return {
              success: false,
              message: "Bloco não encontrado: #{full_path}"
            }
          end

          model = Sketchup.active_model
          definitions = model.definitions

          # Carregar o componente
          definition = definitions.load(full_path, allow_newer: true)

          unless definition.is_a?(Sketchup::ComponentDefinition)
            return {
              success: false,
              message: "O arquivo não é um componente válido: #{full_path}"
            }
          end

          # Colocar o componente no modelo
          model.place_component(definition)

          {
            success: true,
            message: "Bloco importado com sucesso: #{File.basename(block_path, '.skp')}",
            block_name: File.basename(block_path, '.skp')
          }
        rescue => e
          {
            success: false,
            message: "Erro ao importar bloco: #{e.message}"
          }
        end
      end

      # Abre a pasta de componentes no explorador de arquivos
      def self.open_blocks_folder(components_path)
        begin
          unless File.directory?(components_path)
            return {
              success: false,
              message: "Erro: O diretório de blocos não foi encontrado:\n#{components_path}"
            }
          end

          # Detecta o sistema operacional e usa o comando apropriado
          if Sketchup.platform == :platform_win
            # Windows - usa explorer com caminho nativo
            win_path = components_path.tr('/', '\\')
            # Usa UI.openURL com file:/// protocol para Windows
            UI.openURL("file:///#{win_path}")
          else
            # macOS/Linux - usa UI.openURL com file:// protocol
            # No macOS, o Finder abre automaticamente
            UI.openURL("file://#{components_path}")
          end

          {
            success: true,
            message: "Pasta de blocos aberta"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao abrir pasta de blocos: #{e.message}"
          }
        end
      end

    end
  end
end

