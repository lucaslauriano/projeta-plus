# encoding: UTF-8

require 'sketchup.rb'
require 'csv'
require 'json'
require_relative '../furniture/pro_furniture_attributes.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProFurnitureReports

      include ProFurnitureAttributes

      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================

      SETTINGS_KEY = "furniture_reports_settings"
      CATEGORY_PREFS_KEY = 'category_prefs'
      COLUMN_PREFS_KEY = 'column_prefs'

      # ========================================
      # MÉTODOS PÚBLICOS - Get Data (NOVOS - para frontend React)
      # ========================================

      def self.get_furniture_types
        begin
          types = ProFurnitureAttributes.get_available_types
          puts "[ProFurnitureReports] Available types: #{types.inspect}"
          { success: true, types: types }
        rescue => e
          puts "[ProFurnitureReports] ERROR in get_furniture_types: #{e.message}"
          puts e.backtrace if e.backtrace
          { success: false, message: "Erro ao buscar tipos: #{e.message}" }
        end
      end

      def self.get_category_data(category)
        begin
          puts "[ProFurnitureReports] Getting data for category: #{category}"
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model

          data = collect_data_for_category(model, category)
          puts "[ProFurnitureReports] Collected #{data.size} unique items"
          result = process_category_items(data, category)
          puts "[ProFurnitureReports] Processed #{result[:items].size} items, total: #{result[:totalValue]}"

          {
            success: true,
            category: category,
            data: {
              category: category,
              items: result[:items],
              total: result[:totalValue],
              itemCount: result[:totalQuantity]
            }
          }
        rescue => e
          puts "ERROR in get_category_data: #{e.message}"
          puts e.backtrace if e.backtrace
          { success: false, message: "Erro ao buscar dados da categoria: #{e.message}" }
        end
      end

      def self.get_category_preferences
        begin
          types = ProFurnitureAttributes.get_available_types
          prefs = load_category_preferences(types)
          { success: true, preferences: prefs }
        rescue => e
          { success: false, message: "Erro ao carregar preferências: #{e.message}" }
        end
      end

      def self.get_column_preferences
        begin
          prefs = load_column_preferences
          { success: true, preferences: prefs }
        rescue => e
          { success: false, message: "Erro ao carregar preferências de colunas: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS PÚBLICOS - Save Data (NOVOS)
      # ========================================

      def self.save_category_preferences(preferences)
        begin
          Sketchup.write_default('projeta_plus_furniture', CATEGORY_PREFS_KEY, JSON.generate(preferences))
          { success: true, message: "Preferências salvas com sucesso" }
        rescue => e
          { success: false, message: "Erro ao salvar preferências: #{e.message}" }
        end
      end

      def self.save_column_preferences(preferences)
        begin
          Sketchup.write_default('projeta_plus_furniture', COLUMN_PREFS_KEY, JSON.generate(preferences))
          { success: true, message: "Preferências de colunas salvas com sucesso" }
        rescue => e
          { success: false, message: "Erro ao salvar preferências de colunas: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS PÚBLICOS - Item Operations (NOVOS)
      # ========================================

      def self.isolate_furniture_item(entity_id)
        begin
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model

          entity = model.entities.find { |e| e.entityID == entity_id }
          return { success: false, message: "Item não encontrado" } unless entity

          model.selection.clear
          model.selection.add(entity)
          model.active_view.zoom_selection

          { success: true, message: "Item isolado com sucesso" }
        rescue => e
          { success: false, message: "Erro ao isolar item: #{e.message}" }
        end
      end

      def self.delete_furniture_item(entity_id)
        begin
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model

          entity = model.entities.find { |e| e.entityID == entity_id }
          return { success: false, message: "Item não encontrado" } unless entity

          model.start_operation('Delete Furniture Item', true)
          entity.erase!
          model.commit_operation

          { success: true, message: "Item removido com sucesso" }
        rescue => e
          model.abort_operation if model
          { success: false, message: "Erro ao remover item: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS - Helpers
      # ========================================

      private

      # Normaliza o tipo para corresponder entre diferentes idiomas
      def self.normalize_type(type)
        type_map = {
          'Mobiliário' => 'Furniture',
          'Furniture' => 'Furniture',
          'Eletrodomésticos' => 'Appliances',
          'Appliances' => 'Appliances',
          'Louças e Metais' => 'Fixtures & Fittings',
          'Fixtures & Fittings' => 'Fixtures & Fittings',
          'Fixtures' => 'Fixtures & Fittings',
          'Acessórios' => 'Accessories',
          'Accessories' => 'Accessories',
          'Decoração' => 'Decoration',
          'Decoration' => 'Decoration'
        }
        type_map[type] || type
      end

      # Processa dados brutos de uma categoria e retorna items formatados com totais
      def self.process_category_items(data, category)
        items = []
        total_value = 0.0
        total_quantity = 0

        sorted_data = data.sort_by { |key, info| key[0].to_s.downcase }
        sorted_data.each_with_index do |(key, info), index|
          name, color, brand, type, dimension, environment, obs, link, value = key
          code = generate_code(type, index + 1)
          quantity = info[:quantity]
          entity_ids = info[:ids] || []

          # Converter valor para float
          item_value = value.to_s.gsub(/[^\d,.]/, '').gsub(',', '.').to_f
          line_total = item_value * quantity

          total_value += line_total
          total_quantity += quantity

          items << {
            id: entity_ids.first.to_s, # Usar o primeiro entity_id como identificador
            entity_ids: entity_ids.map(&:to_s),
            code: code,
            name: name.to_s,
            color: color.to_s,
            brand: brand.to_s,
            type: type.to_s,
            dimension: dimension.to_s,
            environment: environment.to_s,
            observations: obs.to_s,
            link: link.to_s,
            value: item_value,
            quantity: quantity,
            lineTotal: line_total
          }
        end

        {
          items: items,
          totalValue: total_value,
          totalQuantity: total_quantity
        }
      end

      # Carrega preferências de exibição de colunas
      def self.load_column_preferences
        begin
          raw = Sketchup.read_default('projeta_plus_furniture', COLUMN_PREFS_KEY, nil)
          if raw && !raw.empty?
            JSON.parse(raw)
          else
            # Valores padrão - todas as colunas visíveis (em português)
            {
              'Código' => true,
              'Nome' => true,
              'Cor' => true,
              'Marca' => true,
              'Dimensão' => true,
              'Ambiente' => true,
              'Observações' => true,
              'Link' => true,
              'Valor' => true,
              'Quantidade' => true
            }
          end
        rescue => e
          puts "Erro ao carregar preferências de colunas: #{e.message}"
          {}
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS - Data Collection
      # ========================================

      def self.collect_data_for_category(model, category)
        data = Hash.new { |h, k| h[k] = { quantity: 0, ids: [] } }
        instances = []
        ProFurnitureAttributes.collect_all_furniture_instances(model.entities, instances)

        puts "[ProFurnitureReports] Total furniture instances found: #{instances.size}"
        
        # Normalizar a categoria esperada para comparação
        normalized_category = normalize_type(category)
        
        prefix = ProFurnitureAttributes::ATTR_PREFIX
        instances.each do |inst|
          type = ProFurnitureAttributes.get_attribute_safe(inst, "#{prefix}type", '').to_s.strip
          normalized_type = normalize_type(type)
          
          # Debug: mostrar os primeiros 3 items para verificar
          if instances.index(inst) < 3
            puts "[DEBUG] Instance #{instances.index(inst) + 1}:"
            puts "  - Type (original): '#{type}'"
            puts "  - Type (normalized): '#{normalized_type}'"
            puts "  - Expected category: '#{category}' (normalized: '#{normalized_category}')"
            puts "  - Match: #{normalized_type == normalized_category}"
            puts "  - Entity ID: #{inst.entityID}"
          end
          
          next if type.empty? || normalized_type != normalized_category

          key = [
            ProFurnitureAttributes.get_attribute_safe(inst, "#{prefix}name", ''),
            ProFurnitureAttributes.get_attribute_safe(inst, "#{prefix}color", ''),
            ProFurnitureAttributes.get_attribute_safe(inst, "#{prefix}brand", ''),
            type,
            ProFurnitureAttributes.get_attribute_safe(inst, "#{prefix}dimension", ''),
            ProFurnitureAttributes.get_attribute_safe(inst, "#{prefix}environment", ''),
            ProFurnitureAttributes.get_attribute_safe(inst, "#{prefix}observations", ''),
            ProFurnitureAttributes.get_attribute_safe(inst, "#{prefix}link", ''),
            ProFurnitureAttributes.get_attribute_safe(inst, "#{prefix}value", '')
          ]

          data[key][:quantity] += 1
          data[key][:ids] << inst.entityID
        end

        puts "[ProFurnitureReports] Items matched for category '#{category}': #{data.size}"
        data
      end

      def self.generate_code(type, index)
        # Normalizar o tipo para garantir consistência
        normalized_type = normalize_type(type)
        
        prefix = case normalized_type
                when 'Furniture' then "FUR"
                when 'Appliances' then "APP"
                when 'Fixtures & Fittings' then "FIX"
                when 'Accessories' then "ACC"
                when 'Decoration' then "DEC"
                else "OTH"
                end
        "#{prefix}#{index.to_s.rjust(3, '0')}"
      end

      # ========================================
      # MÉTODOS PÚBLICOS - Export
      # ========================================

      def self.export_category_csv(category, path)
        begin
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model

          data = collect_data_for_category(model, category)
          return { success: false, message: ProjetaPlus::Localization.t('messages.no_data_to_export') } if data.empty?

          # Garantir que o path tem a extensão .csv
          path = path.end_with?('.csv') ? path : "#{path}.csv"
          
          CSV.open(path, "w") do |csv|
            csv << [
              ProjetaPlus::Localization.t('table_headers.code'),
              ProjetaPlus::Localization.t('table_headers.name'),
              ProjetaPlus::Localization.t('table_headers.color'),
              ProjetaPlus::Localization.t('table_headers.brand'),
              ProjetaPlus::Localization.t('table_headers.type'),
              ProjetaPlus::Localization.t('table_headers.dimension'),
              ProjetaPlus::Localization.t('table_headers.environment'),
              ProjetaPlus::Localization.t('table_headers.observations'),
              ProjetaPlus::Localization.t('table_headers.link'),
              ProjetaPlus::Localization.t('table_headers.value'),
              ProjetaPlus::Localization.t('table_headers.quantity')
            ]

            sorted_data = data.sort_by { |key, info| key[0].to_s.downcase }
            sorted_data.each_with_index do |(key, info), i|
              name, color, brand, type, dimension, environment, obs, link, value = key
              code = generate_code(type, i + 1)
              csv << [code, name, color, brand, type, dimension, environment, obs, link, value, info[:quantity]]
            end
          end

          { success: true, message: "#{ProjetaPlus::Localization.t('messages.export_success')}: #{path}", path: path }
        rescue => e
          { success: false, message: "#{ProjetaPlus::Localization.t('messages.export_failed')}: #{e.message}" }
        end
      end

      def self.export_xlsx(categories, path)
        begin
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model

          # Verificar se está no Windows (WIN32OLE só funciona no Windows)
          unless Sketchup.platform == :platform_win
            return { 
              success: false, 
              message: "Exportação XLSX está disponível apenas no Windows. Use exportação CSV no macOS." 
            }
          end

          unless defined?(WIN32OLE)
            return { success: false, message: ProjetaPlus::Localization.t('messages.excel_not_available') }
          end

          # Garantir que o path tem a extensão .xlsx
          path = path.end_with?('.xlsx') ? path : "#{path}.xlsx"

          excel = WIN32OLE.new('Excel.Application')
          excel.Visible = false
          workbook = excel.Workbooks.Add
          worksheet = workbook.Worksheets(1)
          worksheet.Name = "Furniture_Report"

          # Title
          worksheet.Cells(1, 1).Value = ProjetaPlus::Localization.t('reports.general_report')
          
          # Load column preferences
          all_columns = {
            ProjetaPlus::Localization.t('table_headers.code') => true,
            ProjetaPlus::Localization.t('table_headers.name') => true,
            ProjetaPlus::Localization.t('table_headers.color') => true,
            ProjetaPlus::Localization.t('table_headers.brand') => true,
            ProjetaPlus::Localization.t('table_headers.dimension') => true,
            ProjetaPlus::Localization.t('table_headers.environment') => true,
            ProjetaPlus::Localization.t('table_headers.observations') => false,
            ProjetaPlus::Localization.t('table_headers.link') => false,
            ProjetaPlus::Localization.t('table_headers.quantity') => true
          }

          col_prefs_json = Sketchup.read_default('projeta_plus_furniture', 'column_prefs', JSON.generate(all_columns))
          begin
            col_prefs = JSON.parse(col_prefs_json)
            all_columns.each { |col, default| col_prefs[col] = default unless col_prefs.key?(col) }
          rescue JSON::ParserError
            col_prefs = all_columns.dup
          end

          headers = all_columns.keys.select { |col| col_prefs[col] }
          
          # Format title
          title_range = worksheet.Range(worksheet.Cells(1, 1), worksheet.Cells(1, headers.length))
          title_range.Merge
          title_range.Font.Bold = true
          title_range.Font.Size = 16
          title_range.Font.Name = "Century Gothic"
          title_range.HorizontalAlignment = -4108
          title_range.Interior.Color = 0xF2F2F2
          title_range.Font.Color = 0x333333
          title_range.Borders.LineStyle = 1
          title_range.Borders.Color = 0xD0D0D0
          title_range.RowHeight = 25

          # Headers
          headers.each_with_index { |h, i| worksheet.Cells(2, i + 1).Value = h }
          header_range = worksheet.Range(worksheet.Cells(2, 1), worksheet.Cells(2, headers.length))
          header_range.Font.Bold = true
          header_range.Font.Size = 11
          header_range.Font.Name = "Century Gothic"
          header_range.Interior.Color = 0xE8E8E8
          header_range.Font.Color = 0x333333
          header_range.HorizontalAlignment = -4108
          header_range.Borders.LineStyle = 1
          header_range.Borders.Color = 0xD0D0D0
          header_range.RowHeight = 20

          row = 3

          # Sort categories
          category_order = ProFurnitureAttributes.get_available_types
          sorted_categories = []
          category_order.each { |cat| sorted_categories << cat if categories.include?(cat) }
          categories.each { |cat| sorted_categories << cat unless sorted_categories.include?(cat) }

          sorted_categories.each_with_index do |category, cat_index|
            data = collect_data_for_category(model, category)
            next if data.empty?

            # Category title
            worksheet.Cells(row, 1).Value = category.upcase
            category_range = worksheet.Range(worksheet.Cells(row, 1), worksheet.Cells(row, headers.length))
            category_range.Merge
            category_range.Font.Bold = true
            category_range.Font.Size = 12
            category_range.Font.Name = "Century Gothic"
            category_range.Interior.Color = 0xDCDCDC
            category_range.Font.Color = 0x333333
            category_range.HorizontalAlignment = -4108
            category_range.Borders.LineStyle = 1
            category_range.Borders.Color = 0xD0D0D0
            category_range.RowHeight = 22
            row += 1

            data.each_with_index do |(key, info), i|
              name, color, brand, type, dimension, environment, obs, link, value = key
              next unless info && info[:ids] && !info[:ids].empty?
              
              id = info[:ids].first
              entity = model.entities.find { |e| e.entityID == id }
              prefix = ProFurnitureAttributes::ATTR_PREFIX
              code = if entity && ProFurnitureAttributes.get_attribute_safe(entity, "#{prefix}code")
                       ProFurnitureAttributes.get_attribute_safe(entity, "#{prefix}code")
                     else
                       generate_code(type, i + 1)
                     end

              all_values = {
                ProjetaPlus::Localization.t('table_headers.code') => code,
                ProjetaPlus::Localization.t('table_headers.name') => name,
                ProjetaPlus::Localization.t('table_headers.color') => color,
                ProjetaPlus::Localization.t('table_headers.brand') => brand,
                ProjetaPlus::Localization.t('table_headers.dimension') => dimension,
                ProjetaPlus::Localization.t('table_headers.environment') => environment,
                ProjetaPlus::Localization.t('table_headers.observations') => obs,
                ProjetaPlus::Localization.t('table_headers.link') => link,
                ProjetaPlus::Localization.t('table_headers.value') => value,
                ProjetaPlus::Localization.t('table_headers.quantity') => info[:quantity]
              }

              headers.each_with_index do |header, c|
                worksheet.Cells(row, c + 1).Value = all_values[header]
              end

              # Format row
              data_range = worksheet.Range(worksheet.Cells(row, 1), worksheet.Cells(row, headers.length))
              data_range.Font.Name = "Century Gothic"
              data_range.Font.Size = 10
              data_range.Font.Color = 0x333333
              data_range.Borders.LineStyle = 1
              data_range.Borders.Color = 0xE0E0E0
              data_range.RowHeight = 18

              # Color code cell
              type_color = ProFurnitureAttributes.get_type_color(type)
              if type_color.respond_to?(:red)
                r, g, b = type_color.red, type_color.green, type_color.blue
                excel_color = (b << 16) | (g << 8) | r
              else
                excel_color = 0xC0C0C0
              end

              code_col_index = headers.index(ProjetaPlus::Localization.t('table_headers.code'))
              if code_col_index
                code_cell = worksheet.Cells(row, code_col_index + 1)
                code_cell.Interior.Color = excel_color
                code_cell.Font.Color = 16777215
                code_cell.Font.Bold = true
                code_cell.HorizontalAlignment = -4108
              end

              row += 1
            end

            row += 1 if cat_index < sorted_categories.length - 1 && !data.empty?
          end

          # Final formatting
          worksheet.Columns.AutoFit
          worksheet.Range("A3").Select
          excel.ActiveWindow.FreezePanes = true

          workbook.SaveAs(path, 51)
          workbook.Close(false)
          excel.Quit

          { success: true, message: "#{ProjetaPlus::Localization.t('messages.export_success')}: #{path}", path: path }
        rescue => e
          { success: false, message: "#{ProjetaPlus::Localization.t('messages.export_failed')}: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS - Preferences
      # ========================================

      def self.load_category_preferences(types)
        begin
          raw = Sketchup.read_default('projeta_plus_furniture', CATEGORY_PREFS_KEY, nil)
          if raw && !raw.empty?
            prefs = JSON.parse(raw)
          else
            prefs = {}
          end
        rescue JSON::ParserError, StandardError => e
          puts "ERROR loading preferences (#{e.message}), using defaults"
          prefs = {}
          Sketchup.write_default('projeta_plus_furniture', CATEGORY_PREFS_KEY, '{}')
        end

        prefs = {} unless prefs.is_a?(Hash)
        types.each { |t| prefs[t] ||= { 'show' => true, 'export' => true } }
        prefs
      end

      def self.save_category_preferences(prefs)
        Sketchup.write_default('projeta_plus_furniture', 'category_prefs', JSON.generate(prefs))
      end

    end
  end
end

