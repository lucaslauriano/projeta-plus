# encoding: UTF-8

require 'json'
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/furniture/pro_furniture_attributes.rb'
require_relative '../modules/report/pro_furniture_reports.rb'

module ProjetaPlus
  module DialogHandlers
    class FurnitureHandler < BaseHandler

      class SelectionObserver < Sketchup::SelectionObserver
        def initialize(handler)
          @handler = handler
        end

        def onSelectionBulkChange(selection)
          @handler.handle_selection_change(selection)
        end

        def onSelectionCleared(selection)
          @handler.handle_selection_change(selection)
        end

        def onSelectionAdded(selection, _entity)
          @handler.handle_selection_change(selection)
        end

        def onSelectionRemoved(selection, _entity)
          @handler.handle_selection_change(selection)
        end
      end

      def initialize(dialog)
        super(dialog)
        @selection_observer = nil
        @last_processed_selection = nil
        @processing_selection = false
      end

      def register_callbacks
        @dialog.add_action_callback('get_furniture_attributes') do |_context, _payload|
          begin
            result = get_selected_furniture_attributes
            log("Get furniture attributes: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureAttributes', result)
          rescue => e
            send_json_response('handleFurnitureAttributes', handle_error(e, 'get_furniture_attributes'))
          end
          nil
        end

        @dialog.add_action_callback('save_furniture_attributes') do |_context, payload|
          begin
            result = save_furniture_attributes(payload)
            log("Save furniture attributes: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureSave', result)
          rescue => e
            send_json_response('handleFurnitureSave', handle_error(e, 'save_furniture_attributes'))
          end
          nil
        end

        @dialog.add_action_callback('resize_proportional') do |_context, payload|
          begin
            result = resize_proportional(payload)
            log("Resize proportional: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureDimensions', result)
          rescue => e
            send_json_response('handleFurnitureDimensions', handle_error(e, 'resize_proportional'))
          end
          nil
        end

        @dialog.add_action_callback('resize_independent') do |_context, payload|
          begin
            result = resize_independent(payload)
            log("Resize independent: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureDimensions', result)
          rescue => e
            send_json_response('handleFurnitureDimensions', handle_error(e, 'resize_independent'))
          end
          nil
        end

        @dialog.add_action_callback('get_dimensions') do |_context, _payload|
          begin
            result = get_current_dimensions
            log("Get dimensions: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureDimensions', result)
          rescue => e
            send_json_response('handleFurnitureDimensions', handle_error(e, 'get_dimensions'))
          end
          nil
        end

        @dialog.add_action_callback('calculate_dimension_string') do |_context, payload|
          begin
            result = calculate_dimension_string(payload)
            log("Calculate dimension string: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureDimensionPreview', result)
          rescue => e
            send_json_response('handleFurnitureDimensionPreview', handle_error(e, 'calculate_dimension_string'))
          end
          nil
        end

        @dialog.add_action_callback('isolate_furniture_item') do |_context, payload|
          begin
            result = isolate_item(payload)
            log("Isolate furniture item: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureOperation', result)
          rescue => e
            send_json_response('handleFurnitureOperation', handle_error(e, 'isolate_furniture_item'))
          end
          nil
        end

        @dialog.add_action_callback('get_furniture_types') do |_context, _payload|
          begin
            result = get_available_types
            log("Get furniture types: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureTypes', result)
          rescue => e
            send_json_response('handleFurnitureTypes', handle_error(e, 'get_furniture_types'))
          end
          nil
        end

        @dialog.add_action_callback('export_furniture_category_csv') do |_context, payload|
          begin
            result = export_category_csv(payload)
            log("Export category CSV: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureOperation', result)
          rescue => e
            send_json_response('handleFurnitureOperation', handle_error(e, 'export_furniture_category_csv'))
          end
          nil
        end

        @dialog.add_action_callback('export_furniture_xlsx') do |_context, payload|
          begin
            result = export_xlsx(payload)
            log("Export XLSX: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureOperation', result)
          rescue => e
            send_json_response('handleFurnitureOperation', handle_error(e, 'export_furniture_xlsx'))
          end
          nil
        end

        @dialog.add_action_callback('get_category_report_data') do |_context, payload|
          begin
            result = get_category_report_data(payload)
            log("Get category report: #{result[:success] ? 'success' : 'failed'}")
            send_json_response('handleFurnitureReport', result)
          rescue => e
            send_json_response('handleFurnitureReport', handle_error(e, 'get_category_report_data'))
          end
          nil
        end

        attach_selection_observer
        send_selection_update(force: true)
      end

      def attach_selection_observer
        model = Sketchup.active_model
        return unless model

        selection = model.selection
        return unless selection

        detach_selection_observer

        @selection_observer = SelectionObserver.new(self)
        selection.add_observer(@selection_observer)
        log('Furniture selection observer attached.')
      rescue => e
        handle_error(e, 'attach_selection_observer')
      end

      def detach_selection_observer
        selection = Sketchup.active_model&.selection
        if selection && @selection_observer
          selection.remove_observer(@selection_observer)
          log('Furniture selection observer detached.')
        end
        @selection_observer = nil
      rescue => e
        handle_error(e, 'detach_selection_observer')
      end

      def handle_selection_change(selection, force: false)
        puts "\n[ProjetaPlus Furniture] ═══════════════════════════════════════"
        puts "[ProjetaPlus Furniture] Selection change detected!"
        puts "[ProjetaPlus Furniture] Processing: #{@processing_selection}"
        puts "[ProjetaPlus Furniture] Force: #{force}"
        
        return if @processing_selection

        signature = selection_signature(selection)
        puts "[ProjetaPlus Furniture] Current signature: #{signature.inspect}"
        puts "[ProjetaPlus Furniture] Last signature: #{@last_processed_selection.inspect}"
        
        return if !force && signature == @last_processed_selection

        @processing_selection = true
        @last_processed_selection = signature

        puts "[ProjetaPlus Furniture] Getting attributes and dimensions..."
        attributes_response = get_selected_furniture_attributes
        dimensions_response = get_current_dimensions

        puts "[ProjetaPlus Furniture] Attributes response: #{attributes_response[:success] ? 'SUCCESS' : 'FAILED'}"
        puts "[ProjetaPlus Furniture] Dimensions response: #{dimensions_response[:success] ? 'SUCCESS' : 'FAILED'}"

        ::UI.start_timer(0, false) do
          send_json_response(
            'handleFurnitureAttributes',
            attributes_response || { success: false, selected: false }
          )
          send_json_response(
            'handleFurnitureDimensions',
            dimensions_response || { success: false }
          )

          if attributes_response && attributes_response[:success]
            message = "Componente selecionado: #{attributes_response[:object_name]} (ID #{attributes_response[:entity_id]})"
          else
            message = "Nenhum componente válido selecionado."
          end

          puts "[ProjetaPlus Furniture] #{message}"
          puts "[ProjetaPlus Furniture] ═══════════════════════════════════════\n"
          log("Selection change -> #{message}")
          execute_script("console.info('ProjetaPlus: #{escape_js_string(message)}');")
        end
      rescue => e
        puts "[ProjetaPlus Furniture] ERROR in handle_selection_change: #{e.message}"
        puts e.backtrace.join("\n")
        handle_error(e, 'handle_selection_change')
      ensure
        @processing_selection = false
      end

      def send_selection_update(selection = nil, force: false)
        selection ||= Sketchup.active_model&.selection
        handle_selection_change(selection, force: force)
      end

      def selection_signature(selection)
        return [] unless selection.respond_to?(:to_a)

        selection.to_a
                 .select { |entity| entity.respond_to?(:entityID) }
                 .map(&:entityID)
                 .sort
      end

      def escape_js_string(str)
        str.to_s
           .gsub('\\', '\\\\\\\\')
           .gsub("\n", '\\n')
           .gsub("\r", '\\r')
           .gsub("'", "\\\\'")
           .gsub('"', '\"')
      end

      private

      # ========== Selection Management ==========

      def get_selected_furniture_attributes
        model = Sketchup.active_model
        selection = model.selection
        entity = selection.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }

        if entity.nil?
          return {
            success: false,
            selected: false,
            message: ProjetaPlus::Localization.t('messages.no_component_selected'),
            selection_count: selection.length
          }
        end

        component = entity.is_a?(Sketchup::Group) ? entity.to_component : entity

        # Initialize attributes if type is set
        prefix = Modules::ProFurnitureAttributes::ATTR_PREFIX
        type = Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}type", "")
        if !type.empty?
          Modules::ProFurnitureAttributes.initialize_default_attributes(component)
        end

        # Get dimension components
        dimensions = Modules::ProFurnitureAttributes.get_dimension_components(entity)
        puts "[ProjetaPlus Furniture] Dimensions calculated: #{dimensions.inspect}"

        # Get all attributes
        attributes = {
          success: true,
          selected: true,
          entity_id: component.entityID,
          name: Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}name", ""),
          color: Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}color", ""),
          brand: Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}brand", ""),
          type: type,
          width: dimensions[:width],
          depth: dimensions[:depth],
          height: dimensions[:height],
          dimension_format: Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}dimension_format", "L x P x A"),
          dimension: Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}dimension", ""),
          environment: Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}environment", ""),
          value: Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}value", ""),
          link: Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}link", ""),
          observations: Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}observations", ""),
          object_name: component.definition.name || "Unnamed Object"
        }

        puts "[ProjetaPlus Furniture] Sending attributes with W/D/H: #{attributes[:width]}/#{attributes[:depth]}/#{attributes[:height]}"
        attributes
      rescue => e
        handle_error(e, 'get_furniture_attributes')
      end

      # ========== Save Attributes ==========

      def save_furniture_attributes(json_data)
        data = parse_payload(json_data)
        
        model = Sketchup.active_model
        selection = model.selection
        entity = selection.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }

        if entity.nil?
          return {
            success: false,
            message: ProjetaPlus::Localization.t('messages.no_component_selected')
          }
        end

        component = entity.is_a?(Sketchup::Group) ? entity.to_component : entity

        # Add prefix to attribute keys
        prefix = Modules::ProFurnitureAttributes::ATTR_PREFIX
        prefixed_data = {}
        data.each do |key, value|
          prefixed_key = key.to_s.start_with?(prefix) ? key.to_s : "#{prefix}#{key}"
          prefixed_data[prefixed_key] = value
        end

        model.start_operation(ProjetaPlus::Localization.t('commands.save_furniture_attributes'), true)

        result = Modules::ProFurnitureAttributes.save_furniture_attributes(component, prefixed_data)

        if result[:success]
          model.commit_operation
          # Invalidate cache after saving
          Modules::ProFurnitureAttributes.invalidate_cache
        else
          model.abort_operation
        end

        result
      rescue => e
        model.abort_operation if model
        handle_error(e, 'save_furniture_attributes')
      end

      # ========== Resize Operations ==========

      def resize_proportional(payload)
        params = parse_payload(payload)
        scale_factor = params['scale_factor'] || params[:scale_factor]
        model = Sketchup.active_model
        selection = model.selection
        entity = selection.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }

        if entity.nil?
          return {
            success: false,
            message: ProjetaPlus::Localization.t('messages.no_component_selected')
          }
        end

        Modules::ProFurnitureAttributes.resize_proportional(entity, scale_factor.to_f)

        # Return updated dimensions
        get_current_dimensions
      rescue => e
        handle_error(e, 'resize_proportional')
      end

      def resize_independent(payload)
        params = parse_payload(payload)
        width = params['width'] || params[:width]
        depth = params['depth'] || params[:depth]
        height = params['height'] || params[:height]
        model = Sketchup.active_model
        selection = model.selection
        entity = selection.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }

        if entity.nil?
          return {
            success: false,
            message: ProjetaPlus::Localization.t('messages.no_component_selected')
          }
        end

        Modules::ProFurnitureAttributes.resize_independent(entity, width, depth, height)

        # Return updated dimensions
        get_current_dimensions
      rescue => e
        handle_error(e, 'resize_independent')
      end

      # ========== Dimension Operations ==========

      def get_current_dimensions
        model = Sketchup.active_model
        selection = model.selection
        entity = selection.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }

        if entity.nil?
          return {
            success: false,
            message: ProjetaPlus::Localization.t('messages.no_component_selected')
          }
        end

        dimensions = Modules::ProFurnitureAttributes.get_dimension_components(entity)

        {
          success: true,
          width: dimensions[:width],
          depth: dimensions[:depth],
          height: dimensions[:height]
        }
      rescue => e
        handle_error(e, 'get_dimensions')
      end

      def calculate_dimension_string(payload)
        params = parse_payload(payload)
        begin
          w = (params['width'] || params[:width]).to_s.strip
          d = (params['depth'] || params[:depth]).to_s.strip
          h = (params['height'] || params[:height]).to_s.strip
          format = params['dimension_format'] || params[:dimension_format] || "L x P x A"

          result = case format
                  when "L x P x A" then "#{w} x #{d} x #{h} cm"
                  when "L x P" then "#{w} x #{d} cm"
                  when "L x A" then "#{w} x #{h} cm"
                  when "SEM DIMENSÃO" then ""
                  else "#{w} x #{d} x #{h} cm"
                  end

          {
            success: true,
            dimension: result
          }
        rescue => e
          handle_error(e, 'calculate_dimension_string')
        end
      end

      # ========== Isolation ==========

      def isolate_item(payload)
        params = parse_payload(payload)
        entity_id = params['entity_id'] || params[:entity_id]
        model = Sketchup.active_model
        target = Modules::ProFurnitureAttributes.find_component_by_id(model.entities, entity_id.to_i)

        if target.nil?
          return {
            success: false,
            message: ProjetaPlus::Localization.t('messages.no_component_selected')
          }
        end

        Modules::ProFurnitureAttributes.isolate_item(target)

        {
          success: true,
          message: ProjetaPlus::Localization.t('messages.item_isolated')
        }
      rescue => e
        handle_error(e, 'isolate_furniture_item')
      end

      # ========== Types ==========

      def get_available_types
        types = Modules::ProFurnitureAttributes.get_available_types

        {
          success: true,
          types: types
        }
      rescue => e
        handle_error(e, 'get_furniture_types')
      end

      # ========== Reports ==========

      def get_category_report_data(payload)
        params = parse_payload(payload)
        category = params['category'] || params[:category]
        model = Sketchup.active_model
        data = Modules::ProFurnitureReports.collect_data_for_category(model, category)

        items = data.map do |key, info|
          name, color, brand, type, dimension, environment, obs, link, value = key
          {
            name: name,
            color: color,
            brand: brand,
            type: type,
            dimension: dimension,
            environment: environment,
            observations: obs,
            link: link,
            value: value,
            quantity: info[:quantity],
            ids: info[:ids]
          }
        end

        {
          success: true,
          items: items
        }
      rescue => e
        handle_error(e, 'get_category_report_data')
      end

      # ========== Export ==========

      def export_category_csv(payload)
        params = parse_payload(payload)
        category = params['category'] || params[:category]
        model = Sketchup.active_model
        result = Modules::ProFurnitureReports.export_category_to_csv(model, category)

        result
      rescue => e
        handle_error(e, 'export_furniture_category_csv')
      end

      def export_xlsx(payload)
        model = Sketchup.active_model
        params = parse_payload(payload)
        categories = params['categories'] || params[:categories]

        path = File.join(File.dirname(model.path), 'Furniture_Report.xlsx')
        result = Modules::ProFurnitureReports.export_to_xlsx(model, categories, path)

        result
      rescue => e
        handle_error(e, 'export_furniture_xlsx')
      end

      def parse_payload(payload)
        return {} if payload.nil? || (payload.respond_to?(:empty?) && payload.empty?)
        payload.is_a?(String) ? JSON.parse(payload) : payload
      rescue JSON::ParserError
        {}
      end

    end
  end
end

