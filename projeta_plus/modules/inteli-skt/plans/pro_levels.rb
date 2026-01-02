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
        
        model.start_operation("Remover Nível", true)
        
        # Remover cenas e section planes
        ['base', 'forro'].each do |type|
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
        
        model.commit_operation
        
        {
          success: true,
          message: "Nível '#{level.name}' removido com sucesso"
        }
      rescue => e
        model.abort_operation if model
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
        
        model.start_operation("Criar Cena Base", true)
        
        unless scene
          # Calcular altura do corte
          cut_height_meters = level.base_cut_height
          cut_height = cut_height_meters.m + 0.05.m
          
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
          
          level.has_base = true
          save_levels(levels)
        end
        
        # Aplicar configurações se disponível (do JSON configurado)
        apply_plan_config_if_available(scene_name, 'base')
        
        # Garantir que o section plane está ativo e a cena está selecionada
        scene = model.pages.find { |s| s.name == scene_name }
        model.pages.selected_page = scene if scene
        
        sp = model.entities.find { |e| e.is_a?(Sketchup::SectionPlane) && e.name == scene_name }
        if sp
          sp.activate
          puts "Section plane '#{scene_name}' ativado"
        end
        
        model.commit_operation
        
        {
          success: true,
          message: scene_existed ? "Cena '#{scene_name}' atualizada!" : "Cena '#{scene_name}' criada com sucesso!"
        }
      rescue => e
        model.abort_operation if model
        { success: false, message: "Erro ao criar cena base: #{e.message}" }
      end
      
      def self.create_ceiling_scene(number)
        levels = load_levels
        level = levels.find { |l| l.number == number.to_i }
        
        return { success: false, message: "Nível não encontrado" } unless level
        
        model = Sketchup.active_model
        scene_name = generate_scene_name('forro', number)
        scene = model.pages.find { |s| s.name == scene_name }
        
        scene_existed = !scene.nil?
        
        model.start_operation("Criar Cena Forro", true)
        
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
          camera.set([0, 0, -100.m], [0, 0, 0], [0, 1, 0])
          model.active_view.camera = camera
          model.active_view.camera.perspective = false
          model.active_view.zoom_extents
          
          # Criar cena
          model.pages.add(scene_name)
          scene = model.pages.find { |s| s.name == scene_name }
          
          level.has_ceiling = true
          save_levels(levels)
        end
        
        # Aplicar configurações se disponível (do JSON configurado)
        apply_plan_config_if_available(scene_name, 'forro')
        
        # Garantir que o section plane está ativo e a cena está selecionada
        scene = model.pages.find { |s| s.name == scene_name }
        model.pages.selected_page = scene if scene
        
        sp = model.entities.find { |e| e.is_a?(Sketchup::SectionPlane) && e.name == scene_name }
        if sp
          sp.activate
          puts "Section plane '#{scene_name}' ativado"
        end
        
        model.commit_operation
        
        {
          success: true,
          message: scene_existed ? "Cena '#{scene_name}' atualizada!" : "Cena '#{scene_name}' criada com sucesso!"
        }
      rescue => e
        model.abort_operation if model
        { success: false, message: "Erro ao criar cena de forro: #{e.message}" }
      end
      
      # ========================================
      # MÉTODOS AUXILIARES
      # ========================================
      
      def self.generate_scene_name(type, number)
        # Capitalizar a primeira letra do tipo
        type_capitalized = type.capitalize
        # Nível 1 não leva número, demais levam underscore + número
        number.to_i == 1 ? type_capitalized : "#{type_capitalized}_#{number}"
      end
      
      def self.apply_plan_config_if_available(scene_name, config_type)
        begin
          # Carregar configurações do ProBasePlans
          require_relative 'pro_base_plans.rb'
          
          base_plans_result = ProjetaPlus::Modules::ProBasePlans.get_base_plans
          return unless base_plans_result[:success] && base_plans_result[:plans]
          
          # Encontrar a configuração correspondente
          config_plan = base_plans_result[:plans].find { |p| p[:id] == config_type }
          return unless config_plan
          
          model = Sketchup.active_model
          scene = model.pages.find { |s| s.name == scene_name }
          return unless scene
          
          puts "Aplicando configuração '#{config_type}' para cena '#{scene_name}'"
          puts "  Estilo: #{config_plan[:style]}"
          puts "  Camadas: #{config_plan[:activeLayers].length} camadas"
          
          model.start_operation("Aplicar Configuração", true)
          
          # Selecionar a cena
          model.pages.selected_page = scene
          
          # Aplicar estilo
          if config_plan[:style] && !config_plan[:style].empty?
            apply_style(config_plan[:style])
          end
          
          # Aplicar visibilidade das camadas
          if config_plan[:activeLayers] && config_plan[:activeLayers].any?
            apply_layers_visibility(config_plan[:activeLayers])
          end
          
          # Zoom total (centralizar modelo)
          model.active_view.zoom_extents
          puts "  Zoom total aplicado"
          
          # Atualizar a cena
          scene.update
          
          # Reativar section plane
          sp = model.entities.find { |e| e.is_a?(Sketchup::SectionPlane) && e.name == scene_name }
          if sp
            sp.activate
            puts "  Section plane reativado"
          end
          
          model.commit_operation
          
          puts "Configuração aplicada com sucesso!"
        rescue => e
          model.abort_operation if model
          puts "Aviso: Não foi possível aplicar configurações: #{e.message}"
          puts e.backtrace.join("\n")
        end
      end
      
      def self.apply_style(style_name)
        model = Sketchup.active_model
        styles_path = File.join(File.dirname(File.dirname(__FILE__)), 'styles')
        
        # Tentar carregar da pasta styles
        style_file_path = File.join(styles_path, "#{style_name}.style")
        
        if File.exist?(style_file_path)
          begin
            model.styles.add_style(style_file_path, true)
            imported_style = model.styles.find { |s| s.name == style_name }
            if imported_style
              model.styles.selected_style = imported_style
              puts "  Estilo '#{style_name}' aplicado"
            end
            return
          rescue => e
            puts "  Erro ao importar estilo #{style_name}: #{e.message}"
          end
        end
        
        # Fallback: buscar estilo já existente no modelo
        style = model.styles.find { |s| s.name == style_name }
        if style
          model.styles.selected_style = style
          puts "  Estilo '#{style_name}' (do modelo) aplicado"
        else
          puts "  Estilo '#{style_name}' não encontrado"
        end
      end
      
      def self.apply_layers_visibility(active_layers)
        model = Sketchup.active_model
        
        # Ocultar todas as camadas primeiro
        model.layers.each { |layer| layer.visible = false }
        
        # Mostrar apenas as camadas ativas
        active_layers.each do |layer_name|
          layer = model.layers.find { |l| l.name == layer_name }
          layer.visible = true if layer
        end
        
        puts "  #{active_layers.length} camadas ativadas"
      end
      
    end
  end
end
