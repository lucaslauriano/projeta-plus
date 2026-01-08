# encoding: UTF-8

require 'json'
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/reports/pro_lightning_reports.rb'

module ProjetaPlus
  module DialogHandlers
    class LightningReportsHandler < BaseHandler

      def initialize(dialog)
        super(dialog)
        @log_file = File.join(File.dirname(File.dirname(__FILE__)), 'lightning_reports_log.txt')
        log_to_file("LightningReportsHandler Initialized. Log file: #{@log_file}")
      end
      
      def log_to_file(msg)
        File.open(@log_file, 'a') { |f| f.puts "[#{Time.now}] #{msg}" }
      rescue
        # ignore logging errors
      end

      def register_callbacks
        register_lightning_reports_callbacks
      end

      private

      def register_lightning_reports_callbacks

        # GET LIGHTNING TYPES
        @dialog.add_action_callback('getLightningTypes') do |_context|
          begin
            log_to_file("getLightningTypes called")
            puts "[LightningReportsHandler] getLightningTypes called"
            
            result = ProjetaPlus::Modules::ProLightningReports.get_lightning_types
            log_to_file("Result: #{result.inspect}")
            
            send_json_response("handleGetLightningTypesResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[LightningReportsHandler] ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "get lightning types")
            send_json_response("handleGetLightningTypesResult", error_result)
          end
          nil
        end

        # GET LIGHTNING DATA
        @dialog.add_action_callback('getLightningData') do |_context, payload|
          begin
            log_to_file("getLightningData called with payload: #{payload.inspect}")
            puts "[LightningReportsHandler] getLightningData called"
            
            params = JSON.parse(payload)
            type = params['type'] || 'standard'
            log_to_file("Type: #{type}")
            
            result = ProjetaPlus::Modules::ProLightningReports.get_lightning_data(type)
            log_to_file("Module returned. Success: #{result[:success]}")
            log_to_file("Items count: #{result.dig(:data, :items)&.size || 0}")
            
            send_json_response("handleGetLightningDataResult", result)
          rescue => e
            log_to_file("CRITICAL ERROR: #{e.message}")
            log_to_file(e.backtrace.join("\n")) if e.backtrace
            
            puts "[LightningReportsHandler] CRITICAL ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "get lightning data")
            send_json_response("handleGetLightningDataResult", error_result)
          end
          nil
        end

        # GET COLUMN PREFERENCES
        @dialog.add_action_callback('getLightningColumnPreferences') do |_context|
          begin
            log_to_file("getLightningColumnPreferences called")
            puts "[LightningReportsHandler] getLightningColumnPreferences called"
            
            result = ProjetaPlus::Modules::ProLightningReports.get_column_preferences
            log_to_file("Preferences loaded: #{result[:success]}")
            
            send_json_response("handleGetLightningColumnPreferencesResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[LightningReportsHandler] ERROR: #{e.message}"
            
            error_result = handle_error(e, "get column preferences")
            send_json_response("handleGetLightningColumnPreferencesResult", error_result)
          end
          nil
        end

        # SAVE COLUMN PREFERENCES
        @dialog.add_action_callback('saveLightningColumnPreferences') do |_context, payload|
          begin
            log_to_file("saveLightningColumnPreferences called")
            puts "[LightningReportsHandler] saveLightningColumnPreferences called"
            
            params = JSON.parse(payload)
            preferences = params['preferences']
            log_to_file("Preferences to save: #{preferences.inspect}")
            
            result = ProjetaPlus::Modules::ProLightningReports.save_column_preferences(preferences)
            log_to_file("Save result: #{result[:success]}")
            
            send_json_response("handleSaveLightningColumnPreferencesResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[LightningReportsHandler] ERROR: #{e.message}"
            
            error_result = handle_error(e, "save column preferences")
            send_json_response("handleSaveLightningColumnPreferencesResult", error_result)
          end
          nil
        end

        # EXPORT CSV
        @dialog.add_action_callback('exportLightningCSV') do |_context, payload|
          begin
            log_to_file("exportLightningCSV called")
            puts "[LightningReportsHandler] exportLightningCSV called"
            
            params = JSON.parse(payload)
            log_to_file("Export params: #{params.keys.inspect}")
            
            result = ProjetaPlus::Modules::ProLightningReports.export_to_csv(params)
            log_to_file("Export result: #{result[:success]}")
            log_to_file("Export path: #{result[:path]}") if result[:success]
            
            send_json_response("handleExportLightningCSVResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[LightningReportsHandler] ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "export CSV")
            send_json_response("handleExportLightningCSVResult", error_result)
          end
          nil
        end

        # EXPORT XLSX
        @dialog.add_action_callback('exportLightningXLSX') do |_context, payload|
          begin
            log_to_file("exportLightningXLSX called")
            puts "[LightningReportsHandler] exportLightningXLSX called"
            
            params = JSON.parse(payload)
            log_to_file("Export params: #{params.keys.inspect}")
            
            result = ProjetaPlus::Modules::ProLightningReports.export_to_xlsx(params)
            log_to_file("Export result: #{result[:success]}")
            log_to_file("Export path: #{result[:path]}") if result[:success]
            
            send_json_response("handleExportLightningXLSXResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[LightningReportsHandler] ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "export XLSX")
            send_json_response("handleExportLightningXLSXResult", error_result)
          end
          nil
        end

      end

    end
  end
end
