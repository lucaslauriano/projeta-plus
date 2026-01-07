# encoding: UTF-8

require 'json'
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/reports/pro_electrical_reports.rb'

module ProjetaPlus
  module DialogHandlers
    class ElectricalReportsHandler < BaseHandler

      def initialize(dialog)
        super(dialog)
        @log_file = File.join(File.dirname(File.dirname(__FILE__)), 'debug_log.txt')
        log_to_file("ElectricalReportsHandler Initialized. Log file: #{@log_file}")
      end
      
      def log_to_file(msg)
        File.open(@log_file, 'a') { |f| f.puts "[#{Time.now}] #{msg}" }
      rescue
        # ignore logging errors
      end

      def register_callbacks
        register_electrical_reports_callbacks
      end

      private

      def register_electrical_reports_callbacks

        # PICK SAVE FILE PATH (específico para electrical reports)
        @dialog.add_action_callback('pickSaveFilePathElectrical') do |_context, payload|
          begin
            params = JSON.parse(payload)
            default_name = params['defaultName'] || 'export'
            file_type = params['fileType'] || 'csv'
            
            extension = file_type == 'xlsx' ? '.xlsx' : '.csv'
            filter = file_type == 'xlsx' ? 'Excel Files|*.xlsx||' : 'CSV Files|*.csv||'
            
            path = ::UI.savepanel("Salvar arquivo #{file_type.upcase}", nil, "#{default_name}#{extension}", filter)
            
            if path
              result = { success: true, path: path }
            else
              result = { success: false, message: 'Salvar cancelado pelo usuário' }
            end
            
            @dialog.execute_script("window.handlePickSaveFilePathElectricalResult(#{result.to_json})")
          rescue => e
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handlePickSaveFilePathElectricalResult(#{error_result.to_json})")
          end
          nil
        end

        # GET REPORT TYPES
        @dialog.add_action_callback('getElectricalReportTypes') do |_context|
          begin
            puts "[ElectricalReportsHandler] getElectricalReportTypes called"
            result = ProjetaPlus::Modules::ProElectricalReports.get_report_types
            puts "[ElectricalReportsHandler] Result: #{result.inspect}"
            @dialog.execute_script("window.handleGetElectricalReportTypesResult(#{result.to_json})")
          rescue => e
            puts "[ElectricalReportsHandler] ERROR: #{e.message}"
            puts e.backtrace if e.backtrace
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleGetElectricalReportTypesResult(#{error_result.to_json})")
          end
          nil
        end

        # GET REPORT DATA
        @dialog.add_action_callback('getElectricalReportData') do |_context, payload|
          begin
            log_to_file("getElectricalReportData called")
            puts "[ElectricalReportsHandler] getElectricalReportData called with: #{payload.inspect}"
            
            params = JSON.parse(payload)
            report_type = params['reportType']
            log_to_file("Report Type: #{report_type}")
            
            # Call module
            log_to_file("Calling ProElectricalReports.get_report_data...")
            result = ProjetaPlus::Modules::ProElectricalReports.get_report_data(report_type)
            log_to_file("Module returned. Success: #{result[:success]}")
            
            # Ensure result is valid JSON before sending
            log_to_file("Serializing to JSON...")
            json_response = result.to_json
            log_to_file("JSON Size: #{json_response.length} chars")
            
            log_to_file("Executing JS callback...")
            @dialog.execute_script("window.handleGetElectricalReportDataResult(#{json_response})")
            log_to_file("JS callback executed.")
            
          rescue => e
            log_to_file("CRITICAL ERROR: #{e.message}")
            log_to_file(e.backtrace.join("\n")) if e.backtrace
            
            puts "[ElectricalReportsHandler] CRITICAL ERROR: #{e.message}"
            puts e.backtrace.join("\n") if e.backtrace
            
            # Retrieve error safely
            error_msg = e.message.gsub('"', "'")
            error_result = { success: false, message: "Erro crítico no Ruby: #{error_msg}" }
            
            # Attempt to send error to frontend
            begin
                @dialog.execute_script("window.handleGetElectricalReportDataResult(#{error_result.to_json})")
            rescue => send_err
                puts "[ElectricalReportsHandler] FAILED TO SEND ERROR TO FRONTEND: #{send_err.message}"
            end
          end
          nil
        end

        # EXPORT CSV
        @dialog.add_action_callback('exportElectricalCSV') do |_context, payload|
          begin
            puts "[ElectricalReportsHandler] exportElectricalCSV called"
            params = JSON.parse(payload)
            
            unless params['path']
              error_result = { success: false, message: 'Caminho do arquivo não fornecido' }
              @dialog.execute_script("window.handleExportElectricalCSVResult(#{error_result.to_json})")
              return nil
            end
            
            report_type = params['reportType']
            file_path = params['path']
            
            result = ProjetaPlus::Modules::ProElectricalReports.export_csv(report_type, file_path)
            puts "[ElectricalReportsHandler] Export result: #{result[:success]}"
            
            @dialog.execute_script("window.handleExportElectricalCSVResult(#{result.to_json})")
          rescue => e
            puts "[ElectricalReportsHandler] ERROR: #{e.message}"
            puts e.backtrace if e.backtrace
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleExportElectricalCSVResult(#{error_result.to_json})")
          end
          nil
        end

        # EXPORT XLSX
        @dialog.add_action_callback('exportElectricalXLSX') do |_context, payload|
          begin
            puts "[ElectricalReportsHandler] exportElectricalXLSX called"
            params = JSON.parse(payload)
            
            unless params['path']
              error_result = { success: false, message: 'Caminho do arquivo não fornecido' }
              @dialog.execute_script("window.handleExportElectricalXLSXResult(#{error_result.to_json})")
              return nil
            end
            
            report_type = params['reportType']
            file_path = params['path']
            
            result = ProjetaPlus::Modules::ProElectricalReports.export_xlsx(report_type, file_path)
            puts "[ElectricalReportsHandler] Export result: #{result[:success]}"
            
            @dialog.execute_script("window.handleExportElectricalXLSXResult(#{result.to_json})")
          rescue => e
            puts "[ElectricalReportsHandler] ERROR: #{e.message}"
            puts e.backtrace if e.backtrace
            error_result = { success: false, message: e.message }
            @dialog.execute_script("window.handleExportElectricalXLSXResult(#{error_result.to_json})")
          end
          nil
        end

      end

    end
  end
end
