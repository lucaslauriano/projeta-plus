# encoding: UTF-8
require 'sketchup.rb'
require 'json'
require_relative '../shared/pro_view_configs_base.rb'

module ProjetaPlus
  module Modules
    module ProSections
      extend ProjetaPlus::Modules::ProViewConfigsBase
      # ========================================
      # SETTINGS AND CONSTANTS
      # ========================================

      ENTITY_NAME = "sections"
      SETTINGS_KEY = "sections_settings"
      
      # Distances and offsets
      EXTEND_DISTANCE = -70.cm
      CAMERA_DISTANCE = 500.cm
      
      # Prefixes and nomenclature
      LAYER_PREFIX = "-CORTES-"
      AUTO_VIEW_LETTERS = %w[a b c d]
      STANDARD_SECTIONS = %w[a b c d]

      # Paths para arquivos JSON
      PLUGIN_PATH = File.dirname(__FILE__)
      JSON_DATA_PATH = File.join(PLUGIN_PATH, 'json_data')
      STYLES_PATH = File.join(File.dirname(PLUGIN_PATH), 'styles')  #TODO
      DEFAULT_DATA_FILE = File.join(JSON_DATA_PATH, 'sections_data.json')
      USER_DATA_FILE = File.join(JSON_DATA_PATH, 'user_sections_data.json')

      # ========================================
      # MÉTODOS PÚBLICOS
      # ========================================

      # Retorna as configurações de seções do JSON
      def self.get_sections
        result = load_from_json
        if result[:success]
          { success: true, sections: result[:data]['sections'] || [], message: "Seções carregadas" }
        else
          { success: false, message: result[:message], sections: [] }
        end
      rescue StandardError => e
        log_error("get_sections", e)
        { success: false, message: "Erro ao carregar seções: #{e.message}", sections: [] }
      end

      # Adiciona nova seção ao JSON
      def self.add_section(params)
        params = normalize_params(params)

        # Validar parâmetros
        return { success: false, message: "ID e nome são obrigatórios" } unless params[:id] && params[:name]

        # Carregar dados atuais
        result = load_from_json
        return result unless result[:success]

        data = result[:data]
        sections = data['sections'] || []

        # Verificar se já existe
        if sections.any? { |s| s['id'] == params[:id] }
          return { success: false, message: "Seção '#{params[:id]}' já existe" }
        end

        # Adicionar nova seção
        new_section = {
          'id' => params[:id],
          'name' => params[:name],
          'style' => params[:style] || '',
          'activeLayers' => params[:activeLayers] || []
        }

        sections << new_section
        data['sections'] = sections

        # Salvar
        save_result = save_to_json(data)
        return save_result unless save_result[:success]

        {
          success: true,
          message: "Seção '#{params[:name]}' adicionada com sucesso",
          section: new_section
        }
      rescue StandardError => e
        log_error("add_section", e)
        { success: false, message: "Erro ao adicionar seção: #{e.message}" }
      end

      # Atualiza seção existente no JSON
      def self.update_section(id, params)
        params = normalize_params(params)
        
        # Carregar dados atuais
        result = load_from_json
        return result unless result[:success]

        data = result[:data]
        sections = data['sections'] || []

        # Encontrar seção
        section = sections.find { |s| s['id'] == id }
        return { success: false, message: "Seção '#{id}' não encontrada" } unless section

        # Atualizar campos
        section['name'] = params[:name] if params[:name]
        section['style'] = params[:style] if params[:style]
        section['activeLayers'] = params[:activeLayers] if params[:activeLayers]

        # Salvar
        save_result = save_to_json(data)
        return save_result unless save_result[:success]

        { success: true, message: "Seção '#{section['name']}' atualizada com sucesso" }
      rescue StandardError => e
        log_error("update_section", e)
        { success: false, message: "Erro ao atualizar seção: #{e.message}" }
      end

      # Remove seção do JSON
      def self.delete_section(id)
        # Carregar dados atuais
        result = load_from_json
        return result unless result[:success]

        data = result[:data]
        sections = data['sections'] || []

        # Encontrar e remover seção
        section = sections.find { |s| s['id'] == id }
        return { success: false, message: "Seção '#{id}' não encontrada" } unless section

        sections.delete(section)
        data['sections'] = sections

        # Salvar
        save_result = save_to_json(data)
        return save_result unless save_result[:success]

        { success: true, message: "Seção '#{section['name']}' removida com sucesso" }
      rescue StandardError => e
        log_error("delete_section", e)
        { success: false, message: "Erro ao remover seção: #{e.message}" }
      end

      # ========================================
      # MÉTODOS ESPECÍFICOS DE SEÇÕES
      # ========================================

      # Cria cortes padrões (A, B, C, D)
      def self.create_standard_sections
        model = Sketchup.active_model
        bounds = model.bounds
        center = bounds.center

        sections_config = standard_sections_config(bounds, center)

        model.start_operation("Criar Cortes Padrões", true)

        # Criar layer única para todos os cortes padrões
        layer = create_or_get_layer(model, "#{LAYER_PREFIX}GERAIS")

        created = []
        sections_config.each do |name, config|
          remove_section_and_page(model, name)
          
          sp = create_section_plane(model, name, config[:position], config[:direction])
          
          # Atribuir a mesma layer para todos os cortes
          sp.layer = layer
          
          # Criar cena alinhada ao corte
          create_aligned_scene(model, sp, config[:position], config[:direction])
          
          created << name
        end

        model.commit_operation

        {
          success: true,
          message: "Cortes padrões (#{created.join(', ')}) criados com sucesso",
          count: created.length
        }
      rescue StandardError => e
        model.abort_operation if model
        log_error("create_standard_sections", e)
        { success: false, message: "Erro ao criar cortes padrões: #{e.message}" }
      end

      # Cria vistas automáticas para objeto selecionado
      def self.create_auto_views(params = {})
        model = Sketchup.active_model
        sel = model.selection.first

        return { success: false, message: "Selecione um objeto para criar os cortes" } unless sel

        # Pegar nome do ambiente dos parâmetros vindos do frontend
        ambiente = (params['environmentName'] || params[:environmentName]).to_s.strip.downcase
        return invalid_input("Nome do ambiente é obrigatório") if ambiente.empty?

        prefixo = ambiente.upcase  # Maiúsculo apenas para a layer
        bb = sel.bounds
        center = bb.center

        sections_config = standard_sections_config(bb, center)

        model.start_operation("Criar Vistas Automáticas", true)

        # Criar layer para o ambiente (maiúsculo)
        layer = create_or_get_layer(model, "#{LAYER_PREFIX}#{prefixo}")

        created = []
        sections_config.each do |letter, config|
          # Nome da cena em minúsculo
          nome_final = "#{ambiente}_#{letter}"
          
          remove_section_and_page(model, nome_final)

          sp = create_section_plane(model, nome_final, config[:position], config[:direction])
          sp.layer = layer
          
          # Criar cena alinhada ao corte
          create_aligned_scene(model, sp, config[:position], config[:direction])
          
          created << nome_final
        end

        model.commit_operation

        {
          success: true,
          message: "Vistas automáticas criadas para #{ambiente}: #{created.join(', ')}",
          count: created.length
        }
      rescue StandardError => e
        model.abort_operation if model
        log_error("create_auto_views", e)
        { success: false, message: "Erro ao criar vistas automáticas: #{e.message}" }
      end

      # Cria corte individual
      def self.create_individual_section(params)
        model = Sketchup.active_model
        params = normalize_params(params)
        
        direction_type = params[:direction_type]
        name = params[:name]

        return invalid_input("Tipo de direção e nome são obrigatórios") unless direction_type && name

        bounds = model.bounds
        center = bounds.center

        config = direction_configs(bounds, center)[direction_type.downcase]
        return invalid_input("Tipo de direção inválido") unless config

        model.start_operation("Criar Corte Individual", true)

        remove_section_and_page(model, name)

        sp = create_section_plane(model, name, config[:position], config[:direction])
        
        # Criar cena alinhada ao corte
        create_aligned_scene(model, sp, config[:position], config[:direction])

        model.commit_operation

        {
          success: true,
          message: "Corte '#{name}' criado com sucesso",
          section: build_section_config(sp)
        }
      rescue StandardError => e
        model.abort_operation if model
        log_error("create_individual_section", e)
        { success: false, message: "Erro ao criar corte individual: #{e.message}" }
      end

      # ========================================
      # MÉTODOS DE PERSISTÊNCIA JSON
      # ========================================

      def self.save_to_json(json_data)
        ensure_json_directory
        File.write(USER_DATA_FILE, JSON.pretty_generate(json_data))
        
        { success: true, message: "Configurações salvas com sucesso", path: USER_DATA_FILE }
      rescue StandardError => e
        log_error("save_to_json", e)
        { success: false, message: "Erro ao salvar configurações: #{e.message}" }
      end

      def self.load_from_json
        file_to_load = File.exist?(USER_DATA_FILE) ? USER_DATA_FILE : DEFAULT_DATA_FILE
        
        unless File.exist?(file_to_load)
          return { success: false, message: "Arquivo não encontrado", data: { 'sections' => [] } }
        end
        
        content = File.read(file_to_load)
        content = remove_bom(content)
        
        # Se o arquivo estiver vazio, usar arquivo padrão
        if content.strip.empty?
          if file_to_load == USER_DATA_FILE && File.exist?(DEFAULT_DATA_FILE)
            content = File.read(DEFAULT_DATA_FILE)
            content = remove_bom(content)
          else
            return { success: true, data: { 'sections' => [] }, message: "Arquivo vazio" }
          end
        end
        
        data = JSON.parse(content)
        
        { success: true, data: data, message: "Configurações carregadas" }
      rescue JSON::ParserError => e
        # Se erro no user file, tentar o default
        if file_to_load == USER_DATA_FILE && File.exist?(DEFAULT_DATA_FILE)
          begin
            content = File.read(DEFAULT_DATA_FILE)
            content = remove_bom(content)
            data = JSON.parse(content)
            return { success: true, data: data, message: "Carregado do arquivo padrão" }
          rescue
            # Se default também falhar, retornar vazio
          end
        end
        log_error("load_from_json - JSON inválido", e)
        { success: false, message: "JSON inválido: #{e.message}", data: { 'sections' => [] } }
      rescue StandardError => e
        log_error("load_from_json", e)
        { success: false, message: "Erro ao carregar: #{e.message}", data: { 'sections' => [] } }
      end

      def self.load_default_data
        unless File.exist?(DEFAULT_DATA_FILE)
          return { success: false, message: "Arquivo padrão não encontrado", data: { sections: [] } }
        end
        
        content = File.read(DEFAULT_DATA_FILE)
        content = remove_bom(content)
        data = JSON.parse(content)
        
        # Salvar como arquivo do usuário
        ensure_json_directory
        File.write(USER_DATA_FILE, JSON.pretty_generate(data))
        
        { success: true, data: data, message: "Dados padrão carregados" }
      rescue StandardError => e
        log_error("load_default_data", e)
        { success: false, message: "Erro: #{e.message}", data: { sections: [] } }
      end

      def self.load_from_file
        file_path = ::UI.openpanel("Selecionar arquivo JSON", "", "JSON|*.json||")
        return cancelled_operation unless file_path
        
        content = File.read(file_path)
        content = remove_bom(content)
        data = JSON.parse(content)
        
        { success: true, data: data, message: "Arquivo carregado com sucesso" }
      rescue StandardError => e
        log_error("load_from_file", e)
        { success: false, message: "Erro ao carregar: #{e.message}", data: { sections: [] } }
      end

      # Importa seções do JSON para o modelo
      def self.import_to_model(json_data)
        model = Sketchup.active_model
        sections = json_data['sections'] || json_data[:sections] || []

        return invalid_input("Nenhuma seção para importar") if sections.empty?

        model.start_operation("Importar Seções", true)

        count = 0
        sections.each do |section|
          section = normalize_params(section)
          next unless section[:name] && section[:position] && section[:direction]

          remove_section_and_page(model, section[:name])

          sp = create_section_plane(model, section[:name], section[:position], section[:direction])
          create_aligned_scene(model, sp, section[:position], section[:direction])
          
          count += 1
        end

        model.commit_operation

        { success: true, message: "#{count} seções importadas com sucesso", count: count }
      rescue StandardError => e
        model.abort_operation if model
        log_error("import_to_model", e)
        { success: false, message: "Erro ao importar: #{e.message}" }
      end

      # ========================================
      # MÉTODOS PRIVADOS (core)
      # ========================================

      private

      # Cria um section plane
      def self.create_section_plane(model, name, position, direction)
        pos_point = Geom::Point3d.new(*position)
        dir_vector = Geom::Vector3d.new(*direction)
        
        sp = model.entities.add_section_plane(pos_point, dir_vector)
        sp.name = name
        sp
      end

      # Cria uma cena alinhada ao section plane
      def self.create_aligned_scene(model, section_plane, position, direction)
        page = model.pages.add(section_plane.name)
        page.use_section_planes = true
        
        model.pages.selected_page = page
        section_plane.activate
        
        # Alinhar câmera ao plano de corte
        align_camera_to_section(model, direction)
        
        # CRÍTICO: Atualizar a página para salvar o estado da câmera
        page.update
        
        page
      end

      # Alinha a câmera para olhar diretamente para o plano de corte
      def self.align_camera_to_section(model, direction)
        view = model.active_view
        
        # Eye: direção invertida multiplicada por -1000 (posição absoluta)
        eye = [direction[0] * -1000, direction[1] * -1000, direction[2] * -1000]
        
        # Target: origem absoluta [0, 0, 0]
        target = [0, 0, 0]
        
        # Up: sempre Z para cima
        up = [0, 0, 1]
        
        # Criar nova câmera e atribuir à view (igual ao código original)
        view.camera = Sketchup::Camera.new(eye, target, up, true)
        view.camera.perspective = false
        
        # Zoom extents para enquadrar o modelo
        view.zoom_extents
      end

      # Constrói configuração de uma seção
      def self.build_section_config(section_plane)
        plane = section_plane.get_plane
        normal = Geom::Vector3d.new(plane[0], plane[1], plane[2])
        position = Geom::Point3d.new(0, 0, 0).offset(normal, plane[3])
        
        {
          id: section_plane.entityID.to_s,
          name: section_plane.name.empty? ? "Section_#{section_plane.entityID}" : section_plane.name,
          position: position.to_a,
          direction: normal.to_a,
          active: section_plane.active?
        }
      end

      # ========================================
      # MÉTODOS AUXILIARES
      # ========================================

      # Normaliza parâmetros (aceita strings e símbolos)
      def self.normalize_params(params)
        {
          id: params['id'] || params[:id],
          name: params['name'] || params[:name],
          style: params['style'] || params[:style],
          activeLayers: params['activeLayers'] || params[:activeLayers] || [],
          direction_type: params['directionType'] || params[:directionType] || params['direction_type'] || params[:direction_type]
        }
      end

      # Valida parâmetros de seção
      def self.validate_section(name, position, direction)
        errors = []
        
        errors << "Nome é obrigatório" if name.to_s.strip.empty?
        errors << "Posição inválida" unless valid_coordinates?(position)
        errors << "Direção inválida" unless valid_coordinates?(direction)
        errors << "Direção não pode ser nula" if direction && direction.all?(&:zero?)
        
        [errors.empty?, errors.join("; ")]
      end

      # Valida se coordenadas são válidas
      def self.valid_coordinates?(coords)
        coords.is_a?(Array) && coords.length == 3 && coords.all? { |c| c.is_a?(Numeric) }
      end

      # Verifica se seção existe
      def self.section_exists?(model, name)
        !find_section_by_name(model, name).nil?
      end

      # Busca seção por nome (case insensitive)
      def self.find_section_by_name(model, name)
        model.entities.grep(Sketchup::SectionPlane)
          .find { |sp| sp.name.casecmp(name.to_s).zero? }
      end

      # Remove seção e página associada
      def self.remove_section_and_page(model, name)
        # Remove section plane
        sp = find_section_by_name(model, name)
        model.entities.erase_entities(sp) if sp
        
        # Remove página
        page = model.pages.find { |p| p.name == name }
        model.pages.erase(page) if page
      end

      # Cria ou obtém layer existente
      def self.create_or_get_layer(model, name)
        model.layers[name] || model.layers.add(name)
      end

      # Standard sections configuration
      def self.standard_sections_config(bounds, center)
        {
          'a' => { 
            position: [center.x, bounds.max.y + EXTEND_DISTANCE, center.z], 
            direction: [0, 1, 0] 
          },
          'b' => { 
            position: [bounds.max.x + EXTEND_DISTANCE, center.y, center.z], 
            direction: [1, 0, 0] 
          },
          'c' => { 
            position: [center.x, bounds.min.y - EXTEND_DISTANCE, center.z], 
            direction: [0, -1, 0] 
          },
          'd' => { 
            position: [bounds.min.x - EXTEND_DISTANCE, center.y, center.z], 
            direction: [-1, 0, 0] 
          }
        }
      end

      # Direction configurations (same as standard sections but with descriptive names)
      def self.direction_configs(bounds, center)
        {
          'front' => { 
            position: [center.x, bounds.max.y + EXTEND_DISTANCE, center.z], 
            direction: [0, 1, 0] 
          },
          'right' => { 
            position: [bounds.max.x + EXTEND_DISTANCE, center.y, center.z], 
            direction: [1, 0, 0] 
          },
          'back' => { 
            position: [center.x, bounds.min.y - EXTEND_DISTANCE, center.z], 
            direction: [0, -1, 0] 
          },
          'left' => { 
            position: [bounds.min.x - EXTEND_DISTANCE, center.y, center.z], 
            direction: [-1, 0, 0] 
          }
        }
      end

      # Garante que diretório JSON existe
      def self.ensure_json_directory
        Dir.mkdir(JSON_DATA_PATH) unless Dir.exist?(JSON_DATA_PATH)
      end

      # Remove BOM de UTF-8
      def self.remove_bom(content)
        content.sub("\xEF\xBB\xBF".force_encoding("UTF-8"), '')
      end

      # Retorno para operação cancelada
      def self.cancelled_operation
        { success: false, message: "Operação cancelada pelo usuário" }
      end

      # Retorno para input inválido
      def self.invalid_input(reason)
        { success: false, message: reason }
      end

      # Log de erros (apenas em modo debug)
      def self.log_error(context, error)
        return unless defined?(Sketchup) && Sketchup.respond_to?(:debug_mode?) && Sketchup.debug_mode?
        
        timestamp = Time.now.strftime("%Y-%m-%d %H:%M:%S")
        puts "[#{timestamp}] #{context}: #{error.message}"
        puts error.backtrace.first(5).join("\n") if error.backtrace
      end

    end
  end
end