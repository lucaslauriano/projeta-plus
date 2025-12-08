# encoding: UTF-8
require 'sketchup.rb'
require 'json'
require_relative 'pro_s3_downloader.rb'

module ProjetaPlus
  module Modules
    # Módulo genérico para gerenciar blocos de componentes
    module BlocksManager

      # ========================================
      # CONFIGURAÇÕES
      # ========================================
      
      # Modo de operação: :local ou :s3
      @@mode = :local
      
      def self.set_mode(mode)
        @@mode = mode
      end
      
      def self.mode
        @@mode
      end

      # ========================================
      # MÉTODOS GENÉRICOS
      # ========================================

      # Retorna a estrutura de pastas e blocos disponíveis
      def self.get_blocks_structure(components_path, options = {})
        begin
          include_custom = options[:include_custom] || false
          
          # Carregar blocos do sistema (local ou S3)
          system_groups = load_system_blocks(components_path)
          
          # Carregar blocos customizados do usuário (se solicitado)
          custom_groups = include_custom ? load_custom_blocks : []
          
          # Combinar grupos
          all_groups = system_groups + custom_groups
          
          {
            success: true,
            groups: all_groups,
            components_path: components_path,
            mode: @@mode
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar estrutura de blocos: #{e.message}",
            groups: []
          }
        end
      end
      
      # Carrega blocos do sistema (padrão)
      def self.load_system_blocks(components_path)
        unless File.directory?(components_path)
          return []
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
              path: File.join(subfolder, file),
              source: 'system'
            }
          end

          next if items.empty?

          groups << {
            id: subfolder.downcase.gsub(/[^a-z0-9]+/, '-'),
            title: subfolder,
            items: items,
            source: 'system'
          }
        end

        groups
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
      
      # Retorna o caminho para componentes customizados
      def self.get_custom_components_path
        home = ENV['HOME'] || ENV['USERPROFILE']
        File.join(home, '.projeta_plus', 'custom_components')
      end

      # Importa um bloco para o modelo
      def self.import_block(block_path, components_path, options = {})
        begin
          source = options[:source] || 'system'
          
          # Determinar caminho completo baseado na fonte
          if source == 'custom'
            full_path = File.join(get_custom_components_path, block_path)
          else
            full_path = File.join(components_path, block_path)
          end

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
            block_name: File.basename(block_path, '.skp'),
            source: source
          }
        rescue => e
          {
            success: false,
            message: "Erro ao importar bloco: #{e.message}"
          }
        end
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
          
          unless File.extname(file_path).downcase == '.skp'
            return {
              success: false,
              message: "Apenas arquivos .skp são permitidos"
            }
          end
          
          # Criar diretório de destino
          custom_path = get_custom_components_path
          category_path = File.join(custom_path, category)
          FileUtils.mkdir_p(category_path)
          
          # Copiar arquivo
          filename = File.basename(file_path)
          dest_path = File.join(category_path, filename)
          
          FileUtils.cp(file_path, dest_path)
          
          {
            success: true,
            message: "Componente customizado adicionado com sucesso",
            filename: filename,
            category: category,
            path: dest_path
          }
        rescue => e
          {
            success: false,
            message: "Erro ao fazer upload: #{e.message}"
          }
        end
      end
      
      # Remove componente customizado
      def self.delete_custom_component(block_path)
        begin
          full_path = File.join(get_custom_components_path, block_path)
          
          unless File.exist?(full_path)
            return {
              success: false,
              message: "Componente não encontrado"
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

