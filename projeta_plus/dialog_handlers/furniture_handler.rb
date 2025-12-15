# encoding: UTF-8

require 'json'
require 'sketchup.rb'
require_relative 'base_handler.rb'
require_relative '../modules/furniture/pro_furniture_attributes.rb'
require_relative '../modules/reports/pro_furniture_reports.rb'

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

        @dialog.add_action_callback('capture_selected_component') do |_context, _payload|
          begin
            log("Manual capture requested - sending current selection")
            send_selection_update(force: true)
            # Retorna sucesso para o frontend
            { success: true, message: "Selection captured" }
          rescue => e
            send_json_response('handleFurnitureAttributes', handle_error(e, 'capture_selected_component'))
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

        @dialog.add_action_callback('resize_independent_live') do |_context, payload|
          begin
            puts "[ProjetaPlus Handler] resize_independent_live chamado com payload: #{payload.inspect}"
            result = resize_independent_live(payload)
            # Não envia resposta para não bloquear a UI durante digitação
            log("Resize independent live: #{result[:success] ? 'success' : 'failed'}")
            puts "[ProjetaPlus Handler] Resultado: #{result.inspect}"
          rescue => e
            puts "[ProjetaPlus Handler] ERRO em resize_independent_live: #{e.message}"
            puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
            log("Error in resize_independent_live: #{e.message}")
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

        # Anexa o observer automaticamente para sincronizar a seleção
        # Observer ativo apenas para detectar quando a seleção é limpa
        attach_selection_observer
        # Não envia update inicial - usuário deve usar botão "Selecionar Componente"
        # send_selection_update(force: true)
      end

      def attach_selection_observer
        model = Sketchup.active_model
        return unless model

        selection = model.selection
        return unless selection

        detach_selection_observer

        @selection_observer = SelectionObserver.new(self)
        #selection.add_observer(@selection_observer)
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

        # Se a seleção está vazia, apenas notifica o frontend para mostrar o botão
        if signature.empty?
          puts "[ProjetaPlus Furniture] Selection cleared - notifying frontend"
          ::UI.start_timer(0, false) do
            send_json_response(
              'handleFurnitureAttributes',
              { success: false, selected: false, message: "Seleção limpa" }
            )
            send_json_response(
              'handleFurnitureDimensions',
              { success: false }
            )
            puts "[ProjetaPlus Furniture] Nenhum componente selecionado."
            puts "[ProjetaPlus Furniture] ═══════════════════════════════════════\n"
            log("Selection change -> Seleção limpa")
          end
          @processing_selection = false
          return
        end

        # Se NÃO for force (manual), ignora seleção automática
        unless force
          puts "[ProjetaPlus Furniture] Seleção automática ignorada (use o botão 'Selecionar Componente')"
          puts "[ProjetaPlus Furniture] ═══════════════════════════════════════\n"
          @processing_selection = false
          return
        end

        # Só carrega atributos se force = true (botão clicado)
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

        prefix = Modules::ProFurnitureAttributes::ATTR_PREFIX
        type = Modules::ProFurnitureAttributes.get_attribute_safe(component, "#{prefix}type", "")
        if !type.empty?
          Modules::ProFurnitureAttributes.initialize_default_attributes(component)
        end

        dimensions = Modules::ProFurnitureAttributes.get_dimension_components(entity)
        puts "[ProjetaPlus Furniture] Dimensions calculated: #{dimensions.inspect}"

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

      def save_furniture_attributes(json_data)
        data = parse_payload(json_data)
        
        puts "[ProjetaPlus Handler] Dados recebidos: #{data.inspect}"
        
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

        prefix = Modules::ProFurnitureAttributes::ATTR_PREFIX
        prefixed_data = {}
        data.each do |key, value|
          prefixed_key = key.to_s.start_with?(prefix) ? key.to_s : "#{prefix}#{key}"
          prefixed_data[prefixed_key] = value
        end

        puts "[ProjetaPlus Handler] Dimensões antes de salvar - W: #{prefixed_data["#{prefix}width"]}, D: #{prefixed_data["#{prefix}depth"]}, H: #{prefixed_data["#{prefix}height"]}"

        model.start_operation(ProjetaPlus::Localization.t('commands.save_furniture_attributes'), true)

        result = Modules::ProFurnitureAttributes.save_furniture_attributes(component, prefixed_data)

        if result[:success]
          model.commit_operation
          Modules::ProFurnitureAttributes.invalidate_cache
          
          puts "[ProjetaPlus Handler] Atributos salvos com sucesso"
          
          # Não envia atualização automática após salvar
          # O frontend reseta o formulário para feedback visual de sucesso
          # O SelectionObserver atualizará quando o usuário selecionar outro componente
        else
          model.abort_operation
          puts "[ProjetaPlus Handler] Erro ao salvar atributos: #{result[:message]}"
        end

        result
      rescue => e
        model.abort_operation if model
        puts "[ProjetaPlus Handler] EXCEPTION em save_furniture_attributes: #{e.message}"
        puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
        handle_error(e, 'save_furniture_attributes')
      end

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

        get_current_dimensions
      rescue => e
        handle_error(e, 'resize_independent')
      end

      def resize_independent_live(payload)
        puts "[ProjetaPlus Handler] ========== resize_independent_live INICIADO =========="
        params = parse_payload(payload)
        width = params['width'] || params[:width]
        depth = params['depth'] || params[:depth]
        height = params['height'] || params[:height]
        
        puts "[ProjetaPlus Handler] Dimensões recebidas - W: #{width}, D: #{depth}, H: #{height}"
        
        # Valida se as dimensões são válidas
        if width.to_s.strip.empty? && depth.to_s.strip.empty? && height.to_s.strip.empty?
          puts "[ProjetaPlus Handler] Todas as dimensões estão vazias, retornando false"
          return { success: false }
        end
        
        model = Sketchup.active_model
        selection = model.selection
        entity = selection.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }

        if entity.nil?
          puts "[ProjetaPlus Handler] Nenhuma entidade selecionada, retornando false"
          return { success: false }
        end

        # Valida entidade
        unless entity.valid?
          puts "[ProjetaPlus Handler] Entidade inválida, retornando false"
          return { success: false }
        end

        puts "[ProjetaPlus Handler] Entidade válida encontrada: #{entity.class}"

        # Obtém dimensões atuais para usar como fallback
        current_dims = Modules::ProFurnitureAttributes.get_dimension_components(entity)
        current_width = Modules::ProFurnitureAttributes.normalize_dimension_input(current_dims[:width]) || 0
        current_depth = Modules::ProFurnitureAttributes.normalize_dimension_input(current_dims[:depth]) || 0
        current_height = Modules::ProFurnitureAttributes.normalize_dimension_input(current_dims[:height]) || 0

        puts "[ProjetaPlus Handler] Dimensões atuais - W: #{current_width}, D: #{current_depth}, H: #{current_height}"

        # Usa as dimensões fornecidas ou mantém as atuais
        width_f = width.to_s.strip.empty? ? current_width : Modules::ProFurnitureAttributes.normalize_dimension_input(width)
        depth_f = depth.to_s.strip.empty? ? current_depth : Modules::ProFurnitureAttributes.normalize_dimension_input(depth)
        height_f = height.to_s.strip.empty? ? current_height : Modules::ProFurnitureAttributes.normalize_dimension_input(height)

        puts "[ProjetaPlus Handler] Dimensões processadas - W: #{width_f}, D: #{depth_f}, H: #{height_f}"

        # Valida dimensões - não aceita valores zerados ou negativos
        unless width_f && depth_f && height_f && width_f > 0 && depth_f > 0 && height_f > 0
          puts "[ProjetaPlus Handler] Dimensões inválidas (zero ou negativo), retornando false"
          return { success: false }
        end

        puts "[ProjetaPlus Handler] Chamando resize_independent com live: true"
        # Redimensiona ao vivo (sem operação undo/redo)
        Modules::ProFurnitureAttributes.resize_independent(entity, width_f, depth_f, height_f, live: true)
        puts "[ProjetaPlus Handler] resize_independent concluído"

        # No modo live, não atualiza a interface automaticamente para evitar loops
        # A interface será atualizada quando o usuário salvar ou quando a seleção mudar

        puts "[ProjetaPlus Handler] ========== resize_independent_live CONCLUÍDO COM SUCESSO =========="
        { success: true }
      rescue => e
        puts "[ProjetaPlus Handler] ========== ERRO em resize_independent_live =========="
        puts "[ProjetaPlus Handler] #{e.message}"
        puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
        log("Error in resize_independent_live: #{e.message}")
        { success: false }
      end

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

      def get_available_types
        types = Modules::ProFurnitureAttributes.get_available_types

        {
          success: true,
          types: types
        }
      rescue => e
        handle_error(e, 'get_furniture_types')
      end

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

