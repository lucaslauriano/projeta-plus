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
        @dialog.add_action_callback("loadSectionAnnotationDefaults") do |action_context|
          defaults = ProjetaPlus::Modules::ProSectionAnnotation.get_defaults
          log("Loading section annotation defaults: #{defaults.inspect}")
          send_json_response("handleSectionDefaults", defaults)
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
      end
      
    end
  end
end
