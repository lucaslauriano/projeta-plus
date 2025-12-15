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

      # ========================================
      # MÉTODOS PARA COMPONENTES CUSTOMIZADOS
      # ========================================

      # Retorna o caminho para componentes customizados
      def self.get_custom_components_path
        home = ENV['HOME'] || ENV['USERPROFILE']
        File.join(home, '.projeta_plus', 'custom_components')
      end

      # Valida e sanitiza um caminho para prevenir path traversal
      # Retorna nil se o caminho for inválido
      def self.sanitize_path(path)
        return nil if path.nil? || path.empty?
        
        # Rejeita caminhos absolutos
        return nil if path.start_with?('/', '\\') || path.match?(/^[a-zA-Z]:/)
        
        # Rejeita sequências de path traversal
        return nil if path.include?('..') || path.include?('~')
        
        # Remove barras duplicadas e normaliza
        path.gsub(/[\/\\]+/, File::SEPARATOR)
      end

      # Carrega blocos customizados do usuário
      def self.load_custom_blocks
        custom_path = get_custom_components_path
        return [] unless File.directory?(custom_path)
        
        groups = []
        
        # Obter subpastas customizadas
        subfolders = Dir.entries(custom_path)
                        .select { |entry| File.directory?(File.join(custom_path, entry)) && !(entry == '.' || entry == '..') }
                        .sort

        subfolders.each do |subfolder|
          subfolder_path = File.join(custom_path, subfolder)
          skp_files = Dir.entries(subfolder_path)
                         .select { |file| File.extname(file).downcase == ".skp" }
                         .sort

          items = skp_files.map do |file|
            {
              id: "custom_#{File.basename(file, '.skp')}",
              name: File.basename(file, ".skp"),
              path: File.join(subfolder, file),
              source: 'custom'
            }
          end

          next if items.empty?

          groups << {
            id: "custom-#{subfolder.downcase.gsub(/[^a-z0-9]+/, '-')}",
            title: "#{subfolder} (Customizado)",
            items: items,
            source: 'custom'
          }
        end

        groups
      end

      # Upload de componente customizado
      def self.upload_custom_component(file_path, category = 'Geral')
        begin
          unless File.exist?(file_path)
            return {
              success: false,
              message: "Arquivo não encontrado: #{file_path}"
            }
          end

          # Valida e sanitiza o nome da categoria
          sanitized_category = sanitize_path(category)
          unless sanitized_category
            return {
              success: false,
              message: "Nome de categoria inválido: #{category}"
            }
          end

          custom_path = get_custom_components_path
          category_path = File.join(custom_path, sanitized_category)
          
          # Verifica se o caminho final está dentro do diretório permitido
          unless category_path.start_with?(custom_path)
            return {
              success: false,
              message: "Caminho de categoria inválido"
            }
          end
          
          # Criar diretório se não existir
          require 'fileutils'
          FileUtils.mkdir_p(category_path)

          # Copiar arquivo (usa basename para garantir que não há path traversal)
          filename = File.basename(file_path)
          dest_path = File.join(category_path, filename)
          
          # Validação adicional: verifica se dest_path está dentro de category_path
          unless dest_path.start_with?(category_path)
            return {
              success: false,
              message: "Caminho de destino inválido"
            }
          end
          
          FileUtils.cp(file_path, dest_path)

          {
            success: true,
            message: "Componente adicionado com sucesso",
            filename: File.basename(filename, '.skp')
          }
        rescue => e
          {
            success: false,
            message: "Erro ao adicionar componente: #{e.message}"
          }
        end
      end

      # Remover componente customizado
      def self.delete_custom_component(block_path)
        begin
          # Valida e sanitiza o caminho do bloco
          sanitized_path = sanitize_path(block_path)
          unless sanitized_path
            return {
              success: false,
              message: "Caminho de componente inválido: #{block_path}"
            }
          end

          custom_path = get_custom_components_path
          full_path = File.join(custom_path, sanitized_path)

          # Verifica se o caminho final está dentro do diretório permitido
          unless full_path.start_with?(custom_path)
            return {
              success: false,
              message: "Caminho de componente inválido"
            }
          end

          unless File.exist?(full_path)
            return {
              success: false,
              message: "Componente não encontrado: #{block_path}"
            }
          end

          File.delete(full_path)

          {
            success: true,
            message: "Componente removido com sucesso"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao remover componente: #{e.message}"
          }
        end
      end

    end
  end
end

