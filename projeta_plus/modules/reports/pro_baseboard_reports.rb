# encoding: UTF-8

require 'sketchup.rb'
require 'csv'
require 'json'

module ProjetaPlus
  module Modules
    module ProBaseboardReports

      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================

      SETTINGS_KEY = "baseboard_reports_settings"
      MAX_RECURSION_LEVEL = 5
      DEFAULT_BAR_LENGTH = 2.4 # metros

      # Mapeamento de colunas
      COLUMN_MAPPING = {
        'modelo' => 'MODELO',
        'soma' => 'SOMA (m)',
        'barra' => 'BARRA (m)',
        'total' => 'TOTAL (un)'
      }

      DEFAULT_COLUMNS = %w[modelo soma barra total]

      # ========================================
      # MÉTODOS PÚBLICOS - Get Data
      # ========================================

      # Retorna dados de rodapés do modelo
      def self.get_baseboard_data
        begin
          puts "[ProBaseboardReports] Getting baseboard data"
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model

          components = search_components_recursive(model.active_entities, 0)
          
          puts "[ProBaseboardReports] Found #{components.size} baseboard components"
          
          if components.empty?
            return {
              success: true,
              data: {
                items: [],
                total: 0,
                summary: { totalLength: 0, totalUnits: 0, uniqueModels: 0 }
              }
            }
          end

          grouped_data = group_and_sum_components(components)
          puts "[ProBaseboardReports] Grouped into #{grouped_data.size} unique models"

          total_length = grouped_data.sum { |item| item[:soma] }
          total_units = grouped_data.sum { |item| item[:total] }

          {
            success: true,
            data: {
              items: grouped_data,
              total: total_units,
              summary: {
                totalLength: total_length.round(2),
                totalUnits: total_units,
                uniqueModels: grouped_data.size
              }
            }
          }
        rescue => e
          puts "[ProBaseboardReports] ERROR in get_baseboard_data: #{e.message}"
          puts e.backtrace.join("\n") if e.backtrace
          { success: false, message: "Erro ao buscar dados: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS PÚBLICOS - Export
      # ========================================

      def self.export_to_csv(params)
        begin
          data = params['data'] || params[:data] || []

          model = Sketchup.active_model
          model_path = model.path

          if model_path.empty?
            return { success: false, message: "O modelo precisa ser salvo antes de exportar" }
          end

          directory = File.dirname(model_path)
          file_path = File.join(directory, "Rodapes.csv")

          write_csv_file(file_path, data)

          {
            success: true,
            message: "Arquivo CSV exportado com sucesso",
            path: file_path
          }
        rescue => e
          puts "[ProBaseboardReports] ERROR in export_to_csv: #{e.message}"
          { success: false, message: "Erro ao exportar CSV: #{e.message}" }
        end
      end

      def self.export_to_xlsx(params)
        begin
          result = export_to_csv(params)
          
          if result[:success]
            csv_path = result[:path]
            xlsx_path = csv_path.gsub('.csv', '.xlsx')
            
            File.rename(csv_path, xlsx_path) if File.exist?(csv_path)
            
            {
              success: true,
              message: "Arquivo exportado com sucesso (formato CSV compatível)",
              path: xlsx_path
            }
          else
            result
          end
        rescue => e
          puts "[ProBaseboardReports] ERROR in export_to_xlsx: #{e.message}"
          { success: false, message: "Erro ao exportar XLSX: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS - Coleta de Dados
      # ========================================

      private

      # Busca componentes de rodapés recursivamente
      def self.search_components_recursive(entities, level)
        components = []
        return components if level >= MAX_RECURSION_LEVEL

        entities.each do |entity|
          next unless entity.valid?

          if entity.is_a?(Sketchup::ComponentInstance)
            # Verifica se possui o atributo "comprimentorodape"
            comprimentorodape = entity.get_attribute("dynamic_attributes", "comprimentorodape")
            next unless comprimentorodape

            definition = entity.definition
            nome = definition.name

            # Calcula o comprimento dinâmico usando LenX
            lenx_em_metros = (entity.transformation.xscale * definition.bounds.width) * 0.0254
            lenx_dinamico = entity.get_attribute("dynamic_attributes", "_lenx_formula")&.to_f || lenx_em_metros

            # Obtém o modelo do rodapé
            modelorodape = definition.get_attribute("dynamic_attributes", "modelorodape")

            # Adiciona se válido
            if lenx_dinamico > 0 && modelorodape
              components << {
                nome: nome,
                comprimento: lenx_dinamico,
                modelo: modelorodape,
                id: entity.persistent_id
              }
            end

            # Busca recursivamente
            if definition.respond_to?(:entities)
              components.concat(search_components_recursive(definition.entities, level + 1))
            end

          elsif entity.is_a?(Sketchup::Group)
            if entity.respond_to?(:entities)
              components.concat(search_components_recursive(entity.entities, level + 1))
            end
          end
        end

        components
      end

      # Agrupa e soma componentes por modelo
      def self.group_and_sum_components(components)
        grouped = Hash.new(0.0)
        
        components.each do |comp|
          modelo = comp[:modelo]
          grouped[modelo] += comp[:comprimento].to_f
        end

        grouped.map do |modelo, soma|
          soma_rounded = soma.round(2)
          total_barras = (soma / DEFAULT_BAR_LENGTH).ceil
          
          {
            modelo: modelo.to_s,
            soma: soma_rounded,
            barra: DEFAULT_BAR_LENGTH,
            total: total_barras
          }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS - Export
      # ========================================

      def self.write_csv_file(file_path, data)
        CSV.open(file_path, 'w:UTF-8') do |csv|
          # Cabeçalho
          csv << ["LEGENDA", "MODELO", "SOMA (m)", "BARRA (m)", "TOTAL (un)"]

          # Dados
          data.each do |item|
            modelo = item['modelo'] || item[:modelo] || ''
            soma = item['soma'] || item[:soma] || 0
            barra = item['barra'] || item[:barra] || DEFAULT_BAR_LENGTH
            total = item['total'] || item[:total] || 0
            
            csv << [
              "",  # Legenda vazia
              modelo.to_s,
              soma,
              barra,
              total
            ]
          end

          # Linha de total
          total_soma = data.sum { |item| (item['soma'] || item[:soma] || 0).to_f }
          total_units = data.sum { |item| (item['total'] || item[:total] || 0).to_i }
          
          csv << [
            "TOTAL",
            "",
            total_soma.round(2),
            "",
            total_units
          ]
        end
      end

    end
  end
end
