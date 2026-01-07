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
            # Recuperar o código e display_name salvos como atributos
            code = page.get_attribute('ProjetaPlus', 'code', nil)
            display_name = page.get_attribute('ProjetaPlus', 'display_name', nil)
            
            # Se não tiver display_name salvo, usar o nome da página
            display_name = page.name if display_name.nil? || display_name.empty?
            
            item_config = {
              id: page.name,
              name: display_name,
              code: code,
              pageName: page.name,
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
          code = params['code'] || params[:code]
          style = params['style'] || params[:style]
          camera_type = params['cameraType'] || params[:cameraType]
          active_layers = params['activeLayers'] || params[:activeLayers]

          # Definir o nome da página: usar code se existir, senão usar name
          page_name = (code && !code.empty?) ? code : name

          # Validar parâmetros
          valid, error_msg = validate_params(name, style, camera_type)
          return { success: false, message: error_msg } unless valid

          # Verificar se já existe
          if model.pages.find { |p| p.name.downcase == page_name.downcase }
            return { success: false, message: "#{entity_name_singular.capitalize} '#{page_name}' já existe" }
          end

          model.start_operation("Adicionar #{entity_name_singular.capitalize}", true)

          # Aplicar configurações antes de criar
          apply_style(style) if style && !style.empty?
          apply_layers_visibility(active_layers) if active_layers

          # Criar a página com o nome definido (code ou name)
          page = model.pages.add(page_name)

          # Salvar o name e code como atributos da página
          page.set_attribute('ProjetaPlus', 'display_name', name) if name && !name.empty?
          if code && !code.empty?
            page.set_attribute('ProjetaPlus', 'code', code)
          end

          # Configurar câmera
          apply_camera_config(page, camera_type) if camera_type

          unhide_all_elements

          # Zoom extents e atualizar
          model.active_view.zoom_extents
          page.update

          model.commit_operation

          {
            success: true,
            message: "#{entity_name_singular.capitalize} '#{page_name}' criada com sucesso",
            entity_name_singular.to_sym => {
              id: page.name,
              name: name,
              code: code,
              pageName: page.name,
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

      # Atualiza configuração existente (suporta scope: current / <n> / all)
      def update_item(name, params)
        entity_name_singular = self::ENTITY_NAME.chomp('s')
        begin
          model = Sketchup.active_model
          new_name = params['name'] || params[:name]
          code = params['code'] || params[:code]
          style = params['style'] || params[:style]
          camera_type = params['cameraType'] || params[:cameraType]
          active_layers = params['activeLayers'] || params[:activeLayers]
      
          # Determinar páginas alvo conforme o escopo passado (current / número / all)
          target_names = parse_update_scope(name, params, model)
      
          model.start_operation("Atualizar #{entity_name_singular.capitalize}", true)
      
          updated = []
      
          target_names.each do |target_name|
            page = model.pages.find { |p| p.name.downcase == target_name.downcase }
            if page
              model.pages.selected_page = page
            else
              page = model.pages.add(target_name)
            end
            
            # Atualizar o nome da página se code mudou
            new_page_name = (code && !code.empty?) ? code : (new_name || page.name)
            if new_page_name != page.name
              # Renomear a página
              page.name = new_page_name
            end
            
            # Salvar o name e code como atributos da página
            page.set_attribute('ProjetaPlus', 'display_name', new_name) if new_name && !new_name.empty?
            if code && !code.empty?
              page.set_attribute('ProjetaPlus', 'code', code)
            end
            
            # Aplicar estilo e camadas para cada página
            apply_style(style) if style && !style.empty?
            apply_layers_visibility(active_layers) if active_layers
      
            # Aplicar configuração de câmera (usa a página)
            apply_camera_config(page, camera_type) if camera_type

            unhide_all_elements
      
            # Atualizar a página
            model.active_view.zoom_extents
            page.update
      
            updated << target_name
          end
      
          model.commit_operation
      
          {
            success: true,
            message: "#{entity_name_singular.capitalize} '#{name}' atualizada(s): #{updated.join(', ')}"
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

      # Aplica configuração (cria se não existir) — suporta scope (current / <n> / all)
      def apply_config(name, code, config)
        entity_name_singular = self::ENTITY_NAME.chomp('s')
        begin
          model = Sketchup.active_model

          # Definir o nome da página: usar code se existir, senão usar name
          page_name = (code && !code.empty?) ? code : name

          # Determinar nomes finais conforme o escopo em config (mesma lógica de update)
          target_names = parse_update_scope(page_name, config, model)

          model.start_operation("Aplicar Configuração de #{entity_name_singular.capitalize}", true)

          target_names.each do |final_name|
            page = model.pages.find { |p| p.name.downcase == final_name.downcase }

            if page
              model.pages.selected_page = page
            else
              page = model.pages.add(final_name)
            end

            # Salvar o name e code como atributos da página
            page.set_attribute('ProjetaPlus', 'display_name', name) if name && !name.empty?
            if code && !code.empty?
              page.set_attribute('ProjetaPlus', 'code', code)
            end

            # Aplicar configurações
            style = config['style'] || config[:style]
            apply_style(style) if style && !style.empty?

            active_layers = config['activeLayers'] || config[:activeLayers]
            apply_layers_visibility(active_layers) if active_layers

            camera_type = config['cameraType'] || config[:cameraType]
            apply_camera_config(page, camera_type) if camera_type

            unhide_all_elements

            model.active_view.zoom_extents
            page.update
          end

          model.commit_operation

          {
            success: true,
            message: "Configuração aplicada para: #{target_names.join(', ')}"
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

      # Retorna camadas visíveis que existem na lista disponível
      def get_visible_layers_filtered(available_layers)
        begin
          model = Sketchup.active_model
          visible_layers = []
          
          model.layers.each do |layer|
            # Incluir apenas se estiver visível E estiver na lista de camadas disponíveis
            if layer.visible? && available_layers.include?(layer.name)
              visible_layers << layer.name
            end
          end
          
          {
            success: true,
            layers: visible_layers.sort,
            message: "Camadas visíveis capturadas e filtradas"
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
          
          # Convert old format to new format (backward compatibility)
          if data[self::ENTITY_NAME] && !data['groups']
            data = {
              'groups' => [{
                'id' => Time.now.to_i.to_s,
                'name' => 'Default',
                'segments' => data[self::ENTITY_NAME]
              }]
            }
          end
          
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
          
          # Convert old format to new format (backward compatibility)
          if data[self::ENTITY_NAME] && !data['groups']
            data = {
              'groups' => [{
                'id' => Time.now.to_i.to_s,
                'name' => 'Default',
                'segments' => data[self::ENTITY_NAME]
              }]
            }
          end
          
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
          
          # Convert old format to new format (backward compatibility)
          if data[self::ENTITY_NAME] && !data['groups']
            data = {
              'groups' => [{
                'id' => Time.now.to_i.to_s,
                'name' => 'Default',
                'segments' => data[self::ENTITY_NAME]
              }]
            }
          end
          
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

      # Resolve lista de nomes de cenas alvo com base no escopo passado em params[:scope]
      # scope pode ser: 'current'|'atual' (padrão), 'all'|'todos', um número '2' ou 'nivel_2'
      def parse_update_scope(base_name, params, model)
        scope = params && (params['scope'] || params[:scope]) || 'current'
        scope_str = scope.to_s.downcase

        case scope_str
        when 'current', 'atual', 'apenas_atual', 'apenas atual'
          level_number = detect_level_number_from_current_scene(model)
          final_name = level_number > 1 ? "#{base_name}_#{level_number}" : base_name
          [final_name]
        when 'all', 'todos', 'todas', 'todos_niveis', 'todos níveis'
          pattern = /^#{Regexp.escape(base_name)}(?:_(\d+))?$/i
          matches = model.pages.map(&:name).select { |n| n =~ pattern }
          matches.empty? ? [base_name] : matches
        else
          if scope_str =~ /^\d+$/
            level = scope_str.to_i
            final_name = level > 1 ? "#{base_name}_#{level}" : base_name
            [final_name]
          elsif scope_str =~ /^nivel[_-]?(\d+)$/i
            level = $1.to_i
            final_name = level > 1 ? "#{base_name}_#{level}" : base_name
            [final_name]
          else
            [base_name]
          end
        end
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
        
        # Posiciona a câmera ABAIXO do modelo, olhando para cima
        eye = Geom::Point3d.new(center.x, center.y, center.z - 1000)
        target = center
        up = Geom::Vector3d.new(0, 1, 0)
        
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
        
        # Posiciona a câmera ABAIXO do modelo, olhando para cima
        eye = Geom::Point3d.new(center.x, center.y, center.z - 1000)
        target = center
        up = Geom::Vector3d.new(0, 1, 0)
        
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
        
        # Vista de topo (direção Z negativa, olhando de cima para baixo)
        if direction.z < -0.9
          return perspective ? :topo_perspectiva : :topo_ortogonal
        # Vista de baixo (direção Z positiva, olhando de baixo para cima)
        elsif direction.z > 0.9
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
      # Exemplos: base -> 1, base_2 -> 2, forro_3 -> 3
      def detect_level_number_from_current_scene(model)
        current_page = model.pages.selected_page
        return 1 unless current_page
        
        scene_name = current_page.name
        
        # Padrões de cenas de nível: base, base_2, base_3, forro, forro_2, forro_3
        if scene_name =~ /^(base|forro)(?:_(\d+))?$/i
          number = $2
          return number ? number.to_i : 1
        end
        
        # Se não for uma cena de nível, retorna 1 (térreo)
        return 1
      end

    end
  end
end
