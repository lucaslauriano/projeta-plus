# encoding: UTF-8

require 'json'
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/reports/pro_coatings_reports.rb'

module ProjetaPlus
  module DialogHandlers
    class CoatingsReportsHandler < BaseHandler

      def initialize(dialog)
        super(dialog)
        @log_file = File.join(File.dirname(File.dirname(__FILE__)), 'coatings_reports_log.txt')
        log_to_file("CoatingsReportsHandler Initialized. Log file: #{@log_file}")
      end
      
      def log_to_file(msg)
        File.open(@log_file, 'a') { |f| f.puts "[#{Time.now}] #{msg}" }
      rescue
        # ignore logging errors
      end

      def register_callbacks
        register_coatings_reports_callbacks
      end

      private

      def register_coatings_reports_callbacks

        # LOAD DATA
        @dialog.add_action_callback('loadCoatingsData') do |_context|
          begin
            log_to_file("loadCoatingsData called")
            puts "[CoatingsReportsHandler] loadCoatingsData called"
            
            result = ProjetaPlus::Modules::ProCoatingsReports.load_data
            log_to_file("Load result: #{result[:success]}, Items: #{result[:data]&.size || 0}")
            
            send_json_response("handleLoadCoatingsDataResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[CoatingsReportsHandler] ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "load coatings data")
            send_json_response("handleLoadCoatingsDataResult", error_result)
          end
          nil
        end

        # SAVE DATA
        @dialog.add_action_callback('saveCoatingsData') do |_context, payload|
          begin
            log_to_file("saveCoatingsData called")
            puts "[CoatingsReportsHandler] saveCoatingsData called"
            
            params = JSON.parse(payload)
            log_to_file("Save params: #{params['data']&.size || 0} items")
            
            result = ProjetaPlus::Modules::ProCoatingsReports.save_data(params)
            log_to_file("Save result: #{result[:success]}")
            
            send_json_response("handleSaveCoatingsDataResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[CoatingsReportsHandler] ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "save coatings data")
            send_json_response("handleSaveCoatingsDataResult", error_result)
          end
          nil
        end

        # ADD SELECTED MATERIAL
        @dialog.add_action_callback('addSelectedMaterial') do |_context|
          begin
            log_to_file("addSelectedMaterial called")
            puts "[CoatingsReportsHandler] addSelectedMaterial called"
            
            result = ProjetaPlus::Modules::ProCoatingsReports.add_selected_material
            log_to_file("Add material result: #{result[:success]}")
            if result[:success]
              log_to_file("Material: #{result[:material][:name]}, Area: #{result[:material][:area]}m²")
            end
            
            send_json_response("handleAddSelectedMaterialResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[CoatingsReportsHandler] ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "add selected material")
            send_json_response("handleAddSelectedMaterialResult", error_result)
          end
          nil
        end

        # EXPORT CSV
        @dialog.add_action_callback('exportCoatingsCSV') do |_context, payload|
          begin
            log_to_file("exportCoatingsCSV called")
            puts "[CoatingsReportsHandler] exportCoatingsCSV called"
            
            params = JSON.parse(payload)
            log_to_file("Export params: #{params['data']&.size || 0} items, #{params['columns']&.size || 0} columns")
            
            result = ProjetaPlus::Modules::ProCoatingsReports.export_to_csv(params)
            log_to_file("Export result: #{result[:success]}")
            log_to_file("Export path: #{result[:path]}") if result[:success]
            
            send_json_response("handleExportCoatingsCSVResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[CoatingsReportsHandler] ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "export CSV")
            send_json_response("handleExportCoatingsCSVResult", error_result)
          end
          nil
        end

        # EXPORT XLSX
        @dialog.add_action_callback('exportCoatingsXLSX') do |_context, payload|
          begin
            log_to_file("exportCoatingsXLSX called")
            puts "[CoatingsReportsHandler] exportCoatingsXLSX called"
            
            params = JSON.parse(payload)
            log_to_file("Export params: #{params['data']&.size || 0} items, #{params['columns']&.size || 0} columns")
            
            result = ProjetaPlus::Modules::ProCoatingsReports.export_to_xlsx(params)
            log_to_file("Export result: #{result[:success]}")
            log_to_file("Export path: #{result[:path]}") if result[:success]
            
            send_json_response("handleExportCoatingsXLSXResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[CoatingsReportsHandler] ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "export XLSX")
            send_json_response("handleExportCoatingsXLSXResult", error_result)
          end
          nil
        end

      end

    end
  end
end
