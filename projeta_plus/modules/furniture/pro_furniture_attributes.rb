# encoding: UTF-8

require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProFurnitureAttributes

      DICTIONARY_NAME = "projeta_plus_furniture".freeze
      CM_TO_INCHES = 2.54

      # Furniture type colors for annotations
      TYPE_COLORS = {
        "Furniture" => Sketchup::Color.new(139, 69, 19),      # Brown
        "Appliances" => Sketchup::Color.new(70, 130, 180),    # Steel Blue
        "Fixtures" => Sketchup::Color.new(60, 179, 113),      # Medium Sea Green
        "Accessories" => Sketchup::Color.new(255, 140, 0),    # Dark Orange
        "Decoration" => Sketchup::Color.new(186, 85, 211),    # Medium Orchid
        "Other" => Sketchup::Color.new(128, 128, 128)         # Gray
      }.freeze

      # Selection observer and cache
      @selection_observer = nil
      @instances_cache = {}
      @cache_timestamp = 0
      @processing_selection = false
      @last_processed_selection = nil

      # ========== Attribute Management ==========

      def self.initialize_default_attributes(component)
        default_attributes = {
          "name" => "",
          "color" => "",
          "brand" => "",
          "type" => "",
          "dimension_format" => "L x P x A",
          "dimension" => "",
          "environment" => "",
          "value" => "",
          "link" => "",
          "observations" => "",
          "code" => ""
        }

        default_attributes.each do |attr_name, default_value|
          current_value = get_attribute_safe(component, attr_name, nil)
          if current_value.nil? || current_value.empty?
            set_attribute_safe(component, attr_name, default_value)
          end
        end

        # Set current dimension if not exists
        if get_attribute_safe(component, "dimension", "").empty?
          dimension_format = get_attribute_safe(component, "dimension_format", "L x P x A")
          current_dim = calculate_dimension_string(component, dimension_format)
          set_attribute_safe(component, "dimension", current_dim)
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

      # ========== Dimension Calculations ==========

      def self.calculate_dimension_string(entity, format = "L x P x A")
        component = entity.is_a?(Sketchup::Group) ? entity.to_component : entity
        bounds = component.bounds

        width = format_number(bounds.width.to_f * CM_TO_INCHES)
        depth = format_number(bounds.depth.to_f * CM_TO_INCHES)
        height = format_number(bounds.height.to_f * CM_TO_INCHES)

        case format
        when "L x P x A" then "#{width} x #{depth} x #{height} cm"
        when "L x P" then "#{width} x #{depth} cm"
        when "L x A" then "#{width} x #{height} cm"
        when "SEM DIMENSÃO" then ""
        else "#{width} x #{depth} x #{height} cm"
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
        bounds = entity.bounds
        # SketchUp bounds: width (X), depth (Y), height (Z)
        # Note: bounds.depth is Z axis (height), bounds.height is Y axis (depth)
        {
          width: format_number(bounds.width.to_f * CM_TO_INCHES),
          depth: format_number(bounds.height.to_f * CM_TO_INCHES),
          height: format_number(bounds.depth.to_f * CM_TO_INCHES)
        }
      end

      # ========== Component Name Generation ==========

      def self.generate_clean_name(name, brand, dimension)
        parts = []
        parts << name unless name.nil? || name.strip.empty?
        parts << brand unless brand.nil? || brand.strip.empty?
        parts << dimension unless dimension.nil? || dimension.strip.empty?

        clean_name = parts.join(" - ")
        copy_to_clipboard(clean_name)
        clean_name
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

      # ========== Component Collection ==========

      def self.collect_all_furniture_instances(entities, arr, level=0)
        return if level > 5

        begin
          entities.each do |e|
            next unless e && e.valid?

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

            next unless component && component.valid?

            begin
              type = get_attribute_safe(component, "type", "").to_s.strip
              arr << component unless type.empty?
            rescue => e
              puts "ERROR reading attributes: #{e.message}"
              next
            end

            if component.definition && component.definition.valid? && component.definition.entities
              begin
                collect_all_furniture_instances(component.definition.entities, arr, level+1)
              rescue => e
                puts "ERROR in recursion: #{e.message}"
                next
              end
            end
          end
        rescue => e
          puts "ERROR in collect_all_furniture_instances: #{e.message}"
        end
      end

      def self.find_component_by_id(entities, target_id, level=0)
        return nil if level > 10
        entities.each do |e|
          next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
          component = e.is_a?(Sketchup::Group) ? e.to_component : e
          return component if component.entityID == target_id

          if component.definition && component.definition.entities
            found = find_component_by_id(component.definition.entities, target_id, level+1)
            return found if found
          end
        end
        nil
      end

      # ========== Cache Management ==========

      def self.get_cached_instances(model)
        current_time = Time.now.to_f

        if @instances_cache.empty? || current_time - @cache_timestamp > 2.0
          @instances_cache.clear
          instances = []
          collect_all_furniture_instances(model.entities, instances)

          instances.each do |inst|
            type = get_attribute_safe(inst, "type", "").to_s.strip
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

      # ========== Resizing Operations ==========

      def self.resize_proportional(entity, scale_factor)
        return unless entity && entity.valid? && scale_factor.to_f > 0

        bounds = entity.bounds
        origin = bounds.min

        model = Sketchup.active_model
        model.start_operation(ProjetaPlus::Localization.t('commands.resize_proportional'), true)
        entity.transform!(Geom::Transformation.scaling(origin, scale_factor.to_f))
        model.commit_operation
      rescue => e
        model.abort_operation if model
        puts "ERROR in resize_proportional: #{e.message}"
      end

      def self.resize_independent(entity, new_width, new_depth, new_height)
        return unless entity && entity.valid?

        new_width_f = new_width.to_f
        new_depth_f = new_depth.to_f
        new_height_f = new_height.to_f

        return unless new_width_f > 0 && new_depth_f > 0 && new_height_f > 0

        bounds = entity.bounds
        current_width_cm = bounds.width * CM_TO_INCHES
        current_depth_cm = bounds.depth * CM_TO_INCHES
        current_height_cm = bounds.height * CM_TO_INCHES

        return if current_width_cm <= 0 || current_depth_cm <= 0 || current_height_cm <= 0

        scale_x = new_width_f / current_width_cm
        scale_y = new_depth_f / current_depth_cm
        scale_z = new_height_f / current_height_cm
        origin = bounds.min

        model = Sketchup.active_model
        model.start_operation(ProjetaPlus::Localization.t('commands.resize_independent'), true)
        entity.transform!(Geom::Transformation.scaling(origin, scale_x, scale_z, scale_y))
        model.commit_operation
      rescue => e
        model.abort_operation if model
        puts "ERROR in resize_independent: #{e.message}"
      end

      # ========== Save Attributes ==========

      def self.save_furniture_attributes(component, attributes)
        return { success: false, message: ProjetaPlus::Localization.t('messages.no_component_selected') } unless component

        begin
          attributes.each do |key, value|
            set_attribute_safe(component, key, value)
          end

          # Generate and set clean name
          name = attributes['name']
          brand = attributes['brand']
          dimension = attributes['dimension']

          clean_name = generate_clean_name(name, brand, dimension)
          component.definition.name = clean_name

          { success: true, message: ProjetaPlus::Localization.t('messages.attributes_saved_success') }
        rescue => e
          { success: false, message: "#{ProjetaPlus::Localization.t('messages.error_saving_attributes')}: #{e.message}" }
        end
      end

      # ========== Visibility Operations ==========

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
        model = Sketchup.active_model
        
        # Navigate to 'general' scene if exists
        scene_name = "general"
        scene = model.pages.find { |p| p.name.downcase == scene_name.downcase }
        model.pages.selected_page = scene if scene

        model.start_operation(ProjetaPlus::Localization.t('commands.isolate_item'), true)

        # Find highest parent
        current = target
        highest_parent = current

        while current.respond_to?(:parent) && !current.parent.is_a?(Sketchup::Model)
          break unless current.is_a?(Sketchup::Group) || current.is_a?(Sketchup::ComponentInstance)
          highest_parent = current
          current = current.parent
        end

        # Select and isolate
        model.selection.clear
        model.selection.add(highest_parent)

        model.entities.each do |e|
          e.visible = highest_parent == e || 
                     (e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)) && 
                     highest_parent.definition.entities.include?(e)
        end

        model.commit_operation

        # Adjust camera
        view = model.active_view
        eye = Geom::Point3d.new(-1000, -1000, 1000)
        target_pt = Geom::Point3d.new(0, 0, 0)
        up = Geom::Vector3d.new(0, 0, 1)

        view.camera.set(eye, target_pt, up)
        view.camera.perspective = true
        view.zoom_extents
      rescue => e
        model.abort_operation if model
        puts "ERROR in isolate_item: #{e.message}"
      end

      # ========== Type Management ==========

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

