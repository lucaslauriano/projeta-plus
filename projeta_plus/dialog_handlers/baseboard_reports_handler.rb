# encoding: UTF-8

require 'json'
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/reports/pro_baseboard_reports.rb'

module ProjetaPlus
  module DialogHandlers
    class BaseboardReportsHandler < BaseHandler

      def initialize(dialog)
        super(dialog)
        @log_file = File.join(File.dirname(File.dirname(__FILE__)), 'baseboard_reports_log.txt')
        log_to_file("BaseboardReportsHandler Initialized. Log file: #{@log_file}")
      end
      
      def log_to_file(msg)
        File.open(@log_file, 'a') { |f| f.puts "[#{Time.now}] #{msg}" }
      rescue
        # ignore logging errors
      end

      def register_callbacks
        register_baseboard_reports_callbacks
      end

      private

      def register_baseboard_reports_callbacks

        # GET BASEBOARD DATA
        @dialog.add_action_callback('getBaseboardData') do |_context|
          begin
            log_to_file("getBaseboardData called")
            puts "[BaseboardReportsHandler] getBaseboardData called"
            
            result = ProjetaPlus::Modules::ProBaseboardReports.get_baseboard_data
            log_to_file("Module returned. Success: #{result[:success]}")
            log_to_file("Items count: #{result.dig(:data, :items)&.size || 0}")
            
            send_json_response("handleGetBaseboardDataResult", result)
          rescue => e
            log_to_file("CRITICAL ERROR: #{e.message}")
            log_to_file(e.backtrace.join("\n")) if e.backtrace
            
            puts "[BaseboardReportsHandler] CRITICAL ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "get baseboard data")
            send_json_response("handleGetBaseboardDataResult", error_result)
          end
          nil
        end

        # EXPORT CSV
        @dialog.add_action_callback('exportBaseboardCSV') do |_context, payload|
          begin
            log_to_file("exportBaseboardCSV called")
            puts "[BaseboardReportsHandler] exportBaseboardCSV called"
            
            params = JSON.parse(payload)
            log_to_file("Export params: #{params.keys.inspect}")
            
            result = ProjetaPlus::Modules::ProBaseboardReports.export_to_csv(params)
            log_to_file("Export result: #{result[:success]}")
            log_to_file("Export path: #{result[:path]}") if result[:success]
            
            send_json_response("handleExportBaseboardCSVResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[BaseboardReportsHandler] ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "export CSV")
            send_json_response("handleExportBaseboardCSVResult", error_result)
          end
          nil
        end

        # EXPORT XLSX
        @dialog.add_action_callback('exportBaseboardXLSX') do |_context, payload|
          begin
            log_to_file("exportBaseboardXLSX called")
            puts "[BaseboardReportsHandler] exportBaseboardXLSX called"
            
            params = JSON.parse(payload)
            log_to_file("Export params: #{params.keys.inspect}")
            
            result = ProjetaPlus::Modules::ProBaseboardReports.export_to_xlsx(params)
            log_to_file("Export result: #{result[:success]}")
            log_to_file("Export path: #{result[:path]}") if result[:success]
            
            send_json_response("handleExportBaseboardXLSXResult", result)
          rescue => e
            log_to_file("ERROR: #{e.message}")
            puts "[BaseboardReportsHandler] ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            error_result = handle_error(e, "export XLSX")
            send_json_response("handleExportBaseboardXLSXResult", error_result)
          end
          nil
        end

      end

    end
  end
end
