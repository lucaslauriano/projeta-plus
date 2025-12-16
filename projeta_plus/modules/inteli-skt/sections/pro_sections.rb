# encoding: UTF-8
require 'sketchup.rb'
require 'json'

module ProjetaPlus
  module Modules
    module ProSections

      # ========================================
      # CONFIGURAÇÕES E CONSTANTES
      # ========================================

      ENTITY_NAME = "sections"
      SETTINGS_KEY = "sections_settings"

      # Paths para arquivos JSON
      PLUGIN_PATH = File.dirname(__FILE__)
      JSON_DATA_PATH = File.join(PLUGIN_PATH, 'json_data')
      DEFAULT_DATA_FILE = File.join(JSON_DATA_PATH, 'sections_data.json')
      USER_DATA_FILE = File.join(JSON_DATA_PATH, 'user_sections_data.json')

      # ========================================
      # MÉTODOS PÚBLICOS
      # ========================================

      # Retorna todas as section planes do modelo
      def self.get_sections
        begin
          model = Sketchup.active_model
          sections = []

          model.entities.grep(Sketchup::SectionPlane).each do |sp|
            plane = sp.get_plane
            section_config = {
              id: sp.name.empty? ? sp.entityID.to_s : sp.name,
              name: sp.name.empty? ? "Section_#{sp.entityID}" : sp.name,
              position: [plane[3].x, plane[3].y, plane[3].z],
              direction: [plane[0], plane[1], plane[2]],
              active: sp.active?
            }
            sections << section_config
          end

          {
            success: true,
            sections: sections,
            message: "#{sections.length} seções carregadas"
          }
        rescue => e
          {
            success: false,
            message: "Erro ao carregar seções: #{e.message}",
            sections: []
          }
        end
      end

      # Adiciona nova section plane ao modelo
      def self.add_section(params)
        begin
          model = Sketchup.active_model
          name = params['name'] || params[:name]
          position = params['position'] || params[:position]
          direction = params['direction'] || params[:direction]

          # Validar parâmetros
          valid, error_msg = validate_section(name, position, direction)
          return { success: false, message: error_msg } unless valid

          # Verificar se já existe
          existing = model.entities.grep(Sketchup::SectionPlane).find { |sp| sp.name.downcase == name.downcase }
          if existing
            return { success: false, message: "Seção '#{name}' já existe" }
          end

          model.start_operation("Adicionar Seção", true)

          # Criar section plane
          pos_point = Geom::Point3d.new(position[0], position[1], position[2])
          dir_vector = Geom::Vector3d.new(direction[0], direction[1], direction[2])
          
          sp = model.entities.add_section_plane(pos_point, dir_vector)
          sp.name = name
          sp.activate

          model.commit_operation

          {
            success: true,
            message: "Seção '#{name}' criada com sucesso",
            section: {
              id: sp.name,
              name: sp.name,
              position: position,
              direction: direction,
              active: true
            }
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao criar seção: #{e.message}"
          }
        end
      end

      # Atualiza section plane existente
      def self.update_section(name, params)
        begin
          model = Sketchup.active_model
          sp = model.entities.grep(Sketchup::SectionPlane).find { |s| s.name.downcase == name.downcase }

          unless sp
            return { success: false, message: "Seção '#{name}' não encontrada" }
          end

          position = params['position'] || params[:position]
          direction = params['direction'] || params[:direction]

          model.start_operation("Atualizar Seção", true)

          # Atualizar posição e direção se fornecidos
          if position && direction
            pos_point = Geom::Point3d.new(position[0], position[1], position[2])
            dir_vector = Geom::Vector3d.new(direction[0], direction[1], direction[2])
            
            # Remover antiga e criar nova (não há método direto para atualizar)
            old_name = sp.name
            model.entities.erase_entities(sp)
            
            sp = model.entities.add_section_plane(pos_point, dir_vector)
            sp.name = old_name
          end

          sp.activate

          model.commit_operation

          {
            success: true,
            message: "Seção '#{name}' atualizada com sucesso"
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao atualizar seção: #{e.message}"
          }
        end
      end

      # Remove section plane do modelo
      def self.delete_section(name)
        begin
          model = Sketchup.active_model
          sp = model.entities.grep(Sketchup::SectionPlane).find { |s| s.name.downcase == name.downcase }

          unless sp
            return { success: false, message: "Seção '#{name}' não encontrada" }
          end

          model.start_operation("Remover Seção", true)
          model.entities.erase_entities(sp)
          model.commit_operation

          {
            success: true,
            message: "Seção '#{name}' removida com sucesso"
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao remover seção: #{e.message}"
          }
        end
      end

      # ========================================
      # MÉTODOS ESPECÍFICOS DE SEÇÕES
      # ========================================

      # Cria cortes padrões (A, B, C, D)
      def self.create_standard_sections
        begin
          model = Sketchup.active_model
          bounds = model.bounds
          center = bounds.center

          sections_config = {
            'A' => { position: [center.x, bounds.max.y + 40, center.z], direction: [0, 1, 0] },
            'B' => { position: [bounds.max.x + 40, center.y, center.z], direction: [1, 0, 0] },
            'C' => { position: [center.x, bounds.min.y - 40, center.z], direction: [0, -1, 0] },
            'D' => { position: [bounds.min.x - 40, center.y, center.z], direction: [-1, 0, 0] }
          }

          model.start_operation("Criar Cortes Padrões", true)

          created = []
          sections_config.each do |name, config|
            # Remover se já existir
            existing = model.entities.grep(Sketchup::SectionPlane).find { |sp| sp.name == name }
            model.entities.erase_entities(existing) if existing

            # Criar novo
            pos_point = Geom::Point3d.new(config[:position][0], config[:position][1], config[:position][2])
            dir_vector = Geom::Vector3d.new(config[:direction][0], config[:direction][1], config[:direction][2])
            
            sp = model.entities.add_section_plane(pos_point, dir_vector)
            sp.name = name
            
            # Criar layer para o corte
            layer_name = "-CORTES-#{name}"
            layer = model.layers[layer_name] || model.layers.add(layer_name)
            sp.layer = layer
            
            created << name
          end

          model.commit_operation

          {
            success: true,
            message: "Cortes padrões (#{created.join(', ')}) criados com sucesso",
            count: created.length
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao criar cortes padrões: #{e.message}"
          }
        end
      end

      # Cria vistas automáticas para objeto selecionado
      def self.create_auto_views
        begin
          model = Sketchup.active_model
          sel = model.selection.first

          unless sel
            return { success: false, message: "Selecione um objeto para criar os cortes" }
          end

          # Solicitar nome do ambiente
          prompts = ['Nome do ambiente (prefixo):']
          defaults = ['']
          results = UI.inputbox(prompts, defaults, 'Criar Vistas Automáticas')
          
          return { success: false, message: "Operação cancelada" } unless results
          
          ambiente = results[0]
          return { success: false, message: "Nome do ambiente é obrigatório" } if ambiente.nil? || ambiente.strip.empty?

          prefixo = ambiente.upcase
          bb = sel.bounds
          extend_distance = 10.cm

          sections_config = [
            { letra: 'a', pos: [bb.center.x, bb.max.y + extend_distance, bb.center.z], dir: [0, 1, 0] },
            { letra: 'b', pos: [bb.min.x - extend_distance, bb.center.y, bb.center.z], dir: [1, 0, 0] },
            { letra: 'c', pos: [bb.center.x, bb.min.y - extend_distance, bb.center.z], dir: [0, -1, 0] },
            { letra: 'd', pos: [bb.max.x + extend_distance, bb.center.y, bb.center.z], dir: [-1, 0, 0] }
          ]

          model.start_operation("Criar Vistas Automáticas", true)

          # Criar layer para o ambiente
          layer_name = "-CORTES-#{prefixo}"
          layer = model.layers[layer_name] || model.layers.add(layer_name)
          layer.visible = true

          created = []
          sections_config.each do |config|
            nome_final = "#{ambiente}_#{config[:letra]}"
            
            # Remover se já existir
            existing = model.entities.grep(Sketchup::SectionPlane).find { |sp| sp.name == nome_final }
            model.entities.erase_entities(existing) if existing

            # Criar novo
            pos_point = Geom::Point3d.new(config[:pos][0], config[:pos][1], config[:pos][2])
            dir_vector = Geom::Vector3d.new(config[:dir][0], config[:dir][1], config[:dir][2])
            
            sp = model.entities.add_section_plane(pos_point, dir_vector)
            sp.name = nome_final
            sp.layer = layer
            sp.activate
            
            created << nome_final
          end

          model.commit_operation

          {
            success: true,
            message: "Vistas automáticas criadas para #{prefixo}: #{created.join(', ')}",
            count: created.length
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao criar vistas automáticas: #{e.message}"
          }
        end
      end

      # Cria corte individual
      def self.create_individual_section(params)
        begin
          model = Sketchup.active_model
          
          direction_type = params['directionType'] || params[:directionType]
          name = params['name'] || params[:name]

          unless direction_type && name
            return { success: false, message: "Tipo de direção e nome são obrigatórios" }
          end

          bounds = model.bounds
          center = bounds.center

          directions_config = {
            'frente' => { position: [center.x, bounds.max.y + 40, center.z], direction: [0, 1, 0] },
            'esquerda' => { position: [bounds.max.x + 40, center.y, center.z], direction: [1, 0, 0] },
            'voltar' => { position: [center.x, bounds.min.y - 40, center.z], direction: [0, -1, 0] },
            'direita' => { position: [bounds.min.x - 40, center.y, center.z], direction: [-1, 0, 0] }
          }

          config = directions_config[direction_type.downcase]
          unless config
            return { success: false, message: "Tipo de direção inválido" }
          end

          model.start_operation("Criar Corte Individual", true)

          # Remover se já existir
          existing = model.entities.grep(Sketchup::SectionPlane).find { |sp| sp.name == name }
          model.entities.erase_entities(existing) if existing

          # Criar novo
          pos_point = Geom::Point3d.new(config[:position][0], config[:position][1], config[:position][2])
          dir_vector = Geom::Vector3d.new(config[:direction][0], config[:direction][1], config[:direction][2])
          
          sp = model.entities.add_section_plane(pos_point, dir_vector)
          sp.name = name
          sp.activate

          model.commit_operation

          {
            success: true,
            message: "Corte '#{name}' criado com sucesso",
            section: {
              id: sp.name,
              name: sp.name,
              position: config[:position],
              direction: config[:direction],
              active: true
            }
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao criar corte individual: #{e.message}"
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
              data: { sections: [] }
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
            data: { sections: [] }
          }
        end
      end

      def self.load_default_data
        begin
          unless File.exist?(DEFAULT_DATA_FILE)
            return {
              success: false,
              message: "Arquivo de dados padrão não encontrado",
              data: { sections: [] }
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
            data: { sections: [] }
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
            data: { sections: [] }
          }
        end
      end

      # Importa seções do JSON para o modelo
      def self.import_to_model(json_data)
        begin
          model = Sketchup.active_model
          sections = json_data['sections'] || json_data[:sections] || []

          return { success: false, message: "Nenhuma seção para importar" } if sections.empty?

          model.start_operation("Importar Seções", true)

          count = 0
          sections.each do |section|
            name = section['name'] || section[:name]
            position = section['position'] || section[:position]
            direction = section['direction'] || section[:direction]

            next unless name && position && direction

            # Remover se já existir
            existing = model.entities.grep(Sketchup::SectionPlane).find { |sp| sp.name == name }
            model.entities.erase_entities(existing) if existing

            # Criar novo
            pos_point = Geom::Point3d.new(position[0], position[1], position[2])
            dir_vector = Geom::Vector3d.new(direction[0], direction[1], direction[2])
            
            sp = model.entities.add_section_plane(pos_point, dir_vector)
            sp.name = name
            
            count += 1
          end

          model.commit_operation

          {
            success: true,
            message: "#{count} seções importadas com sucesso",
            count: count
          }
        rescue => e
          model.abort_operation if model
          {
            success: false,
            message: "Erro ao importar seções: #{e.message}"
          }
        end
      end

      # ========================================
      # MÉTODOS PRIVADOS (auxiliares)
      # ========================================

      private

      def self.validate_section(name, position, direction)
        return [false, "Nome da seção é obrigatório"] if name.nil? || name.strip.empty?
        return [false, "Posição é obrigatória"] if position.nil? || position.length != 3
        return [false, "Direção é obrigatória"] if direction.nil? || direction.length != 3
        [true, nil]
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
