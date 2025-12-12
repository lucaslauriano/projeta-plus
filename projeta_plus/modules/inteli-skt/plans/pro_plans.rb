# encoding: UTF-8
require 'sketchup.rb'
require 'json'
require_relative '../shared/pro_view_configs_base.rb'
require_relative 'pro_levels.rb'

module ProjetaPlus
  module Modules
    module ProPlans
      extend ProjetaPlus::Modules::ProViewConfigsBase

      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================

      ENTITY_NAME = "plans"
      SETTINGS_KEY = "plans_settings"

      # Paths para arquivos JSON e estilos
      PLUGIN_PATH = File.dirname(__FILE__)
      JSON_DATA_PATH = File.join(PLUGIN_PATH, 'json_data')
      STYLES_PATH = File.join(File.dirname(PLUGIN_PATH), 'styles')  # Compartilhado com scenes
      DEFAULT_DATA_FILE = File.join(JSON_DATA_PATH, 'plans_data.json')
      USER_DATA_FILE = File.join(JSON_DATA_PATH, 'user_plans_data.json')

      # ========================================
      # MÉTODOS PÚBLICOS ESPECÍFICOS
      # ========================================

      # Wrapper para get_items com nome específico
      def self.get_plans
        get_items
      end

      # Wrapper para add_item com nome específico
      def self.add_plan(params)
        add_item(params)
      end

      # Wrapper para update_item com nome específico
      def self.update_plan(name, params)
        update_item(name, params)
      end

      # Wrapper para delete_item com nome específico
      def self.delete_plan(name)
        delete_item(name)
      end

      # Wrapper para apply_config com nome específico
      def self.apply_plan_config(name, config)
        apply_config(name, config)
      end

      # ========================================
      # MÉTODOS DE NÍVEIS (LEVELS)
      # ========================================

      def self.get_levels
        ProjetaPlus::Modules::ProLevels.get_levels
      end

      def self.add_level(height_str)
        ProjetaPlus::Modules::ProLevels.add_level(height_str)
      end

      def self.remove_level(number)
        ProjetaPlus::Modules::ProLevels.remove_level(number)
      end

      def self.create_base_scene(number)
        ProjetaPlus::Modules::ProLevels.create_base_scene(number)
      end

      def self.create_ceiling_scene(number)
        ProjetaPlus::Modules::ProLevels.create_ceiling_scene(number)
      end

    end
  end
end
