# encoding: UTF-8

require 'sketchup.rb'
require 'set'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProFurnitureAttributes

      DICTIONARY_NAME = "dynamic_attributes".freeze
      ATTR_PREFIX = "pro_furn_".freeze
      CM_TO_INCHES = 2.54
      MIN_DIMENSION_CM = 1.0

      TYPE_COLORS = {
        "Furniture" => Sketchup::Color.new(139, 69, 19),      
        "Appliances" => Sketchup::Color.new(70, 130, 180),    
        "Fixtures" => Sketchup::Color.new(60, 179, 113),     
        "Accessories" => Sketchup::Color.new(255, 140, 0),    
        "Decoration" => Sketchup::Color.new(186, 85, 211),    
        "Other" => Sketchup::Color.new(128, 128, 128)         
      }.freeze

      @selection_observer = nil
      @instances_cache = {}
      @cache_timestamp = 0
      @processing_selection = false
      @last_processed_selection = nil

      def self.initialize_default_attributes(component)
        default_attributes = {
          "#{ATTR_PREFIX}name" => "",
          "#{ATTR_PREFIX}color" => "",
          "#{ATTR_PREFIX}brand" => "",
          "#{ATTR_PREFIX}type" => "",
          "#{ATTR_PREFIX}dimension_format" => "L x P x A",
          "#{ATTR_PREFIX}dimension" => "",
          "#{ATTR_PREFIX}environment" => "",
          "#{ATTR_PREFIX}value" => "",
          "#{ATTR_PREFIX}link" => "",
          "#{ATTR_PREFIX}observations" => "",
          "#{ATTR_PREFIX}code" => ""
        }

        default_attributes.each do |attr_name, default_value|
          current_value = get_attribute_safe(component, attr_name, nil)
          if current_value.nil? || current_value.empty?
            set_attribute_safe(component, attr_name, default_value)
          end
        end

        if get_attribute_safe(component, "#{ATTR_PREFIX}dimension", "").empty?
          dimension_format = get_attribute_safe(component, "#{ATTR_PREFIX}dimension_format", "L x P x A")
          current_dim = calculate_dimension_string(component, dimension_format)
          set_attribute_safe(component, "#{ATTR_PREFIX}dimension", current_dim)
        end
      end

      def self.set_attribute_safe(component, key, value)
        component.definition.set_attribute(DICTIONARY_NAME, key, value)
      end

      def self.get_attribute_safe(component, key, default = "")
        value = component.definition.get_attribute(DICTIONARY_NAME, key, nil)
        value = component.get_attribute(DICTIONARY_NAME, key, default) if value.nil?
        value || default
      end

      def self.sync_attributes_to_definition(component)
        attrs = component.attribute_dictionaries
        return unless attrs && attrs[DICTIONARY_NAME]

        attrs[DICTIONARY_NAME].each do |key, value|
          component.definition.set_attribute(DICTIONARY_NAME, key, value)
        end
      end

      def self.calculate_dimension_string(entity, format = "L x P x A")
        return "" unless entity && entity.valid?
        
        begin
          component = entity.is_a?(Sketchup::Group) ? entity.to_component : entity
          return "" unless component && component.valid?
          
          bounds = component.bounds
          return "" unless bounds && bounds.valid?
          
          width = format_number(bounds.width.to_f * CM_TO_INCHES)
          depth = format_number(bounds.height.to_f * CM_TO_INCHES)
          height = format_number(bounds.depth.to_f * CM_TO_INCHES)

          case format
          when "L x P x A" then "#{width} x #{depth} x #{height} cm"
          when "L x P" then "#{width} x #{depth} cm"
          when "L x A" then "#{width} x #{height} cm"
          when "SEM DIMENSÃO" then ""
          else "#{width} x #{depth} x #{height} cm"
          end
        rescue => e
          puts "ERROR in calculate_dimension_string: #{e.message}"
          ""
        end
      end

      def self.format_number(num)
        return "" if num.nil?
        rounded = num.to_f.round(2)
        if rounded.to_i == rounded
          rounded.to_i.to_s
        else
          sprintf('%.2f', rounded).sub(/\.?0+$/, '')
        end
      end

      def self.get_dimension_components(entity)
        return { width: "", depth: "", height: "" } unless entity && entity.valid?
        
        begin
          bounds = entity.bounds
          return { width: "", depth: "", height: "" } unless bounds && bounds.valid?
          
          {
            width: format_number(bounds.width.to_f * CM_TO_INCHES),
            depth: format_number(bounds.height.to_f * CM_TO_INCHES),
            height: format_number(bounds.depth.to_f * CM_TO_INCHES)
          }
        rescue => e
          puts "ERROR in get_dimension_components: #{e.message}"
          { width: "", depth: "", height: "" }
        end
      end

      def self.generate_clean_name(name, brand, dimension)
        parts = []
        parts << name unless name.nil? || name.strip.empty?
        parts << brand unless brand.nil? || brand.strip.empty?
        parts << dimension unless dimension.nil? || dimension.strip.empty?

        clean_name = parts.join(" - ")
        copy_to_clipboard(clean_name)
        clean_name
      end

      def self.build_dimension_label(entity, format)
        dims = get_dimension_components(entity)
        width = dims[:width]
        depth = dims[:depth]
        height = dims[:height]

        case format
        when "L x P x A"
          return "#{width}L x #{depth}P x #{height}A" unless [width, depth, height].any?(&:empty?)
        when "L x P"
          return "#{width}L x #{depth}P" unless [width, depth].any?(&:empty?)
        when "L x A"
          return "#{width}L x #{height}A" unless [width, height].any?(&:empty?)
        when "SEM DIMENSÃO"
          return ""
        end

        return "#{width}L x #{depth}P x #{height}A" unless [width, depth, height].any?(&:empty?)
        ""
      end

      def self.copy_to_clipboard(text)
        begin
          if RUBY_PLATFORM =~ /mswin|mingw|cygwin/
            IO.popen('echo ' + text.gsub('"', '""') + ' | clip', 'w').close
          elsif RUBY_PLATFORM =~ /darwin/
            IO.popen('pbcopy', 'w') { |f| f << text }
          else
            IO.popen('xclip -selection clipboard', 'w') { |f| f << text } rescue nil
          end
          puts "📋 #{ProjetaPlus::Localization.t('messages.name_copied_to_clipboard')}: #{text}"
        rescue => e
          puts "⚠️ #{ProjetaPlus::Localization.t('messages.clipboard_copy_failed')}: #{e.message}"
        end
      end

      def self.collect_all_furniture_instances(entities, arr, level=0)
        return if level > 5 || entities.nil?

        begin
          # Cria uma cópia da lista para evitar problemas durante iteração no Windows
          entities_list = entities.to_a
          
          entities_list.each do |e|
            # Validação robusta para Windows
            begin
              next unless e
              next unless e.respond_to?(:valid?)
              next unless e.valid?
            rescue => validation_error
              next
            end

            component = nil
            begin
              component = case e
                         when Sketchup::Group
                           next unless e.valid?
                           e.to_component
                         when Sketchup::ComponentInstance
                           next unless e.valid?
                           e
                         else
                           next
                         end
            rescue => conversion_error
              next
            end

            next unless component
            begin
              next unless component.valid?
            rescue => component_validation_error
              next
            end

            begin
              type = get_attribute_safe(component, "#{ATTR_PREFIX}type", "").to_s.strip
              arr << component unless type.empty?
            rescue => attr_error
              # Ignora erros de leitura de atributos
              next
            end

            # Recursão com validação adicional
            begin
              if component.respond_to?(:definition) && component.definition && 
                 component.definition.valid? && component.definition.respond_to?(:entities)
                definition_entities = component.definition.entities
                if definition_entities && definition_entities.respond_to?(:each)
                  collect_all_furniture_instances(definition_entities, arr, level+1)
                end
              end
            rescue => recursion_error
              # Ignora erros de recursão
              next
            end
          end
        rescue => e
          puts "ERROR in collect_all_furniture_instances: #{e.message}"
          puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
        end
      end

      def self.find_component_by_id(entities, target_id, level=0)
        return nil if level > 10 || entities.nil?
        
        begin
          # Cria uma cópia da lista para evitar problemas durante iteração no Windows
          entities_list = entities.to_a
          
          entities_list.each do |e|
            begin
              # Validação robusta
              next unless e
              next unless e.respond_to?(:valid?)
              next unless e.valid?
              next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
            rescue => validation_error
              next
            end

            component = nil
            begin
              component = e.is_a?(Sketchup::Group) ? e.to_component : e
              next unless component && component.valid?
            rescue => conversion_error
              next
            end

            begin
              return component if component.respond_to?(:entityID) && component.entityID == target_id
            rescue => id_error
              next
            end

            # Recursão com validação
            begin
              if component.respond_to?(:definition) && component.definition && 
                 component.definition.valid? && component.definition.respond_to?(:entities)
                definition_entities = component.definition.entities
                if definition_entities && definition_entities.respond_to?(:each)
                  found = find_component_by_id(definition_entities, target_id, level+1)
                  return found if found
                end
              end
            rescue => recursion_error
              next
            end
          end
        rescue => e
          puts "ERROR in find_component_by_id: #{e.message}"
        end
        
        nil
      end

      def self.get_cached_instances(model)
        current_time = Time.now.to_f

        if @instances_cache.empty? || current_time - @cache_timestamp > 2.0
          @instances_cache.clear
          instances = []
          collect_all_furniture_instances(model.entities, instances)

          instances.each do |inst|
            type = get_attribute_safe(inst, "#{ATTR_PREFIX}type", "").to_s.strip
            next if type.empty?
            @instances_cache[type] ||= []
            @instances_cache[type] << inst
          end

          @cache_timestamp = current_time
        end

        @instances_cache
      end

      def self.invalidate_cache
        @instances_cache.clear if @instances_cache
        @cache_timestamp = 0
      end

      def self.resize_proportional(entity, scale_factor)
        return unless entity && entity.valid? && scale_factor.to_f > 0

        begin
          bounds = entity.bounds
          return unless bounds && bounds.valid?
          
          origin = bounds.min

          model = Sketchup.active_model
          return unless model && model.valid?
          
          model.start_operation(ProjetaPlus::Localization.t('commands.resize_proportional'), true)
          entity.transform!(Geom::Transformation.scaling(origin, scale_factor.to_f))
          model.commit_operation
        rescue => e
          model.abort_operation if model && model.valid?
          puts "ERROR in resize_proportional: #{e.message}"
          puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
        end
      end

      def self.normalize_dimension_input(value)
        str = value.to_s.strip
        return nil if str.empty?
        str.tr(',', '.').to_f
      end

      def self.resize_independent(entity, new_width, new_depth, new_height, live: false)
        return unless entity && entity.valid?

        begin
          new_width_f = normalize_dimension_input(new_width)
          new_depth_f = normalize_dimension_input(new_depth)
          new_height_f = normalize_dimension_input(new_height)

          return unless new_width_f && new_depth_f && new_height_f

          new_width_f = [new_width_f, MIN_DIMENSION_CM].max
          new_depth_f = [new_depth_f, MIN_DIMENSION_CM].max
          new_height_f = [new_height_f, MIN_DIMENSION_CM].max

          bounds = entity.bounds
          return unless bounds && bounds.valid?
          
          current_width_cm = bounds.width * CM_TO_INCHES
          current_depth_cm = bounds.height * CM_TO_INCHES
          current_height_cm = bounds.depth * CM_TO_INCHES

          return if current_width_cm <= 0 || current_depth_cm <= 0 || current_height_cm <= 0

          scale_x = new_width_f / current_width_cm
          scale_y = new_depth_f / current_depth_cm
          scale_z = new_height_f / current_height_cm

          origin = bounds.min
          
          model = Sketchup.active_model
          return unless model && model.valid?

          # No modo ao vivo, usa operação transparente (similar ao exemplo)
          if live
            begin
              puts "[ProjetaPlus] Aplicando transformação ao vivo - SX: #{scale_x}, SY: #{scale_y}, SZ: #{scale_z}"
              # Usa operação transparente no modo live (não aparece no undo, mas permite atualização)
              model.start_operation('Redimensionar Independente', true, false, true)
              entity.transform!(Geom::Transformation.scaling(origin, scale_x, scale_y, scale_z))
              model.commit_operation
              puts "[ProjetaPlus] Transformação ao vivo aplicada com sucesso"
            rescue => e
              model.abort_operation if model && model.valid?
              puts "ERROR in live resize: #{e.message}"
              puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
            end
          else
            # Modo normal (não ao vivo) - funciona igual em todas as plataformas
            begin
              model.start_operation(ProjetaPlus::Localization.t('commands.resize_independent'), true)
              entity.transform!(Geom::Transformation.scaling(origin, scale_x, scale_y, scale_z))
              model.commit_operation
            rescue => e
              model.abort_operation if model && model.valid?
              raise
            end
          end
        rescue => e
          model.abort_operation if model && model.valid? && !live
          puts "ERROR in resize_independent: #{e.message}"
          puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
        end
      end

      def self.mac?
        RUBY_PLATFORM =~ /darwin/
      end

      def self.resize_independent_with_timer(entity, new_width, new_depth, new_height)
        return unless entity && entity.valid?

        begin
          new_width_f = normalize_dimension_input(new_width)
          new_depth_f = normalize_dimension_input(new_depth)
          new_height_f = normalize_dimension_input(new_height)

          return unless new_width_f && new_depth_f && new_height_f

          new_width_f = [new_width_f, MIN_DIMENSION_CM].max
          new_depth_f = [new_depth_f, MIN_DIMENSION_CM].max
          new_height_f = [new_height_f, MIN_DIMENSION_CM].max

          bounds = entity.bounds
          return unless bounds && bounds.valid?
          
          current_width_cm = bounds.width * CM_TO_INCHES
          current_depth_cm = bounds.height * CM_TO_INCHES
          current_height_cm = bounds.depth * CM_TO_INCHES

          return if current_width_cm <= 0 || current_depth_cm <= 0 || current_height_cm <= 0

          scale_x = new_width_f / current_width_cm
          scale_y = new_depth_f / current_depth_cm
          scale_z = new_height_f / current_height_cm

          origin = bounds.min

          # Usa timer para garantir que a operação rode na thread principal
          UI.start_timer(0, false) do
            begin
              model = Sketchup.active_model
              return unless model && model.valid?
              return unless entity && entity.valid?
              
              entity.transform!(Geom::Transformation.scaling(origin, scale_x, scale_y, scale_z))
              model.active_view.invalidate if model.active_view && model.active_view.valid?
            rescue => e
              puts "ERROR in timer resize: #{e.message}"
              puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
            end
          end
        rescue => e
          puts "ERROR in resize_independent_with_timer: #{e.message}"
          puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
        end
      end

      def self.save_furniture_attributes(component, attributes)
        return { success: false, message: nil } unless component && component.valid?

        begin
          # Extrai as novas dimensões
          new_width = attributes["#{ATTR_PREFIX}width"] || attributes["width"]
          new_depth = attributes["#{ATTR_PREFIX}depth"] || attributes["depth"]
          new_height = attributes["#{ATTR_PREFIX}height"] || attributes["height"]

          # Salva os outros atributos primeiro
          attributes.each do |key, value|
            next if key == "#{ATTR_PREFIX}width" || key == "#{ATTR_PREFIX}depth" || key == "#{ATTR_PREFIX}height" ||
                    key == "width" || key == "depth" || key == "height"
            set_attribute_safe(component, key, value)
          end

          # Obtém as dimensões atuais do componente
          current_dims = get_dimension_components(component)
          current_width = normalize_dimension_input(current_dims[:width]) || 0
          current_depth = normalize_dimension_input(current_dims[:depth]) || 0
          current_height = normalize_dimension_input(current_dims[:height]) || 0

          # Processa as novas dimensões - usa as atuais como fallback se não fornecidas
          width_f = nil
          depth_f = nil
          height_f = nil

          if new_width && !new_width.to_s.strip.empty?
            width_f = normalize_dimension_input(new_width)
          end
          if new_depth && !new_depth.to_s.strip.empty?
            depth_f = normalize_dimension_input(new_depth)
          end
          if new_height && !new_height.to_s.strip.empty?
            height_f = normalize_dimension_input(new_height)
          end

          # Se pelo menos uma dimensão foi fornecida, usa as atuais como fallback para as não fornecidas
          if width_f || depth_f || height_f
            width_f ||= current_width
            depth_f ||= current_depth
            height_f ||= current_height

            # Valida que todas as dimensões são válidas e positivas
            if width_f && depth_f && height_f && width_f > 0 && depth_f > 0 && height_f > 0
              # Verifica se há diferença significativa (maior que 0.01 cm)
              needs_resize = (width_f - current_width).abs > 0.01 || 
                            (depth_f - current_depth).abs > 0.01 || 
                            (height_f - current_height).abs > 0.01

              if needs_resize
                puts "[ProjetaPlus] Redimensionando componente: #{current_width}x#{current_depth}x#{current_height} -> #{width_f}x#{depth_f}x#{height_f}"
                resize_independent(component, width_f, depth_f, height_f)
                puts "[ProjetaPlus] Redimensionamento concluído"
              else
                puts "[ProjetaPlus] Dimensões não alteradas, pulando redimensionamento"
              end
            else
              puts "[ProjetaPlus] WARNING: Dimensões inválidas - W:#{width_f} D:#{depth_f} H:#{height_f}"
            end
          end

          # Atualiza o nome do componente
          name = attributes["#{ATTR_PREFIX}name"] || attributes['name'] || ""
          brand = attributes["#{ATTR_PREFIX}brand"] || attributes['brand'] || ""
          format = attributes["#{ATTR_PREFIX}dimension_format"] ||
                   get_attribute_safe(component, "#{ATTR_PREFIX}dimension_format", "L x P x A")
          
          dimension_label = build_dimension_label(component, format)
          clean_name = generate_clean_name(name, brand, dimension_label)
          component.definition.name = clean_name if component.definition && component.definition.valid?

          { success: true, message: ProjetaPlus::Localization.t('messages.attributes_saved_success') }
        rescue => e
          puts "ERROR in save_furniture_attributes: #{e.message}"
          puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
          { success: false, message: "#{ProjetaPlus::Localization.t('messages.error_saving_attributes')}: #{e.message}" }
        end
      end

      def self.set_visible_recursive(component, value)
        component.visible = value
        component.definition.entities.each do |e|
          if e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
            set_visible_recursive(e.is_a?(Sketchup::Group) ? e.to_component : e, value)
          else
            e.visible = value
          end
        end
      end

      def self.isolate_item(target)
        return unless target && target.valid?
        
        model = Sketchup.active_model
        return unless model && model.valid?
        
        scene_name = "general"
        scene = model.pages.find { |p| p.name.downcase == scene_name.downcase }
        model.pages.selected_page = scene if scene

        model.start_operation(ProjetaPlus::Localization.t('commands.isolate_item'), true)

        begin
          current = target
          highest_parent = current

          # Encontra o parent mais alto na hierarquia
          while current.respond_to?(:parent) && current.valid?
            parent = current.parent
            break if parent.nil? || parent.is_a?(Sketchup::Model)
            break unless parent.valid?
            break unless current.is_a?(Sketchup::Group) || current.is_a?(Sketchup::ComponentInstance)
            
            highest_parent = current
            current = parent
          end

          # Valida o highest_parent antes de usar
          return unless highest_parent && highest_parent.valid?

          # Limpa seleção e adiciona o componente isolado
          model.selection.clear
          begin
            model.selection.add(highest_parent) if highest_parent.valid?
          rescue => e
            puts "WARNING: Could not add to selection: #{e.message}"
          end

          # Coleta todos os IDs das entidades que devem permanecer visíveis
          visible_ids = Set.new
          visible_ids.add(highest_parent.entityID) if highest_parent.respond_to?(:entityID)
          
          # Adiciona todas as entidades dentro da definição do highest_parent
          if highest_parent.respond_to?(:definition) && highest_parent.definition && highest_parent.definition.valid?
            collect_entity_ids_recursive(highest_parent.definition.entities, visible_ids)
          end

          # Define visibilidade de todas as entidades do modelo
          begin
            entities_list = model.entities.to_a
            entities_list.each do |e|
              next unless e && e.valid?
              begin
                e.visible = visible_ids.include?(e.entityID) if e.respond_to?(:entityID)
              rescue => err
                # Ignora erros de entidades inválidas
                next
              end
            end
          rescue => err
            puts "WARNING: Error setting visibility: #{err.message}"
          end

          model.commit_operation

          # Ajusta a câmera
          view = model.active_view
          if view && view.valid?
            eye = Geom::Point3d.new(-1000, -1000, 1000)
            target_pt = Geom::Point3d.new(0, 0, 0)
            up = Geom::Vector3d.new(0, 0, 1)

            view.camera.set(eye, target_pt, up)
            view.camera.perspective = true
            view.zoom_extents
          end
        rescue => e
          model.abort_operation if model
          puts "ERROR in isolate_item: #{e.message}"
          puts e.backtrace.join("\n") if e.respond_to?(:backtrace)
        end
      end

      def self.collect_entity_ids_recursive(entities, id_set, level = 0)
        return if level > 10 || entities.nil?
        
        begin
          entities_list = entities.to_a
          entities_list.each do |e|
            next unless e && e.valid?
            begin
              id_set.add(e.entityID) if e.respond_to?(:entityID)
              
              if e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
                component = e.is_a?(Sketchup::Group) ? e.to_component : e
                if component && component.valid? && component.respond_to?(:definition) && 
                   component.definition && component.definition.valid? && component.definition.entities
                  collect_entity_ids_recursive(component.definition.entities, id_set, level + 1)
                end
              end
            rescue => err
              # Ignora erros de entidades inválidas
              next
            end
          end
        rescue => e
          # Ignora erros gerais
          return
        end
      end

      def self.get_available_types
        [
          ProjetaPlus::Localization.t('furniture_types.furniture'),
          ProjetaPlus::Localization.t('furniture_types.appliances'),
          ProjetaPlus::Localization.t('furniture_types.fixtures'),
          ProjetaPlus::Localization.t('furniture_types.accessories'),
          ProjetaPlus::Localization.t('furniture_types.decoration')
        ]
      end

      def self.color_to_hex(color)
        return "#808080" unless color.respond_to?(:red)
        "#%02x%02x%02x" % [color.red, color.green, color.blue]
      end

      def self.get_type_color(type)
        TYPE_COLORS[type] || TYPE_COLORS["Other"]
      end

    end
  end
end
