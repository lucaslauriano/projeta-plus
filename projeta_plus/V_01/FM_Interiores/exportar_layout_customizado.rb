require 'sketchup.rb'
require 'fileutils'
require 'json'

module FM
    module ExtensaoSkp

    extend self

    @ultima_config = nil

    def abrir_janela_exportar_layout
      html = <<-HTML
  <!DOCTYPE html>
  <html>
  <head>
    <meta charset="utf-8">
    <title>Exportar LayOut</title>
    <style>
      body {
        font-family: Century Gothic, sans-serif;
        margin: 10px;
        text-align: center;
        background-color: #f6f6f6;
      }

      .button-container {
        display: flex;
        justify-content: center;
        gap: 1px;
        margin-bottom: 10px;
      }

      .container {
        display: flex;
        flex-direction: column;
        align-items: center;
        justify-content: center;
        width: 100%;
        margin: 5px auto;
      }

      table {
        width: auto;
        border-collapse: collapse;
        margin: 5px auto;
        table-layout: auto;
        font-size: 12px;
      }

      th, td {
        border: 1px solid #ddd;
        padding: 5px;
        text-align: center;
        white-space: nowrap;
        vertical-align: middle;
      }

      th {
        background-color: #ffffff;
        font-weight: bold;

      }

      button {
        margin: 3px 5px;
        padding: 5px;
        font-size: 12px;
        cursor: pointer;
        background-color: #dee9b6;
        border-radius: 10px;
        box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.2);
        transition: background-color 0.3s ease;
      }

      button:hover {
        background-color: #becc8a;
      }

      h1 {
        font-size: 18px;
        margin: 10px 0;
        display: inline-block;
        border: 3px solid #becc8a;
        padding: 5px;
        border-radius: 10px;
        box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.2);
      }

      h2 {
        font-size: 14px;
        margin: 5px 0;
        margin-top: 15px;
      }

      footer {
        margin-top: 20px;
        font-size: 12px;
        color: #666;
        text-align: center;
        border-top: 1px solid #ccc;
        padding-top: 10px;
      }

      p {
        font-size: 10px;
        margin: 5px 0;
        cursor: pointer;
      }
      #configTable th:nth-child(1),
      #configTable td:nth-child(1) {
        width: 100px; /* Nome da Página */
      }

      #configTable th:nth-child(2),
      #configTable td:nth-child(2),
      #configTable th:nth-child(3),
      #configTable td:nth-child(3),
      #configTable th:nth-child(4),
      #configTable td:nth-child(4) {
        width: 100px; /* Cenas */
      }

      #configTable th:nth-child(5),
      #configTable td:nth-child(5) {
        width: 50px; /* Escala */
      }

      #configTable th:nth-child(7),
      #configTable td:nth-child(7) {
        width: 100px; /* Botões */
      } 

      #configTable th:nth-child(5),
      #configTable td:nth-child(5),
      #configTable th:nth-child(6),
      #configTable td:nth-child(6) {
        width: 50px; /* View */
      }

      .input-row {
        display: flex;
        justify-content: center;
        align-items: center;
        gap: 10px;
        flex-wrap: wrap;
        margin-bottom: 10px;
        font-size: 12px;
      }

      .input-row label {
        font-size: 12px;
        margin-right: 5px;
      }

      .input-row input {
        font-size: 12px;
        padding: 4px;
        width: 80px;
        text-align: center;         /* Centraliza horizontalmente */
        vertical-align: middle;     /* Alinha verticalmente */
        line-height: 1.4;           /* Ajusta altura da linha para centralização */
        border-radius: 6px;
        border: 1px solid #ccc;
        box-sizing: border-box;     /* Garante que padding não ultrapasse o tamanho */
      }

      /* Remove setas no Chrome, Safari, Edge, Opera */
      input[type=number]::-webkit-outer-spin-button,
      input[type=number]::-webkit-inner-spin-button {
        -webkit-appearance: none;
        margin: 0;
      }

      /* Remove setas no Firefox */
      input[type=number] {
        -moz-appearance: textfield;
      }

      #configTable th:nth-child(5),
      #configTable td:nth-child(5) {
        width: 80px;  /* Ajuste a largura que quiser */
        max-width: 80px;
        white-space: nowrap;
      }

      #configTable td:nth-child(5) input[type="number"] {
        width: 100%;        /* Ocupa toda largura da célula */
        box-sizing: border-box; /* Padding e borda entram na largura */
        text-align: center; /* Centraliza o número */
        padding: 2px 5px;   /* Espaçamento interno para conforto */
      }

    </style>
  </head>
  <body>
    <h1>Exportar para LayOut</h1>

    <table id="configTable">
      <thead>
        <tr>
          <th>Nome da Página</th>
          <th>Cena 01</th>
          <th>Cena 02 ou <br>Sobreposição</th>
          <th>Cena 03 ou <br>Sobreposição</th>
          <th>Escala</th>
          <th>Largura View</th>
          <th>Altura View</th>
          <th>Ações</th>
        </tr>
      </thead>

      <tbody></tbody>
    </table>

    <button onclick="addRow()">Adicionar Linha</button><br><br>

    <div class="input-row">
      <label for="scale">Escala Padrão:</label>
      <input type="number" id="scale" value="50" step="0.01">

      <label for="vw">Largura da Viewport (cm):</label>
      <input type="number" id="vw" value="20" step="0.1">

      <label for="vh">Altura da Viewport (cm):</label>
      <input type="number" id="vh" value="20" step="0.1">
    </div>

    <div class="button-container">
      <button onclick="enviarConfig()">Exportar</button>
      <button id="btn_salvar_config">Salvar Configurações</button>
      <button onclick="exportarConfigParaArquivo()">Exportar Configuração</button>
      <button onclick="importarDeArquivo()">Importar Configuração</button>
    </div>

    <script>
      let cenasDisponiveis = []

      function populateScenes(scenes) {
        cenasDisponiveis = scenes
        addRow()
      }
      
      function moverLinhaParaCima(botao) {
    const linha = botao.closest("tr");
    const anterior = linha.previousElementSibling;
    if (anterior) {
      linha.parentNode.insertBefore(linha, anterior);
    }
    }

    function moverLinhaParaBaixo(botao) {
      const linha = botao.closest("tr");
      const proxima = linha.nextElementSibling;
      if (proxima) {
        linha.parentNode.insertBefore(proxima, linha);
      }
    }

      function criarSelect() {
        const select = document.createElement("select")
        const empty = document.createElement("option")
        empty.value = ""
        empty.textContent = "--"
        select.appendChild(empty)
        cenasDisponiveis.forEach(nome => {
          const opt = document.createElement("option")
          opt.value = nome
          opt.textContent = nome
          select.appendChild(opt)
        })
        return select
      }

      function addRow(dados = null) {
        const tabela = document.querySelector("#configTable tbody")
        const tr = document.createElement("tr")

        const nome = document.createElement("input")
        nome.type = "text"
        nome.placeholder = "Ex: Planta Layout"
        if (dados) nome.value = dados.page_name || ""

        const tdNome = document.createElement("td")
        tdNome.appendChild(nome)
        tr.appendChild(tdNome)

        for (let i = 0; i < 3; i++) {
          const td = document.createElement("td")
          const select = criarSelect()
          if (dados && [dados.main_scene, dados.overlay_1, dados.overlay_2][i])
            select.value = [dados.main_scene, dados.overlay_1, dados.overlay_2][i]
          td.appendChild(select)
          tr.appendChild(td)
        }

        // Escala
        const tdEscala = document.createElement("td")
        const escala = document.createElement("input")
        escala.type = "number"
        escala.step = "0.01"
        escala.value = dados?.scale || document.getElementById("scale").value
        tdEscala.appendChild(escala)
        tr.appendChild(tdEscala)

        // Largura
        const tdLargura = document.createElement("td")
        const largura = document.createElement("input")
        largura.type = "number"
        largura.step = "0.1"
        largura.value = dados?.vw || document.getElementById("vw").value
        tdLargura.appendChild(largura)
        tr.appendChild(tdLargura)

        // Altura
        const tdAltura = document.createElement("td")
        const altura = document.createElement("input")
        altura.type = "number"
        altura.step = "0.1"
        altura.value = dados?.vh || document.getElementById("vh").value
        tdAltura.appendChild(altura)
        tr.appendChild(tdAltura)

        const tdRemover = document.createElement("td")
        const btnRemover = document.createElement("button");
        btnRemover.textContent = "🗑️";
        btnRemover.onclick = () => tr.remove();

        const btnUp = document.createElement("button");
        btnUp.textContent = "⬆️";
        btnUp.onclick = () => moverLinhaParaCima(btnUp);

        const btnDown = document.createElement("button");
        btnDown.textContent = "⬇️";
        btnDown.onclick = () => moverLinhaParaBaixo(btnDown);

        tdRemover.appendChild(btnUp);
        tdRemover.appendChild(btnDown);
        tdRemover.appendChild(btnRemover);

        tr.appendChild(tdRemover)

        tabela.appendChild(tr)
      }

    function enviarConfig() {
        const linhas = document.querySelectorAll("#configTable tbody tr")
        const config = {
          scale: document.getElementById("scale").value,
          vw: document.getElementById("vw").value,
          vh: document.getElementById("vh").value,
          pages: []
        }

        linhas.forEach(linha => {
          const inputs = linha.querySelectorAll("input, select")
          config.pages.push({
            page_name: inputs[0].value,
            main_scene: inputs[1].value,
            overlay_1: inputs[2].value,
            overlay_2: inputs[3].value,
            scale: inputs[4].value,
            vw: inputs[5].value,
            vh: inputs[6].value
          })
        })

        window.sketchup.enviar_config(JSON.stringify(config)) // ✅ agora está no lugar certo
      }


      function exportarConfigParaArquivo() {
        const linhas = document.querySelectorAll("#configTable tbody tr")
        const config = {
          scale: document.getElementById("scale").value,
          vw: document.getElementById("vw").value,
          vh: document.getElementById("vh").value,
          pages: []
        }

        linhas.forEach(linha => {
          const inputs = linha.querySelectorAll("input, select")
          config.pages.push({
            page_name: inputs[0].value,
            main_scene: inputs[1].value,
            overlay_1: inputs[2].value,
            overlay_2: inputs[3].value,
            scale: inputs[4].value
          })
        })

        window.sketchup.exportar_config_arquivo(JSON.stringify(config))
      }


      function importarDeArquivo() {
        window.sketchup.importar_config()
      }

      window.populateScenes = populateScenes

      window.carregarConfigSalva = function(config) {
        document.getElementById("scale").value = config.scale || 50
        document.getElementById("vw").value = config.vw || 20
        document.getElementById("vh").value = config.vh || 20
        const tbody = document.querySelector("#configTable tbody")
        tbody.innerHTML = ""
        config.pages.forEach(p => addRow(p))
      }

      document.addEventListener("DOMContentLoaded", function() {
        if (window.sketchup && window.sketchup.ready) {
          window.sketchup.ready();
        }
      });

      document.getElementById('btn_salvar_config').addEventListener('click', () => {
        const linhas = document.querySelectorAll("#configTable tbody tr")
        const config = {
          scale: document.getElementById("scale").value,
          vw: document.getElementById("vw").value,
          vh: document.getElementById("vh").value,
          pages: []
        }

        linhas.forEach(linha => {
          const inputs = linha.querySelectorAll("input, select")
          config.pages.push({
            page_name: inputs[0].value,
            main_scene: inputs[1].value,
            overlay_1: inputs[2].value,
            overlay_2: inputs[3].value,
            scale: inputs[4].value
          })
        })

        sketchup.salvar_config(JSON.stringify(config))
      });



    </script>

    <footer>
      (C) 2025. Todos os direitos reservados. VERSÃO 1.0 (20/07/25)
    </footer>
  </body>
  </html>
  HTML

      dlg = UI::HtmlDialog.new(
        dialog_title: "Exportar para LayOut",
        preferences_key: "ExportarLayoutCustomizado",
        scrollable: true,
        resizable: true,
        width: 800,
        height: 600,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      dlg.set_html(html)
        dlg.add_action_callback("enviar_config") do |_, data_json|
          config = JSON.parse(data_json)
          @ultima_config = config
          Sketchup.active_model.set_attribute("ExportarLayoutCustomizado", "ultima_config", config.to_json)

          opcoes = ["Criar novo arquivo", "Incluir em arquivo existente (Xref)"]
            escolha = UI.inputbox(
              ["Escolha o modo de exportação:"],
              [opcoes[0]],
              [opcoes.join("|")],
              "Modo de Exportação"
            )

            if escolha.nil?
              return # usuário cancelou
            end

            modo_exportacao = escolha[0]

            if modo_exportacao == "Criar novo arquivo"
              export_from_config(config, novo_arquivo: true)
            elsif modo_exportacao == "Incluir em arquivo existente (Xref)"
              export_from_config(config, novo_arquivo: false)
            end

        end


        dlg.add_action_callback("exportar_config_arquivo") do |_, data_json|
          path = UI.savepanel("Salvar configuração", "", "config_layout.json")
          File.write(path, data_json) if path
        end


        dlg.add_action_callback("importar_config") do
          path = UI.openpanel("Importar configuração", "", "json")
          if path && File.exist?(path)
            begin
              json = File.read(path)
              config = JSON.parse(json)
              @ultima_config = config
              dlg.execute_script("window.carregarConfigSalva(#{json})")
            rescue => e
              UI.messagebox("Erro ao importar o arquivo: #{e.message}")
            end
          end
        end

        dlg.add_action_callback("ready") do
          scenes = Sketchup.active_model.pages.map(&:name)
          dlg.execute_script("window.populateScenes(" + scenes.to_json + ")")
          json_salvo = Sketchup.active_model.get_attribute("ExportarLayoutCustomizado", "ultima_config")
          if json_salvo
            begin
              config_salva = JSON.parse(json_salvo)
              @ultima_config = config_salva
              dlg.execute_script("window.carregarConfigSalva(" + @ultima_config.to_json + ")")
            rescue => e
              puts "Erro ao carregar config salva: #{e.message}"
            end
          end
        end

        dlg.add_action_callback("salvar_config") do |_, json_data|
          begin
            config = JSON.parse(json_data)
            @ultima_config = config  # Atualiza a variável Ruby
            Sketchup.active_model.set_attribute("ExportarLayoutCustomizado", "ultima_config", config.to_json)
            puts "Configurações salvas com sucesso."
          rescue JSON::ParserError => e
            puts "Erro ao salvar configurações: #{e.message}"
          end
        end    

        dlg.show
      end

      def normalize_scene_name(name)
        name.strip.downcase.gsub(/\s+/, "")
      end

      def export_from_config(config, novo_arquivo: true)
        model = Sketchup.active_model

        # Verifica se o arquivo nunca foi salvo
        if model.path.nil? || model.path.empty?
          UI.messagebox("Antes de exportar, salve o arquivo do SketchUp.\n\nA exportação foi cancelada para que você possa salvar manualmente.")
          return
        end

        scene_map = model.pages.to_a.map { |scene| [scene.name, scene] }.to_h

        template_path = nil
        save_path = nil

        if novo_arquivo
          template_path = UI.openpanel("Selecione o template LayOut", "", "*.layout")
          return unless template_path && File.exist?(template_path)

          model_path = model.path
          if model_path.nil? || model_path.empty?
            UI.messagebox("Por favor, salve o arquivo do SketchUp antes de exportar para o LayOut.")
            return
          end

          save_path = UI.savepanel("Salvar como", File.dirname(model_path), "#{File.basename(model_path, ".skp")}.layout")
          return unless save_path

          FileUtils.cp(template_path, save_path)
        else
          save_path = UI.openpanel("Selecione o arquivo LayOut existente para incluir as páginas", "", "*.layout")
          return unless save_path && File.exist?(save_path)
        end

        doc = Layout::Document.open(save_path)

        config["pages"].each do |page|
          page_name = page["page_name"]
          scenes = [page["main_scene"], page["overlay_1"], page["overlay_2"]].compact.map(&:strip).uniq.map do |name|
            scene_map[name]
          end.compact

          next if scenes.empty?

          escala_pagina = page["scale"] ? page["scale"].to_f : config["scale"].to_f
          escala_pagina = 50 if escala_pagina <= 0

          puts "Exportando página: #{page_name} com #{scenes.size} cena(s) na escala #{escala_pagina}..."

          vw = (page["vw"] || config["vw"] || 20).to_f / 2.54
          vh = (page["vh"] || config["vh"] || 20).to_f / 2.54

          pagina_existente = doc.pages.find { |p| p.name == page_name }

          if pagina_existente
            add_centered_viewport_page(doc, model, scenes, escala_pagina, page_name, vw, vh, pagina_existente, save_path)
          else
            add_centered_viewport_page(doc, model, scenes, escala_pagina, page_name, vw, vh, nil, save_path)
          end
        end

        UI.messagebox("LayOut exportado com sucesso!\n\n#{save_path}")
        Sketchup.send_to_layout(save_path)
      end

      def adicionar_viewport(doc, model, page, layer, bounds, idx, scale, view_type = nil)
        viewport = Layout::SketchUpModel.new(model.path, bounds)
        viewport.current_scene = idx + 1
        viewport.scale = 1.0 / scale unless viewport.perspective?
        viewport.render_mode = Layout::SketchUpModel::RASTER_RENDER
        viewport.display_background = false
        viewport.view = view_type if view_type
        doc.add_entity(viewport, layer, page)
      end

      def add_centered_viewport_page(doc, model, scenes, scale, page_name, vw, vh, pagina_existente = nil, save_path)
        page = pagina_existente || doc.pages.add(page_name)

        nome_arquivo = File.basename(model.path, ".skp")

        layer = doc.layers.find { |l| l.name == nome_arquivo } || doc.layers.add(nome_arquivo)
        layer.set_nonshared(page, Layout::Layer::UNSHARELAYERACTION_CLEAR)
        page.set_layer_visibility(layer, true)

        paper_width = doc.page_info.width
        paper_height = doc.page_info.height
        cx = (paper_width - vw) / 2.0
        cy = (paper_height - vh) / 2.0 + vh
        p1 = Geom::Point2d.new(cx, cy - vh)
        p2 = Geom::Point2d.new(cx + vw, cy)
        bounds = Geom::Bounds2d.new(p1, p2)

        scenes.each do |scene|
          idx = model.pages.to_a.index(scene)
          next unless idx && idx + 1 <= model.pages.size

          nome_cena = scene.name.strip

          if nome_cena.start_with?("det-")
          puts "Exportando detalhes para a cena: #{nome_cena}"

          adicionar_viewport(doc, model, page, layer, bounds, idx, scale)

          vistas_legendas = {
            Layout::SketchUpModel::TOP_VIEW => "Topo",
            Layout::SketchUpModel::FRONT_VIEW => "Frente",
            Layout::SketchUpModel::BACK_VIEW => "Fundo",
            Layout::SketchUpModel::LEFT_VIEW => "Esquerda",
            Layout::SketchUpModel::RIGHT_VIEW => "Direita"
          }

          vistas_legendas.each do |vista, legenda|
            puts "Adicionando vista: #{legenda}"
            adicionar_viewport(doc, model, page, layer, bounds, idx, scale, vista)
          end
        else
          adicionar_viewport(doc, model, page, layer, bounds, idx, scale)
        end

        doc.save(save_path)
      end
    

      
    end
  end #ExtensaoSkp
end #FM

