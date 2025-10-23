# encoding: UTF-8
require 'sketchup.rb'
require_relative 'base_handler.rb'

module ProjetaPlus
  module DialogHandlers
    class AnnotationHandler < BaseHandler
      
      def register_callbacks
        register_room_annotation_callbacks
        register_section_annotation_callbacks
        register_ceiling_annotation_callbacks
        register_view_indication_callbacks
        register_lighting_annotation_callbacks
        register_circuit_connection_callbacks
      end
      
      private
      
      def register_room_annotation_callbacks
        @dialog.add_action_callback("loadRoomAnnotationDefaults") do |action_context|
          defaults = ProjetaPlus::Modules::ProRoomAnnotation.get_defaults
          log("Loading room annotation defaults: #{defaults.inspect}")
          send_json_response("handleRoomDefaults", defaults)
          nil
        end
        
        @dialog.add_action_callback("startRoomAnnotation") do |action_context, json_payload|
          begin
            args = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProRoomAnnotation.start_interactive_annotation(args)
            log("Room annotation started with args: #{args.inspect}")
            send_json_response("handleRoomAnnotationResult", result)
          rescue => e
            error_result = handle_error(e, "room annotation")
            send_json_response("handleRoomAnnotationResult", error_result)
          end
          nil
        end
      end
      
      def register_section_annotation_callbacks
        @dialog.add_action_callback("startSectionAnnotation") do |action_context, json_payload|
          begin
            result = ProjetaPlus::Modules::ProSectionAnnotation.start_interactive_annotation
            log("Section annotation started (using fixed module values)")
            send_json_response("handleSectionAnnotationResult", result)
          rescue => e
            error_result = handle_error(e, "section annotation")
            send_json_response("handleSectionAnnotationResult", error_result)
          end
          nil
        end
      end
      
      def register_ceiling_annotation_callbacks
        @dialog.add_action_callback("loadCeilingAnnotationDefaults") do |action_context|
          defaults = ProjetaPlus::Modules::ProCeilingAnnotation.get_defaults
          log("Loading ceiling annotation defaults: #{defaults.inspect}")
          send_json_response("handleCeilingDefaults", defaults)
          nil
        end
        
        @dialog.add_action_callback("startCeilingAnnotation") do |action_context, json_payload|
          begin
            args = JSON.parse(json_payload)
            result = ProjetaPlus::Modules::ProCeilingAnnotation.start_interactive_annotation(args)
            log("Ceiling annotation started with args: #{args.inspect}")
            send_json_response("handleCeilingAnnotationResult", result)
          rescue => e
            error_result = handle_error(e, "ceiling annotation")
            send_json_response("handleCeilingAnnotationResult", error_result)
          end
          nil
        end
      end
      
      def register_view_indication_callbacks
        @dialog.add_action_callback("activate_view_indication_tool") do |action_context|
          activate_view_indication_tool
        end
        
        @dialog.add_action_callback("get_view_indication_settings") do |action_context|
          get_view_indication_settings
        end
        
        @dialog.add_action_callback("update_view_indication_settings") do |action_context, settings_json|
          update_view_indication_settings(settings_json)
        end
      end
      
      def activate_view_indication_tool
        begin
          model = Sketchup.active_model
          
          if model.nil?
            @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.no_model_open")}', 'error');")
            return
          end
          
          # Activate the view indication tool
          tool = ProjetaPlus::Modules::ProViewIndication::ViewIndicationTool.new
          model.select_tool(tool)
          
          @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.view_indication_tool_activated")}', 'success');")
          
        rescue => e
          puts "[ProjetaPlus] Error activating view indication tool: #{e.message}"
          puts e.backtrace.join("\n")
          @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.error_activating_tool")}', 'error');")
        end
      end
      
      def get_view_indication_settings
        begin
          settings = ProjetaPlus::ProSettings.get_settings
          
          view_indication_settings = {
            cut_level: settings[:cut_height] || ProjetaPlus::Modules::ProViewIndication::CUT_LEVEL,
            default_scale: settings[:scale] || ProjetaPlus::Modules::ProViewIndication::DEFAULT_SCALE,
            block_name: ProjetaPlus::Modules::ProViewIndication::BLOCK_NAME
          }
          
          @dialog.execute_script("updateViewIndicationSettings(#{view_indication_settings.to_json});")
          
        rescue => e
          puts "[ProjetaPlus] Error getting view indication settings: #{e.message}"
          puts e.backtrace.join("\n")
          @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.error_getting_settings")}', 'error');")
        end
      end

      def update_view_indication_settings(settings_json)
        begin
          settings = JSON.parse(settings_json, symbolize_names: true)
          
          # Validate settings
          cut_level = settings[:cut_level].to_f
          default_scale = settings[:default_scale].to_f
          
          if cut_level <= 0 || default_scale <= 0
            @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.invalid_view_indication_values")}', 'error');")
            return
          end
          
          # Update settings
          ProjetaPlus::ProSettings.update_setting(:cut_height, cut_level)
          ProjetaPlus::ProSettings.update_setting(:scale, default_scale)
          
          @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.view_indication_settings_updated")}', 'success');")
          
        rescue JSON::ParserError => e
          puts "[ProjetaPlus] JSON parsing error in view indication settings: #{e.message}"
          @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.json_parse_error")}', 'error');")
        rescue => e
          puts "[ProjetaPlus] Error updating view indication settings: #{e.message}"
          puts e.backtrace.join("\n")
          @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.error_updating_settings")}', 'error');")
        end
      end
      
      def register_lighting_annotation_callbacks
        @dialog.add_action_callback("loadLightingAnnotationDefaults") do |action_context|
          defaults = ProjetaPlus::Modules::ProLightingAnnotation.get_defaults
          log("Loading lighting annotation defaults: #{defaults.inspect}")
          send_json_response("handleLightingDefaults", defaults)
          nil
        end
        
        @dialog.add_action_callback("startLightingAnnotation") do |action_context, json_payload|
          begin
            args = JSON.parse(json_payload)
            puts "args: #{args.inspect}"
            puts "args['circuit_text']: #{args['circuit_text']}"
            puts "args['circuit_scale']: #{args['circuit_scale']}"
            puts "args['circuit_height_cm']: #{args['circuit_height_cm']}"
            puts "args['circuit_font']: #{args['circuit_font']}"
            puts "args['circuit_text_color']: #{args['circuit_text_color']}"
            result = ProjetaPlus::Modules::ProLightingAnnotation.start_interactive_annotation(args)
            log("Lighting annotation started with args: #{args.inspect}")
            send_json_response("handleLightingAnnotationResult", result)
          rescue => e
            error_result = handle_error(e, "lighting annotation")
            send_json_response("handleLightingAnnotationResult", error_result)
          end
          nil
        end
      end
      
      def register_circuit_connection_callbacks
        @dialog.add_action_callback("startCircuitConnection") do |action_context|
          begin
            result = ProjetaPlus::Modules::ProCircuitConnection.start_interactive_connection
            log("Circuit connection tool started")
            send_json_response("handleCircuitConnectionResult", result)
          rescue => e
            error_result = handle_error(e, "circuit connection")
            send_json_response("handleCircuitConnectionResult", error_result)
          end
          nil
        end
      end
      
    end
  end
end
