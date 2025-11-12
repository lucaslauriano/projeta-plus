
module Exportar
    PREFIX = "pro_mob_".freeze

    # ---------- Seleção ao vivo (Exportar) ----------
    @export_dialog = nil
    @selection_observer = nil
    
    # ---------- Redimensionamento ----------
    @attr_dialog = nil
    @attr_observer = nil
    
    # Função para gerar nome limpo (sem hífen isolado) e copiar para área de transferência
    def self.gerar_nome_limpo(nome, marca, dimensao)
      partes = []
      
      # Adicionar nome se não estiver vazio
      partes << nome unless nome.nil? || nome.strip.empty?
      
      # Adicionar marca se não estiver vazia
      partes << marca unless marca.nil? || marca.strip.empty?
      
      # Adicionar dimensão se não estiver vazia
      partes << dimensao unless dimensao.nil? || dimensao.strip.empty?
      
      # Juntar as partes com " - ", evitando hífens isolados
      nome_final = partes.join(" - ")
      
      # Copiar para área de transferência usando método do SketchUp
      begin
        # Método mais compatível com SketchUp
        if RUBY_PLATFORM =~ /mswin|mingw|cygwin/
          # Windows - usar comando cmd
          IO.popen('echo ' + nome_final.gsub('"', '""') + ' | clip', 'w').close
        elsif RUBY_PLATFORM =~ /darwin/
          # macOS
          IO.popen('pbcopy', 'w') { |f| f << nome_final }
        else
          # Linux
          IO.popen('xclip -selection clipboard', 'w') { |f| f << nome_final } rescue nil
        end
        puts "📋 Nome copiado para área de transferência: #{nome_final}"
      rescue => e
        puts "⚠️ Não foi possível copiar para área de transferência: #{e.message}"
        # Tentar método alternativo no Windows
        begin
          require 'win32/clipboard'
          Win32::Clipboard.set_data(nome_final)
          puts "📋 Nome copiado para área de transferência (método alternativo): #{nome_final}"
        rescue => e2
          puts "⚠️ Método alternativo também falhou: #{e2.message}"
        end
      end
      
      return nome_final
    end
    
    # Dimensões desejadas (podem ser definidas pelo usuário)
    ALTURA_DESEJADA ||= nil
    LARGURA_DESEJADA ||= nil
    COMPRIMENTO_DESEJADA ||= nil
    
    def self.ensure_live_selection
      sel = Sketchup.active_model.selection
      unless @selection_observer
        @last_selection_time = 0
        @selection_observer = Class.new(Sketchup::SelectionObserver) do
          def schedule(selection)
            return if FM_Extensions::Exportar.processing_selection?
            
            # Debounce aprimorado: evita múltiplas chamadas muito próximas
            @last_selection_time = Time.now.to_f
            current_time = @last_selection_time
            
            UI.start_timer(0.2, false) do
              # Só executa se não houve nova seleção nos últimos 200ms e não está processando
              if Time.now.to_f - current_time < 0.1 && !FM_Extensions::Exportar.processing_selection?
                begin
                  FM_Extensions::Exportar.handle_selection_changed(selection)
                rescue => e
                  puts "ERRO no observer de seleção: #{e.message}"
                ensure
                  FM_Extensions::Exportar.reset_processing_flag
                end
              end
            end
          end

          def onSelectionAdded(selection, entity); schedule(selection); end
          def onSelectionRemoved(selection, entity); schedule(selection); end
          def onSelectionCleared(selection); schedule(selection); end
          def onSelectionBulkChange(selection); schedule(selection); end
        end.new
      end
      # Remove antes de adicionar para evitar duplicatas; Selection não expõe .observers
      sel.remove_observer(@selection_observer) if @selection_observer
      sel.add_observer(@selection_observer)
    end

    def self.processing_selection?
      @processing_selection
    end
    
    def self.reset_processing_flag
      @processing_selection = false
    end

    def self.handle_selection_changed(selection)
      return if @processing_selection
      return unless @export_dialog && @export_dialog.visible?
      
      @processing_selection = true
      
      begin
        ent = selection.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }
        return unless ent && ent.valid?

        comp = ent.is_a?(Sketchup::Group) ? ent.to_component : ent
        return unless comp && comp.valid?
        
        tipo = get_attribute_safe(comp, "#{PREFIX}tipo", "").to_s.strip
        return if tipo.empty?

        key = [
          get_attribute_safe(comp, "#{PREFIX}nome", ""),
          get_attribute_safe(comp, "#{PREFIX}cor", ""),
          get_attribute_safe(comp, "#{PREFIX}marca", ""),
          tipo,
          get_attribute_safe(comp, "#{PREFIX}dimensao", ""),
          get_attribute_safe(comp, "#{PREFIX}ambiente", ""),
          get_attribute_safe(comp, "#{PREFIX}observacoes", ""),
          get_attribute_safe(comp, "#{PREFIX}link", "")
        ]

        updated_html = update_category_data_live(Sketchup.active_model, tipo, selected_id: comp.entityID, selected_key: key)
        return if updated_html.nil? || updated_html.empty?
        
        script = "document.querySelector('#table-" + tipo.gsub(' ', '-') + " tbody').innerHTML = `#{updated_html}`;"
        @export_dialog.execute_script(script) if @export_dialog && @export_dialog.visible?
      rescue => e
        puts "ERRO em handle_selection_changed: #{e.message}"
        puts e.backtrace.first(5) if e.backtrace
      ensure
        @processing_selection = false
      end
    end

    # Cache de instâncias com timeout de 2 segundos
    def self.get_cached_instances(model)
      current_time = Time.now.to_f
      
      # Invalida cache após 2 segundos ou se não existe
      if @instances_cache.empty? || current_time - @cache_timestamp > 2.0
        @instances_cache.clear
        instances = []
        collect_all_pro_mob_instances(model.entities, instances)
        
        # Agrupa por tipo para acelerar buscas
        instances.each do |inst|
          tipo = get_attribute_safe(inst, "#{PREFIX}tipo", "").to_s.strip
          next if tipo.empty?
          @instances_cache[tipo] ||= []
          @instances_cache[tipo] << inst
        end
        
        @cache_timestamp = current_time
      end
      
      @instances_cache
    end

    # Gera linhas da tabela destacando o item selecionado (quando fornecido)
    def self.update_category_data_live(model, categoria, selected_id: nil, selected_key: nil)
      begin
        instances_by_type = get_cached_instances(model)
        instances = instances_by_type[categoria] || []

        dados = Hash.new { |h, k| h[k] = { qtd: 0, ids: [] } }

        instances.each do |inst|
          next unless inst && inst.valid?
          
          # Já temos o tipo correto do cache, não precisa verificar novamente
          begin
            key = [
              get_attribute_safe(inst, "#{PREFIX}nome", ""),
              get_attribute_safe(inst, "#{PREFIX}cor", ""),
              get_attribute_safe(inst, "#{PREFIX}marca", ""),
              categoria,  # usar categoria diretamente
              get_attribute_safe(inst, "#{PREFIX}dimensao", ""),
              get_attribute_safe(inst, "#{PREFIX}ambiente", ""),
              get_attribute_safe(inst, "#{PREFIX}observacoes", ""),
              get_attribute_safe(inst, "#{PREFIX}link", ""),
              get_attribute_safe(inst, "#{PREFIX}valor", "")
            ]

            dados[key][:qtd] += 1
            dados[key][:ids] << inst.entityID
          rescue => e
            puts "ERRO processando instância: #{e.message}"
            next
          end
        end

      if dados.empty?
        "<tr><td colspan='11' style='color:red;'>Nenhum dado encontrado.</td></tr>"
      else
        index = 1
        # Ordenar por pro_mob_nome (primeiro elemento da key)
        dados_ordenados = dados.sort_by { |key, info| key[0].to_s.downcase }
        dados_ordenados.map do |key, info|
          nome, cor, marca, tipo, dimensao, ambiente, obs, link, valor = key
          id = (selected_key && selected_id && key == selected_key) ? selected_id : info[:ids].first
          highlight = (selected_key && key == selected_key)
          
          # Obter código do atributo pro_mob_cod ou gerar se não existir
          entity = Sketchup.active_model.entities.find { |e| e.entityID == id }
          codigo = if entity && get_attribute_safe(entity, "#{ProMobTipoAnnotator::PREFIX}cod")
                     get_attribute_safe(entity, "#{ProMobTipoAnnotator::PREFIX}cod")
                   else
                     ProMobTipoAnnotator.generate_annotation_code(tipo, index)
                   end
          
          # Obter cor do tipo para o fundo do código
          type_color = ProMobTipoAnnotator::TYPE_COLORS[tipo] || ProMobTipoAnnotator::TYPE_COLORS["Outros"]
          color_hex = ProMobTipoAnnotator.color_to_hex(type_color)
          
          # Calcular total (valor × quantidade)
          valor_num = valor.to_s.gsub(/[^0-9.,]/, '').gsub(',', '.').to_f
          total_item = valor_num * info[:qtd]
          
          html = "<tr id='linha-#{id}'#{highlight ? " style='background-color:#fff3cd'" : ''}>
            <td class='codigo-cell' style='background-color:#{color_hex}; color:white;'>#{codigo}</td>
            <td>#{nome}</td>
            <td>#{cor}</td>
            <td>#{marca}</td>
            <td>#{tipo}</td>
            <td>#{dimensao}</td>
            <td>#{ambiente}</td>
            <td>#{format_clickable_link(link)}</td>
            <td>#{obs}</td>
            <td>#{valor}</td>
            <td>#{info[:qtd]}</td>
            <td style='font-weight:bold;'>#{sprintf('%.2f', total_item)}</td>
            <td><button onclick='isolateItem(#{id})'>Isolar</button></td>
            <td><button onclick='deleteItem(#{id})'>Excluir</button></td>
          </tr>"
          index += 1
          html
        end.join
      end
      rescue => e
        puts "ERRO em update_category_data_live: #{e.message}"
        puts e.backtrace.first(3) if e.backtrace
        "<tr><td colspan='11' style='color:red;'>Erro ao carregar dados: #{e.message}</td></tr>"
      end
    end

    # Método para invalidar cache manualmente
    def self.invalidate_cache
      @instances_cache.clear if @instances_cache
      @cache_timestamp = 0
    end

    def self.isolate_item(target)
        SKETCHUP_CONSOLE.clear
        nome_cena = "geral"
        model = Sketchup.active_model
        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }

        if cena
          model.pages.selected_page = cena
        else
          puts "Cena '#{nome_cena}' não encontrada."
          return
        end

        model.start_operation("Isolar Item", true)

        # 1. Sobe até estar dentro do model.entities
      current = target
      highest_parent = current

      while current.respond_to?(:parent) && !current.parent.is_a?(Sketchup::Model)
        # só aceita Group ou ComponentInstance como pai mais alto
        break unless current.is_a?(Sketchup::Group) || current.is_a?(Sketchup::ComponentInstance)
        highest_parent = current
        current = current.parent
      end

        # 2. Seleciona apenas o pai mais alto
        model.selection.clear
        model.selection.add(highest_parent)

        # 3. Oculta todo o resto do modelo, exceto o pai mais alto e seus filhos
        model.entities.each do |e|
          # Mostra se é o pai ou está dentro dele
          e.visible = highest_parent == e || (e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)) && highest_parent.definition.entities.include?(e)
        end

        model.commit_operation
        
        # 4. Ajusta a câmera
        view = model.active_view
        eye    = Geom::Point3d.new(-1000, -1000, 1000)
        target_pt = Geom::Point3d.new(0, 0, 0)
        up     = Geom::Vector3d.new(0, 0, 1)

        view.camera.set(eye, target_pt, up)
        view.camera.perspective = true
        view.zoom_extents
    end


    # ---------- Funções auxiliares ----------
    def self.format_clickable_link(link)
      return "" if link.nil? || link.to_s.strip.empty?
      
      link_str = link.to_s.strip
      
      if link_str.match(/^https?:\/\//i)
        "<a href='#{link_str}' target='_blank' style='color: #007bff; text-decoration: underline;'>#{link_str}</a>"
      elsif link_str.match(/^www\./i) || link_str.include?('.')
        full_link = "http://#{link_str}"
        "<a href='#{full_link}' target='_blank' style='color: #007bff; text-decoration: underline;'>#{link_str}</a>"
      else
        link_str
      end
    end

    def self.set_attribute_safe(comp, key, value)
      comp.definition.set_attribute("dynamic_attributes", key, value)
    end

    def self.get_attribute_safe(comp, key, default = "")
      value = comp.definition.get_attribute("dynamic_attributes", key, nil)
      value = comp.get_attribute("dynamic_attributes", key, default) if value.nil?
      value || default
    end

    def self.sync_attributes_to_definition(comp)
      attrs = comp.attribute_dictionaries
      return unless attrs && attrs["dynamic_attributes"]
      
      attrs["dynamic_attributes"].each do |key, value|
        next unless key.start_with?(PREFIX) || key == "#{PREFIX}ambiente"
        comp.definition.set_attribute("dynamic_attributes", key, value)
      end
    end

    # Inicializa todos os atributos necessários para um componente móvel
    def self.initialize_default_attributes(comp)
      # Lista de atributos padrão que devem existir
      default_attributes = {
        "#{PREFIX}nome" => "",
        "#{PREFIX}cor" => "",
        "#{PREFIX}marca" => "",
        "#{PREFIX}tipo" => "",
        "#{PREFIX}observacoes" => "",
        "#{PREFIX}link" => "",
        "#{PREFIX}formato_dimensao" => "L x P x A",
        "#{PREFIX}dimensao" => "",
        "#{PREFIX}ambiente" => "",  # Usando o novo formato sem prefixo
        "#{PREFIX}valor" => ""  # Campo para valor do mobiliário
      }
      
      # Verifica e cria apenas os atributos que não existem
      default_attributes.each do |attr_name, default_value|
        current_value = get_attribute_safe(comp, attr_name, nil)
        if current_value.nil? || current_value.empty?
          set_attribute_safe(comp, attr_name, default_value)
        end
      end
      
      # Define a dimensão atual se não existir
      if get_attribute_safe(comp, "#{PREFIX}dimensao", "").empty?
        current_dim = dimension_string_for(comp)
        set_attribute_safe(comp, "#{PREFIX}dimensao", current_dim)
      end
    end

    # Coleta todos os componentes/grupos com atributo pro_mob_ até 5 níveis (reduzido para performance)
    def self.collect_all_pro_mob_instances(entities, arr, level=0)
      return if level > 5  # Reduzir para 5 níveis para melhor performance
      
      begin
        entities.each do |e|
          next unless e && e.valid?
          
          comp = case e
                 when Sketchup::Group 
                   next unless e.valid?
                   e.to_component
                 when Sketchup::ComponentInstance 
                   next unless e.valid?
                   e
                 else 
                   next
                 end

          next unless comp && comp.valid?

          begin
            tipo = get_attribute_safe(comp, "#{PREFIX}tipo", "").to_s.strip
            arr << comp unless tipo.empty?
          rescue => e
            puts "ERRO lendo atributos: #{e.message}"
            next
          end

          # Buscar dentro do componente/grupo recursivamente (com mais validações)
          if comp.definition && comp.definition.valid? && comp.definition.entities
            begin
              collect_all_pro_mob_instances(comp.definition.entities, arr, level+1)
            rescue => e
              puts "ERRO na recursão: #{e.message}"
              next
            end
          end
        end
      rescue => e
        puts "ERRO em collect_all_pro_mob_instances: #{e.message}"
      end
    end

    # Procura componente ou grupo por ID recursivamente
    def self.find_component_by_id(entities, target_id, level=0)
      return nil if level > 10  # Aumentar para 10 níveis
      entities.each do |e|
        next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
        comp = e.is_a?(Sketchup::Group) ? e.to_component : e
        return comp if comp.entityID == target_id
        
        # Buscar dentro do componente/grupo
        if comp.definition && comp.definition.entities
          found = find_component_by_id(comp.definition.entities, target_id, level+1)
          return found if found
        end
      end
      nil
    end

    # Torna visível recursivamente todos os elementos de um componente
    def self.set_visible_recursive(comp, value)
      comp.visible = value
      comp.definition.entities.each do |e|
        if e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
          set_visible_recursive(e.is_a?(Sketchup::Group) ? e.to_component : e, value)
        else
          e.visible = value
        end
      end
    end

    # ---------- Atualização da tabela ----------
    def self.update_category_data(model, categoria)
      instances = []
      collect_all_pro_mob_instances(model.entities, instances)

      dados = Hash.new { |h, k| h[k] = { qtd: 0, ids: [] } }

      instances.each do |inst|
        tipo = get_attribute_safe(inst, "#{PREFIX}tipo", "").to_s.strip
        next if tipo.empty? || tipo != categoria

        key = [
          get_attribute_safe(inst, "#{PREFIX}nome", ""),
          get_attribute_safe(inst, "#{PREFIX}cor", ""),
          get_attribute_safe(inst, "#{PREFIX}marca", ""),
          tipo,
          get_attribute_safe(inst, "#{PREFIX}dimensao", ""),
          get_attribute_safe(inst, "#{PREFIX}ambiente", ""),
          get_attribute_safe(inst, "#{PREFIX}observacoes", ""),
          get_attribute_safe(inst, "#{PREFIX}link", "")
        ]

        dados[key][:qtd] += 1
        dados[key][:ids] << inst.entityID
      end

      if dados.empty?
        "<tr><td colspan='11' style='color:red;'>Nenhum dado encontrado.</td></tr>"
      else
        index = 1
        # Ordenar por pro_mob_nome (primeiro elemento da key)
        dados_ordenados = dados.sort_by { |key, info| key[0].to_s.downcase }
        dados_ordenados.map do |key, info|
          nome, cor, marca, tipo, dimensao, ambiente, obs, link, valor = key
          id = info[:ids].first # usa o primeiro ID só como referência
          
          # Obter código do atributo pro_mob_cod ou gerar se não existir
          entity = Sketchup.active_model.entities.find { |e| e.entityID == id }
          codigo = if entity && get_attribute_safe(entity, "#{ProMobTipoAnnotator::PREFIX}cod")
                     get_attribute_safe(entity, "#{ProMobTipoAnnotator::PREFIX}cod")
                   else
                     ProMobTipoAnnotator.generate_annotation_code(tipo, index)
                   end
          
          # Obter cor do tipo para o fundo do código
          type_color = ProMobTipoAnnotator::TYPE_COLORS[tipo] || ProMobTipoAnnotator::TYPE_COLORS["Outros"]
          color_hex = ProMobTipoAnnotator.color_to_hex(type_color)
          
          # Calcular total (valor × quantidade)
          valor_num = valor.to_s.gsub(/[^0-9.,]/, '').gsub(',', '.').to_f
          total_item = valor_num * info[:qtd]
          
          html = "<tr id='linha-#{id}'>
            <td class='codigo-cell' style='background-color:#{color_hex}; color:white;'>#{codigo}</td>
            <td>#{nome}</td>
            <td>#{cor}</td>
            <td>#{marca}</td>
            <td>#{tipo}</td>
            <td>#{dimensao}</td>
            <td>#{ambiente}</td>
            <td>#{format_clickable_link(link)}</td>
            <td>#{obs}</td>
            <td>#{valor}</td>
            <td>#{info[:qtd]}</td>
            <td style='font-weight:bold;'>#{sprintf('%.2f', total_item)}</td>
            <td><button onclick='isolateItem(#{id})'>Isolar</button></td>
            <td><button onclick='deleteItem(#{id})'>Excluir</button></td>
          </tr>"
          index += 1
          html
        end.join
      end
    end

    def self.format_number(num)
      return "" if num.nil?
      arred = num.to_f.round(2)
      if arred.to_i == arred
        arred.to_i.to_s
      else
        # Mantém ponto decimal para compatibilidade com JavaScript
        sprintf('%.2f', arred).sub(/\.?0+$/, '')
      end
    end

    # ---------- Painel de Atributos (Seleção Dinâmica) ----------
    @attr_dialog = nil
    @attr_observer = nil

    def self.dimension_string_for(ent)
      comp = ent.is_a?(Sketchup::Group) ? ent.to_component : ent
      b = comp.bounds
      # L = X (width), P = Z (height), A = Y (depth) - SWAP Y/Z CORRIGIDO
      l = format_number(b.width.to_f * 2.54)
      p = format_number(b.height.to_f * 2.54)  # Profundidade = height
      a = format_number(b.depth.to_f * 2.54)   # Altura = depth
      "#{l}L x #{p}P x #{a}A cm"
    end

    def self.open_attributes_dialog_live
      sel = Sketchup.active_model.selection
      ent = sel.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }

      # Permite abrir sem seleção; usa strings vazias e preenche ao selecionar
      comp = ent ? (ent.is_a?(Sketchup::Group) ? ent.to_component : ent) : nil
      
      # Inicializa atributos padrão se o componente existe e tem tipo definido
      if comp && !get_attribute_safe(comp, "#{PREFIX}tipo", "").empty?
        initialize_default_attributes(comp)
      end
      nome     = comp ? get_attribute_safe(comp, "#{PREFIX}nome", "") : ""
      cor      = comp ? get_attribute_safe(comp, "#{PREFIX}cor", "") : ""
      marca    = comp ? get_attribute_safe(comp, "#{PREFIX}marca", "") : ""
      tipo     = comp ? get_attribute_safe(comp, "#{PREFIX}tipo", "") : ""
      obs      = comp ? get_attribute_safe(comp, "#{PREFIX}observacoes", "") : ""
      ambiente = comp ? get_attribute_safe(comp, "#{PREFIX}ambiente", "") : ""
      link     = comp ? get_attribute_safe(comp, "#{PREFIX}link", "") : ""
      valor    = comp ? get_attribute_safe(comp, "#{PREFIX}valor", "") : ""
      
      # Dimensões individuais ao vivo se há componente
      if ent
        bounds = ent.bounds
        x_val = format_number(bounds.width.to_f * 2.54)    # X = Largura
        y_val = format_number(bounds.height.to_f * 2.54)   # Y = Profundidade (height)
        z_val = format_number(bounds.depth.to_f * 2.54)    # Z = Altura (depth)
      else
        x_val = y_val = z_val = ""
      end

      html = <<-HTML
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            body { font-family: Arial, sans-serif; margin: 0; padding: 0; background-color: #f5f5f5; }12; border-bottom: 1px solid #ccc; }
            .tab-button { flex: 1; padding: 10px; cursor: pointer; background: #e0e0e0; border: none; font-weight: bold; color: #333; transition: 0.2s; }
            .tab-button.active { background: #007ACC; color: white; box-shadow: inset 0 -2px 6px rgba(0,0,0,0.2); }
            .tab-content { display: none; padding: 16px; }
            .tab-content.active { display: block; }
            .input-group { margin-bottom: 15px; }
            .input-group label { font-weight: bold; margin-bottom: 5px; display: flex; align-items: center; }
            input, select, button, textarea { width: 94%; padding: 10px; border: 1px solid #ccc; border-radius: 10px; box-sizing: border-box; }
            textarea { height:60px; resize: vertical; }
            button { background-color: #007ACC; color: white; font-weight: bold; border: none; cursor: pointer; }
            button:hover { background-color: #005f99; }
            .readonly-field { background: #f5f5f5 !important; }
          </style>
        </head>
        <body>

          <div id="atributos" class="tab-content active" style="display: block; padding: 16px;">
            
            <div id="status-selecao" style="background: #e8f5e8; border: 1px solid #4caf50; border-radius: 5px; padding: 8px; margin-bottom: 15px; font-size: 12px;">
              <strong>🎯 Status:</strong> <span id="status-texto">Selecione um componente ou grupo</span>
            </div>
            
            <div class="input-group">
              <label>Nome:</label>
              <input id="nome" type="text" value="#{nome}">
            </div>
            <div class="input-group">
              <label>Cor:</label>
              <input id="cor" type="text" value="#{cor}">
            </div>
            <div class="input-group">
              <label>Marca:</label>
              <input id="marca" type="text" value="#{marca}">
            </div>
            <div class="input-group">
              <label>Tipo:</label>
              <select id="tipo">
                <option value="Mobiliário" #{'selected' if tipo=="Mobiliário"}>Mobiliário</option>
                <option value="Eletrodomésticos" #{'selected' if tipo=="Eletrodomésticos"}>Eletrodomésticos</option>
                <option value="Louças e Metais" #{'selected' if tipo=="Louças e Metais"}>Louças e Metais</option> 
                <option value="Acessórios" #{'selected' if tipo=="Acessórios"}>Acessórios</option>
                <option value="Decoração" #{'selected' if tipo=="Decoração"}>Decoração</option>
              </select>
            </div>
            
            <h4>Dimensões (Redimensionamento ao vivo)</h4>
            <div class="input-group">
              <label style="display: flex; align-items: center; gap: 10px;">
                <input type="checkbox" id="trava_x" style="width: auto;">
                <span>🔒 Largura (cm):</span>
              </label>
              <input id="x" type="number" step="0.1" value="#{x_val}" onchange="redimensionarAoVivo('x')">
            </div>
            <div class="input-group">
              <label style="display: flex; align-items: center; gap: 10px;">
                <input type="checkbox" id="trava_y" style="width: auto;">
                <span>🔒 Profundidade (cm):</span>
              </label>
              <input id="y" type="number" step="0.1" value="#{y_val}" onchange="redimensionarAoVivo('y')">
            </div>
            <div class="input-group">
              <label style="display: flex; align-items: center; gap: 10px;">
                <input type="checkbox" id="trava_z" style="width: auto;">
                <span>🔒 Altura (cm):</span>
              </label>
              <input id="z" type="number" step="0.1" value="#{z_val}" onchange="redimensionarAoVivo('z')">
            </div>
            
            <div class="input-group" style="background: #e3f2fd; padding: 10px; border-radius: 5px; font-size: 12px;">
              <strong>💡 Dica:</strong> Marque o checkbox 🔒 para manter a proporção baseada nessa dimensão. 
              Altere os valores e o objeto será redimensionado automaticamente!
            </div>
            
            <div class="input-group">
              <label>Formato da Dimensão:</label>
              <select id="formato_dimensao">
                <option value="L x P">L x P</option>
                <option value="L x P x A" selected>L x P x A</option>
                <option value="L x A">L x A</option>
                <option value="">SEM DIMENSÃO</option>
              </select>
            </div>
            <div class="input-group">
              <label>Dimensão Final:</label>
              <input id="dimensao" type="text" readonly class="readonly-field">
            </div>
            
            <div class="input-group">
              <label>Ambiente:</label>
              <input id="ambiente" type="text" value="#{ambiente}">
            </div>
            <div class="input-group">
              <label>Valor:</label>
              <input id="valor" type="text" value="#{valor}" placeholder="Ex: R$ 150,00">
            </div>
            <div class="input-group">
              <label>Link:</label>
              <input id="link" type="text" value="#{link}">
            </div>
            <div class="input-group">
              <label>Observações:</label>
              <textarea id="observacoes">#{obs}</textarea>
            </div>
            <button onclick="enviar()">Salvar Atributos</button>
          </div>



          <script>
            // Variáveis para controlar as dimensões originais
            var dimensoesOriginais = { x: 0, y: 0, z: 0 };
            
            function redimensionarAoVivo(dimensao) {
              // console.log('redimensionarAoVivo chamado para:', dimensao);  // Debug desabilitado
              
              // Converte vírgula para ponto antes do parseFloat
              var valorX = parseFloat(String(document.getElementById('x').value || '0').replace(',', '.')) || 0;
              var valorY = parseFloat(String(document.getElementById('y').value || '0').replace(',', '.')) || 0;
              var valorZ = parseFloat(String(document.getElementById('z').value || '0').replace(',', '.')) || 0;
              
              // console.log('Valores lidos - X:', valorX, 'Y:', valorY, 'Z:', valorZ);  // Debug desabilitado
              
              // Validação: não aceita valores zerados ou negativos
              if (valorX <= 0 || valorY <= 0 || valorZ <= 0) {
                console.log('Erro: Todas as dimensões devem ser maiores que zero');
                console.log('Valores que causaram erro - X:', valorX, 'Y:', valorY, 'Z:', valorZ);
                return;
              }
              
              var travaX = document.getElementById('trava_x').checked;
              var travaY = document.getElementById('trava_y').checked;
              var travaZ = document.getElementById('trava_z').checked;
              
              // Se alguma trava estiver marcada, aplicar redimensionamento proporcional
              if (travaX || travaY || travaZ) {
                var fatorEscala = 1.0;
                
                if (travaX && dimensoesOriginais.x > 0) {
                  fatorEscala = valorX / dimensoesOriginais.x;
                } else if (travaY && dimensoesOriginais.y > 0) {
                  fatorEscala = valorY / dimensoesOriginais.y;
                } else if (travaZ && dimensoesOriginais.z > 0) {
                  fatorEscala = valorZ / dimensoesOriginais.z;
                }
                
                // Validação do fator de escala
                if (fatorEscala > 0) {
                  sketchup.redimensionarProporcional(fatorEscala);
                } else {
                  console.log('Erro: Fator de escala inválido');
                }
                
              } else {
                // Redimensionamento independente (sem proporção)
                sketchup.redimensionarIndependente(valorX, valorY, valorZ);
              }
            }

            function setVal(id, v){ 
              var el=document.getElementById(id); 
              if(el){ 
                el.value = v || ''; 
              }
            }
            
            // Atualiza a dimensão final baseada no formato selecionado
            function atualizarDimensaoFinal() {
              var x = parseFloat(document.getElementById('x').value) || 0;
              var y = parseFloat(document.getElementById('y').value) || 0;
              var z = parseFloat(document.getElementById('z').value) || 0;
              var formato = document.getElementById('formato_dimensao').value;
              var dimensaoEl = document.getElementById('dimensao');
              
              if (!formato) {
                dimensaoEl.value = '';
                return;
              }
              
              var dimensaoFinal = '';
              switch(formato) {
                case 'L x P x A':
                  dimensaoFinal = x + 'L x ' + y + 'P x ' + z + 'A cm';
                  break;
                case 'L x P':
                  dimensaoFinal = x + 'L x ' + y + 'P cm';
                  break;
                case 'L x A':
                  dimensaoFinal = x + 'L x ' + z + 'A cm';
                  break;
                default:
                  dimensaoFinal = '';
              }
              
              dimensaoEl.value = dimensaoFinal;
            }
            
            // Adiciona event listeners com timeout para garantir que elementos existam
            setTimeout(function() {
              var formatoEl = document.getElementById('formato_dimensao');
              var xEl = document.getElementById('x');
              var yEl = document.getElementById('y');
              var zEl = document.getElementById('z');
              
              if(formatoEl) formatoEl.addEventListener('change', atualizarDimensaoFinal);
              if(xEl) xEl.addEventListener('input', atualizarDimensaoFinal);
              if(yEl) yEl.addEventListener('input', atualizarDimensaoFinal);
              if(zEl) zEl.addEventListener('input', atualizarDimensaoFinal);
            }, 100);
            
            function enviar(){
              var dados = {
                nome: document.getElementById("nome").value,
                cor: document.getElementById("cor").value,
                marca: document.getElementById("marca").value,
                tipo: document.getElementById("tipo").value,
                x: document.getElementById("x").value,
                y: document.getElementById("y").value,
                z: document.getElementById("z").value,
                formato_dimensao: document.getElementById("formato_dimensao").value,
                dimensao: document.getElementById("dimensao").value,
                observacoes: document.getElementById("observacoes").value,
                link: document.getElementById("link").value,
                valor: document.getElementById("valor").value
              };
              // Salvar diretamente como pro_ambiente sem o prefixo pro_mob_
              dados["pro_mob_ambiente"] = document.getElementById("ambiente").value;
              sketchup.salvarAtributosLive(JSON.stringify(dados));
            }


            window.fmSetSelectedBlockAttr = function(payload){
              try { 
                var p = (typeof payload==='string') ? JSON.parse(payload) : payload; 
                // console.log('Payload recebido:', p);  // Debug desabilitado
              } catch(e){ 
                console.error('Erro ao processar payload:', e, payload);
                return; 
              }
              
              // Atualiza status de seleção
              var statusEl = document.getElementById('status-texto');
              var statusBox = document.getElementById('status-selecao');
              if(p.selecionado && p.nome_objeto) {
                if(statusEl) statusEl.innerHTML = 'Objeto selecionado: <strong>' + p.nome_objeto + '</strong> (' + p.x + ' x ' + p.y + ' x ' + p.z + ' cm)';
                if(statusBox) {
                  statusBox.style.background = '#e8f5e8';
                  statusBox.style.borderColor = '#4caf50';
                }
                // Habilita campos
                document.querySelectorAll('input, select, textarea').forEach(function(el) {
                  el.disabled = false;
                  el.style.opacity = '1';
                });
              }
              
              setVal('nome', p.nome);
              setVal('cor', p.cor);
              setVal('marca', p.marca);
              var tipoSel = document.getElementById('tipo'); if(tipoSel){ tipoSel.value = p.tipo || ''; }
              
              // Popula dimensões e armazena valores originais para cálculo de proporção
              var xVal = (p.x !== undefined && p.x !== null && p.x !== '') ? p.x : '';
              var yVal = (p.y !== undefined && p.y !== null && p.y !== '') ? p.y : '';
              var zVal = (p.z !== undefined && p.z !== null && p.z !== '') ? p.z : '';
              
              setVal('x', xVal);
              setVal('y', yVal);
              setVal('z', zVal);
              
              // console.log('Dimensões definidas - X:', xVal, 'Y:', yVal, 'Z:', zVal);  // Debug desabilitado
              
              // Armazena dimensões originais para cálculo proporcional (converte vírgula para ponto)
              dimensoesOriginais.x = parseFloat(String(xVal).replace(',', '.')) || 0;
              dimensoesOriginais.y = parseFloat(String(yVal).replace(',', '.')) || 0;
              dimensoesOriginais.z = parseFloat(String(zVal).replace(',', '.')) || 0;
              
              // Formato salvo ou padrão
              var formatoSel = document.getElementById('formato_dimensao'); 
              if(formatoSel){ formatoSel.value = p.formato_dimensao || 'L x P x A'; }
              
              setVal('ambiente', p.ambiente);
              setVal('link', p.link);
              setVal('observacoes', p.observacoes);
              
              // Atualiza dimensão final
              setTimeout(function() {
                if(typeof atualizarDimensaoFinal === 'function') {
                  atualizarDimensaoFinal();
                }
              }, 50);
            };
            window.fmClearSelectedBlockAttr = function(payload){
              var p = payload ? ((typeof payload==='string') ? JSON.parse(payload) : payload) : {};
              
              // Atualiza status
              var statusEl = document.getElementById('status-texto');
              var statusBox = document.getElementById('status-selecao');
              
              if(p.total_selection > 0) {
                if(statusEl) statusEl.innerHTML = 'Seleção inválida: ' + p.total_selection + ' objeto(s) selecionado(s). Selecione apenas <strong>um componente ou grupo</strong>.';
                if(statusBox) {
                  statusBox.style.background = '#fff3cd';
                  statusBox.style.borderColor = '#ffc107';
                }
              } else {
                if(statusEl) statusEl.innerHTML = 'Nenhum objeto selecionado. Clique em um <strong>componente ou grupo</strong> para editar.';
                if(statusBox) {
                  statusBox.style.background = '#f8f9fa';
                  statusBox.style.borderColor = '#6c757d';
                }
              }
              
              // Desabilita campos quando não há seleção válida
              document.querySelectorAll('input:not([type="checkbox"]), select, textarea').forEach(function(el) {
                el.disabled = true;
                el.style.opacity = '0.6';
              });
              
              setVal('nome',''); setVal('cor',''); setVal('marca','');
              var tipoSel = document.getElementById('tipo'); if(tipoSel){ tipoSel.value = ''; }
              setVal('x',''); setVal('y',''); setVal('z','');
              
              // Limpa checkboxes de trava
              document.getElementById('trava_x').checked = false;
              document.getElementById('trava_y').checked = false;
              document.getElementById('trava_z').checked = false;
              
              // Limpa dimensões originais
              dimensoesOriginais = { x: 0, y: 0, z: 0 };
              
              var formatoSel = document.getElementById('formato_dimensao'); if(formatoSel){ formatoSel.value = 'L x P x A'; }
              setVal('dimensao',''); setVal('ambiente',''); setVal('link',''); setVal('observacoes','');
            };
            
            // Adiciona listeners aos campos de dimensão para redimensionamento automático
            function adicionarListenersDimensao() {
              ['x', 'y', 'z'].forEach(function(campo) {
                var el = document.getElementById(campo);
                if(el) {
                  el.addEventListener('input', function() {
                    if(this.value && !isNaN(this.value) && parseFloat(this.value) > 0) {
                      // Atualizar dimensão final e aplicar redimensionamento
                      atualizarDimensaoFinal();
                      redimensionarAoVivo(campo);
                    }
                  });
                }
              });
            }
            
            // Função para habilitar/desabilitar interface baseado na seleção
            function habilitarInterface(habilitar) {
              document.querySelectorAll('input:not([type="checkbox"]), select, textarea').forEach(function(el) {
                el.disabled = !habilitar;
                el.style.opacity = habilitar ? '1' : '0.6';
              });
            }
            
            // Inicialização quando o documento carregar
            document.addEventListener('DOMContentLoaded', function() {
              adicionarListenersDimensao();
              // Interface inicialmente desabilitada até que algo seja selecionado
              habilitarInterface(false);
            });
          </script>
        </body>
        </html>
      HTML

      dlg = UI::HtmlDialog.new(
        dialog_title: "FM Mobiliário - Atributos e Redimensionamento",
        width: 420,
        height: 580,
        style: UI::HtmlDialog::STYLE_UTILITY,  # Permite ficar "flutuante"
        resizable: true
      )

      dlg.set_html(html)
      # Callback para retornar dimensões ao vivo do item selecionado
      dlg.add_action_callback("get_live_dimensions") do |_ctx|
        sel = Sketchup.active_model.selection
        ent = sel.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }
        if ent
          comp_sel = ent.is_a?(Sketchup::Group) ? ent.to_component : ent
          # Pega sempre do modelo sem inversão
          dims = dimension_string_for(comp_sel)
          new_val = dims
          dlg.execute_script("(function(){ var el=document.getElementById('dimensao'); if(el){ el.value = '#{new_val.gsub("'","\\'") }'; } })();")
        end
      end
      dlg.add_action_callback("salvarAtributosLive") do |_ctx, json|
        dados = JSON.parse(json)
        sel = Sketchup.active_model.selection
        ent = sel.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }
        if ent
          c = ent.is_a?(Sketchup::Group) ? ent.to_component : ent
          
          # Salva todos os atributos incluindo os novos campos x, y, z
          dados.each do |k, v|
            if k == "#{PREFIX}ambiente"
              c.definition.set_attribute("dynamic_attributes", k, v)  # Salva diretamente sem prefixo
            else
              c.definition.set_attribute("dynamic_attributes", "#{PREFIX}#{k}", v)
            end
          end
          
          new_name = gerar_nome_limpo(dados['nome'], dados['marca'], dados['dimensao'])
          c.definition.name = new_name
          
          UI.messagebox("Atributos salvos com sucesso!")
        else
          UI.messagebox("Selecione um componente ou grupo para salvar os atributos.")
        end
      end

      # Callback para redimensionamento proporcional ao vivo
      dlg.add_action_callback("redimensionarProporcional") do |_, fator_escala|
        # puts ">>> Callback redimensionarProporcional chamado com fator: #{fator_escala}"  # Debug desabilitado
        
        sel = Sketchup.active_model.selection
        ent = sel.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }
        
        unless ent
          puts "ERRO: Nenhum objeto válido selecionado para redimensionar"
          return
        end
        
        unless fator_escala.to_f > 0
          puts "ERRO: Fator de escala inválido: #{fator_escala}"
          return
        end
        
        bounds = ent.bounds
        origem = bounds.min
        
        model = Sketchup.active_model
        model.start_operation('Redimensionar Proporcional', true)
        ent.transform!(Geom::Transformation.scaling(origem, fator_escala.to_f))
        model.commit_operation
        
        # Atualizar interface após redimensionamento com delay
        UI.start_timer(0.2, false) { push_selected_to_attr_dialog }
      end

      # Callback para redimensionamento independente ao vivo  
      dlg.add_action_callback("redimensionarIndependente") do |_, nova_x, nova_y, nova_z|
        # puts ">>> Callback redimensionarIndependente chamado - X: #{nova_x}, Y: #{nova_y}, Z: #{nova_z}"  # Debug desabilitado
        
        sel = Sketchup.active_model.selection
        ent = sel.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }
        
        unless ent
          puts "ERRO: Nenhum objeto válido selecionado para redimensionar independente"
          return
        end
        
        # Validação: não aceita valores zerados ou negativos
        nova_x_f = nova_x.to_f
        nova_y_f = nova_y.to_f  
        nova_z_f = nova_z.to_f
        
        unless nova_x_f > 0 && nova_y_f > 0 && nova_z_f > 0
          puts "ERRO: Dimensões inválidas - X: #{nova_x_f}, Y: #{nova_y_f}, Z: #{nova_z_f}"
          return
        end
        
        bounds = ent.bounds
        largura_atual_cm = bounds.width * 2.54      # X = largura
        profundidade_atual_cm = bounds.height * 2.54 # Y = profundidade (height)
        altura_atual_cm = bounds.depth * 2.54      # Z = altura (depth)

        return if largura_atual_cm <= 0 || profundidade_atual_cm <= 0 || altura_atual_cm <= 0

        sx = nova_x_f / largura_atual_cm         # nova_x é largura
        sy = nova_y_f / profundidade_atual_cm    # nova_y é profundidade
        sz = nova_z_f / altura_atual_cm          # nova_z é altura
        origem = bounds.min
        
        # puts "Aplicando transformação - SX: #{sx}, SY: #{sy}, SZ: #{sz}"  # Debug desabilitado
        
        model = Sketchup.active_model
        model.start_operation('Redimensionar Independente', true)
        ent.transform!(Geom::Transformation.scaling(origem, sx, sy, sz))
        model.commit_operation
        
        # puts "Redimensionamento concluído com sucesso!"  # Debug desabilitado
        
        # Atualizar interface após redimensionamento com delay
        UI.start_timer(0.2, false) { push_selected_to_attr_dialog }
      end

      unless @attr_observer
        @attr_observer = Class.new(Sketchup::SelectionObserver) do
          def schedule(selection)
            # Pequeno delay para garantir que a seleção foi processada
            UI.start_timer(0.1, false) { FM_Extensions::Exportar.push_selected_to_attr_dialog }
          end
          def onSelectionAdded(selection, entity)
            puts "Objeto adicionado à seleção: #{entity.class}"
            schedule(selection)
          end
          def onSelectionRemoved(selection, entity)
            puts "Objeto removido da seleção: #{entity.class}"
            schedule(selection)
          end
          def onSelectionCleared(selection)
            puts "Seleção limpa"
            schedule(selection)
          end
          def onSelectionBulkChange(selection)
            puts "Mudança em massa na seleção: #{selection.length} objetos"
            schedule(selection)
          end
        end.new
      end
      # Remove antes de adicionar para evitar duplicatas
      sel.remove_observer(@attr_observer) if @attr_observer
      sel.add_observer(@attr_observer)

      @attr_dialog = dlg
      dlg.set_on_closed { 
        @attr_dialog = nil
        # Remove observer
        if @attr_observer
          sel.remove_observer(@attr_observer)
          @attr_observer = nil
        end
      }
      dlg.show

      push_selected_to_attr_dialog
      
      # Trigger imediato para seleção atual
      UI.start_timer(0.1, false) do
        current_selection = Sketchup.active_model.selection
        push_selected_to_attr_dialog if current_selection.length > 0
      end
    end

    def self.push_selected_to_attr_dialog
      return unless @attr_dialog && @attr_dialog.visible?
      
      sel = Sketchup.active_model.selection
      ent = sel.detect { |e| e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group) }
      
      # Cache simples: evita processamento se mesma seleção
      current_selection_id = ent ? ent.entityID : nil
      if @last_processed_selection == current_selection_id
        return
      end
      @last_processed_selection = current_selection_id
      
      if ent
        comp = ent.is_a?(Sketchup::Group) ? ent.to_component : ent
        
        # Inicializa atributos padrão se o componente tem tipo definido
        tipo_atual = get_attribute_safe(comp, "#{PREFIX}tipo", "")
        if !tipo_atual.empty?
          initialize_default_attributes(comp)
        end
        
        # Debug reduzido (apenas para casos problemáticos)
        if comp.nil? || (!comp.definition || comp.definition.name.nil? || comp.definition.name.empty?)
          puts "AVISO: Objeto selecionado pode ter problemas - ID: #{ent.entityID}"
        end
        
        # Calcula dimensões atuais dos bounds (ao vivo)
        begin
          bounds = ent.bounds
          
          # Debug: verificar se bounds é válido
          if bounds.width == 0 || bounds.height == 0 || bounds.depth == 0
            puts "AVISO: Objeto com bounds zerados - Width: #{bounds.width}, Height: #{bounds.height}, Depth: #{bounds.depth}"
          end
          
          # Garantir que bounds são números válidos
          width_cm = bounds.width.to_f * 2.54
          height_cm = bounds.height.to_f * 2.54  
          depth_cm = bounds.depth.to_f * 2.54
          
          # Debug detalhado apenas se bounds problemáticos
          if bounds.width == 0 || bounds.height == 0 || bounds.depth == 0
            puts "Bounds originais - W: #{bounds.width}, H: #{bounds.height}, D: #{bounds.depth}"
            puts "Bounds em CM - W: #{width_cm}, H: #{height_cm}, D: #{depth_cm}"
          end
          
          # Se alguma dimensão for 0 ou muito pequena, usar valor mínimo
          width_cm = 0.1 if width_cm <= 0.01
          height_cm = 0.1 if height_cm <= 0.01  
          depth_cm = 0.1 if depth_cm <= 0.01
          
          x_atual = format_number(width_cm)   # X = Largura
          y_atual = format_number(height_cm)  # Y = Profundidade (height)
          z_atual = format_number(depth_cm)   # Z = Altura (depth)
          
          # puts "Dimensões calculadas - X: #{x_atual}, Y: #{y_atual}, Z: #{z_atual}"  # Debug desabilitado
          
        rescue => e
          puts "ERRO ao calcular bounds: #{e.message}"
          x_atual = y_atual = z_atual = "0.00"
        end
        
        # Nome do objeto para exibir na interface
        nome_objeto = if comp.definition && comp.definition.name && !comp.definition.name.empty?
                        comp.definition.name
                      else
                        "Objeto sem nome (#{ent.class.name})"
                      end
        
        # Buscar atributos com fallback seguro
        begin
          nome = get_attribute_safe(comp, "#{PREFIX}nome", "") || ""
          cor = get_attribute_safe(comp, "#{PREFIX}cor", "") || ""
          marca = get_attribute_safe(comp, "#{PREFIX}marca", "") || ""
          tipo = get_attribute_safe(comp, "#{PREFIX}tipo", "") || ""
          formato = get_attribute_safe(comp, "#{PREFIX}formato_dimensao", "L x P x A") || "L x P x A"
          ambiente = get_attribute_safe(comp, "#{PREFIX}ambiente", "") || ""
          obs = get_attribute_safe(comp, "#{PREFIX}observacoes", "") || ""
          link = get_attribute_safe(comp, "#{PREFIX}link", "") || ""
          valor = get_attribute_safe(comp, "#{PREFIX}valor", "") || ""
          
          # puts "Atributos lidos - Nome: '#{nome}', Tipo: '#{tipo}', Marca: '#{marca}'"  # Debug desabilitado
        rescue => e
          puts "ERRO ao ler atributos: #{e.message}"
          nome = cor = marca = tipo = ambiente = obs = link = valor = ""
          formato = "L x P x A"
        end
        
        payload = {
          nome: nome,
          cor: cor,
          marca: marca,
          tipo: tipo,
          x: x_atual,
          y: y_atual,
          z: z_atual,
          formato_dimensao: formato,
          ambiente: ambiente,
          observacoes: obs,
          link: link,
          valor: valor,
          nome_objeto: nome_objeto,
          selecionado: true
        }
        
        # puts "Payload enviado: #{payload.inspect}"  # Debug desabilitado
        # puts "Atualizando interface para: #{nome_objeto} (#{x_atual}x#{y_atual}x#{z_atual})"  # Debug desabilitado
        @attr_dialog.execute_script("window.fmSetSelectedBlockAttr && window.fmSetSelectedBlockAttr(" + payload.to_json + ");")
      else
        # Nenhum objeto válido selecionado
        payload = { selecionado: false, total_selection: sel.length }
        @attr_dialog.execute_script("window.fmClearSelectedBlockAttr && window.fmClearSelectedBlockAttr(" + payload.to_json + ");")
      end
    end
    
    # ---------- Edição de atributos ----------
    def self.edit_component_attributes(comp)
      bounds = comp.bounds
      largura = format_number(bounds.width.to_f * 2.54)
      altura  = format_number(bounds.height.to_f * 2.54)
      profund = format_number(bounds.depth.to_f * 2.54)

      

      dimensao = "#{largura} x #{altura} x #{profund} cm"



      nome     = get_attribute_safe(comp, "#{PREFIX}nome", "")
      cor      = get_attribute_safe(comp, "#{PREFIX}cor", "")
      marca    = get_attribute_safe(comp, "#{PREFIX}marca", "")
      tipo     = get_attribute_safe(comp, "#{PREFIX}tipo", "")
      obs      = get_attribute_safe(comp, "#{PREFIX}observacoes", "")
      ambiente = get_attribute_safe(comp, "#{PREFIX}ambiente", "")
      link = get_attribute_safe(comp, "#{PREFIX}link", "")
      valor = get_attribute_safe(comp, "#{PREFIX}valor", "")



      html = <<-HTML
        <html>
        <head>
          <meta charset="UTF-8">
          <style>
            body { font-family: Arial; padding: 10px; }
            label { display:block; margin-top:8px; }
            input, select, textarea { width:95%; padding:4px; }
            textarea { height:60px; }
            button { margin-top:15px; padding:6px 12px; }
          </style>
        </head>
        <body>
          <h3>Definir atributos do componente</h3>
          <label>Nome: <input id="nome" type="text" value="#{nome}"></label>
          <label>Cor: <input id="cor" type="text" value="#{cor}"></label>
          <label>Marca: <input id="marca" type="text" value="#{marca}"></label>
          <label>Tipo:
            <select id="tipo">
              <option value="Mobiliário" #{'selected' if tipo=="Mobiliário"}>Mobiliário</option>
              <option value="Eletrodomésticos" #{'selected' if tipo=="Eletrodomésticos"}>Eletrodomésticos</option>
              <option value="Louças e Metais" #{'selected' if tipo=="Louças e Metais"}>Louças e Metais</option>
              <option value="Acessórios" #{'selected' if tipo=="Acessórios"}>Acessórios</option>
              <option value="Decoração" #{'selected' if tipo=="Decoração"}>Decoração</option>
            </select>
          </label>
          <label>Dimensão (LxAxP):</label>
          <input id="dimensao" type="text" value="#{dimensao}" readonly>
          <label>Ambiente: <input id="ambiente" type="text" value="#{ambiente}"></label>
          <label>Valor: <input id="valor" type="text" value="#{valor}" placeholder="Ex: R$ 150,00"></label>
          <label>Link: <input id="link" type="text" value="#{link}"></label>
          <label>Observações:</label>
          <textarea id="observacoes">#{obs}</textarea>
          <button onclick="enviar()">Salvar</button>

          <script>
            function enviar(){
              var dados = {
                nome: document.getElementById("nome").value,
                cor: document.getElementById("cor").value,
                marca: document.getElementById("marca").value,
                tipo: document.getElementById("tipo").value,
                observacoes: document.getElementById("observacoes").value,
                link: document.getElementById("link").value,
                valor: document.getElementById("valor").value
              };
              // Salvar diretamente como pro_ambiente sem o prefixo pro_mob_
              dados["pro_mob_ambiente"] = document.getElementById("ambiente").value;
              sketchup.salvarAtributos(JSON.stringify(dados));
            }
          </script>
        </body>
        </html>
      HTML

      dlg = UI::HtmlDialog.new(
        dialog_title: "Atributos do Componente",
        width: 320,
        height: 480,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      dlg.set_html(html)
      dlg.add_action_callback("salvarAtributos") do |_ctx, json|
        dados = JSON.parse(json)
        dados.each do |k, v|
          if k == "pro_mob_ambiente"
            comp.definition.set_attribute("dynamic_attributes", k, v)  # Salva diretamente sem prefixo
          else
            comp.definition.set_attribute("dynamic_attributes", "#{PREFIX}#{k}", v)
          end
        end
        # Salva a dimensão atual dos bounds no momento do salvamento
        current_dim = dimension_string_for(comp)
        comp.definition.set_attribute("dynamic_attributes", "#{PREFIX}dimensao", current_dim)
        new_name = gerar_nome_limpo(dados['nome'], dados['marca'], current_dim)
        comp.definition.name = new_name
        UI.messagebox("Atributos salvos com dimensão atual: #{current_dim}")
      end
      dlg.show
    end

    # ---------- Janela de Exportação ----------
    def self.open_export_dialog
      model = Sketchup.active_model
      if model.path.empty?
        UI.messagebox("Salve o modelo antes de exportar o CSV.")
        return
      end

      tipos = []
      instances = []
      collect_all_pro_mob_instances(model.entities, instances)
      instances.each do |inst|
        tipo = get_attribute_safe(inst, "#{PREFIX}tipo", "").to_s.strip
        tipos << tipo unless tipo.empty?
      end
      tipos.uniq!
      return UI.messagebox("Nenhum componente com atributo '#{PREFIX}tipo' encontrado.") if tipos.empty?

      dialog = UI::HtmlDialog.new(
        dialog_title: "Relatórios por Tipo",
        preferences_key: "fm_exportar_tipos",
        scrollable: true,
        resizable: true,
        width: 950,
        height: 700,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      html_sections = tipos.map do |tipo|
        # Gerar dados da categoria imediatamente
        dados_categoria = update_category_data_live(model, tipo)
        
        # Calcular total geral da categoria
        dados = collect_data_for_category(model, tipo)
        total_geral = dados.sum do |key, info|
          valor = key[8] || "" # valor é o 9º elemento (índice 8)
          valor_num = valor.to_s.gsub(/[^0-9.,]/, '').gsub(',', '.').to_f
          valor_num * info[:qtd]
        end
        
        <<-HTML
        <div class="categoria">
          <h2>#{tipo} <span style="color:#666; font-size:12px;">(#{collect_data_for_category(model, tipo).length} itens)</span></h2>
          <table id="table-#{tipo.gsub(' ', '-')}">
            <thead>
              <tr>
              <th>Código</th>
              <th>Nome</th><th>Cor</th><th>Marca</th><th>Tipo</th>
              <th>Dimensão</th><th>Ambiente</th><th>Link</th><th>Observações</th>
              <th>Valor</th>
              <th>Qtd</th><th>Total</th><th>Isolar</th><th>Excluir</th>
              </tr>
            </thead>
            <tbody>#{dados_categoria}
              <tr style="background-color:#f8f9fa; font-weight:bold; border-top:2px solid #dee2e6;">
                <td colspan="11" style="text-align:right; padding:10px;">TOTAL GERAL:</td>
                <td style="font-size:16px; color:#28a745;">#{sprintf('%.2f', total_geral)}</td>
                <td colspan="2"></td>
              </tr>
            </tbody>
          </table>
          <button onclick="updateCategory('#{tipo}')">🔄 Recarregar Dados</button>
          <button onclick="exportCategory('#{tipo}')">📊 Exportar CSV</button>
          <hr>
        </div>
        HTML
      end.join("\n")

      html_content = <<-HTML
      <!DOCTYPE html>
      <html lang="pt">
        <head>
          <meta charset='UTF-8'>
          <title>Relatórios por Tipo</title>
          <style>
            body{font-family:'Century Gothic',sans-serif;margin:10px;text-align:left;background-color:#f6f6f6;}
            h1{font-size:12px;text-align:left;margin:10px 0;}
            h2{font-size:12px;text-align:left;margin:10px 0;}
            table{font-size:12px;width:100%;border-collapse:collapse;margin:10px 0;background:#fff;}
            th,td{border:1px solid #ddd;padding:8px;text-align:left;}
            th{background-color:#eee;}
            .codigo-cell{font-family:'Century Gothic',sans-serif;font-weight:bold;text-align:center;border-radius:4px;}
            button{margin:2px;padding:4px 8px;font-size:12px;cursor:pointer;border-radius:8px;background:#dee9b6;border:0;}
            button:hover{background:#becc8a;}
          </style>
        </head>
        <body>
          <h1>📋 Relatórios de Componentes por Tipo</h1>
          <p style="color:#666; margin-bottom:20px;">✅ Dados carregados automaticamente</p>
          #{html_sections}
          <script>
            function updateCategory(categoria){ sketchup.update_category(categoria); }
            function exportCategory(categoria){ sketchup.export_category(categoria); }

            function isolateItem(id){ sketchup.isolate_item(id); }

            function deleteItem(id){
              const row = document.getElementById('linha-'+id);
              if(row) row.remove();
              reajustarNumeracao();
            }

            function reajustarNumeracao(){
              const linhas = document.querySelectorAll("tbody tr");
              linhas.forEach((linha, i) => {
                const celulaSeq = linha.querySelector(".seq");
                if(celulaSeq) celulaSeq.textContent = i+1;
              });
            }

          </script>
        </body>
      </html>
      HTML

      dialog.set_html(html_content)
      # Preferências iniciais
      prefs = load_category_prefs(tipos)

      dialog.add_action_callback("save_prefs") do |_ctx, json|
        begin
          prefs_obj = JSON.parse(json)
          save_category_prefs(prefs_obj)
        rescue => e
          puts "Erro ao salvar prefs: #{e}"
        end
      end

      dialog.add_action_callback("export_selected_xlsx") do |_ctx|
        begin
          # Carrega as preferências ou usa padrão
          prefs_json = Sketchup.read_default('fm_exportar_tipos', 'prefs', '{}')
          prefs_json = '{}' if prefs_json.nil? || prefs_json.empty?
          
          begin
            prefs = JSON.parse(prefs_json)
          rescue JSON::ParserError => parse_error
            puts "Erro ao fazer parse das preferências: #{parse_error.message}"
            prefs = {}
            # Limpar preferência corrompida
            Sketchup.write_default('fm_exportar_tipos', 'prefs', '{}')
          end
          
          prefs = {} unless prefs.is_a?(Hash)
          export_selected_xlsx(model, prefs)
        rescue => e
          UI.messagebox("Falha ao exportar XLSX: #{e.message}")
          puts "ERRO detalhado: #{e.backtrace.first(5)}" if e.backtrace
        end
      end

      dialog.add_action_callback("save_column_prefs") do |_ctx, prefs_json|
        begin
          Sketchup.write_default('fm_exportar_colunas', 'prefs', prefs_json)
          puts "Preferências de colunas salvas: #{prefs_json}"
        rescue => e
          puts "Erro ao salvar preferências de colunas: #{e}"
        end
      end

      dialog.add_action_callback("update_category") do |_ctx, categoria|
        updated_html = update_category_data(model, categoria)
        table_id = 'table-' + categoria.gsub(' ','-')
        script = "(function(){var tb=document.querySelector('#"+table_id+" tbody'); if(tb){ tb.innerHTML = `#{updated_html}`; } if(window.fmApplyCols){ window.fmApplyCols(window.fmColPrefs||{}); }})();"
        dialog.execute_script(script)
      end

      dialog.add_action_callback("export_category") do |_ctx, categoria|
          dados = Hash.new { |h, k| h[k] = { qtd: 0 } }

          instances = []
          collect_all_pro_mob_instances(model.entities, instances)
          instances.each do |inst|
            tipo = get_attribute_safe(inst, "#{PREFIX}tipo", "").to_s.strip
            next if tipo.empty? || tipo != categoria

            key = [
              get_attribute_safe(inst, "#{PREFIX}nome", ""),
              get_attribute_safe(inst, "#{PREFIX}cor", ""),
              get_attribute_safe(inst, "#{PREFIX}marca", ""),
              tipo,
              get_attribute_safe(inst, "#{PREFIX}dimensao", ""),
              get_attribute_safe(inst, "#{PREFIX}ambiente", ""),
              get_attribute_safe(inst, "#{PREFIX}observacoes", ""),
              get_attribute_safe(inst, "#{PREFIX}link", "")
            ]

            dados[key][:qtd] += 1
          end

          if dados.empty?
            UI.messagebox("Nenhum dado para exportar em #{categoria}.")
            next
          end

          file_path = File.join(File.dirname(model.path), "#{categoria}.csv")
          CSV.open(file_path, "w") do |csv|
          csv << ["Código","Nome","Cor","Marca","Tipo","Dimensão","Ambiente","Observações","Link","Valor","Qtd"]
          # Ordenar por pro_mob_nome (primeiro elemento da key)
          dados_ordenados = dados.sort_by { |key, info| key[0].to_s.downcase }
          dados_ordenados.each_with_index do |(key, info), i|
            nome, cor, marca, tipo, dimensao, ambiente, obs, link, valor = key
            id = info[:ids].first
            
            # Obter código do atributo pro_mob_cod ou gerar se não existir
            entity = Sketchup.active_model.entities.find { |e| e.entityID == id }
            codigo = if entity && get_attribute_safe(entity, "#{ProMobTipoAnnotator::PREFIX}cod")
                       get_attribute_safe(entity, "#{ProMobTipoAnnotator::PREFIX}cod")
                     else
                       ProMobTipoAnnotator.generate_annotation_code(tipo, i + 1)
                     end
            
            csv << [codigo, nome, cor, marca, tipo, dimensao, ambiente, obs, link, valor, info[:qtd]]
          end
        end
      end



      dialog.add_action_callback("isolate_item") do |_ctx, id|
        model = Sketchup.active_model
        target = find_component_by_id(model.entities, id.to_i)
        next unless target

        FM_Extensions::Exportar.isolate_item(target)
      end



      # Conectar seleção ao vivo ao dialog de exportação
      @export_dialog = dialog
      ensure_live_selection
      dialog.set_on_closed { 
        @export_dialog = nil
        # Limpar observers e cache ao fechar
        if @selection_observer
          begin
            Sketchup.active_model.selection.remove_observer(@selection_observer)
          rescue => e
            puts "ERRO removendo observer: #{e.message}"
          end
          @selection_observer = nil
        end
        invalidate_cache
        @processing_selection = false
      }
      begin
        js = <<~JS
          (function(){
            if(window.fmInit) return;
            function sortTable(table, colIndex, type, dir){
              var tbody = table.tBodies[0]; if(!tbody) return;
              var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
              var mul = (dir==='desc')?-1:1;
              rows.sort(function(a,b){
                var ta=a.children[colIndex].textContent.trim();
                var tb=b.children[colIndex].textContent.trim();
                if(type==='num'){
                  var na=parseFloat(ta.replace(',', '.'))||0;
                  var nb=parseFloat(tb.replace(',', '.'))||0;
                  return (na-nb)*mul;
                }
                return ta.localeCompare(tb)*mul;
              });
              rows.forEach(function(r){ tbody.appendChild(r); });
              if (typeof reajustarNumeracao === 'function') { try { reajustarNumeracao(); } catch(e){} }
            }
            function addSorting(table){
              var ths = table.tHead ? table.tHead.querySelectorAll('th') : [];
              var types = ['num','text','text','text','text','text','text','text','text','num','none','none'];
              for(var i=0;i<ths.length;i++){
                var th=ths[i]; var type = types[i]||'none';
                if(i===0) continue; // primeira coluna (#) não é ordenável
                if(type==='none') continue;
                th.style.cursor='pointer';
                (function(idx, t){ var dir='asc'; ths[idx].onclick=function(){ sortTable(table, idx, t, dir); dir=(dir==='asc'?'desc':'asc'); }; })(i, type);
              }
            }
            function buildConfigUI(tipos, prefs){
              var overlay=document.createElement('div'); overlay.style.cssText='position:fixed;inset:0;background:rgba(0,0,0,.3);display:flex;align-items:center;justify-content:center;z-index:9999;';
              var box=document.createElement('div'); box.style.cssText='background:#fff;padding:16px;border-radius:8px;min-width:400px;max-width:700px;max-height:80vh;overflow-y:auto;';
              box.innerHTML='<h3>Configuração de Exportação</h3>'
                + '<div style="display:flex;gap:20px;">'
                + '<div style="flex:1;"><h4>Categorias</h4><div id="cfgList"></div></div>'
                + '<div style="flex:1;"><h4>Colunas para Exportar</h4><div id="cfgColunas"></div></div>'
                + '</div>'
                + '<div style="margin-top:15px;text-align:right;border-top:1px solid #eee;padding-top:10px;">'
                + '<button id="cfgSave" style="background:#4CAF50;color:white;border:none;padding:8px 16px;margin-left:8px;border-radius:4px;cursor:pointer;">Salvar</button> '
                + '<button id="cfgClose" style="background:#f44336;color:white;border:none;padding:8px 16px;border-radius:4px;cursor:pointer;">Fechar</button>'
                + '</div>';
              overlay.appendChild(box); document.body.appendChild(overlay);
              var list=box.querySelector('#cfgList');
              tipos.forEach(function(tp){
                var p=prefs[tp]||{show:true, export:true};
                var row=document.createElement('div'); row.style.margin='4px 0';
                row.innerHTML='<strong>'+tp+'</strong> '
                  +'<label style="margin-left:8px"><input type="checkbox" class="cfg-show" data-tipo="'+tp+'" '+(p.show?'checked':'')+'> Mostrar</label> '
                  +'<label style="margin-left:8px"><input type="checkbox" class="cfg-exp" data-tipo="'+tp+'" '+(p.export?'checked':'')+'> Exportar</label>';
                list.appendChild(row);
              });
              
              // Configuração de colunas
              var colunasList = box.querySelector('#cfgColunas');
              var availableCols = ['Código','Nome','Cor','Marca','Dimensão','Ambiente','Observações','Link','Qtd'];
              var currentColPrefs = {};
              try { 
                var saved = localStorage.getItem('fm_column_prefs');
                if(saved) currentColPrefs = JSON.parse(saved);
              } catch(e) {}
              
              availableCols.forEach(function(col){
                var enabled = currentColPrefs[col] !== undefined ? currentColPrefs[col] : 
                             (col === 'Link' ? false : true); // Link desabilitado por padrão
                var row = document.createElement('div'); 
                row.style.cssText = 'margin:4px 0;display:flex;align-items:center;';
                row.innerHTML = '<label style="display:flex;align-items:center;gap:8px;cursor:pointer;">'
                  + '<input type="checkbox" class="cfg-col" data-col="'+col+'" '+(enabled?'checked':'')+'>'
                  + '<span>'+col+'</span>'
                  + '</label>';
                colunasList.appendChild(row);
              });
              
              box.querySelector('#cfgClose').onclick=function(){ overlay.remove(); };
              box.querySelector('#cfgSave').onclick=function(){
                // Salvar preferências de categorias
                var out={}; tipos.forEach(function(tp){ out[tp]={show:true, export:true}; });
                box.querySelectorAll('.cfg-show').forEach(function(el){ var tp=el.getAttribute('data-tipo'); if(!out[tp]) out[tp]={}; out[tp].show=el.checked; });
                box.querySelectorAll('.cfg-exp').forEach(function(el){ var tp=el.getAttribute('data-tipo'); if(!out[tp]) out[tp]={}; out[tp].export=el.checked; });
                try{ localStorage.setItem('fm_prefs', JSON.stringify(out)); }catch(e){}
                if(window.sketchup && sketchup.save_prefs){ sketchup.save_prefs(JSON.stringify(out)); }
                
                // Salvar preferências de colunas
                var colOut = {};
                box.querySelectorAll('.cfg-col').forEach(function(el){ 
                  colOut[el.getAttribute('data-col')] = el.checked; 
                });
                try{ localStorage.setItem('fm_column_prefs', JSON.stringify(colOut)); }catch(e){}
                if(window.sketchup && sketchup.save_column_prefs){ 
                  sketchup.save_column_prefs(JSON.stringify(colOut)); 
                }
                
                tipos.forEach(function(tp){ var sec=document.querySelector('#table-'+tp.replace(/\s+/g,'-')).closest('.categoria'); if(sec){ sec.style.display = (out[tp]&&out[tp].show)?'':'none'; } });
                overlay.remove();
              };
            }
            window.fmInit = function(tipos, prefs){
              var h1 = document.querySelector('h1');
              if(h1 && !document.getElementById('btnCfg')){
                var c = document.createElement('div');
                c.style.cssText = 'margin: 10px 0; text-align: center;';
                c.innerHTML = '<button id="btnCfg" style="margin: 5px; padding: 8px 16px; background: #f0f0f0; border: 1px solid #ccc; border-radius: 4px; cursor: pointer;">Configuração</button> <button id="btnXLSX" style="margin: 5px; padding: 8px 16px; background: #4CAF50; color: white; border: 1px solid #45a049; border-radius: 4px; cursor: pointer;">Exportar XLSX (selecionadas)</button>';
                h1.insertAdjacentElement('afterend', c);
                document.getElementById('btnXLSX').onclick = function(){ if(window.sketchup && sketchup.export_selected_xlsx){ sketchup.export_selected_xlsx(); } };
                document.getElementById('btnCfg').onclick = function(){ buildConfigUI(tipos, prefs); };
              }
              tipos.forEach(function(tp){
                var sec=document.querySelector('#table-'+tp.replace(/\s+/g,'-')).closest('.categoria');
                var p=prefs[tp]||{show:true, export:true}; if(sec){ sec.style.display = p.show?'':''; }
              });
              document.querySelectorAll('table').forEach(addSorting);
            }
          })();
        JS
        dialog.execute_script(js)
        dialog.execute_script("window.fmInit && window.fmInit(" + tipos.to_json + ", " + load_category_prefs(tipos).to_json + ");")
      rescue => e
        puts "Falha ao injetar JS de ordenação/configuração: #{e}"
      end
      UI.start_timer(0.0, false) do
        begin
          js = <<~JS
            (function(){
              if(window.fmInit) return;
              function sortTable(table, colIndex, type, dir){
                var tbody = table.tBodies[0]; if(!tbody) return;
                var rows = Array.prototype.slice.call(tbody.querySelectorAll('tr'));
                var mul = (dir==='desc')?-1:1;
                rows.sort(function(a,b){
                  var ta=a.children[colIndex].textContent.trim();
                  var tb=b.children[colIndex].textContent.trim();
                  if(type==='num'){
                    var na=parseFloat(ta.replace(',', '.'))||0;
                    var nb=parseFloat(tb.replace(',', '.'))||0;
                    return (na-nb)*mul;
                  }
                  return ta.localeCompare(tb)*mul;
                });
                rows.forEach(function(r){ tbody.appendChild(r); });
                if (typeof reajustarNumeracao === 'function') { try { reajustarNumeracao(); } catch(e){} }
              }
              function addSorting(table){
                var ths = table.tHead ? table.tHead.querySelectorAll('th') : [];
                var types = ['num','text','text','text','text','text','text','text','text','num','none','none'];
                for(var i=0;i<ths.length;i++){
                  var th=ths[i]; var type = types[i]||'none';
                  if(i===0) continue; // primeira coluna (#) não é ordenável
                  if(type==='none') continue;
                  th.style.cursor='pointer';
                  (function(idx, t){ var dir='asc'; ths[idx].onclick=function(){ sortTable(table, idx, t, dir); dir=(dir==='asc'?'desc':'asc'); }; })(i, type);
                }
              }
              function buildConfigUI(tipos, prefs){
                var overlay=document.createElement('div'); overlay.style.cssText='position:fixed;inset:0;background:rgba(0,0,0,.3);display:flex;align-items:center;justify-content:center;z-index:9999;';
                var box=document.createElement('div'); box.style.cssText='background:#fff;padding:12px;border-radius:8px;min-width:320px;max-width:600px;';
                box.innerHTML='<h3>Configuração</h3><div id="cfgList"></div><div style="margin-top:8px;text-align:right"><button id="cfgSave">Salvar</button> <button id="cfgClose">Fechar</button></div>';
                overlay.appendChild(box); document.body.appendChild(overlay);
                var list=box.querySelector('#cfgList');
                tipos.forEach(function(tp){
                  var p=prefs[tp]||{show:true, export:true};
                  var row=document.createElement('div'); row.style.margin='4px 0';
                  row.innerHTML='<strong>'+tp+'</strong> '
                    +'<label style="margin-left:8px"><input type="checkbox" class="cfg-show" data-tipo="'+tp+'" '+(p.show?'checked':'')+'> Mostrar</label> '
                    +'<label style="margin-left:8px"><input type="checkbox" class="cfg-exp" data-tipo="'+tp+'" '+(p.export?'checked':'')+'> Exportar</label>';
                  list.appendChild(row);
                });
                box.querySelector('#cfgClose').onclick=function(){ overlay.remove(); };
                box.querySelector('#cfgSave').onclick=function(){
                  var out={}; tipos.forEach(function(tp){ out[tp]={show:true, export:true}; });
                  box.querySelectorAll('.cfg-show').forEach(function(el){ var tp=el.getAttribute('data-tipo'); if(!out[tp]) out[tp]={}; out[tp].show=el.checked; });
                  box.querySelectorAll('.cfg-exp').forEach(function(el){ var tp=el.getAttribute('data-tipo'); if(!out[tp]) out[tp]={}; out[tp].export=el.checked; });
                  try{ localStorage.setItem('fm_prefs', JSON.stringify(out)); }catch(e){}
                  if(window.sketchup && sketchup.save_prefs){ sketchup.save_prefs(JSON.stringify(out)); }
                  tipos.forEach(function(tp){ var sec=document.querySelector('#table-'+tp.replace(/\s+/g,'-')).closest('.categoria'); if(sec){ sec.style.display = (out[tp]&&out[tp].show)?'':'none'; } });
                  overlay.remove();
                };
              }
              window.fmInit = function(tipos, prefs){
                var h1 = document.querySelector('h1');
                if(h1 && !document.getElementById('btnCfg')){
                  var c = document.createElement('div');
                  c.style.cssText = 'margin: 10px 0; text-align: center;';
                  c.innerHTML = '<button id="btnCfg" style="margin: 5px; padding: 8px 16px; background: #f0f0f0; border: 1px solid #ccc; border-radius: 4px; cursor: pointer;">Configuração</button> <button id="btnXLSX" style="margin: 5px; padding: 8px 16px; background: #4CAF50; color: white; border: 1px solid #45a049; border-radius: 4px; cursor: pointer;">Exportar XLSX (selecionadas)</button>';
                  h1.insertAdjacentElement('afterend', c);
                  document.getElementById('btnXLSX').onclick = function(){ if(window.sketchup && sketchup.export_selected_xlsx){ sketchup.export_selected_xlsx(); } };
                  document.getElementById('btnCfg').onclick = function(){ buildConfigUI(tipos, prefs); };
                }
                tipos.forEach(function(tp){
                  var sec=document.querySelector('#table-'+tp.replace(/\s+/g,'-')).closest('.categoria');
                  var p=prefs[tp]||{show:true, export:true}; if(sec){ sec.style.display = p.show?'':''; }
                });
                document.querySelectorAll('table').forEach(addSorting);
              }
            })();
          JS
          dialog.execute_script(js)
          dialog.execute_script("window.fmInit && window.fmInit(" + tipos.to_json + ", " + load_category_prefs(tipos).to_json + ");")
        rescue => e
          puts "Falha ao injetar JS (on_loaded): #{e}"
        end
      end
      dialog.show
      
      # Trigger imediato para seleção atual
      UI.start_timer(0.1, false) do
        current_selection = Sketchup.active_model.selection
        handle_selection_changed(current_selection) if current_selection.length > 0
      end
    end

    # ---------- Preferências e Exportação XLSX ----------
    def self.load_category_prefs(tipos)
      begin
        raw = Sketchup.read_default('fm_exportar_tipos', 'prefs', '{}')
        # Garantir que raw seja uma string válida
        raw = '{}' if raw.nil? || raw.empty?
        
        # Tentar fazer parse do JSON
        prefs = JSON.parse(raw)
      rescue JSON::ParserError, StandardError => e
        puts "Erro ao carregar preferências (#{e.message}), usando padrão"
        prefs = {}
        # Limpar preferência corrompida
        Sketchup.write_default('fm_exportar_tipos', 'prefs', '{}')
      end
      
      # Garantir que prefs seja um hash
      prefs = {} unless prefs.is_a?(Hash)
      
      tipos.each { |t| prefs[t] ||= { 'show' => true, 'export' => true } }
      prefs
    end

    def self.save_category_prefs(prefs)
      Sketchup.write_default('fm_exportar_tipos', 'prefs', JSON.generate(prefs))
    end

    def self.export_selected_xlsx(model, prefs)
      tipos = prefs.keys.select { |k| prefs[k]['export'] }
      if tipos.empty?
        UI.messagebox('Nenhuma categoria marcada para exportação.')
        return
      end
      unless defined?(WIN32OLE)
        UI.messagebox('Excel (WIN32OLE) indisponível. Não foi possível gerar XLSX.')
        return
      end
      path_xlsx = File.join(File.dirname(model.path), 'Lista de Compras.xlsx')
      export_to_xlsx_multi(model, tipos, path_xlsx)
      UI.messagebox("Exportado: #{path_xlsx}")
    end

    def self.collect_data_for_category(model, categoria)
      dados = Hash.new { |h, k| h[k] = { qtd: 0, ids: [] } }
      instances = []
      collect_all_pro_mob_instances(model.entities, instances)
      instances.each do |inst|
        tipo = get_attribute_safe(inst, "#{PREFIX}tipo", '').to_s.strip
        next if tipo.empty? || tipo != categoria
        key = [
          get_attribute_safe(inst, "#{PREFIX}nome", ''),
          get_attribute_safe(inst, "#{PREFIX}cor", ''),
          get_attribute_safe(inst, "#{PREFIX}marca", ''),
          tipo,
          get_attribute_safe(inst, "#{PREFIX}dimensao", ''),
          get_attribute_safe(inst, "#{PREFIX}ambiente", ''),
          get_attribute_safe(inst, "#{PREFIX}observacoes", ''),
          get_attribute_safe(inst, "#{PREFIX}link", '')
        ]
        dados[key][:qtd] += 1
        dados[key][:ids] << inst.entityID
      end
      dados
    end

    def self.export_to_xlsx_single(categoria, dados, path)
      excel = WIN32OLE.new('Excel.Application')
      excel.Visible = false
      wb = excel.Workbooks.Add
      ws = wb.Worksheets(1)
      ws.Name = categoria[0,31]
      headers = ["Código","Nome","Cor","Marca","Tipo","Dimensão","Ambiente","Observações","Link","Valor","Qtd"]
      ws.Cells(1,1).Value = "Relatório - #{categoria}"
      ws.Range(ws.Cells(1,1), ws.Cells(1, headers.length)).Merge
      ws.Range(ws.Cells(1,1), ws.Cells(1, headers.length)).Font.Bold = true
      headers.each_with_index { |h,i| ws.Cells(2, i+1).Value = h }
      row = 3
      # Ordenar por pro_mob_nome (primeiro elemento da key) 
      dados_ordenados = dados.sort_by { |key, info| key[0].to_s.downcase }
      dados_ordenados.each_with_index do |(key, info), i|
        nome, cor, marca, tipo, dimensao, ambiente, obs, link, valor = key
        codigo = i + 1
        values = [codigo, nome, cor, marca, tipo, dimensao, ambiente, obs, link, valor, info[:qtd]]
        values.each_with_index { |v, c| ws.Cells(row, c+1).Value = v }
        row += 1
      end
      ws.Columns.AutoFit
      wb.SaveAs(path, 51)
      wb.Close(false)
      excel.Quit
    end

    def self.export_to_xlsx_multi(model, categorias, path)
      excel = WIN32OLE.new('Excel.Application')
      excel.Visible = false
      wb = excel.Workbooks.Add
      
      # Usar apenas uma planilha para todas as categorias
      ws = wb.Worksheets(1)
      ws.Name = "Relatorio_Mobiliario"
      
      # Título geral com formatação melhorada
      ws.Cells(1,1).Value = "Relatório Geral"
      
      # Definir todas as colunas disponíveis
      all_columns = {
        "Código" => true,
        "Nome" => true, 
        "Cor" => true,
        "Marca" => true,
        "Dimensão" => true,
        "Ambiente" => true,
        "Observações" => false, # Por padrão desabilitado
        "Link" => false,  # Por padrão desabilitado
        "Qtd" => true
      }
      
      # Carregar preferências de colunas
      col_prefs_json = Sketchup.read_default('fm_exportar_colunas', 'prefs', JSON.generate(all_columns))
      begin
        col_prefs = JSON.parse(col_prefs_json)
        # Garantir que todas as colunas existam nas preferências
        all_columns.each { |col, default| col_prefs[col] = default unless col_prefs.key?(col) }
      rescue JSON::ParserError
        col_prefs = all_columns.dup
      end
      
      # Criar array de headers apenas com colunas habilitadas
      headers = all_columns.keys.select { |col| col_prefs[col] }
      title_range = ws.Range(ws.Cells(1,1), ws.Cells(1, headers.length))
      title_range.Merge
      title_range.Font.Bold = true
      title_range.Font.Size = 16
      title_range.Font.Name = "Century Gothic"
      title_range.HorizontalAlignment = -4108  # xlCenter
      title_range.Interior.Color = 0xF2F2F2     # Cinza muito claro
      title_range.Font.Color = 0x333333         # Cinza escuro
      title_range.Borders.LineStyle = 1
      title_range.Borders.Color = 0xD0D0D0      # Bordas cinza claro
      title_range.RowHeight = 25
      
      # Cabeçalhos com formatação melhorada
      headers.each_with_index { |h,i| ws.Cells(2, i+1).Value = h }
      header_range = ws.Range(ws.Cells(2,1), ws.Cells(2, headers.length))
      header_range.Font.Bold = true
      header_range.Font.Size = 11
      header_range.Font.Name = "Century Gothic"
      header_range.Interior.Color = 0xE8E8E8     # Cinza claro
      header_range.Font.Color = 0x333333         # Cinza escuro
      header_range.HorizontalAlignment = -4108   # xlCenter
      header_range.Borders.LineStyle = 1
      header_range.Borders.Color = 0xD0D0D0      # Bordas cinza claro
      header_range.RowHeight = 20
      
      row = 3
      
      # Ordenar categorias conforme especificado
      categoria_order = ["Mobiliário","Decoração","Eletrodomésticos", "Louças e Metais", "Acessórios"]
      categorias_ordenadas = []
      
      # Adicionar categorias na ordem especificada se existirem
      categoria_order.each do |cat|
        categorias_ordenadas << cat if categorias.include?(cat)
      end
      
      # Adicionar categorias não listadas
      categorias.each do |cat|
        categorias_ordenadas << cat unless categorias_ordenadas.include?(cat)
      end
      
      categorias_ordenadas.each_with_index do |categoria, cat_index|
        dados = collect_data_for_category(model, categoria)
        
        # Pular categoria se não tiver dados
        next if dados.empty?
        
        # Adicionar linha de título da categoria (mesclada) com formatação melhorada
        ws.Cells(row, 1).Value = categoria.upcase
        category_range = ws.Range(ws.Cells(row, 1), ws.Cells(row, headers.length))
        category_range.Merge
        category_range.Font.Bold = true
        category_range.Font.Size = 12
        category_range.Font.Name = "Century Gothic"
        category_range.Interior.Color = 0xDCDCDC     # Cinza médio
        category_range.Font.Color = 0x333333         # Cinza escuro
        category_range.HorizontalAlignment = -4108   # xlCenter
        category_range.Borders.LineStyle = 1
        category_range.Borders.Color = 0xD0D0D0      # Bordas cinza claro
        category_range.RowHeight = 22
        row += 1
        
        dados.each_with_index do |(key, info), i|
          nome, cor, marca, tipo, dimensao, ambiente, obs, link, valor = key
          
          # Verificar se info e ids existem
          next unless info && info[:ids] && !info[:ids].empty?
          id = info[:ids].first
          
          # Obter código do atributo pro_mob_cod
          entity = model.entities.find { |e| e.entityID == id }
          codigo = if entity && get_attribute_safe(entity, "#{ProMobTipoAnnotator::PREFIX}cod")
                    get_attribute_safe(entity, "#{ProMobTipoAnnotator::PREFIX}cod")
                  else
                    ProMobTipoAnnotator.generate_annotation_code(tipo, i + 1)
                  end
          
          # Criar hash com todos os valores possíveis
          all_values = {
            "Código" => codigo,
            "Nome" => nome,
            "Cor" => cor, 
            "Marca" => marca,
            "Dimensão" => dimensao,
            "Ambiente" => ambiente,
            "Observações" => obs,
            "Link" => link,
            "Valor" => valor,
            "Qtd" => info[:qtd]
          }
          
          # Inserir apenas os valores das colunas habilitadas
          headers.each_with_index do |header, c|
            ws.Cells(row, c+1).Value = all_values[header]
          end
          
          # Formatação geral da linha
          data_range = ws.Range(ws.Cells(row, 1), ws.Cells(row, headers.length))
          data_range.Font.Name = "Century Gothic"
          data_range.Font.Size = 10
          data_range.Font.Color = 0x333333          # Cinza escuro para texto
          data_range.Borders.LineStyle = 1
          data_range.Borders.Color = 0xE0E0E0       # Bordas cinza muito claro
          data_range.RowHeight = 18
          
          # Aplicar cor de fundo na célula do código usando cores corretas do SketchUp
          type_color = ProMobTipoAnnotator::TYPE_COLORS[tipo] || ProMobTipoAnnotator::TYPE_COLORS["Outros"]
          
          # Converter cor do SketchUp::Color para RGB do Excel (formato BGR)
          if type_color.respond_to?(:red) && type_color.respond_to?(:green) && type_color.respond_to?(:blue)
            r = type_color.red
            g = type_color.green  
            b = type_color.blue
            # Excel usa formato BGR (Blue-Green-Red)
            excel_color = (b << 16) | (g << 8) | r
          else
            # Fallback para cor padrão
            excel_color = 0xC0C0C0  # Cinza claro
          end
          
          # Aplicar formatação à célula do código (se a coluna existir)
          codigo_col_index = headers.index("Código")
          if codigo_col_index
            codigo_cell = ws.Cells(row, codigo_col_index + 1)
            codigo_cell.Interior.Color = excel_color
            codigo_cell.Font.Color = 16777215  # Branco
            codigo_cell.Font.Bold = true
            codigo_cell.HorizontalAlignment = -4108  # xlCenter
          end
          
          # Formatação especial para a coluna do link (fonte menor)
          link_col_index = headers.index("Link")
          if link_col_index && link && !link.empty?
            link_cell = ws.Cells(row, link_col_index + 1)
            link_cell.Font.Size = 8
            link_cell.Font.Color = 0x0000FF  # Azul para links
            link_cell.Font.Underline = true
          end
          
          # Centralizar quantidade
          qtd_col_index = headers.index("Qtd")
          if qtd_col_index
            qtd_cell = ws.Cells(row, qtd_col_index + 1)
            qtd_cell.HorizontalAlignment = -4108  # xlCenter
            qtd_cell.Font.Bold = true
          end
          
          row += 1
        end
        
        # Adicionar linha em branco entre categorias (exceto na última)
        if cat_index < categorias_ordenadas.length - 1 && !dados.empty?
          row += 1
        end
      end
      
      # Ajustes finais de formatação
      total_range = ws.Range(ws.Cells(1,1), ws.Cells(row-1, headers.length))
      
      # Fonte padrão para toda a planilha
      total_range.Font.Name = "Century Gothic"
      
      # Autoajustar colunas com larguras mínimas e máximas
      ws.Columns.AutoFit
      
      # Ajustar larguras específicas das colunas (apenas para as colunas habilitadas)
      column_widths = {
        "Código" => 8,
        "Nome" => 20,
        "Cor" => 12,
        "Marca" => 15,
        "Dimensão" => 15,
        "Ambiente" => 12,
        "Observações" => 25,
        "Link" => 30,
        "Qtd" => 6
      }
      
      headers.each_with_index do |header, index|
        width = column_widths[header] || 15  # Largura padrão se não especificada
        ws.Columns(index + 1).ColumnWidth = width
      end
      
      # Congelar painéis (fixar cabeçalhos)
      ws.Range("A3").Select
      excel.ActiveWindow.FreezePanes = true
      
      # Adicionar bordas sutis em toda a tabela
      total_range.Borders.LineStyle = 1
      total_range.Borders.Weight = 1           # Bordas mais finas
      total_range.Borders.Color = 0xE0E0E0     # Cinza muito claro
      
      wb.SaveAs(path, 51)
      wb.Close(false)
      excel.Quit
    end

    # Exporta todas as categorias que possuem dados (ignora prefs de categoria)
    def self.export_selected_xlsx(model, prefs=nil)
      tipos = []
      instances = []
      collect_all_pro_mob_instances(model.entities, instances)
      instances.each do |inst|
        tipo = get_attribute_safe(inst, "#{PREFIX}tipo", '').to_s.strip
        tipos << tipo unless tipo.empty?
      end
      tipos.uniq!
      tipos = tipos.select { |t| !collect_data_for_category(model, t).empty? }
      if tipos.empty?
        UI.messagebox('Nenhuma categoria com dados para exportar.')
        return
      end
      unless defined?(WIN32OLE)
        UI.messagebox('Excel (WIN32OLE) indisponível. Não foi possível gerar XLSX.')
        return
      end
      path_xlsx = File.join(File.dirname(model.path), 'Relatorio - Mobiliario.xlsx')
      export_to_xlsx_multi(model, tipos, path_xlsx)
      UI.messagebox("Exportado: #{path_xlsx}")
    end

  end # module