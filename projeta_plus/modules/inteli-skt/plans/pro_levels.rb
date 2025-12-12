# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module ProLevels
      
      ALTURA_CORTE_PADRAO = 1.50 # metros
      
      # ========================================
      # ESTRUTURA DE DADOS
      # ========================================
      
      class Level
        attr_accessor :number, :height_meters, :has_base, :has_ceiling
        
        def initialize(number, height_meters)
          @number = number
          @height_meters = height_meters.to_f
          @has_base = false
          @has_ceiling = false
        end
        
        def name
          number == 1 ? "Térreo" : "Pavimento #{number - 1}"
        end
        
        def base_cut_height
          @height_meters + ALTURA_CORTE_PADRAO + 0.10
        end
        
        def ceiling_cut_height
          @height_meters + ALTURA_CORTE_PADRAO + 0.05
        end
        
        def to_hash
          {
            'number' => @number,
            'height_meters' => @height_meters,
            'has_base' => @has_base,
            'has_ceiling' => @has_ceiling,
            'name' => name,
            'base_cut_height' => base_cut_height,
            'ceiling_cut_height' => ceiling_cut_height
          }
        end
        
        def self.from_hash(hash)
          level = new(hash['number'] || 1, hash['height_meters'] || 0.0)
          level.has_base = hash['has_base'] || false
          level.has_ceiling = hash['has_ceiling'] || false
          level
        end
      end
      
      # ========================================
      # PERSISTÊNCIA
      # ========================================
      
      def self.save_levels(levels)
        model = Sketchup.active_model
        dict = model.attribute_dictionary('ProjetaPlus_Levels', true)
        dict['levels'] = levels.map(&:to_hash).to_json
        { success: true, message: "Níveis salvos com sucesso" }
      rescue => e
        { success: false, message: "Erro ao salvar níveis: #{e.message}" }
      end
      
      def self.load_levels
        model = Sketchup.active_model
        dict = model.attribute_dictionary('ProjetaPlus_Levels')
        
        return [] unless dict && dict['levels']
        
        levels_data = JSON.parse(dict['levels'])
        levels_data.map { |h| Level.from_hash(h) }
      rescue => e
        puts "Erro ao carregar níveis: #{e.message}"
        []
      end
      
      # ========================================
      # MÉTODOS PÚBLICOS
      # ========================================
      
      def self.get_levels
        levels = load_levels
        {
          success: true,
          levels: levels.map(&:to_hash)
        }
      rescue => e
        { success: false, message: e.message, levels: [] }
      end
      
      def self.add_level(height_str)
        levels = load_levels
        
        height = height_str.to_s.tr(',', '.').to_f
        number = levels.empty? ? 1 : levels.map(&:number).max + 1
        
        level = Level.new(number, height)
        levels << level
        
        save_levels(levels)
        
        {
          success: true,
          message: "Nível '#{level.name}' adicionado com sucesso",
          level: level.to_hash
        }
      rescue => e
        { success: false, message: "Erro ao adicionar nível: #{e.message}" }
      end
      
      def self.remove_level(number)
        levels = load_levels
        level = levels.find { |l| l.number == number.to_i }
        
        return { success: false, message: "Nível não encontrado" } unless level
        
        model = Sketchup.active_model
        
        # Remover cenas e section planes
        ['base', 'ceiling'].each do |type|
          scene_name = generate_scene_name(type, number)
          
          # Remover cena
          scene = model.pages.find { |s| s.name == scene_name }
          model.pages.erase(scene) if scene
          
          # Remover section plane
          sp = model.entities.find { |e| e.is_a?(Sketchup::SectionPlane) && e.name == scene_name }
          sp.erase! if sp
        end
        
        levels.delete(level)
        save_levels(levels)
        
        {
          success: true,
          message: "Nível '#{level.name}' removido com sucesso"
        }
      rescue => e
        { success: false, message: "Erro ao remover nível: #{e.message}" }
      end
      
      def self.create_base_scene(number)
        levels = load_levels
        level = levels.find { |l| l.number == number.to_i }
        
        return { success: false, message: "Nível não encontrado" } unless level
        
        model = Sketchup.active_model
        scene_name = generate_scene_name('base', number)
        scene = model.pages.find { |s| s.name == scene_name }
        
        scene_existed = !scene.nil?
        
        unless scene
          # Calcular altura do corte
          cut_height_meters = level.base_cut_height
          cut_height = cut_height_meters.m
          
          # Criar section plane (plano horizontal voltado para baixo)
          sp = model.entities.add_section_plane([0, 0, cut_height], [0, 0, -1])
          sp.name = scene_name
          sp.activate
          
          # Configurar vista de topo
          camera = model.active_view.camera
          camera.set([0, 0, 100.m], [0, 0, 0], [0, 1, 0])
          model.active_view.camera = camera
          model.active_view.camera.perspective = false
          model.active_view.zoom_extents
          
          # Criar cena
          model.pages.add(scene_name)
          scene = model.pages.find { |s| s.name == scene_name }
          model.pages.selected_page = scene
          
          sp.activate
          
          level.has_base = true
          save_levels(levels)
        end
        
        # Aplicar configurações se disponível
        apply_plan_config_if_available(scene_name, 'base')
        
        # Reativar section plane
        sp = model.entities.find { |e| e.is_a?(Sketchup::SectionPlane) && e.name == scene_name }
        sp.activate if sp
        
        {
          success: true,
          message: scene_existed ? "Cena '#{scene_name}' atualizada!" : "Cena '#{scene_name}' criada com sucesso!"
        }
      rescue => e
        { success: false, message: "Erro ao criar cena base: #{e.message}" }
      end
      
      def self.create_ceiling_scene(number)
        levels = load_levels
        level = levels.find { |l| l.number == number.to_i }
        
        return { success: false, message: "Nível não encontrado" } unless level
        
        model = Sketchup.active_model
        scene_name = generate_scene_name('ceiling', number)
        scene = model.pages.find { |s| s.name == scene_name }
        
        scene_existed = !scene.nil?
        
        unless scene
          # Calcular altura do corte
          cut_height_meters = level.ceiling_cut_height
          cut_height = cut_height_meters.m
          
          # Criar section plane (plano horizontal voltado para cima)
          sp = model.entities.add_section_plane([0, 0, cut_height], [0, 0, 1])
          sp.name = scene_name
          sp.activate
          
          # Configurar vista de baixo para cima
          camera = model.active_view.camera
          camera.set([0, 0, -1000], [0, 0, 0], [0, 1, 0])
          model.active_view.camera = camera
          model.active_view.camera.perspective = false
          model.active_view.zoom_extents
          
          # Criar cena
          model.pages.add(scene_name)
          scene = model.pages.find { |s| s.name == scene_name }
          model.pages.selected_page = scene
          
          sp.activate
          
          level.has_ceiling = true
          save_levels(levels)
        end
        
        # Aplicar configurações se disponível
        apply_plan_config_if_available(scene_name, 'ceiling')
        
        # Reativar section plane
        sp = model.entities.find { |e| e.is_a?(Sketchup::SectionPlane) && e.name == scene_name }
        sp.activate if sp
        
        {
          success: true,
          message: scene_existed ? "Cena '#{scene_name}' atualizada!" : "Cena '#{scene_name}' criada com sucesso!"
        }
      rescue => e
        { success: false, message: "Erro ao criar cena de forro: #{e.message}" }
      end
      
      # ========================================
      # MÉTODOS AUXILIARES
      # ========================================
      
      def self.generate_scene_name(type, number)
        number.to_i == 1 ? type : "#{type}#{number}"
      end
      
      def self.apply_plan_config_if_available(scene_name, config_type)
        return unless defined?(ProjetaPlus::Modules::ProPlans)
        
        # Tentar aplicar configuração do ProPlans se existir
        ProjetaPlus::Modules::ProPlans.apply_plan_config(scene_name, { 'type' => config_type })
      rescue => e
        puts "Aviso: Não foi possível aplicar configurações: #{e.message}"
      end
      
    end
  end
end
