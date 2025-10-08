# encoding: UTF-8
require 'json'

module FM
  module ExportarImagens
    extend self

    def mostrar_janela
      model = Sketchup.active_model
      pages = model.pages
      cenas = pages.map(&:name)

      dlg = UI::HtmlDialog.new(
        dialog_title: "Exportar Cenas",
        preferences_key: "fm_exportar_imagens",
        scrollable: true,
        resizable: false,
        width: 300,
        height: 700,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      html = gerar_html(cenas)
      dlg.set_html(html)

      dlg.add_action_callback("exportarSelecionadas") do |_, json_data|
        data = JSON.parse(json_data)
        exportar_cenas(data)
        dlg.close
      end

      dlg.show
    end

    def gerar_html(cenas)
      cenas_json = cenas.to_json

      <<-HTML
      <!DOCTYPE html>
      <html lang="pt-BR">
      <head>
          <meta charset="UTF-8">
          <title>Exportar Cenas</title>
          <style>
          body {
              font-family: Century Gothic, sans-serif;
              margin: 10px;
              text-align: center;
              background-color: #f6f6f6;
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
              font-size: 12px;
          }
          th, td {
              border: 1px solid #ddd;
              padding: 5px;
              text-align: left;
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
              margin: 5px 0 15px 0;
          }
          .input-row {
              display: flex;
              flex-direction: column;
              align-items: center;
              gap: 10px;
              margin-bottom: 10px;
              font-size: 12px;
          }
          .input-row label {
              font-size: 12px;
              margin-bottom: 2px;
          }
          .input-row input,
          .input-row select {
              font-size: 12px;
              padding: 4px;
              width: 80px;
              text-align: center;
              border-radius: 6px;
              border: 1px solid #ccc;
              box-sizing: border-box;
          }
          input[type=number]::-webkit-outer-spin-button,
          input[type=number]::-webkit-inner-spin-button {
              -webkit-appearance: none;
              margin: 0;
          }
          input[type=number] {
              -moz-appearance: textfield;
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
              margin-top: 5px;
              margin-bottom: 15px;
          }
          </style>
      </head>
      <body>
          <div class="container">
          <h1>Exportar Cenas</h1>
          <p>Selecione as cenas desejadas e clique em Exportar. Tudo será salvo no mesmo local do arquivo.</p>

          <div class="input-row">
              <label for="prefixo">Prefixo:</label>
              <input id="prefixo" type="text" value="Imagem">

              <label for="largura">Largura (px):</label>
              <input id="largura" type="number" value="1920" min="100">

              <label for="proporcao">Proporção:</label>
              <select id="proporcao">
              <option value="16:9">16:9</option>
              <option value="4:3">4:3</option>
              <option value="1:1">1:1</option>
              <option value="4:5">4:5</option>
              <option value="9:16">9:16</option>
              <option value="21:9">21:9</option>
              </select>
          </div>

          <h2>Selecionar Cenas:</h2>
          <table>
              <thead>
              <tr>
                  <th>✓</th>
                  <th>Nome da Cena</th>
              </tr>
              </thead>
              <tbody id="cenas-body"></tbody>
          </table>

          <button onclick="enviarSelecionadas()">Exportar</button>

          <footer>
          Todos os direitos reservados. VERSÃO 1.0 (20/07/25)
          </footer>
          </div>

          <script>
          const cenas = #{cenas_json};

          function preencherTabela() {
              const tbody = document.getElementById('cenas-body');
              tbody.innerHTML = cenas.map(nome => \`
              <tr>
                  <td><input type="checkbox" value="\${nome}"></td>
                  <td>\${nome}</td>
              </tr>
              \`).join('');
          }

          function enviarSelecionadas() {
              const selecionadas = Array.from(document.querySelectorAll('input[type=checkbox]:checked'))
              .map(input => input.value);

              const dados = {
              cenas: selecionadas,
              prefixo: document.getElementById('prefixo').value,
              largura: parseInt(document.getElementById('largura').value),
              proporcao: document.getElementById('proporcao').value
              };

              sketchup.exportarSelecionadas(JSON.stringify(dados));
          }

          preencherTabela();
          </script>
      </body>
      </html>
      HTML
    end

    def exportar_cenas(data)
      model = Sketchup.active_model
      view = model.active_view
      pages = model.pages

      aspect_ratios = {
        "16:9" => 16.0 / 9.0,
        "4:3"  => 4.0 / 3.0,
        "1:1"  => 1.0,
        "4:5"  => 4.0 / 5.0,
        "9:16" => 9.0 / 16.0,
        "21:9" => 21.0 / 9.0
      }

      prefixo = data["prefixo"].strip
      largura = data["largura"].to_i
      proporcao = data["proporcao"]
      cenas_nomes = data["cenas"]

      if cenas_nomes.empty?
        UI.messagebox("Nenhuma cena selecionada.")
        return
      end

      ratio = aspect_ratios[proporcao] || 16.0 / 9.0
      altura = (largura / ratio).round

      if model.path.empty?
        UI.messagebox("Salve o arquivo antes de exportar as imagens.")
        return
      end

      output_dir = File.dirname(model.path)
      cenas_exportadas = pages.select { |p| cenas_nomes.include?(p.name) }

      cenas_exportadas.each_with_index do |page, i|
        pages.selected_page = page
        numero = format('%02d', i + 1)
        filename = File.join(output_dir, "#{prefixo}_#{numero}.jpg")

        puts "Exportando imagem #{numero} - Cena: '#{page.name}'"

        options = {
          filename: filename,
          width: largura,
          height: altura,
          antialias: true,
          compression: 1.0,
          transparent: false
        }

        view.write_image(options)
        puts "Concluído"
      end

      UI.messagebox("Exportação concluída! #{cenas_exportadas.size} imagem(ns) gerada(s).")
    end
  end
end
