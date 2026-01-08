# encoding: UTF-8

require 'sketchup.rb'
require 'csv'
require 'json'

module ProjetaPlus
  module Modules
    module ProCoatingsReports

      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================

      SETTINGS_KEY = "coatings_reports_settings"
      CONVERSION_FACTOR = 0.00064516 # Conversão de área do SketchUp para m²

      # Mapeamento de colunas
      COLUMN_MAPPING = {
        'ambiente' => 'Ambiente',
        'material' => 'Material',
        'marca' => 'Marca',
        'acabamento' => 'Acabamento',
        'area' => 'Área (m²)',
        'acrescimo' => 'Acréscimo (%)',
        'total' => 'Total (m²)'
      }

      DEFAULT_COLUMNS = %w[ambiente material marca acabamento area acrescimo total]

      # ========================================
      # MÉTODOS PÚBLICOS - Persistência
      # ========================================

      def self.get_data_file_path
        model = Sketchup.active_model
        model_path = model.path
        
        return nil if model_path.empty?
        
        dir = File.dirname(model_path)
        filename = File.basename(model_path, '.skp')
        File.join(dir, "#{filename}_materiais.json")
      end

      def self.save_data(params)
        begin
          data = params['data'] || params[:data] || []
          
          file_path = get_data_file_path
          unless file_path
            return { success: false, message: "O modelo precisa ser salvo antes de persistir dados" }
          end
          
          File.open(file_path, 'w') do |file|
            file.write(JSON.pretty_generate(data))
          end
          
          {
            success: true,
            message: "Dados salvos com sucesso",
            path: file_path
          }
        rescue => e
          puts "[ProCoatingsReports] ERROR in save_data: #{e.message}"
          { success: false, message: "Erro ao salvar dados: #{e.message}" }
        end
      end

      def self.load_data
        begin
          file_path = get_data_file_path
          
          unless file_path && File.exist?(file_path)
            return {
              success: true,
              data: [],
              message: "Nenhum dado salvo encontrado"
            }
          end
          
          json_content = File.read(file_path)
          data = JSON.parse(json_content)
          
          {
            success: true,
            data: data,
            message: "Dados carregados com sucesso"
          }
        rescue => e
          puts "[ProCoatingsReports] ERROR in load_data: #{e.message}"
          {
            success: false,
            data: [],
            message: "Erro ao carregar dados: #{e.message}"
          }
        end
      end

      # ========================================
      # MÉTODOS PÚBLICOS - Adicionar Material
      # ========================================

      def self.add_selected_material
        begin
          model = Sketchup.active_model
          material = model.materials.current

          unless material
            return { success: false, message: "Nenhum material selecionado. Use o conta-gotas para selecionar um material." }
          end

          # Calcular área do material
          areas = iterate_entities(model.entities)
          selected_area = areas[material] || 0.0
          area_m2 = (selected_area * CONVERSION_FACTOR).round(2)

          if area_m2 == 0
            return { success: false, message: "Material selecionado não está aplicado em nenhuma face." }
          end

          material_name = material.display_name

          {
            success: true,
            material: {
              name: material_name,
              area: area_m2
            },
            message: "Material '#{material_name}' adicionado: #{area_m2}m²"
          }
        rescue => e
          puts "[ProCoatingsReports] ERROR in add_selected_material: #{e.message}"
          { success: false, message: "Erro ao adicionar material: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS PÚBLICOS - Export
      # ========================================

      def self.export_to_csv(params)
        begin
          data = params['data'] || params[:data] || []
          columns = params['columns'] || params[:columns] || DEFAULT_COLUMNS

          model = Sketchup.active_model
          model_path = model.path

          if model_path.empty?
            return { success: false, message: "O modelo precisa ser salvo antes de exportar" }
          end

          directory = File.dirname(model_path)
          file_path = File.join(directory, "Revestimentos.csv")

          write_csv_file(file_path, data, columns)

          {
            success: true,
            message: "Arquivo CSV exportado com sucesso",
            path: file_path
          }
        rescue => e
          puts "[ProCoatingsReports] ERROR in export_to_csv: #{e.message}"
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
          puts "[ProCoatingsReports] ERROR in export_to_xlsx: #{e.message}"
          { success: false, message: "Erro ao exportar XLSX: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS
      # ========================================

      private

      def self.iterate_entities(entities, areas = Hash.new(0))
        entities.each do |entity|
          if entity.is_a?(Sketchup::Face)
            # Material da frente
            mat = entity.material
            areas[mat] += entity.area if mat
            
            # Material de trás
            back_mat = entity.back_material
            areas[back_mat] += entity.area if back_mat
            
          elsif entity.is_a?(Sketchup::Group)
            iterate_entities(entity.entities, areas)
            
          elsif entity.is_a?(Sketchup::ComponentInstance)
            iterate_entities(entity.definition.entities, areas)
          end
        end
        areas
      end

      def self.write_csv_file(file_path, data, columns)
        CSV.open(file_path, 'w:UTF-8') do |csv|
          # Cabeçalho
          headers = columns.map { |col| COLUMN_MAPPING[col] || col.capitalize }
          csv << headers

          # Dados
          data.each do |item|
            row = columns.map do |col|
              value = item[col] || item[col.to_sym] || ''
              
              # Formatar números se necessário
              if col == 'area' || col == 'total'
                value.is_a?(Numeric) ? value.round(2) : value
              elsif col == 'acrescimo'
                value.is_a?(Numeric) ? value.round(0) : value
              else
                value
              end
            end
            csv << row
          end

          # Linha de total
          if data.any?
            total_row = columns.map do |col|
              case col
              when 'ambiente'
                'TOTAL'
              when 'area'
                total_area = data.sum { |item| (item['area'] || item[:area] || 0).to_f }
                total_area.round(2)
              when 'total'
                total_with_acrescimo = data.sum { |item| (item['total'] || item[:total] || 0).to_f }
                total_with_acrescimo.round(2)
              else
                ''
              end
            end
            csv << total_row
          end
        end
      end

    end
  end
end
