# coding: utf-8
require 'sketchup.rb'
require 'csv'
require 'json'

module FM_Extensions
  module Exportar

    CATEGORIAS = {
      "Mobiliário" => ['-INTERIORES-MOBILIARIO', '-INTERIORES-QUADRO', '-INTERIORES-TAPETE', '-INTERIORES-CORTINA'],
      "Eletro"     => ['-INTERIORES-ELETRO (AEREO)', '-INTERIORES-ELETRO (MARCENARIA)', '-INTERIORES-ELETRO (MARMORARIA)', '-INTERIORES-ELETRO (PISO)'],
      "Metais"     => ['-BANHEIRO-BACIA', '-BANHEIRO-BOX', '-BANHEIRO-ACESSORIOS', '-BANHEIRO-CHUVEIRO',
                       '-MARMORARIA-CUBA E METAIS','-BANHEIRO-RALO',"-TECNICO-REGISTRO ACABAMENTO","-INTERIORES-CUBA E METAIS"]
    }.freeze

    PREF_ROOT   = "FM_Exportar_Categorias".freeze
    ATTR_DICT   = "FM_Exportar".freeze

    # ---------- Persistência ----------
    def self.read_selected_tags(model, categoria)
      # 1) do modelo
      arr = model.get_attribute(ATTR_DICT, "#{categoria}_tags")
      if arr.is_a?(Array) && !arr.empty?
        return arr
      end
      # 2) global
      s = Sketchup.read_default(PREF_ROOT, "#{categoria}_tags", "")
      return s.split(",").map(&:strip).reject(&:empty?) unless s.nil? || s.empty?
      # 3) fallback
      CATEGORIAS[categoria] || []
    end

    def self.write_selected_tags(model, categoria, tags)
      tags = Array(tags).map(&:to_s).uniq
      model.set_attribute(ATTR_DICT, "#{categoria}_tags", tags)
      Sketchup.write_default(PREF_ROOT, "#{categoria}_tags", tags.join(","))
    end

    def self.all_model_tags(model)
      # Retorna todos os nomes de etiquetas do arquivo
      model.layers.map(&:name).compact
    end

    # ---------- Diálogo de escolher etiquetas ----------
    def self.abrir_dialogo_etiquetas(categoria)
      model = Sketchup.active_model
      etiquetas_todas = all_model_tags(model).sort
      selecionadas = read_selected_tags(model, categoria) & etiquetas_todas
      selecionadas = CATEGORIAS[categoria] if selecionadas.empty? && CATEGORIAS[categoria]

      dlg = UI::HtmlDialog.new(
        dialog_title: "Escolher Etiquetas - #{categoria}",
        preferences_key: "fm_exportar_escolher_#{categoria}",
        scrollable: true,
        resizable: false,
        width: 360,
        height: 540,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      html = gerar_html_etiquetas(categoria, etiquetas_todas, selecionadas)
      dlg.set_html(html)

      dlg.add_action_callback("salvarEtiquetas") do |_, json_data|
        data = JSON.parse(json_data)
        escolhidas = Array(data["etiquetas"]).map(&:to_s)
        write_selected_tags(model, categoria, escolhidas)
        UI.messagebox("Preferências de '#{categoria}' salvas.")
        dlg.close
      end

      dlg.show
    end

    def self.gerar_html_etiquetas(categoria, etiquetas, selecionadas)
      etiquetas_json    = etiquetas.to_json
      selecionadas_json = selecionadas.to_json
      <<-HTML
      <!DOCTYPE html>
      <html lang="pt-BR">
      <head>
        <meta charset="UTF-8">
        <title>Escolher Etiquetas</title>
        <style>
          body{font-family:Century Gothic, sans-serif;margin:10px;text-align:center;background:#f6f6f6;}
          h1{font-size:16px;margin:10px 0;border:2px solid #becc8a;padding:5px;border-radius:8px;display:inline-block;}
          .actions{margin:6px 0;}
          table{width:100%;border-collapse:collapse;font-size:12px;margin-bottom:10px;background:#fff;}
          th,td{border:1px solid #ddd;padding:6px;text-align:left;vertical-align:middle;}
          th{background:#fff;}
          button{margin:3px 5px;padding:6px 10px;font-size:12px;cursor:pointer;background:#dee9b6;border-radius:10px;
                 box-shadow:2px 2px 10px rgba(0,0,0,0.2);transition:background-color .3s ease;border:0;}
          button:hover{background:#becc8a;}
        </style>
      </head>
      <body>
        <h1>Etiquetas - #{categoria}</h1>
        <div class="actions">
          <button onclick="selecionarTudo()">Selecionar tudo</button>
          <button onclick="limparTudo()">Limpar</button>
        </div>
        <table>
          <thead><tr><th>✓</th><th>Etiqueta</th></tr></thead>
          <tbody id="etiquetas-body"></tbody>
        </table>
        <button onclick="salvar()">Salvar</button>

        <script>
          const etiquetas = #{etiquetas_json};
          const selecionadas = #{selecionadas_json};

          function preencher() {
            const tbody = document.getElementById('etiquetas-body');
            tbody.innerHTML = etiquetas.map(e => {
              const checked = selecionadas.includes(e) ? "checked" : "";
              return `<tr>
                <td style="width:40px;text-align:center;"><input type="checkbox" value="${e}" ${checked}></td>
                <td>${e}</td>
              </tr>`;
            }).join('');
          }
          function selecionarTudo(){
            document.querySelectorAll('input[type=checkbox]').forEach(i=>i.checked=true);
          }
          function limparTudo(){
            document.querySelectorAll('input[type=checkbox]').forEach(i=>i.checked=false);
          }
          function salvar(){
            const escolhidas = Array.from(document.querySelectorAll('input[type=checkbox]:checked')).map(i=>i.value);
            sketchup.salvarEtiquetas(JSON.stringify({categoria:"#{categoria}", etiquetas:escolhidas}));
          }
          preencher();
        </script>
      </body>
      </html>
      HTML
    end

    # ---------- Busca e contagem ----------
    def self.buscar_componentes(entities, allowed_layers, instances)
      entities.each do |entity|
        if entity.is_a?(Sketchup::ComponentInstance) || entity.is_a?(Sketchup::Group)
          # conta somente se a própria etiqueta do item estiver selecionada
          if entity.respond_to?(:layer) && allowed_layers.include?(entity.layer.name)
            instances << entity
          end
          child_entities =
            entity.is_a?(Sketchup::ComponentInstance) ? entity.definition.entities :
            entity.is_a?(Sketchup::Group) ? entity.entities : nil
          buscar_componentes(child_entities, allowed_layers, instances) if child_entities
        end
      end
    end

    # ---------- Conjunto de etiquetas visíveis incluindo ancestrais ----------
    def self.coletar_etiquetas_ancestrais_para(selected_names)
      model = Sketchup.active_model
      visible = selected_names.to_set
      stack = []
      rec = lambda do |entities, chain|
        entities.each do |e|
          next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
          this_tag = e.respond_to?(:layer) && e.layer ? e.layer.name : nil
          # Se o item está numa etiqueta selecionada, adicione também as etiquetas do caminho
          if this_tag && selected_names.include?(this_tag)
            chain.each do |anc|
              if anc.respond_to?(:layer) && anc.layer
                visible << anc.layer.name
              end
            end
            visible << this_tag
          end
          children = e.is_a?(Sketchup::ComponentInstance) ? e.definition.entities : e.entities
          rec.call(children, chain + [e]) if children
        end
      end
      rec.call(model.entities, [])
      visible.to_a
    end

    # ---------- Atualização da tabela ----------
    def self.update_category_data(model, categoria)
      selected_layers = read_selected_tags(model, categoria)
      selected_layers = all_model_tags(model) if selected_layers.nil? || selected_layers.empty?
      instances = []
      buscar_componentes(model.entities, selected_layers, instances)

      data = Hash.new(0)
      instances.each do |inst|
        desc = inst.definition.name
        data[desc] += 1
      end

      if data.empty?
        "<tr><td colspan='4' style='color:red;'>Nenhum dado encontrado.</td></tr>"
      else
        idx = 0
        data.keys.sort_by(&:downcase).map { |descricao|
          idx += 1
          qt = data[descricao]
          "<tr><td>#{idx}</td><td>#{descricao}</td><td>#{qt}</td><td><button onclick=\"removeRow(this)\">Remover</button></td></tr>"
        }.join
      end
    end

    # ---------- Ferramentas ----------
    def self.medida_item
      model = Sketchup.active_model
      selection = model.selection
      if selection.empty?
        UI.messagebox('Nenhum objeto selecionado.')
        return
      end
      first_entity = selection[0]
      if first_entity.is_a?(Sketchup::Group) || first_entity.is_a?(Sketchup::ComponentInstance)
        component = first_entity.is_a?(Sketchup::Group) ? first_entity.to_component : first_entity
        polegadas_para_cm = 2.54
        tamanho_x = (component.bounds.width * polegadas_para_cm).round(2).to_i
        tamanho_y = (component.bounds.height * polegadas_para_cm).round(2).to_i
        tamanho_z = (component.bounds.depth * polegadas_para_cm).round(2).to_i
        novo_nome = "DEFINIR - L #{tamanho_x} x P #{tamanho_y} x A #{tamanho_z} cm"
        component.definition.name = novo_nome
      else
        UI.messagebox('O objeto selecionado não é um grupo ou um componente.')
      end
    end

    def self.open_export_dialog
      model = Sketchup.active_model
      model_path = model.path
      if model_path.empty?
        UI.messagebox("Por favor, salve o modelo antes de exportar o CSV.")
        return false
      end
      show_dialog
    end

    # ---------- UI principal ----------
    def self.show_dialog
      dialog = UI::HtmlDialog.new(
        dialog_title: "Mobiliário, Eletro, Louças e Metais",
        preferences_key: "com.example.exportar_dados",
        scrollable: true,
        resizable: true,
        width: 800,
        height: 600,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      html_content = <<-HTML
      <!DOCTYPE html>
      <html lang="pt">
        <head>
          <meta http-equiv='content-type' content='text/html; charset=utf-8'>
          <title>Mobiliário, Eletro, Louças e Metais</title>
          <style>
            body{font-family:'Century Gothic',sans-serif;margin:10px;text-align:center;background-color:#f6f6f6;}
            p{font-size:10px;margin:5px;margin-bottom:10px;}
            h1{font-size:18px;margin:10px 0;display:inline-block;border:3px solid #becc8a;padding:5px;border-radius:10px;box-shadow:2px 2px 10px rgba(0,0,0,0.2);}
            h2{font-size:16px;margin:10px 0;}
            table{font-size:12px;width:100%;border-collapse:collapse;margin:10px 0;margin-bottom:10px;}
            th,td{border:1px solid #ddd;padding:10px;text-align:left;}
            th{background-color:#fff;}
            .footer{margin-top:20px;font-size:10px;color:#a7af8b;text-align:center;border-top:1px solid #ccc;padding-top:10px;}
            hr{border:none;border-top:1px solid #ccc;margin:20px 0;}
            button{margin:3px 4px;padding:5px 8px;font-size:12px;cursor:pointer;background-color:#dee9b6;border-radius:10px;
                   box-shadow:2px 2px 10px rgba(0,0,0,0.2);transition:background-color 0.3s ease;border:0;}
            button:hover{background-color:#becc8a;}
            th:last-child,td:last-child{width:auto;min-width:fit-content;text-align:center;}
            td:nth-child(3),th:nth-child(3),td:nth-child(1),th:nth-child(1){text-align:center;}
          </style>
        </head>
        <body>
          <h1>Relatórios</h1>
          <p>Abaixo temos os relatórios de cada categoria, clique nos botões para executar as ações em cada um deles:</p>

          <div class="categoria">
            <h2>Mobiliário</h2>
            <table id="table-Mobiliário">
              <thead><tr><th>Legenda</th><th>Descrição</th><th>Quantidade</th><th>Ações</th></tr></thead>
              <tbody></tbody>
            </table>
            <button onclick="updateCategory('Mobiliário')">Atualizar Tabela</button>
            <button onclick="chooseTags('Mobiliário')">Escolher Etiquetas</button>
            <button onclick="isolateCategory('Mobiliário')">Isolar Itens</button>
            <button onclick="exportCategory('Mobiliário')">Exportar Relatório</button>
            <hr>
          </div>

          <div class="categoria">
            <h2>Eletrodomésticos</h2>
            <table id="table-Eletro">
              <thead><tr><th>Legenda</th><th>Descrição</th><th>Quantidade</th><th>Ações</th></tr></thead>
              <tbody></tbody>
            </table>
            <button onclick="updateCategory('Eletro')">Atualizar Tabela</button>
            <button onclick="chooseTags('Eletro')">Escolher Etiquetas</button>
            <button onclick="isolateCategory('Eletro')">Isolar Itens</button>
            <button onclick="exportCategory('Eletro')">Exportar Relatório</button>
            <hr>
          </div>

          <div class="categoria">
            <h2>Louças e Metais</h2>
            <table id="table-Metais">
              <thead><tr><th>Legenda</th><th>Descrição</th><th>Quantidade</th><th>Ações</th></tr></thead>
              <tbody></tbody>
            </table>
            <button onclick="updateCategory('Metais')">Atualizar Tabela</button>
            <button onclick="chooseTags('Metais')">Escolher Etiquetas</button>
            <button onclick="isolateCategory('Metais')">Isolar Itens</button>
            <button onclick="exportCategory('Metais')">Exportar Relatório</button>
            <hr>
          </div>

          <script>
            function updateCategory(categoria){ sketchup.update_category(categoria); }
            function chooseTags(categoria){ sketchup.choose_tags(categoria); }
            function isolateCategory(categoria){ sketchup.isolate_category(categoria); }
            function removeRow(btn){
              var row = btn.parentNode.parentNode;
              var tbody = row.parentNode;
              tbody.removeChild(row);
              var rows = tbody.getElementsByTagName("tr");
              for (var i=0;i<rows.length;i++){
                rows[i].getElementsByTagName("td")[0].innerText = i+1;
              }
            }
            function exportCategory(categoria){
              var table = document.getElementById("table-"+categoria);
              var data = [];
              var rows = table.getElementsByTagName("tbody")[0].rows;
              for (var i=0;i<rows.length;i++){
                var cells = rows[i].cells;
                data.push([cells[0].innerText, cells[1].innerText, cells[2].innerText]);
              }
              sketchup.export_category(JSON.stringify([categoria, data]));
            }
          </script>

          <footer>
            <p>Desenvolvido por
              <a href="https://francielimadeira.com" target="_blank" style="text-decoration:none;color:#666;font-weight:bold;">
                Francieli Madeira
              </a>
              (C) 2025. Todos os direitos reservados. VERSÃO 1.0 (26/02/25)
            </p>
          </footer>
        </body>
      </html>
      HTML

      dialog.set_html(html_content)

      # Atualizar tabela pela seleção salva
      dialog.add_action_callback("update_category") do |_ctx, categoria|
        begin
          updated_html = update_category_data(Sketchup.active_model, categoria)
          script = "document.querySelector('#table-" + categoria.gsub(' ', '-') + " tbody').innerHTML = `#{updated_html}`;"
          dialog.execute_script(script)
        rescue => e
          UI.messagebox("Erro ao atualizar a tabela de #{categoria}: #{e.message}")
        end
      end

      # Abrir seletor de etiquetas
      dialog.add_action_callback("choose_tags") do |_ctx, categoria|
        abrir_dialogo_etiquetas(categoria)
      end

      # Isolar itens respeitando ancestrais
      dialog.add_action_callback("isolate_category") do |_ctx, categoria|
        begin
          model = Sketchup.active_model
          etiqueta_page = model.pages.find { |p| p.name.downcase == 'etiquetar' }
          selected = read_selected_tags(model, categoria)
          if selected.nil? || selected.empty?
            UI.messagebox("Nenhuma etiqueta configurada para #{categoria}.")
            next
          end

          if etiqueta_page
            model.pages.selected_page = etiqueta_page
            model.pages.selected_page.update
          end

          # Etiquetas visíveis = selecionadas + ancestrais necessários
          require 'set'
          visible_names = coletar_etiquetas_ancestrais_para(selected)

          model.start_operation("Isolando #{categoria}", true)
          model.layers.each do |camada|
            name = camada.name
            camada.visible = visible_names.include?(name)
          end
          model.commit_operation
        rescue => e
          UI.messagebox("Erro ao isolar itens: #{e.message}")
        end
      end

      # Exportar CSV
      dialog.add_action_callback("export_category") do |_context, args|
        begin
          args = JSON.parse(args)
          categoria = args[0]
          data = args[1]
          model = Sketchup.active_model
          model_path = model.path
          if model_path.empty?
            UI.messagebox("Por favor, salve o modelo antes de exportar o CSV.")
            next
          end
          directory = File.dirname(model_path)
          file_path = File.join(directory, "#{categoria}.csv")
          CSV.open(file_path, "w") do |csv|
            csv << ["LEGENDA", "DESCRIÇÃO", "QUANTIDADE"]
            data.each_with_index do |row, idx|
              csv << [idx + 1, row[1], row[2]]
            end
          end
          UI.messagebox("Exportação de #{categoria} concluída com sucesso em:\n#{file_path}")
        rescue => e
          UI.messagebox("Erro ao exportar CSV: #{e.message}")
        end
      end

      dialog.set_size(800, 600)
      dialog.show
    end

  end # Exportar

  # ---------- Toolbar ----------
  toolbar = UI::Toolbar.new('FM - Mobiliário')

  cmd_item_mobiliario = UI::Command.new('Novo Item') {
    FM_Extensions::Exportar.medida_item
  }
  icon_item_mobiliario = File.join(__dir__, 'icones', 'itemmob.png')
  if File.exist?(icon_item_mobiliario)
    cmd_item_mobiliario.small_icon = icon_item_mobiliario
    cmd_item_mobiliario.large_icon = icon_item_mobiliario
  else
    UI.messagebox("Ícone não encontrado: #{icon_item_mobiliario}")
  end
  cmd_item_mobiliario.tooltip = 'Novo Item'
  cmd_item_mobiliario.status_bar_text = 'Atualiza a descrição do componente e acrescenta dimensões em cm.'
  toolbar.add_item(cmd_item_mobiliario)

  cmd_exportar_dados = UI::Command.new('Exportar Dados') {
    FM_Extensions::Exportar.open_export_dialog
  }
  icon_exportar_dados = File.join(__dir__, 'icones', 'exporte.png')
  if File.exist?(icon_exportar_dados)
    cmd_exportar_dados.small_icon = icon_exportar_dados
    cmd_exportar_dados.large_icon = icon_exportar_dados
  else
    UI.messagebox("Ícone não encontrado: #{icon_exportar_dados}")
  end
  cmd_exportar_dados.tooltip = 'Exportar Dados'
  cmd_exportar_dados.status_bar_text = 'Exporta dados de Mobiliário, Eletro ou Louças e Metais.'
  toolbar.add_item(cmd_exportar_dados)

  toolbar.show
end # FM_Extensions
