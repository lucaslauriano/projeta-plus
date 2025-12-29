# encoding: UTF-8

require 'sketchup.rb'
require 'csv'
require 'json'

module ProjetaPlus
  module Modules
    module ProElectricalReports

      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================

      SETTINGS_KEY = "electrical_reports_settings"
      ATTR_PREFIX = "pro_rela_"

      # Tipos de relatório disponíveis
      REPORT_TYPES = {
        modules: {
          id: 'eletrica_modulos',
          filter: 'ELÉTRICA MODULOS',
          title: 'Montagem de Suportes + Módulos'
        },
        points: {
          id: 'eletrica',
          filter: 'ELÉTRICA',
          title: 'Pontos Elétricos'
        },
        hydro: {
          id: 'hidro',
          filter: 'HIDRO',
          title: 'Pontos Hidráulicos'
        },
        lightning: {
          id: 'iluminacao',
          filter: 'ILUMINAÇÃO',
          title: 'Pontos Iluminação'
        },
        climate: {
          id: 'climatizacao',
          filter: 'CLIMA',
          title: 'Pontos Climatização'
        },
        parts: {
          id: 'pecas',
          filter: 'ELÉTRICA MODULOS',
          title: 'Contagem de Peças'
        }
      }

      # ========================================
      # MÉTODOS PÚBLICOS - Get Data
      # ========================================

      def self.get_report_types
        begin
          types = REPORT_TYPES.values.map { |type| {
            id: type[:id],
            title: type[:title]
          }}
          { success: true, types: types }
        rescue => e
          { success: false, message: "Erro ao buscar tipos: #{e.message}" }
        end
      end

      def self.get_report_data(report_type)
        begin
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model

          # Encontra a configuração pelo ID (que vem do frontend)
          type_entry = REPORT_TYPES.find { |k, v| v[:id] == report_type }
          
          unless type_entry
            return { success: false, message: "Tipo de relatório inválido: #{report_type}" }
          end

          report_key = type_entry[0]
          type_config = type_entry[1]

          instances = collect_instances(model.active_entities, 1, 5)
          
          data = case report_key
                 when :modules
                   process_modules_data(instances)
                 when :parts
                   process_parts_data(instances)
                 when :points
                   process_points_data(instances, type_config[:filter])
                 when :hydro
                   process_hydro_data(instances)
                 when :lightning
                   process_lightning_data(instances)
                 when :climate
                   process_climate_data(instances)
                 else
                   []
                 end

          {
            success: true,
            report_type: report_type,
            data: data,
            total: data.is_a?(Array) ? data.reduce(0) { |sum, item| sum + (item[:quantidade] || item[:quantity] || 0) } : 0,
            count: data.length
          }
        rescue => e
          puts "ERROR in get_report_data: #{e.message}"
          puts e.backtrace if e.backtrace
          { success: false, message: "Erro ao buscar dados: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS DE EXPORTAÇÃO
      # ========================================

      def self.export_csv(report_type, file_path)
        begin
          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model

          unless file_path && !file_path.empty?
            return { success: false, message: "Caminho do arquivo não fornecido" }
          end

          result = get_report_data(report_type)
          return result unless result[:success]

          data = result[:data]
          return { success: false, message: "Nenhum dado para exportar" } if data.empty?

          # Garantir extensão .csv
          file_path = file_path.end_with?('.csv') ? file_path : "#{file_path}.csv"

          write_csv(file_path, data, report_type)

          { success: true, message: "Exportado com sucesso", path: file_path }
        rescue => e
          { success: false, message: "Erro ao exportar CSV: #{e.message}" }
        end
      end

      def self.export_xlsx(report_type, file_path)
        begin
          # Verificar se está no Windows (WIN32OLE só funciona no Windows)
          unless Sketchup.platform == :platform_win
            return { 
              success: false, 
              message: "Exportação XLSX está disponível apenas no Windows. Use exportação CSV no macOS." 
            }
          end

          unless file_path && !file_path.empty?
            return { success: false, message: "Caminho do arquivo não fornecido" }
          end

          # Por enquanto exporta como CSV mesmo no Windows
          file_path_csv = file_path.gsub('.xlsx', '.csv')
          result = export_csv(report_type, file_path_csv)
          if result[:success]
            result[:message] = "Exportado como CSV (XLSX requer biblioteca adicional)"
            result[:path] = file_path_csv
          end
          result
        rescue => e
          { success: false, message: "Erro ao exportar: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS - Coleta de Dados
      # ========================================

      private

      def self.collect_instances(entities, level = 1, limit = 5, result = [])
        return result if level > limit

        entities.each do |entity|
          if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
            result << entity
            collect_instances(entity.definition.entities, level + 1, limit, result)
          end
        end

        result
      end

      def self.get_attribute(entity, key, default = "Desconhecido")
        return default unless entity.definition.attribute_dictionaries
        
        entity.definition.attribute_dictionaries.each do |dict|
          if dict.keys.include?("#{ATTR_PREFIX}eletrica")
            val = dict[key]
            # Force string encoding if it is a string
            if val.is_a?(String)
                begin
                    val = val.dup.force_encoding("UTF-8")
                rescue
                    val = val.to_s
                end
            end
            return val || default
          end
        end
        
        default
      end

      def self.should_count?(entity)
        situacao = get_attribute(entity, "#{ATTR_PREFIX}situacao", "")
        contar = get_attribute(entity, "#{ATTR_PREFIX}contar", "")
        
        situacao != "4" && contar.upcase != "NÃO"
      end

      def self.convert_height(altura_raw)
        return "" unless altura_raw
        "#{(altura_raw.to_f * 2.54).round(2)} cm"
      end

      # ========================================
      # MÉTODOS PRIVADOS - Processamento de Dados
      # ========================================

      def self.process_modules_data(instances)
        data = []
        
        instances.each do |entity|
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
          next unless entity.definition.attribute_dictionaries
          next unless should_count?(entity)

          tipo = get_attribute(entity, "#{ATTR_PREFIX}tipo", "")
          next unless tipo.upcase == "ELÉTRICA MODULOS"

          suporte = get_attribute(entity, "#{ATTR_PREFIX}suporte", "")
          next if suporte.strip.upcase == "SAÍDA DE FIO"

          modulo = get_attribute(entity, "#{ATTR_PREFIX}modulo", "")
          modulo_partes = modulo.split("-").map(&:strip)
          next if modulo_partes.empty? || modulo_partes[0].strip.casecmp("desconhecido").zero?

          altura_raw = get_attribute(entity, "a003_altura", nil)
          
          data << {
            ambiente: get_attribute(entity, "pro_ambiente", ""),
            uso: get_attribute(entity, "#{ATTR_PREFIX}uso", ""),
            suporte: suporte,
            altura: convert_height(altura_raw),
            modulo_1: modulo_partes[0] || "",
            modulo_2: modulo_partes[1] || "",
            modulo_3: modulo_partes[2] || "",
            modulo_4: modulo_partes[3] || "",
            modulo_5: modulo_partes[4] || "",
            modulo_6: modulo_partes[5] || ""
          }
        end

        group_and_count(data, [:ambiente, :uso, :suporte, :altura, :modulo_1, :modulo_2, :modulo_3, :modulo_4, :modulo_5, :modulo_6])
      end

      def self.process_parts_data(instances)
        dados_modulos = []
        
        instances.each do |entity|
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
          next unless entity.definition.attribute_dictionaries
          next unless should_count?(entity)

          tipo = get_attribute(entity, "#{ATTR_PREFIX}tipo", "")
          next unless tipo.upcase == "ELÉTRICA MODULOS"

          suporte = get_attribute(entity, "#{ATTR_PREFIX}suporte", "")
          next if suporte.strip.upcase == "SAÍDA DE FIO"

          modulo = get_attribute(entity, "#{ATTR_PREFIX}modulo", "")
          modulo_partes = modulo.split("-").map(&:strip)
          next if modulo_partes.empty? || modulo_partes[0].strip.casecmp("desconhecido").zero?

          dados_modulos << {
            suporte: suporte,
            modulo_partes: modulo_partes
          }
        end

        pecas = Hash.new(0)
        
        dados_modulos.each do |item|
          item[:modulo_partes].each do |modulo|
            next if modulo.nil? || modulo.strip.empty?
            pecas[modulo.strip] += 1
          end
          
          suporte = item[:suporte].strip
          unless suporte.empty? || suporte.upcase == "SAÍDA DE FIO"
            pecas["SUPORTE: #{suporte}"] += 1
          end
        end

        resultado = pecas.map { |peca, qtd| { peca: peca, quantidade: qtd } }
        resultado.sort_by { |item| item[:peca].upcase }
      end

      def self.process_points_data(instances, filter_type)
        data = []
        
        instances.each do |entity|
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
          next unless entity.definition.attribute_dictionaries
          next unless should_count?(entity)

          tipo = get_attribute(entity, "#{ATTR_PREFIX}tipo", "")
          next unless tipo.upcase == filter_type

          altura_raw = get_attribute(entity, "a003_altura", nil)
          
          data << {
            ambiente: get_attribute(entity, "pro_ambiente", ""),
            uso: get_attribute(entity, "#{ATTR_PREFIX}uso", ""),
            suporte: get_attribute(entity, "#{ATTR_PREFIX}suporte", ""),
            altura: convert_height(altura_raw)
          }
        end

        group_and_count(data, [:ambiente, :uso, :suporte, :altura])
      end

      def self.process_hydro_data(instances)
        data = []
        
        instances.each do |entity|
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
          next unless entity.definition.attribute_dictionaries
          next unless should_count?(entity)

          tipo = get_attribute(entity, "#{ATTR_PREFIX}tipo", "")
          next unless tipo.upcase == "HIDRO"

          modulo = get_attribute(entity, "#{ATTR_PREFIX}modulo", "")
          next unless modulo.strip.casecmp("desconhecido").zero?

          altura_raw = get_attribute(entity, "a003_altura", nil)
          
          data << {
            ambiente: get_attribute(entity, "pro_ambiente", ""),
            uso: get_attribute(entity, "#{ATTR_PREFIX}uso", ""),
            suporte: get_attribute(entity, "#{ATTR_PREFIX}suporte", ""),
            altura: convert_height(altura_raw)
          }
        end

        group_and_count(data, [:ambiente, :uso, :suporte, :altura])
      end

      def self.process_lightning_data(instances)
        data = []
        
        instances.each do |entity|
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
          next unless entity.definition.attribute_dictionaries
          next unless should_count?(entity)

          tipo = get_attribute(entity, "#{ATTR_PREFIX}tipo", "")
          next unless tipo.upcase == "ILUMINAÇÃO"

          modulo = get_attribute(entity, "#{ATTR_PREFIX}modulo", "")
          next unless modulo.strip.casecmp("desconhecido").zero?

          altura_raw = get_attribute(entity, "a003_altura", nil)
          
          data << {
            ambiente: get_attribute(entity, "pro_ambiente", ""),
            uso: get_attribute(entity, "#{ATTR_PREFIX}uso", ""),
            suporte: get_attribute(entity, "#{ATTR_PREFIX}suporte", ""),
            altura: convert_height(altura_raw)
          }
        end

        group_and_count(data, [:ambiente, :uso, :suporte, :altura])
      end

      def self.process_climate_data(instances)
        data = []
        
        instances.each do |entity|
          next unless entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
          next unless entity.definition.attribute_dictionaries
          next unless should_count?(entity)

          tipo = get_attribute(entity, "#{ATTR_PREFIX}tipo", "")
          next unless tipo.upcase == "CLIMA"

          data << {
            ambiente: get_attribute(entity, "pro_ambiente", ""),
            uso: get_attribute(entity, "#{ATTR_PREFIX}uso", ""),
            modelo: get_attribute(entity, "#{ATTR_PREFIX}modelo", ""),
            suporte: get_attribute(entity, "#{ATTR_PREFIX}suporte", "")
          }
        end

        group_and_count(data, [:ambiente, :uso, :modelo, :suporte])
      end

      def self.group_and_count(data, keys)
        agrupado = Hash.new(0)
        
        data.each do |item|
          key = keys.map { |k| item[k] }.join("|||")
          agrupado[key] += 1
        end

        agrupado.map do |key, count|
          valores = key.split("|||", -1)
          resultado = {}
          keys.each_with_index { |k, i| resultado[k] = valores[i] }
          resultado[:quantidade] = count
          resultado
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS - Exportação
      # ========================================

      def self.write_csv(file_path, data, report_type)
        type_config = REPORT_TYPES[report_type.to_sym]
        
        CSV.open(file_path, 'w:UTF-8') do |csv|
          # Cabeçalho
          if data.first
            headers = data.first.keys.map { |k| k.to_s.upcase }
            csv << headers

            # Dados
            data.each do |item|
              row = item.values
              csv << row
            end
          end
        end
      end

    end
  end
end
