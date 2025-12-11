# encoding: UTF-8
require 'sketchup.rb'
require 'json'
require_relative '../shared/pro_view_configs_base.rb'

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

    end
  end
end
