# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module ProDetails
      
      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================
      
      # Índice da câmera para alternar entre ângulos
      @camera_index = 0

      # Ângulos de câmera isométrica predefinidos
      CAMERA_ANGLES = [
        [1000, 1000, 1000],   # Frontal direita superior
        [-1000, 1000, 1000],  # Frontal esquerda superior
        [-1000, -1000, 1000], # Traseira esquerda superior
        [1000, -1000, 1000]   # Traseira direita superior
      ].freeze

      # Prefixo para camadas de detalhamento
      DETAIL_LAYER_PREFIX = "-DET-"

      # ========================================
      # MÉTODOS PÚBLICOS
      # ========================================

      def self.camera_index
        @camera_index
      end

      def self.camera_index=(value)
        @camera_index = value
      end

      # Cria uma camada de detalhamento para um grupo ou componente selecionado
      # @return [Hash] { success: Boolean, message: String, layer_name: String }
      def self.create_carpentry_detail
        model = Sketchup.active_model
        return { success: false, message: "Nenhum modelo ativo" } unless model
        
        # Valida seleção
        validation_result = validate_single_entity_selection(model)
        return validation_result unless validation_result[:success]

        entity = model.selection.first
        
        model.start_operation("Criar Detalhamento de Marcenaria", true)

        begin
          layer_name = generate_unique_layer_name(model)
          new_layer = model.layers.add(layer_name)
          entity.layer = new_layer

          model.commit_operation
          
          return { 
            success: true, 
            message: "Detalhe #{layer_name.upcase} criado com sucesso.",
            layer_name: layer_name
          }
        rescue => e
          model.abort_operation
          return { success: false, message: "Erro ao criar detalhamento: #{e.message}" }
        end
      end

      # Cria ou atualiza cenas para todas as camadas de detalhamento
      # @return [Hash] { success: Boolean, message: String, count: Integer }
      def self.create_general_details
        model = Sketchup.active_model
        return { success: false, message: "Nenhum modelo ativo" } unless model
        
        det_layers = get_detail_layers(model)

        if det_layers.empty?
          return { success: false, message: "Nenhuma camada de detalhamento encontrada. Crie camadas com prefixo #{DETAIL_LAYER_PREFIX} primeiro." }
        end

        model.start_operation("Criar/Atualizar Cenas de Detalhamento", true)

        begin
          det_layers.each do |current_layer|
            create_or_update_scene_for_layer(model, current_layer, det_layers)
          end

          model.commit_operation
          
          return { 
            success: true, 
            message: "#{det_layers.length} cena(s) criada(s)/atualizada(s) com sucesso.",
            count: det_layers.length
          }
        rescue => e
          model.abort_operation
          return { success: false, message: "Erro ao criar cenas: #{e.message}" }
        end
      end

      # Retorna lista de estilos disponíveis no modelo
      # @return [Hash] { success: Boolean, styles: Array, message: String }
      def self.get_styles
        model = Sketchup.active_model
        return { success: false, message: "Nenhum modelo ativo", styles: [] } unless model
        
        begin
          styles = model.styles.map(&:name)
          
          return { 
            success: true, 
            styles: styles,
            message: "#{styles.length} estilo(s) encontrado(s)"
          }
        rescue => e
          return { success: false, message: "Erro ao obter estilos: #{e.message}", styles: [] }
        end
      end

      # Duplica a cena atual com novo estilo e sufixo
      # @param params_json [String] JSON com { estilo: String, sufixo: String }
      # @return [Hash] { success: Boolean, message: String, scene_name: String }
      def self.duplicate_scene(params_json)
        begin
          params = JSON.parse(params_json)
          style_name = params['estilo']
          suffix = params['sufixo']

          # Valida parâmetros
          validation = validate_duplicate_params(style_name, suffix)
          return validation unless validation[:success]

          model = Sketchup.active_model
          return { success: false, message: "Nenhum modelo ativo" } unless model
          
          # Valida cena atual
          current_page = model.pages.selected_page
          unless current_page
            return { success: false, message: "Nenhuma cena selecionada. Selecione uma cena primeiro." }
          end
          
          unless current_page.name.downcase.start_with?('det-')
            return { success: false, message: "A cena selecionada deve começar com 'det-'. Cena atual: '#{current_page.name}'" }
          end

          # Valida nome duplicado
          new_name = "#{current_page.name}-#{suffix}"
          if model.pages.any? { |p| p.name.downcase == new_name.downcase }
            return { success: false, message: "Já existe uma cena com o nome '#{new_name}'. Escolha outro sufixo." }
          end

          # Valida estilo
          style = model.styles[style_name]
          unless style
            return { success: false, message: "Estilo '#{style_name}' não encontrado no modelo." }
          end

          model.start_operation("Duplicar Cena de Detalhamento", true)

          model.styles.selected_style = style
          model.active_view.zoom_extents
          model.pages.add(new_name)

          model.commit_operation
          
          return { 
            success: true, 
            message: "Cena '#{new_name}' criada com sucesso.",
            scene_name: new_name
          }
        rescue JSON::ParserError => e
          return { success: false, message: "Erro ao processar parâmetros: #{e.message}" }
        rescue => e
          model.abort_operation if model
          return { success: false, message: "Erro ao duplicar cena: #{e.message}" }
        end
      end

      # Alterna entre ângulos de câmera isométrica predefinidos
      # @return [Hash] { success: Boolean, message: String, angle_index: Integer }
      def self.toggle_perspective
        model = Sketchup.active_model
        return { success: false, message: "Nenhum modelo ativo" } unless model
        
        view = model.active_view
        pages = model.pages
        page = pages.selected_page
        
        unless page
          return { success: false, message: "Nenhuma cena selecionada. Selecione uma cena primeiro." }
        end
        
        begin
          # Avança índice do ângulo
          self.camera_index = (camera_index + 1) % CAMERA_ANGLES.length

          # Cria nova câmera com ângulo atual
          camera = Sketchup::Camera.new(
            CAMERA_ANGLES[camera_index],
            [0, 0, 0],
            [0, 0, 1],
            false  # ortográfica
          )

          view.camera = camera
          view.zoom_extents

          # Atualiza cena para salvar câmera
          page.use_camera = true
          page.update
          
          return { 
            success: true, 
            message: "Vista alternada para ângulo #{camera_index + 1} de #{CAMERA_ANGLES.length}.",
            angle_index: camera_index
          }
        rescue => e
          return { success: false, message: "Erro ao alternar vista: #{e.message}" }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS (auxiliares)
      # ========================================

      private

      # Valida se há uma única entidade selecionada (grupo ou componente)
      # @param model [Sketchup::Model]
      # @return [Hash] { success: Boolean, message: String }
      def self.validate_single_entity_selection(model)
        selection = model.selection
        
        unless selection.length == 1
          return { success: false, message: "Selecione um único grupo ou componente. Seleção atual: #{selection.length} entidade(s)." }
        end

        entity = selection.first
        unless entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
          return { success: false, message: "A entidade selecionada deve ser um grupo ou componente. Tipo atual: #{entity.class.name}" }
        end

        { success: true }
      end

      # Gera nome único para nova camada de detalhamento
      # @param model [Sketchup::Model]
      # @return [String] Nome da camada (ex: "-DET-1")
      def self.generate_unique_layer_name(model)
        existing_names = model.layers.map(&:name)
        number = 1
        number += 1 while existing_names.include?("#{DETAIL_LAYER_PREFIX}#{number}")
        "#{DETAIL_LAYER_PREFIX}#{number}"
      end

      # Retorna todas as camadas de detalhamento do modelo
      # @param model [Sketchup::Model]
      # @return [Array<Sketchup::Layer>]
      def self.get_detail_layers(model)
        model.layers.to_a.select { |l| l.name.start_with?(DETAIL_LAYER_PREFIX) }
      end

      # Cria ou atualiza cena para uma camada de detalhamento
      # @param model [Sketchup::Model]
      # @param current_layer [Sketchup::Layer]
      # @param all_detail_layers [Array<Sketchup::Layer>]
      def self.create_or_update_scene_for_layer(model, current_layer, all_detail_layers)
        pages = model.pages
        scene_name = current_layer.name[1..-1].downcase
        
        # Busca cena existente ou cria nova
        scene = pages.find { |p| p.name.downcase == scene_name }
        scene ||= pages.add(scene_name)
        
        pages.selected_page = scene

        # Configura câmera isométrica ortográfica
        camera = Sketchup::Camera.new(
          CAMERA_ANGLES[0],
          [0, 0, 0],
          [0, 0, 1],
          false
        )
        model.active_view.camera = camera

        # Oculta todas camadas de detalhamento exceto a atual
        all_detail_layers.each do |layer|
          layer.visible = (layer == current_layer)
        end

        model.active_view.zoom_extents
        scene.update
      end

      # Valida parâmetros para duplicação de cena
      # @param style_name [String]
      # @param suffix [String]
      # @return [Hash] { success: Boolean, message: String }
      def self.validate_duplicate_params(style_name, suffix)
        if suffix.nil? || suffix.strip.empty?
          return { success: false, message: "O sufixo da cena é obrigatório." }
        end

        if style_name.nil? || style_name.strip.empty?
          return { success: false, message: "O nome do estilo é obrigatório." }
        end

        { success: true }
      end

    end
  end
end
