# encoding: UTF-8

require 'sketchup.rb'
require 'csv'
require 'json'

module ProjetaPlus
  module Modules
    module ProLightningReports

      SETTINGS_KEY = "lightning_reports_settings"
      COLUMN_PREFS_KEY = 'lightning_column_prefs'
      
      PREFIX_STANDARD = "pro_ilu"
      PREFIX_FURNITURE = "pro_ilu_furn"
      
      MAX_RECURSION_LEVEL = 5

      COLUMN_MAPPING = {
        'legenda' => 'LEGENDA',
        'luminaria' => 'LUMINÁRIA',
        'marca_luminaria' => 'MARCA LUMINÁRIA',
        'lampada' => 'LÂMPADA',
        'marca_lampada' => 'MARCA LÂMPADA',
        'temperatura' => 'TEMPERATURA',
        'irc' => 'IRC',
        'lumens' => 'LUMENS',
        'dimer' => 'DÍMER',
        'ambiente' => 'AMBIENTE',
        'quantidade' => 'QUANTIDADE'
      }

      DEFAULT_COLUMNS = %w[
        legenda luminaria marca_luminaria lampada marca_lampada
        temperatura irc lumens dimer ambiente quantidade
      ]


      # Retorna tipos de iluminação disponíveis
      def self.get_lightning_types
        begin
          types = [
            { id: 'standard', name: 'Padrão', prefix: PREFIX_STANDARD },
            { id: 'furniture', name: 'Marcenaria', prefix: PREFIX_FURNITURE }
          ]
          { success: true, types: types }
        rescue => e
          puts "[ProLightningReports] ERROR in get_lightning_types: #{e.message}"
          { success: false, message: "Erro ao buscar tipos: #{e.message}" }
        end
      end

      def self.get_lightning_data(type = 'standard')
        begin
          puts "[ProLightningReports] Getting data for type: #{type}"
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model

          prefix = type == 'furniture' ? PREFIX_FURNITURE : PREFIX_STANDARD
          components = search_components_recursive(model.entities, prefix, 0)
          
          puts "[ProLightningReports] Found #{components.size} raw components"
          
          if components.empty?
            return {
              success: true,
              type: type,
              data: {
                items: [],
                total: 0,
                summary: { totalItems: 0, uniqueItems: 0 }
              }
            }
          end

          grouped_data = group_and_count_components(components)
          puts "[ProLightningReports] Grouped into #{grouped_data.size} unique items"

          {
            success: true,
            type: type,
            data: {
              items: grouped_data,
              total: grouped_data.sum { |item| item[:quantidade] },
              summary: {
                totalItems: grouped_data.sum { |item| item[:quantidade] },
                uniqueItems: grouped_data.size
              }
            }
          }
        rescue => e
          puts "[ProLightningReports] ERROR in get_lightning_data: #{e.message}"
          puts e.backtrace.join("\n") if e.backtrace
          { success: false, message: "Erro ao buscar dados: #{e.message}" }
        end
      end

      def self.get_column_preferences
        begin
          prefs = load_column_preferences
          { success: true, preferences: prefs }
        rescue => e
          { success: false, message: "Erro ao carregar preferências: #{e.message}" }
        end
      end

      def self.save_column_preferences(preferences)
        begin
          Sketchup.write_default('projeta_plus_lightning', COLUMN_PREFS_KEY, JSON.generate(preferences))
          { success: true, message: "Preferências salvas com sucesso" }
        rescue => e
          { success: false, message: "Erro ao salvar preferências: #{e.message}" }
        end
      end

      def self.export_to_csv(params)
        begin
          columns = params['columns'] || params[:columns] || DEFAULT_COLUMNS
          data = params['data'] || params[:data] || []
          type = params['type'] || params[:type] || 'standard'

          model = Sketchup.active_model
          model_path = model.path

          if model_path.empty?
            return { success: false, message: "O modelo precisa ser salvo antes de exportar" }
          end

          directory = File.dirname(model_path)
          type_name = type == 'furniture' ? 'Iluminacao_Marcenaria' : 'Iluminacao'
          file_path = File.join(directory, "#{type_name}.csv")

          write_csv_file(file_path, columns, data)

          {
            success: true,
            message: "Arquivo CSV exportado com sucesso",
            path: file_path
          }
        rescue => e
          puts "[ProLightningReports] ERROR in export_to_csv: #{e.message}"
          { success: false, message: "Erro ao exportar CSV: #{e.message}" }
        end
      end

      def self.export_to_xlsx(params)
        begin
          # Por enquanto, exporta como CSV
          # TODO: Implementar exportação real para XLSX quando biblioteca estiver disponível
          result = export_to_csv(params)
          
          if result[:success]
            csv_path = result[:path]
            xlsx_path = csv_path.gsub('.csv', '.xlsx')
            
            # Renomear arquivo
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
          puts "[ProLightningReports] ERROR in export_to_xlsx: #{e.message}"
          { success: false, message: "Erro ao exportar XLSX: #{e.message}" }
        end
      end

      private

      def self.search_components_recursive(entities, prefix, level)
        components = []
        return components if level >= MAX_RECURSION_LEVEL

        entities.each do |entity|
          if entity.is_a?(Sketchup::ComponentInstance)
            definition = entity.definition

            attrs = extract_lightning_attributes(definition, prefix)

            if attrs.values.any? { |v| !v.nil? && v.to_s.strip != '' }
              components << attrs
            end

            components.concat(
              search_components_recursive(definition.entities, prefix, level + 1)
            )

          elsif entity.is_a?(Sketchup::Group)
            components.concat(
              search_components_recursive(entity.entities, prefix, level + 1)
            )
          end
        end

        components
      end

      def self.extract_lightning_attributes(definition, prefix)
        {
          pro_ilu: definition.get_attribute("dynamic_attributes", prefix),
          pro_ilu_t1: definition.get_attribute("dynamic_attributes", "#{prefix}_t1"),
          pro_ilu_t2: definition.get_attribute("dynamic_attributes", "#{prefix}_t2"),
          pro_ilu_t3: definition.get_attribute("dynamic_attributes", "#{prefix}_t3"),
          pro_ilu_t4: definition.get_attribute("dynamic_attributes", "#{prefix}_t4"),
          pro_ilu_t5: definition.get_attribute("dynamic_attributes", "#{prefix}_t5"),
          pro_ilu_t6: definition.get_attribute("dynamic_attributes", "#{prefix}_t6"),
          pro_ilu_t7: definition.get_attribute("dynamic_attributes", "#{prefix}_t7"),
          pro_ilu_t8: definition.get_attribute("dynamic_attributes", "#{prefix}_t8"),
          pro_ilu_t9: definition.get_attribute("dynamic_attributes", "#{prefix}_t9")
        }
      end

      def self.group_and_count_components(components)
        grouped = Hash.new(0)
        
        components.each do |comp|
          key = [
            comp[:pro_ilu],
            comp[:pro_ilu_t1],
            comp[:pro_ilu_t2],
            comp[:pro_ilu_t3],
            comp[:pro_ilu_t4],
            comp[:pro_ilu_t5],
            comp[:pro_ilu_t6],
            comp[:pro_ilu_t7],
            comp[:pro_ilu_t8],
            comp[:pro_ilu_t9]
          ]
          grouped[key] += 1
        end

        grouped.map do |key, count|
          {
            legenda: key[0]&.to_s || '',
            luminaria: key[1]&.to_s || '',
            marca_luminaria: key[2]&.to_s || '',
            lampada: key[3]&.to_s || '',
            marca_lampada: key[4]&.to_s || '',
            temperatura: key[5]&.to_s || '',
            irc: key[6]&.to_s || '',
            lumens: key[7]&.to_s || '',
            dimer: key[8]&.to_s || '',
            ambiente: key[9]&.to_s || '',
            quantidade: count
          }
        end
      end

      def self.load_column_preferences
        begin
          json_str = Sketchup.read_default('projeta_plus_lightning', COLUMN_PREFS_KEY)
          return DEFAULT_COLUMNS unless json_str
          
          prefs = JSON.parse(json_str)
          prefs.is_a?(Array) ? prefs : DEFAULT_COLUMNS
        rescue => e
          puts "[ProLightningReports] Error loading preferences: #{e.message}"
          DEFAULT_COLUMNS
        end
      end

      def self.write_csv_file(file_path, columns, data)
        CSV.open(file_path, 'w:UTF-8') do |csv|
          headers = columns.map { |col| COLUMN_MAPPING[col] || col.upcase }
          csv << headers

          data.each do |item|
            row = columns.map do |col|
              value = item[col] || item[col.to_sym] || ''
              value.to_s
            end
            csv << row
          end

          if columns.include?('quantidade')
            total_row = columns.map do |col|
              if col == 'quantidade'
                total = data.sum { |item| (item[col] || item[col.to_sym] || 0).to_i }
                "TOTAL: #{total}"
              elsif col == columns.first
                'TOTAL'
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
