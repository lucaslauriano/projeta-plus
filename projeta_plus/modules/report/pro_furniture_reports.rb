# encoding: UTF-8

require 'sketchup.rb'
require 'csv'
require_relative '../furniture/pro_furniture_attributes.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProFurnitureReports

      include ProFurnitureAttributes

      # ========== Data Collection ==========

      def self.collect_data_for_category(model, category)
        data = Hash.new { |h, k| h[k] = { quantity: 0, ids: [] } }
        instances = []
        ProFurnitureAttributes.collect_all_furniture_instances(model.entities, instances)

        instances.each do |inst|
          type = ProFurnitureAttributes.get_attribute_safe(inst, 'type', '').to_s.strip
          next if type.empty? || type != category

          key = [
            ProFurnitureAttributes.get_attribute_safe(inst, 'name', ''),
            ProFurnitureAttributes.get_attribute_safe(inst, 'color', ''),
            ProFurnitureAttributes.get_attribute_safe(inst, 'brand', ''),
            type,
            ProFurnitureAttributes.get_attribute_safe(inst, 'dimension', ''),
            ProFurnitureAttributes.get_attribute_safe(inst, 'environment', ''),
            ProFurnitureAttributes.get_attribute_safe(inst, 'observations', ''),
            ProFurnitureAttributes.get_attribute_safe(inst, 'link', ''),
            ProFurnitureAttributes.get_attribute_safe(inst, 'value', '')
          ]

          data[key][:quantity] += 1
          data[key][:ids] << inst.entityID
        end

        data
      end

      # ========== HTML Table Generation ==========

      def self.generate_category_table_html(model, category, selected_id: nil, selected_key: nil)
        begin
          instances_by_type = ProFurnitureAttributes.get_cached_instances(model)
          instances = instances_by_type[category] || []

          data = Hash.new { |h, k| h[k] = { quantity: 0, ids: [] } }

          instances.each do |inst|
            next unless inst && inst.valid?

            begin
              key = [
                ProFurnitureAttributes.get_attribute_safe(inst, "name", ""),
                ProFurnitureAttributes.get_attribute_safe(inst, "color", ""),
                ProFurnitureAttributes.get_attribute_safe(inst, "brand", ""),
                category,
                ProFurnitureAttributes.get_attribute_safe(inst, "dimension", ""),
                ProFurnitureAttributes.get_attribute_safe(inst, "environment", ""),
                ProFurnitureAttributes.get_attribute_safe(inst, "observations", ""),
                ProFurnitureAttributes.get_attribute_safe(inst, "link", ""),
                ProFurnitureAttributes.get_attribute_safe(inst, "value", "")
              ]

              data[key][:quantity] += 1
              data[key][:ids] << inst.entityID
            rescue => e
              puts "ERROR processing instance: #{e.message}"
              next
            end
          end

          return "<tr><td colspan='12' style='color:red;'>#{ProjetaPlus::Localization.t('messages.no_data_found')}</td></tr>" if data.empty?

          index = 1
          sorted_data = data.sort_by { |key, info| key[0].to_s.downcase }
          
          sorted_data.map do |key, info|
            name, color, brand, type, dimension, environment, obs, link, value = key
            id = (selected_key && selected_id && key == selected_key) ? selected_id : info[:ids].first
            highlight = (selected_key && key == selected_key)

            entity = Sketchup.active_model.entities.find { |e| e.entityID == id }
            code = if entity && ProFurnitureAttributes.get_attribute_safe(entity, "code")
                     ProFurnitureAttributes.get_attribute_safe(entity, "code")
                   else
                     generate_code(type, index)
                   end

            type_color = ProFurnitureAttributes.get_type_color(type)
            color_hex = ProFurnitureAttributes.color_to_hex(type_color)

            value_num = value.to_s.gsub(/[^0-9.,]/, '').gsub(',', '.').to_f
            total_item = value_num * info[:quantity]

            html = "<tr id='row-#{id}'#{highlight ? " style='background-color:#fff3cd'" : ''}>
              <td class='code-cell' style='background-color:#{color_hex}; color:white;'>#{code}</td>
              <td>#{name}</td>
              <td>#{color}</td>
              <td>#{brand}</td>
              <td>#{type}</td>
              <td>#{dimension}</td>
              <td>#{environment}</td>
              <td>#{format_clickable_link(link)}</td>
              <td>#{obs}</td>
              <td>#{value}</td>
              <td>#{info[:quantity]}</td>
              <td style='font-weight:bold;'>#{sprintf('%.2f', total_item)}</td>
              <td><button onclick='isolateItem(#{id})'>#{ProjetaPlus::Localization.t('buttons.isolate')}</button></td>
              <td><button onclick='deleteItem(#{id})'>#{ProjetaPlus::Localization.t('buttons.delete')}</button></td>
            </tr>"
            index += 1
            html
          end.join
        rescue => e
          puts "ERROR in generate_category_table_html: #{e.message}"
          puts e.backtrace.first(3) if e.backtrace
          "<tr><td colspan='12' style='color:red;'>#{ProjetaPlus::Localization.t('messages.error_loading_data')}: #{e.message}</td></tr>"
        end
      end

      # ========== Helper Methods ==========

      def self.format_clickable_link(link)
        return "" if link.nil? || link.to_s.strip.empty?

        link_str = link.to_s.strip

        if link_str.match(/^https?:\/\//i)
          "<a href='#{link_str}' target='_blank' style='color: #007bff; text-decoration: underline;'>#{link_str}</a>"
        elsif link_str.match(/^www\./i) || link_str.include?('.')
          full_link = "http://#{link_str}"
          "<a href='#{full_link}' target='_blank' style='color: #007bff; text-decoration: underline;'>#{link_str}</a>"
        else
          link_str
        end
      end

      def self.generate_code(type, index)
        prefix = case type
                when ProjetaPlus::Localization.t('furniture_types.furniture') then "FUR"
                when ProjetaPlus::Localization.t('furniture_types.appliances') then "APP"
                when ProjetaPlus::Localization.t('furniture_types.fixtures') then "FIX"
                when ProjetaPlus::Localization.t('furniture_types.accessories') then "ACC"
                when ProjetaPlus::Localization.t('furniture_types.decoration') then "DEC"
                else "OTH"
                end
        "#{prefix}#{index.to_s.rjust(3, '0')}"
      end

      # ========== CSV Export ==========

      def self.export_category_to_csv(model, category)
        data = collect_data_for_category(model, category)

        return { success: false, message: ProjetaPlus::Localization.t('messages.no_data_to_export') } if data.empty?

        file_path = File.join(File.dirname(model.path), "#{category}.csv")
        
        begin
          CSV.open(file_path, "w") do |csv|
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

          { success: true, message: "#{ProjetaPlus::Localization.t('messages.export_success')}: #{file_path}" }
        rescue => e
          { success: false, message: "#{ProjetaPlus::Localization.t('messages.export_failed')}: #{e.message}" }
        end
      end

      # ========== XLSX Export ==========

      def self.export_to_xlsx(model, categories, path)
        return { success: false, message: ProjetaPlus::Localization.t('messages.excel_not_available') } unless defined?(WIN32OLE)

        begin
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
              code = if entity && ProFurnitureAttributes.get_attribute_safe(entity, "code")
                       ProFurnitureAttributes.get_attribute_safe(entity, "code")
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

          { success: true, message: "#{ProjetaPlus::Localization.t('messages.export_success')}: #{path}" }
        rescue => e
          { success: false, message: "#{ProjetaPlus::Localization.t('messages.export_failed')}: #{e.message}" }
        end
      end

      # ========== Preferences ==========

      def self.load_category_preferences(types)
        begin
          raw = Sketchup.read_default('projeta_plus_furniture', 'category_prefs', '{}')
          raw = '{}' if raw.nil? || raw.empty?
          prefs = JSON.parse(raw)
        rescue JSON::ParserError, StandardError => e
          puts "ERROR loading preferences (#{e.message}), using defaults"
          prefs = {}
          Sketchup.write_default('projeta_plus_furniture', 'category_prefs', '{}')
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

