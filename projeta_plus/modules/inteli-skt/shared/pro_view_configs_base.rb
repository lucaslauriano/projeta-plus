# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module ProViewConfigsBase

      # ========================================
      # MÉTODOS PÚBLICOS GENÉRICOS
      # ========================================

      # Retorna todas as configurações do modelo
      def get_items
        entity_name_singular = self::ENTITY_NAME.chomp('s')
        begin
          model = Sketchup.active_model
          items = []

          model.pages.each do |page|
            item_config = {
              id: page.name,
              name: page.name,
              style: page.style ? page.style.name : '',
              cameraType: detect_camera_type(page),
              activeLayers: get_page_visible_layers(page)
            }
            items << item_config
          end

          {
            success: true,
            self::ENTITY_NAME.to_sym => items,
            message: "#{items.length} #{self::ENTITY_NAME} carregadas"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar #{self::ENTITY_NAME}: #{e.message}",
            self::ENTITY_NAME.to_sym => []
          }
        end
      end

      # Adiciona nova configuração ao modelo
      def add_item(params)
        entity_name_singular = self::ENTITY_NAME.chomp('s')
        begin
          model = Sketchup.active_model
          name = params['name'] || params[:name]
          style = params['style'] || params[:style]
          camera_type = params['cameraType'] || params[:cameraType]
          active_layers = params['activeLayers'] || params[:activeLayers] || []

          # Validar parâmetros
          valid, error_msg = validate_params(name, style, camera_type)
          return { success: false, message: error_msg } unless valid

          # Verificar se já existe
          if model.pages.find { |p| p.name.downcase == name.downcase }
            return { success: false, message: "#{entity_name_singular.capitalize} '#{name}' já existe" }
          end

          model.start_operation("Adicionar #{entity_name_singular.capitalize}", true)

          # Aplicar configurações antes de criar
          apply_style(style) if style && !style.empty?
          apply_layers_visibility(active_layers)

          # Criar a página
          page = model.pages.add(name)

          # Configurar câmera
          apply_camera_config(page, camera_type) if camera_type

          # Zoom extents e atualizar
          model.active_view.zoom_extents
          page.update

          model.commit_operation

          {
            success: true,
            message: "#{entity_name_singular.capitalize} '#{name}' criada com sucesso",
            entity_name_singular.to_sym => {
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
            message: "Erro ao criar #{entity_name_singular}: #{e.message}"
          }
        end
      end

      # Atualiza configuração existente
      def update_item(name, params)
        entity_name_singular = self::ENTITY_NAME.chomp('s')
        begin
          model = Sketchup.active_model
          page = model.pages.find { |p| p.name.downcase == name.downcase }

          unless page
            return { success: false, message: "#{entity_name_singular.capitalize} '#{name}' não encontrada" }
          end

          style = params['style'] || params[:style]
          camera_type = params['cameraType'] || params[:cameraType]
          active_layers = params['activeLayers'] || params[:activeLayers]

          model.start_operation("Atualizar #{entity_name_singular.capitalize}", true)

          # Selecionar a página
          model.pages.selected_page = page

          # Aplicar estilo
          apply_style(style) if style && !style.empty?

          # Aplicar visibilidade de camadas
          apply_layers_visibility(active_layers) if active_layers

          # Aplicar configuração de câmera
          apply_camera_config(page, camera_type) if camera_type

          # Atualizar a página (sem renomear - usuário cria nova cena se quiser nome diferente)
          model.active_view.zoom_extents
          page.update

          model.commit_operation

          {
            success: true,
            message: "#{entity_name_singular.capitalize} '#{name}' atualizada com sucesso"
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao atualizar #{entity_name_singular}: #{e.message}"
          }
        end
      end

      # Remove configuração do modelo
      def delete_item(name)
        entity_name_singular = self::ENTITY_NAME.chomp('s')
        begin
          model = Sketchup.active_model
          page = model.pages.find { |p| p.name.downcase == name.downcase }

          unless page
            return { success: false, message: "#{entity_name_singular.capitalize} '#{name}' não encontrada" }
          end

          model.start_operation("Remover #{entity_name_singular.capitalize}", true)
          model.pages.erase(page)
          model.commit_operation

          {
            success: true,
            message: "#{entity_name_singular.capitalize} '#{name}' removida com sucesso"
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao remover #{entity_name_singular}: #{e.message}"
          }
        end
      end

      # Aplica configuração (cria se não existir)
      def apply_config(name, config)
        entity_name_singular = self::ENTITY_NAME.chomp('s')
        begin
          model = Sketchup.active_model
          
          # Detectar número do nível da cena atual
          level_number = detect_level_number_from_current_scene(model)
          
          # Adicionar número ao nome se estiver em uma cena de nível específico
          final_name = level_number > 1 ? "#{name}#{level_number}" : name
          
          page = model.pages.find { |p| p.name.downcase == final_name.downcase }
          
          model.start_operation("Aplicar Configuração de #{entity_name_singular.capitalize}", true)
          
          # Reexibir todos os elementos ocultos
          unhide_all_elements
          
          # Criar página se não existir ou selecionar se já existe
          if page
            model.pages.selected_page = page
            message = "#{entity_name_singular.capitalize} '#{final_name}' atualizada com sucesso"
          else
            page = model.pages.add(final_name)
            message = "#{entity_name_singular.capitalize} '#{final_name}' criada com sucesso"
          end
          
          # Aplicar configurações
          style = config['style'] || config[:style]
          apply_style(style) if style && !style.empty?
          
          active_layers = config['activeLayers'] || config[:activeLayers]
          apply_layers_visibility(active_layers) if active_layers
          
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
          
          model.active_view.zoom_extents
          page.update
          model.commit_operation
          
          {
            success: true,
            message: message
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao aplicar configuração: #{e.message}"
          }
        end
      end

      # Retorna estilos disponíveis
      def get_available_styles
        begin
          styles = []
          
          # Ler arquivos .style da pasta
          if Dir.exist?(self::STYLES_PATH)
            Dir.glob(File.join(self::STYLES_PATH, '*.style')).each do |file_path|
              style_name = File.basename(file_path, '.style')
              styles << style_name
            end
          end
          
          # Fallback: usar os do modelo
          if styles.empty?
            model = Sketchup.active_model
            model.styles.each { |style| styles << style.name }
          end
          
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
      def get_available_layers
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
      def get_visible_layers
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

      # Retorna estado atual do modelo
      def get_current_state
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

      def save_to_json(json_data)
        begin
          ensure_json_directory
          
          File.write(self::USER_DATA_FILE, JSON.pretty_generate(json_data))
          
          {
            success: true,
            message: "Sucesso ao salvar configurações",
            path: self::USER_DATA_FILE
          }
        rescue => e
          {
            success: false,
            message: "Erro ao salvar configurações: #{e.message}"
          }
        end
      end

      def load_from_json
        entity_name_singular = self::ENTITY_NAME.chomp('s')
        begin
          file_to_load = File.exist?(self::USER_DATA_FILE) ? self::USER_DATA_FILE : self::DEFAULT_DATA_FILE
          
          unless File.exist?(file_to_load)
            return {
              success: false,
              message: "Arquivo de configurações não encontrado",
              data: { groups: [], self::ENTITY_NAME.to_sym => [] }
            }
          end
          
          content = File.read(file_to_load)
          content = remove_bom(content)
          data = JSON.parse(content)
          
          {
            success: true,
            data: data,
            message: "Sucesso ao carregar configurações"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar configurações: #{e.message}",
            data: { groups: [], self::ENTITY_NAME.to_sym => [] }
          }
        end
      end

      def load_default_data
        entity_name_singular = self::ENTITY_NAME.chomp('s')
        begin
          unless File.exist?(self::DEFAULT_DATA_FILE)
            return {
              success: false,
              message: "Arquivo de dados padrão não encontrado",
              data: { groups: [], self::ENTITY_NAME.to_sym => [] }
            }
          end
          
          content = File.read(self::DEFAULT_DATA_FILE)
          content = remove_bom(content)
          data = JSON.parse(content)
          
          # Salvar como arquivo do usuário
          ensure_json_directory
          File.write(self::USER_DATA_FILE, JSON.pretty_generate(data))
          
          {
            success: true,
            data: data,
            message: "Sucesso ao carregar dados padrão"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar dados padrão: #{e.message}",
            data: { groups: [], self::ENTITY_NAME.to_sym => [] }
          }
        end
      end

      def load_from_file
        entity_name_singular = self::ENTITY_NAME.chomp('s')
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
            data: { groups: [], self::ENTITY_NAME.to_sym => [] }
          }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS (auxiliares)
      # ========================================

      private

      def unhide_all_elements
        model = Sketchup.active_model
        entidades = model.entities
        
        entidades.each do |entidade|
          entidade.hidden = false if entidade.hidden?
        end
      end

      def validate_params(name, style, camera_type)
        entity_name_singular = self::ENTITY_NAME.chomp('s')
        return [false, "Nome da #{entity_name_singular} é obrigatório"] if name.nil? || name.strip.empty?
        [true, nil]
      end

      def apply_style(style_name)
        model = Sketchup.active_model
        
        # Primeiro tentar carregar da pasta styles
        style_file_path = File.join(self::STYLES_PATH, "#{style_name}.style")
        
        if File.exist?(style_file_path)
          begin
            model.styles.add_style(style_file_path, true)
            imported_style = model.styles.find { |s| s.name == style_name }
            model.styles.selected_style = imported_style if imported_style
            return
          rescue => e
            puts "Erro ao importar estilo #{style_name}: #{e.message}"
          end
        end
        
        # Fallback: buscar estilo já existente no modelo
        style = model.styles.find { |s| s.name == style_name }
        model.styles.selected_style = style if style
      end

      def apply_layers_visibility(active_layers)
        model = Sketchup.active_model
        
        # Ocultar todas as camadas primeiro
        model.layers.each { |layer| layer.visible = false }
        
        # Mostrar apenas as camadas ativas
        active_layers.each do |layer_name|
          layer = model.layers.find { |l| l.name == layer_name }
          layer.visible = true if layer
        end
      end

      def apply_camera_config(page, camera_type)
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

      def configure_iso_camera(page)
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        eye = Geom::Point3d.new(center.x - 1000, center.y - 1000, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 0, 1)
        
        camera.set(eye, target, up)
        model.active_view.camera = camera
      end

      def configure_inverted_camera(page)
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        eye = Geom::Point3d.new(center.x + 1000, center.y + 1000, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 0, 1)
        
        camera.set(eye, target, up)
        model.active_view.camera = camera
      end

      def configure_top_camera(page)
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        eye = Geom::Point3d.new(center.x, center.y, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 1, 0)
        
        camera.set(eye, target, up)
        model.active_view.camera = camera
      end

      # Métodos diretos para aplicar câmera (sem page)
      def configure_iso_camera_direct
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        eye = Geom::Point3d.new(center.x - 1000, center.y - 1000, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 0, 1)
        
        camera.set(eye, target, up)
      end

      def configure_inverted_camera_direct
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        eye = Geom::Point3d.new(center.x + 1000, center.y + 1000, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 0, 1)
        
        camera.set(eye, target, up)
      end

      def configure_top_camera_direct
        model = Sketchup.active_model
        camera = model.active_view.camera
        bounds = model.bounds
        center = bounds.center
        
        eye = Geom::Point3d.new(center.x, center.y, center.z + 1000)
        target = center
        up = Geom::Vector3d.new(0, 1, 0)
        
        camera.set(eye, target, up)
      end

      def detect_camera_type(page)
        camera = page.camera
        return :iso_perspectiva unless camera
        
        detect_camera_type_from_camera(camera)
      end

      def detect_camera_type_from_camera(camera)
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

      def get_page_visible_layers(page)
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

      def ensure_json_directory
        Dir.mkdir(self::JSON_DATA_PATH) unless Dir.exist?(self::JSON_DATA_PATH)
      end

      def remove_bom(content)
        content.sub("\xEF\xBB\xBF".force_encoding("UTF-8"), '')
      end

      # Detecta o número do nível da cena atual
      # Exemplos: base2 -> 2, forro3 -> 3, base -> 1
      def detect_level_number_from_current_scene(model)
        current_page = model.pages.selected_page
        return 1 unless current_page
        
        scene_name = current_page.name
        
        # Padrões de cenas de nível: base, base2, base3, forro, forro2, forro3
        if scene_name =~ /^(base|forro)(\d+)?$/i
          number = $2
          return number ? number.to_i : 1
        end
        
        # Se não for uma cena de nível, retorna 1 (térreo)
        return 1
      end

    end
  end
end
