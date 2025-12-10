# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module ProScenes

      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================

      SETTINGS_KEY = "scenes_settings"

      # Paths para arquivos JSON
      PLUGIN_PATH = File.dirname(__FILE__)
      JSON_DATA_PATH = File.join(PLUGIN_PATH, 'json_data')
      DEFAULT_DATA_FILE = File.join(JSON_DATA_PATH, 'scenes_data.json')
      USER_DATA_FILE = File.join(JSON_DATA_PATH, 'user_scenes_data.json')

      # ========================================
      # MÉTODOS PÚBLICOS
      # ========================================

      # Retorna todas as cenas do modelo com suas configurações
      def self.get_scenes
        begin
          model = Sketchup.active_model
          scenes = []

          model.pages.each do |page|
            scene_config = {
              id: page.name,
              name: page.name,
              style: page.style ? page.style.name : '',
              cameraType: detect_camera_type(page),
              activeLayers: get_page_visible_layers(page)
            }
            scenes << scene_config
          end

          {
            success: true,
            scenes: scenes,
            message: "#{scenes.length} cenas carregadas"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar cenas: #{e.message}",
            scenes: []
          }
        end
      end

      # Adiciona nova cena ao modelo
      def self.add_scene(params)
        begin
          model = Sketchup.active_model
          name = params['name'] || params[:name]
          style = params['style'] || params[:style]
          camera_type = params['cameraType'] || params[:cameraType]
          active_layers = params['activeLayers'] || params[:activeLayers] || []

          # Validar parâmetros
          valid, error_msg = validate_scene_params(name, style, camera_type)
          return { success: false, message: error_msg } unless valid

          # Verificar se já existe
          if model.pages.find { |p| p.name.downcase == name.downcase }
            return { success: false, message: "Cena '#{name}' já existe" }
          end

          model.start_operation('Adicionar Cena', true)

          # Aplicar configurações antes de criar a cena
          apply_style(style) if style && !style.empty?
          apply_layers_visibility(active_layers)

          # Criar a cena
          page = model.pages.add(name)

          # Configurar câmera
          apply_camera_config(page, camera_type) if camera_type

          # Zoom extents e atualizar
          model.active_view.zoom_extents
          page.update

          model.commit_operation

          {
            success: true,
            message: "Cena '#{name}' criada com sucesso",
            scene: {
              id: page.name,
              name: page.name,
              style: style,
              cameraType: camera_type,
              activeLayers: active_layers
            }
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao criar cena: #{e.message}"
          }
        end
      end

      # Atualiza cena existente
      def self.update_scene(name, params)
        begin
          model = Sketchup.active_model
          page = model.pages.find { |p| p.name.downcase == name.downcase }

          unless page
            return { success: false, message: "Cena '#{name}' não encontrada" }
          end

          new_name = params['name'] || params[:name]
          style = params['style'] || params[:style]
          camera_type = params['cameraType'] || params[:cameraType]
          active_layers = params['activeLayers'] || params[:activeLayers]

          model.start_operation('Atualizar Cena', true)

          # Selecionar a cena
          model.pages.selected_page = page

          # Aplicar estilo
          apply_style(style) if style && !style.empty?

          # Aplicar visibilidade de camadas
          apply_layers_visibility(active_layers) if active_layers

          # Aplicar configuração de câmera
          apply_camera_config(page, camera_type) if camera_type

          # Renomear se necessário
          if new_name && new_name != name
            page.name = new_name
          end

          # Atualizar a cena
          model.active_view.zoom_extents
          page.update

          model.commit_operation

          {
            success: true,
            message: "Cena '#{name}' atualizada com sucesso"
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao atualizar cena: #{e.message}"
          }
        end
      end

      # Remove cena do modelo
      def self.delete_scene(name)
        begin
          model = Sketchup.active_model
          page = model.pages.find { |p| p.name.downcase == name.downcase }

          unless page
            return { success: false, message: "Cena '#{name}' não encontrada" }
          end

          model.start_operation('Remover Cena', true)
          model.pages.erase(page)
          model.commit_operation

          {
            success: true,
            message: "Cena '#{name}' removida com sucesso"
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao remover cena: #{e.message}"
          }
        end
      end

      # Aplica configuração a uma cena (cria se não existir)
      def self.apply_scene_config(name, config)
        begin
          model = Sketchup.active_model
          
          # Aplicar estilo
          style = config['style'] || config[:style]
          apply_style(style) if style && !style.empty?
          
          # Aplicar visibilidade de camadas
          active_layers = config['activeLayers'] || config[:activeLayers]
          apply_layers_visibility(active_layers) if active_layers
          
          # Aplicar configuração de câmera
          camera_type = config['cameraType'] || config[:cameraType]
          if camera_type
            camera = model.active_view.camera
            camera_type_sym = camera_type.is_a?(String) ? camera_type.to_sym : camera_type
            
            case camera_type_sym
            when :iso_perspectiva, :iso
              configure_iso_camera_direct
              camera.perspective = true
            when :iso_ortogonal
              configure_iso_camera_direct
              camera.perspective = false
            when :iso_invertida_perspectiva
              configure_inverted_camera_direct
              camera.perspective = true
            when :iso_invertida_ortogonal
              configure_inverted_camera_direct
              camera.perspective = false
            when :topo_perspectiva, :topo
              configure_top_camera_direct
              camera.perspective = true
            when :topo_ortogonal
              configure_top_camera_direct
              camera.perspective = false
            end
            
            model.active_view.camera = camera
          end
          
          # Zoom extents
          model.active_view.zoom_extents
          
          {
            success: true,
            message: "Configuração aplicada com sucesso"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao aplicar configuração: #{e.message}"
          }
        end
      end

      # Retorna estilos disponíveis no modelo
      def self.get_available_styles
        begin
          model = Sketchup.active_model
          styles = []
          
          model.styles.each { |style| styles << style.name }
          
          {
            success: true,
            styles: styles.sort
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar estilos: #{e.message}",
            styles: []
          }
        end
      end

      # Retorna todas as camadas do modelo
      def self.get_available_layers
        begin
          model = Sketchup.active_model
          layers = []
          
          model.layers.each { |layer| layers << layer.name }
          
          {
            success: true,
            layers: layers.sort
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar camadas: #{e.message}",
            layers: []
          }
        end
      end

      # Retorna camadas atualmente visíveis
      def self.get_visible_layers
        begin
          model = Sketchup.active_model
          visible_layers = []
          
          model.layers.each do |layer|
            visible_layers << layer.name if layer.visible?
          end
          
          {
            success: true,
            layers: visible_layers.sort
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar camadas visíveis: #{e.message}",
            layers: []
          }
        end
      end

      # Retorna estado atual do modelo (estilo, câmera, camadas visíveis)
      def self.get_current_state
        begin
          model = Sketchup.active_model
          camera = model.active_view.camera
          
          current_style = model.styles.selected_style ? model.styles.selected_style.name : ''
          current_camera = detect_camera_type_from_camera(camera)
          visible_layers = []
          
          model.layers.each do |layer|
            visible_layers << layer.name if layer.visible?
          end
          
          {
            success: true,
            style: current_style,
            cameraType: current_camera,
            activeLayers: visible_layers.sort
          }
        rescue => e
          {
            success: false,
            message: "Erro ao obter estado atual: #{e.message}"
          }
        end
      end

      # ========================================
      # MÉTODOS DE PERSISTÊNCIA JSON
      # ========================================

      def self.save_to_json(json_data)
        begin
          ensure_json_directory
          
          File.write(USER_DATA_FILE, JSON.pretty_generate(json_data))
          
          {
            success: true,
            message: "Configurações salvas com sucesso",
            path: USER_DATA_FILE
          }
        rescue => e
          {
            success: false,
            message: "Erro ao salvar configurações: #{e.message}"
          }
        end
      end

      def self.load_from_json
        begin
          file_to_load = File.exist?(USER_DATA_FILE) ? USER_DATA_FILE : DEFAULT_DATA_FILE
          
          unless File.exist?(file_to_load)
            return {
              success: false,
              message: "Arquivo de configurações não encontrado",
              data: { groups: [], scenes: [] }
            }
          end
          
          content = File.read(file_to_load)
          content = remove_bom(content)
          data = JSON.parse(content)
          
          {
            success: true,
            data: data,
            message: "Configurações carregadas com sucesso"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar configurações: #{e.message}",
            data: { groups: [], scenes: [] }
          }
        end
      end

      def self.load_default_data
        begin
          unless File.exist?(DEFAULT_DATA_FILE)
            return {
              success: false,
              message: "Arquivo de dados padrão não encontrado",
              data: { groups: [], scenes: [] }
            }
          end
          
          content = File.read(DEFAULT_DATA_FILE)
          content = remove_bom(content)
          data = JSON.parse(content)
          
          # Salvar como arquivo do usuário
          ensure_json_directory
          File.write(USER_DATA_FILE, JSON.pretty_generate(data))
          
          {
            success: true,
            data: data,
            message: "Dados padrão carregados com sucesso"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar dados padrão: #{e.message}",
            data: { groups: [], scenes: [] }
          }
        end
      end

      def self.load_from_file
        begin
          file_path = UI.openpanel("Selecionar arquivo JSON", "", "JSON|*.json||")
          
          return { success: false, message: "Nenhum arquivo selecionado" } unless file_path
          
          content = File.read(file_path)
          content = remove_bom(content)
          data = JSON.parse(content)
          
          {
            success: true,
            data: data,
            message: "Arquivo carregado com sucesso"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar arquivo: #{e.message}",
            data: { groups: [], scenes: [] }
          }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS (auxiliares)
      # ========================================

      private

      def self.validate_scene_params(name, style, camera_type)
        return [false, "Nome da cena é obrigatório"] if name.nil? || name.strip.empty?
        [true, nil]
      end

      def self.apply_style(style_name)
        model = Sketchup.active_model
        style = model.styles.find { |s| s.name == style_name }
        model.styles.selected_style = style if style
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
      end


      def self.apply_camera_config(page, camera_type)
        model = Sketchup.active_model
        camera = model.active_view.camera
        
        camera_type_sym = camera_type.is_a?(String) ? camera_type.to_sym : camera_type
        
        case camera_type_sym
        when :iso_perspectiva, :iso
          configure_iso_camera(page)
          camera.perspective = true
        when :iso_ortogonal
          configure_iso_camera(page)
          camera.perspective = false
        when :iso_invertida_perspectiva
          configure_inverted_camera(page)
          camera.perspective = true
        when :iso_invertida_ortogonal
          configure_inverted_camera(page)
          camera.perspective = false
        when :topo_perspectiva, :topo
          configure_top_camera(page)
          camera.perspective = true
        when :topo_ortogonal
          configure_top_camera(page)
          camera.perspective = false
        end
        
        model.active_view.camera = camera
      end

      def self.configure_iso_camera(page)
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        # Câmera isométrica padrão
        eye = Geom::Point3d.new(center.x - 1000, center.y - 1000, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 0, 1)
        
        camera.set(eye, target, up)
        model.active_view.camera = camera
      end

      def self.configure_inverted_camera(page)
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        # Câmera isométrica invertida
        eye = Geom::Point3d.new(center.x + 1000, center.y + 1000, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 0, 1)
        
        camera.set(eye, target, up)
        model.active_view.camera = camera
      end

      def self.configure_top_camera(page)
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        # Vista de topo
        eye = Geom::Point3d.new(center.x, center.y, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 1, 0)
        
        camera.set(eye, target, up)
        model.active_view.camera = camera
      end

      # Métodos diretos para aplicar câmera (sem page)
      def self.configure_iso_camera_direct
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        eye = Geom::Point3d.new(center.x - 1000, center.y - 1000, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 0, 1)
        
        camera.set(eye, target, up)
      end

      def self.configure_inverted_camera_direct
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        eye = Geom::Point3d.new(center.x + 1000, center.y + 1000, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 0, 1)
        
        camera.set(eye, target, up)
      end

      def self.configure_top_camera_direct
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        eye = Geom::Point3d.new(center.x, center.y, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 1, 0)
        
        camera.set(eye, target, up)
      end

      def self.detect_camera_type(page)
        # Ler a câmera diretamente da página sem mudar a seleção
        camera = page.camera
        return :iso_perspectiva unless camera # Fallback se não houver câmera
        
        detect_camera_type_from_camera(camera)
      end

      def self.detect_camera_type_from_camera(camera)
        direction = camera.direction
        perspective = camera.perspective?
        
        # Vista de topo (direção Z negativa)
        if direction.z < -0.9
          return perspective ? :topo_perspectiva : :topo_ortogonal
        # Vista isométrica invertida (direção X e Y positivas)
        elsif direction.x > 0.3 && direction.y > 0.3
          return perspective ? :iso_invertida_perspectiva : :iso_invertida_ortogonal
        # Vista isométrica padrão
        else
          return perspective ? :iso_perspectiva : :iso_ortogonal
        end
      end

      def self.get_page_visible_layers(page)
        model = Sketchup.active_model
        visible_layers = []
        
        # Ler as camadas diretamente da página
        if page.layers && page.layers.respond_to?(:each)
          page.layers.each do |layer|
            visible_layers << layer.name if layer
          end
        else
          # Fallback: usar camadas visíveis do modelo atual
          model.layers.each do |layer|
            visible_layers << layer.name if layer.visible?
          end
        end
        
        visible_layers
      end

      def self.ensure_json_directory
        Dir.mkdir(JSON_DATA_PATH) unless Dir.exist?(JSON_DATA_PATH)
      end

      def self.remove_bom(content)
        content.sub("\xEF\xBB\xBF".force_encoding("UTF-8"), '')
      end

    end
  end
end
