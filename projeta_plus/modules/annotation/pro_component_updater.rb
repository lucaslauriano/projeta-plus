# encoding: UTF-8
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProComponentUpdater

      def self.get_defaults
        {
          last_attribute: Sketchup.read_default("ComponentUpdater", "last_attribute", "scale"),
          last_value: Sketchup.read_default("ComponentUpdater", "last_value", ""),
          last_situation_type: Sketchup.read_default("ComponentUpdater", "last_situation_type", "1")
        }
      end

      def self.update_component_attributes(args)
        model = Sketchup.active_model
        
        if model.nil?
          return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") }
        end

        selection = model.selection
        targets = selection.grep(Sketchup::ComponentInstance)

        if targets.empty?
          return { success: false, message: "No component selected." }
        end

        # Extract parameters from frontend args
        attribute_type = args['attribute_type'].to_s
        new_value = args['new_value'].to_s
        situation_type = args['situation_type'].to_s
        
        # Debug: Print received parameters
        puts "DEBUG: Received args: #{args.inspect}"
        puts "DEBUG: attribute_type: '#{attribute_type}'"
        puts "DEBUG: new_value: '#{new_value}'"
        puts "DEBUG: situation_type: '#{situation_type}'"

        # Map frontend attribute types to actual dynamic attribute names
        attribute_map = {
          'scale' => 'b002_escala',
          'environment' => 'c001a_ambiente', 
          'usage' => 'c002a_uso',
          'usagePrefix' => 'c002b_uso',
          'situation' => 'a002_situacao'
        }

        # Map frontend situation to internal values
        situation_map = {
          'new' => '1',
          'existing' => '2', 
          'modify' => '3',
          'remove' => '4'
        }

        # Get the actual attribute name
        actual_attribute = attribute_map[attribute_type]
        puts "DEBUG: attribute_map: #{attribute_map.inspect}"
        puts "DEBUG: actual_attribute: '#{actual_attribute}'"
        unless actual_attribute
          return { success: false, message: "Invalid attribute type: #{attribute_type}" }
        end

        # Get the actual situation value (if situation_type is provided)
        actual_situation = situation_type.empty? ? nil : situation_type

        # Determine the final value to set
        final_value = if attribute_type == 'situation'
                        actual_situation
                      else
                        new_value
                      end

        # Save preferences for next use
        Sketchup.write_default("ComponentUpdater", "last_attribute", attribute_type)
        Sketchup.write_default("ComponentUpdater", "last_value", new_value)
        Sketchup.write_default("ComponentUpdater", "last_situation_type", situation_type)

        model.start_operation("Update Attribute #{attribute_type}", true)

        begin
          targets.each_with_index do |instance, index|
            if defined?($dc_observers)
              dc = $dc_observers.get_latest_class

              # Apply value and force refresh
              instance.set_attribute("dynamic_attributes", actual_attribute, final_value)
              instance.set_attribute("dynamic_attributes", "_refresh", "TRUE")

              dc.set_attribute(instance, "dynamic_attributes", actual_attribute, final_value)
              dc.set_attribute(instance, "dynamic_attributes", "_refresh", "TRUE")

              # Redraw
              start_time = Time.now
              dc.redraw_with_undo(instance)
              duration = Time.now - start_time
              puts "#{duration.round(6)}s para redesenhar: #{instance.definition.name}"
            else
              puts "⚠ Plugin de Componentes Dinâmicos não disponível."
            end
          end

          model.commit_operation
          { success: true, message: ProjetaPlus::Localization.t("messages.component_updater_success") }
        rescue StandardError => e
          model.abort_operation
          { success: false, message: ProjetaPlus::Localization.t("messages.error_updating_components") + ": #{e.message}" }
        end
      end

    end # module ProComponentUpdater
  end # module Modules
end # module ProjetaPlus
