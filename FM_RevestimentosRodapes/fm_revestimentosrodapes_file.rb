# encoding: UTF-8
require 'sketchup.rb'

Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'csv'
require 'json'

module FM_Extensions

  module FM_ProjectMaterials

    # ===========================================================
    #  ARMAZENAMENTO EM MEMÓRIA (CACHE TEMPORÁRIA NA SESSÃO)
    # ===========================================================
    @materials_cache = []

    def self.materials_cache
      @materials_cache
    end

    def self.materials_cache=(new_data)
      @materials_cache = new_data
    end

    # ===========================================================
    #              ABRIR O DIÁLOGO (SEM set_on_loaded)
    # ===========================================================
    def self.open_materials_dialog
      html = <<-HTML
        <!DOCTYPE html>
        <html lang="en">
        <head>
          <meta charset="UTF-8">
          <title>Revestimentos</title>
          <style>
            body {
              font-family: 'Century Gothic', sans-serif;
              margin: 10px;
              text-align: center;
              background-color: #f4f4f4;
            }
            button {
              font-size: 12px;
              margin: 3px 0;
              padding: 5px 5px;
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
              margin: 10px;
              margin-bottom: 2px;
              display: inline-block;
              border: 3px solid #becc8a;
              padding: 5px;
              border-radius: 10px;
              box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.2);
              background-color: #fff;
            }
            h2 {
              font-size: 14px;
              margin-top: 10px;
              cursor: pointer;
              border: 1px solid #ccc;
              border-radius: 10px;    
              box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
              padding: 5px;
            }
            h3 {
              font-size: 14px;
              margin-top: 10px;
            }
            p {
              font-size: 10px;
              margin: 5px 0;
              margin-bottom: 20px;
            }
            table {
              font-size: 12px;
              width: 100%;          /* A largura é definida de acordo com o conteúdo */
              max-width: 100%;      /* Nunca ultrapassa a largura do contêiner */
              table-layout: auto;   /* Ajusta as colunas conforme o tamanho dos dados */
              border-collapse: collapse;
              margin-top: 20px;
            }
            th, td {
              border: 1px solid #ddd;
              padding: 10px;
              text-align: left;
            }
            th {
              background-color: #ffffff;
            }
            td:first-child, th:first-child {
              width: 50%;
              word-wrap: break-word;
              white-space: normal;
            }
            input[type="text"], input[type="number"] {
              width: 100%;
              padding: 5px;
              margin-top: 5px;
              box-sizing: border-box;
              border: 1px solid #ccc;
              border-radius: 4px;
            }
            footer {
              margin-top: 20px;
              font-size: 10px;
              color: #666;
              text-align: center;
              border-top: 1px solid #ccc;
              padding-top: 10px;
            }
            .hidden {
              display: none;
            }
          </style>
          <script>
            let materialsData = [];

            function restoreTable(dataArray) {
              const tbody = document.querySelector('#materials-table tbody');
              tbody.innerHTML = "";

              // Substitui o array local pelos dados vindos do Ruby
              materialsData = dataArray;

              dataArray.forEach(item => {
                // item = [materialName, area, acrescimo, total]
                // Passamos "sync = false" para NÃO fazer o push novamente
                addRowToTable(item[0], item[1], item[2], item[3], false);
              });
            }


            // Adiciona nova linha
            // materialName, area, acrescimo=0, total=area, sync=true
              function addRowToTable(materialName, area, acrescimo = 0, total = area, sync = true) {
                const table = document.getElementById('materials-table').getElementsByTagName('tbody')[0];
                const row = table.insertRow(table.rows.length);
              
                const cell1 = row.insertCell(0);
                const cell2 = row.insertCell(1);
                const cell3 = row.insertCell(2);
                const cell4 = row.insertCell(3);
                const cell5 = row.insertCell(4);
              
                // Cria os inputs normalmente
                cell1.innerHTML = '<input type="text" value="' + materialName + '" onblur="updateMaterialName(this)" />';
                cell2.innerHTML = '<input type="text" value="' + area + '" readonly />';
                cell3.innerHTML = '<input type="number" value="' + acrescimo + '" onchange="updateTotal(this)" />';
                cell4.innerHTML = '<input type="text" value="' + total + '" readonly />';
                cell5.innerHTML = '<button onclick="removeRow(this)">Remover</button>';
              
                // Se for para sincronizar, significa que o usuário está adicionando algo novo
                // ou editando diretamente (não é um restore)
                // Então só nesse caso adicionamos ao array
                if (sync) {
                  materialsData.push([materialName, area, acrescimo, total]);
                  syncCacheWithRuby(); // se quiser sincronizar imediatamente
                }
              }
            

            // Atualiza o nome do material quando perder foco
            function updateMaterialName(inputEl) {
              const row = inputEl.closest('tr');
              const rowIndex = Array.from(row.parentElement.children).indexOf(row);
              materialsData[rowIndex][0] = inputEl.value; // Nome do material
              syncCacheWithRuby();
            }

            // Atualiza o total quando muda acréscimo
            function updateTotal(input) {
              const row = input.closest('tr');
              const areaInput = row.querySelector('td:nth-child(2) input');
              const totalInput = row.querySelector('td:nth-child(4) input');
              const acrescimoInput = row.querySelector('td:nth-child(3) input');

              const areaVal = parseFloat(areaInput.value) || 0;
              const acrescimoVal = parseFloat(acrescimoInput.value) / 100 || 0;
              const totalVal = areaVal * (1 + acrescimoVal);
              totalInput.value = totalVal.toFixed(2);

              // Atualiza o array
              const rowIndex = Array.from(row.parentElement.children).indexOf(row);
              materialsData[rowIndex][2] = acrescimoInput.value;  // string de acréscimo
              materialsData[rowIndex][3] = totalVal.toFixed(2);   // total

              // Salva no Ruby
              syncCacheWithRuby();
            }

            // Remover linha
            function removeRow(button) {
              const row = button.closest('tr');
              const table = row.parentElement;
              const rowIndex = Array.from(table.children).indexOf(row);

              // Remove do array local
              materialsData.splice(rowIndex, 1);

              // Remove do DOM
              row.remove();
              syncCacheWithRuby();
            }

            // Botão "Adicionar Material": chama Ruby
            function addMaterial() {
              sketchup.add_material();
            }

            // Botão "Exportar CSV"
            function exportCSV() {
              const updatedData = [];
              const rows = document.querySelectorAll('#materials-table tbody tr');
              rows.forEach(row => {
                const cells = row.querySelectorAll('input');
                // Monta array: [ "0", materialName, area, acrescimo, total ]
                updatedData.push([" ", cells[0].value, cells[1].value, cells[2].value, cells[3].value]);
              });
              sketchup.save_csv(updatedData);
            }

            // Sincroniza com o Ruby, enviando o array materialsData inteiro
            function syncCacheWithRuby() {
              sketchup.update_cache(materialsData);
            }
          </script>
        </head>
        <body>
          <h1>Revestimentos</h1>
          <p>Selecione um material com o conta-gotas e clique em ADICIONAR MATERIAL, altere as informações necessárias e clique em EXPORTAR.</p>

          <div>
            <h3>Quantitativo de Materiais</h3>
          </div>
          
          <table id="materials-table">
            <thead>
              <tr>
                <th>Material</th>
                <th>Área (m²)</th>
                <th>Acréscimo (%)</th>
                <th>Total</th>
                <th>Ações</th>
              </tr>
            </thead>
            <tbody></tbody>
          </table>

          <button onclick="addMaterial()">Adicionar Material</button>
          <button onclick="exportCSV()" style="margin-top: 20px;">Exportar Tabela</button>
          
          <footer>
            <p>Desenvolvido por 
              <a href="https://francielimadeira.com" target="_blank" style="text-decoration: none; color: #666; font-weight: bold;">
                Francieli Madeira
              </a> 
              © 2024. Todos os direitos reservados. VERSÃO 1.0 (23/02/25)
            </p>
          </footer>
        </body>
        </html>
      HTML

      dialog = UI::HtmlDialog.new(
        dialog_title: "Materiais do Projeto",
        preferences_key: "com.example.materias_projeto".dup.force_encoding('UTF-8'),
        scrollable: true,
        resizable: true,
        width: 600,
        height: 500,
        style: UI::HtmlDialog::STYLE_DIALOG
      )
      dialog.set_html(html)

      # Exibe o diálogo
      dialog.show

      # Usa um timer no lugar de set_on_loaded (que pode não existir)
      UI.start_timer(0.2, false) do
        # Converter cache para JSON e chamar restoreTable no JS
        json_data = FM_ProjectMaterials.materials_cache.to_json
        dialog.execute_script("restoreTable(#{json_data})")
      end

      # ============================
      # CALLBACKS DO LADO RUBY
      # ============================
      dialog.add_action_callback("add_material") do |_context|
        add_selected_material(dialog)
      end

      dialog.add_action_callback("save_csv") do |_context, csv_data|
        export_to_csv(csv_data)
      end

      # Sempre que o JS chamar "syncCacheWithRuby()", cai aqui
      dialog.add_action_callback("update_cache") do |_context, new_data|
        # Armazena na variável @materials_cache
        FM_ProjectMaterials.materials_cache = new_data
      end
    end

    # ===========================================================
    #         ADICIONAR MATERIAL (quando clicado no JS)
    # ===========================================================
    def self.add_selected_material(dialog)
      model = Sketchup.active_model
      material = model.materials.current

      if material.nil?
        UI.messagebox("Nenhum material selecionado.")
        return
      end

      # Calcula área total do material
      areas = iterate_entities(model.entities)
      selected_area = areas[material] || 0.0
      area_m2 = (selected_area * 0.00064516).round(2)

      # Envia pro JS inserir na tabela
      dialog.execute_script("addRowToTable('#{material.display_name}', '#{area_m2}')")
    end

    # Percorre entidades para somar áreas por material
    def self.iterate_entities(entities, areas = Hash.new(0))
      entities.each do |entity|
        if entity.is_a?(Sketchup::Face)
          mat = entity.material || entity.back_material
          areas[mat] += entity.area if mat
        elsif entity.is_a?(Sketchup::Group) || entity.is_a?(Sketchup::ComponentInstance)
          iterate_entities(entity.definition.entities, areas)
        end
      end
      areas
    end

    # ===========================================================
    #         EXPORTAR CSV
    # ===========================================================
    def self.export_to_csv(csv_data)
      model = Sketchup.active_model
      model_path = model.path
    
      if model_path.empty?
        UI.messagebox("Por favor, salve o modelo antes de exportar o arquivo CSV.")
        return
      end
    
      # Perguntar ao usuário se deseja converter todas as letras para maiúsculas
      result = UI.messagebox("Deseja converter os valores para letras maiúsculas?", MB_YESNO, "Opção de Exportação")
      convert_to_uppercase = (result == IDYES)
    
      output_dir = File.dirname(model_path)
    
      # Abrir caixa de diálogo para o usuário definir o nome do arquivo
      filename = UI.inputbox(["Nome do arquivo:"], ["Revestimentos"], "Exportar CSV")[0]
    
      # Garantir que o usuário não deixou o nome em branco
      filename = "Revestimentos" if filename.strip.empty?
    
      output_file = File.join(output_dir, "#{filename}.csv")
    
      CSV.open(output_file, 'w') do |csv|
        csv << ['LEGENDA', 'DESCRIÇÃO', 'ÁREA(m²)', 'ACRÉSCIMO(%)', 'TOTAL(m²)']
        csv_data.each do |row|
          csv << (convert_to_uppercase ? row.map(&:upcase) : row)
        end
      end
    
      UI.messagebox("Exportação concluída com sucesso para #{output_file}.")
    end
    

  end


  ##################

  # coding: utf-8
module FM_Rodapes

  # **********************************************************************
  # Busca componentes recursivamente, até um nível máximo (5)
  # **********************************************************************
  def self.buscar_componentes(entities, nivel = 0)
    detalhes = []
    return detalhes if nivel >= 5

    entities.each do |entity|
      next unless entity.valid?  # Ignora entidades inválidas ou excluídas

      if entity.is_a?(Sketchup::ComponentInstance)
        # Verifica se o componente possui o atributo "comprimentorodape"
        comprimentorodape = entity.get_attribute("dynamic_attributes", "comprimentorodape")
        next unless comprimentorodape

        definition = entity.definition
        nome = definition.name

        # Calcula o comprimento dinâmico usando LenX (convertendo polegadas para metros)
        lenx_em_metros = (entity.transformation.xscale * definition.bounds.width) * 0.0254
        lenx_dinamico = entity.get_attribute("dynamic_attributes", "_lenx_formula")&.to_f || lenx_em_metros
        puts "LenX dinâmico (metros): #{lenx_dinamico}"

        # Obtém o modelo do rodapé
        modelorodape = definition.get_attribute("dynamic_attributes", "modelorodape")

        # Adiciona os detalhes se o comprimento for válido
        if lenx_dinamico > 0
          detalhes << {
            nome: nome,
            comprimento: lenx_dinamico,
            modelo: modelorodape,
            id: entity.persistent_id
          }
        end

        # Busca recursivamente nas subentidades, se disponíveis
        if definition.respond_to?(:entities)
          detalhes.concat(buscar_componentes(definition.entities, nivel + 1))
        end

      elsif entity.is_a?(Sketchup::Group)
        # Busca dentro dos grupos, se houver subentidades
        if entity.respond_to?(:entities)
          detalhes.concat(buscar_componentes(entity.entities, nivel + 1))
        end
      end
    end

    detalhes
  end

  # **********************************************************************
  # Importa um bloco a partir do diretório de blocos
  # **********************************************************************
  def self.import_block(block_name, blocks_dir)
    subfolder, block_file = File.split(block_name)
    # Para compor o caminho usamos o valor original;
    # para exibição, podemos forçar UTF-8 (se necessário)
    display_subfolder = subfolder.dup.force_encoding('UTF-8')
    block_path = File.join(blocks_dir, subfolder, "#{block_file}.skp")

    if File.exist?(block_path)
      model = Sketchup.active_model
      definitions = model.definitions
      # Carrega o bloco com allow_newer: true se necessário
      definition = definitions.load(block_path, allow_newer: true)
      model.place_component(definition) if definition.is_a?(Sketchup::ComponentDefinition)
    else
      UI.messagebox("Bloco não encontrado: #{block_path}")
    end
  end

  # **********************************************************************
  # Exporta os dados para CSV, com opção de converter valores para maiúsculas
  # **********************************************************************
  def self.export_to_csv(somas)
    model = Sketchup.active_model
    file_path = File.join(File.dirname(model.path), "Rodapés.csv")

    # Pergunta ao usuário se deseja converter os valores para letras maiúsculas
    result = UI.messagebox("Deseja converter os valores para letras maiúsculas?", MB_YESNO, "Opção de Exportação")
    convert_to_uppercase = (result == IDYES)

    begin
      CSV.open(file_path, "wb") do |csv|
        # Cabeçalho da tabela
        csv << ["LEGENDA", "MODELO", "SOMA (m)", "BARRA (m)", "TOTAL (un)"]

        # Processa cada par modelo-soma
        somas.each do |modelo, soma|
          barra = 2.4
          total = (soma / barra).ceil
          modelo_final = convert_to_uppercase ? modelo.to_s.upcase : modelo
          csv << ["", modelo_final, soma, barra, total]
        end
      end

      UI.messagebox("Tabela exportada com sucesso para:\n#{file_path}")
    rescue => e
      UI.messagebox("Erro ao exportar o CSV:\n#{e.message}")
    end
  end

  # **********************************************************************
  # Gera a estrutura HTML para exibir os blocos disponíveis
  # **********************************************************************
  def self.generate_blocks_html(blocks_dir)
    structure_html = ""

    begin
      subfolders = Dir.entries(blocks_dir)
                      .select { |entry|
                        File.directory?(File.join(blocks_dir, entry)) &&
                        !(entry == '.' || entry == '..')
                      }
                      .sort_by { |entry| entry == "Geral" ? "" : entry }
    rescue => e
      UI.messagebox("Erro ao acessar o diretório de blocos:\n#{e.message}")
      return ""
    end

    subfolders.each_with_index do |subfolder, index|
      subfolder_path = File.join(blocks_dir, subfolder)
      # Converte para UTF-8 para exibição
      subfolder_utf8 = subfolder.dup.force_encoding('UTF-8')

      begin
        block_names = Dir.entries(subfolder_path)
                        .select { |file| File.extname(file).downcase == ".skp" }
                        .map { |file| File.basename(file, ".skp").dup.force_encoding('UTF-8') }
      rescue => e
        UI.messagebox("Erro lendo arquivos na subpasta '#{subfolder_utf8}':\n#{e.message}")
        next
      end

      next if block_names.empty?

      # Define um ID único para a seção de expandir/colapsar
      section_id = "section-#{index}"
      structure_html << <<-HTML
        <h3 onclick="toggleVisibility('#{section_id}')">#{subfolder_utf8}</h3>
        <div id="#{section_id}" class="hidden">
      HTML

      block_names.each do |block_name|
        structure_html << "<button onclick=\"sketchup.import_block('#{subfolder_utf8}/#{block_name}')\">#{block_name}</button>\n"
      end

      structure_html << "</div>"
    end

    if structure_html.empty?
      structure_html = %(
        <p style="color:red;">
          Nenhuma subpasta ou arquivo .skp foi encontrado em:
          <br><strong>#{blocks_dir}</strong>
        </p>
      )
    end

    structure_html
  end

  # **********************************************************************
  # Abre a interface HTML de rodapés, integrando blocos dinâmicos e dados
  # **********************************************************************
  def self.open_rodapes_dialog
    model = Sketchup.active_model
    blocks_dir = File.join(__dir__, 'blocos')
    structure_html = generate_blocks_html(blocks_dir)

    # Processa os componentes do modelo para identificar os rodapés
    entities = model.active_entities
    componentes = buscar_componentes(entities)

    # Filtra apenas os componentes que possuem o atributo "modelorodape"
    componentes_filtrados = componentes.select { |componente| componente[:modelo] }
    agrupados = componentes_filtrados.group_by { |componente| componente[:modelo] }
    somas = agrupados.transform_values do |lista|
      soma = lista.map { |componente| componente[:comprimento].to_f }.sum
      soma.round(2)
    end

    # Gera o HTML para a tabela de quantitativos
    table_html = ""
    agrupados.each do |modelo, lista|
      soma = somas[modelo]
      table_html << <<-ROW
        <tr>
          <td>#{modelo}</td>
          <td class="soma">#{soma}</td>
          <td><input type="number" class="barra" value="2.4" step="0.1" onchange="updateTotals()"></td>
          <td class="total">#{(soma / 2.4).ceil}</td>
        </tr>
      ROW
    end

    # Monta o HTML completo da interface
    html = <<-HTML
    <!DOCTYPE html>
    <html lang="pt">
    <head>
      <meta charset="UTF-8">
      <title>Rodapés</title>
      <style>
        body {
          font-family: Century Gothic, sans-serif;
          margin: 10px;
          text-align: center;
          background-color: #f6f6f6;
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
          margin: 10px;
          margin-bottom: 2px;
          display: inline-block;
          border: 3px solid #becc8a;
          padding: 5px;
          border-radius: 10px;
          box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.2);
          background-color: #fff;
        }
        h2 {
          font-size: 14px;
          margin-top: 10px;
          cursor: pointer;
          border: 1px solid #ccc;
          border-radius: 10px;    
          box-shadow: 2px 2px 5px rgba(0, 0, 0, 0.2);
          padding: 5px;
        }
        h3 {
          font-size: 14px;
          margin: 10px 0;
          border: 3px solid #becc8a;
          box-shadow: 2px 2px 10px rgba(0, 0, 0, 0.2);
          border: 3px solid #ccc;
          padding: 5px;
          border-radius: 10px;
          width: auto;
          display: inline-block;
          cursor: pointer;
        }
        h4 {
              font-size: 14px;
              margin-top: 10px;
            }
        p {
          font-size: 10px;
          margin: 5px 0;
          margin-bottom: 20px;
        }
        .hidden {
          display: none;
        }
        table {
          font-size: 12px;
          width: 100%;          /* A largura é definida de acordo com o conteúdo */
          max-width: 100%;      /* Nunca ultrapassa a largura do contêiner */
          table-layout: auto;   /* Ajusta as colunas conforme o tamanho dos dados */
          border-collapse: collapse;
          margin-top: 20px;
        }
        th, td {
          border: 1px solid #ddd;
          padding: 10px;
          text-align: left;
        }
        th {
          background-color: #ffffff;
        }
        td:first-child, th:first-child {
          width: 60%;
          word-wrap: break-word;
          white-space: normal;
        }
        input[type="text"], input[type="number"] {
          width: 100%;
          padding: 5px;
          margin-top: 5px;
          box-sizing: border-box;
          border: 1px solid #ccc;
          border-radius: 4px;
        }
        footer {
          margin-top: 20px;
          font-size: 10px;
          color: #666;
          text-align: center;
          border-top: 1px solid #ccc;
          padding-top: 10px;
        }
      </style>
      <script>
        function toggleVisibility(sectionId) {
          const section = document.getElementById(sectionId);
          if (section.classList.contains("hidden")) {
            section.classList.remove("hidden");
          } else {
            section.classList.add("hidden");
          }
        }
        function updateTotals() {
          const rows = document.querySelectorAll("table tbody tr");
          rows.forEach(row => {
            const soma = parseFloat(row.querySelector(".soma").textContent) || 0;
            const barra = parseFloat(row.querySelector(".barra").value) || 2.4;
            row.querySelector(".total").textContent = Math.ceil(soma / barra);
          });
        }
        function updateTable() {
          window.location = 'skp:update_table';
        }
        function exportTable() {
          window.location = 'skp:export_table';
        }
      </script>
    </head>
    <body>
      <h1>Rodapés</h1>
      <p>Clique no botão abaixo para importar os blocos dinâmicos de rodapés.</p>
      #{structure_html}
      
      <h4>Quantitativo de Rodapés</h4>
      <table>
        <thead>
          <tr>
            <th>Modelo</th>
            <th>Soma (m)</th>
            <th>Barra (m)</th>
            <th>Total</th>
          </tr>
        </thead>
        <tbody>
          #{table_html}
        </tbody>
      </table>
      <button onclick="updateTable()">Atualizar Dados</button>
      <button onclick="exportTable()">Exportar Tabela</button>
      <button onclick="sketchup.open_blocks_folder()" style="margin-top: 20px;">Abrir Pasta de Blocos</button>
      <p>Use os botões acima para atualizar, exportar os dados ou abrir a pasta para blocos personalizados.</p>
      <footer>
        <p>Desenvolvido por 
          <a href="https://francielimadeira.com" target="_blank" style="text-decoration: none; color: #666; font-weight: bold;">Francieli Madeira</a> 
          © 2024. Todos os direitos reservados. VERSÃO 1.0 (23/02/25)
        </p>
      </footer>
    </body>
    </html>
    HTML

    # Se necessário, forçamos o encoding do HTML (caso os dados dinâmicos não estejam em UTF-8)
    html = html.dup.force_encoding('UTF-8')
  
    # Cria e configura a janela de diálogo HTML
    dialog = UI::HtmlDialog.new({
      dialog_title: "Resumo dos Rodapés".dup.force_encoding('UTF-8'),
      preferences_key: "com.example.resumo_rodapes".dup.force_encoding('UTF-8'),
      scrollable: true,
      resizable: true,
      width: 600,
      height: 500,
      style: UI::HtmlDialog::STYLE_DIALOG
    })

    dialog.set_html(html)
  
    # Callback para importar bloco
    dialog.add_action_callback("import_block") do |_context, block_name|
      import_block(block_name, blocks_dir)
    end
  
    # Callback para atualizar a tabela
    dialog.add_action_callback("update_table") do |_context|
      componentes = buscar_componentes(Sketchup.active_model.active_entities)
      puts "Componentes processados:"
      componentes.each { |c| puts c }
      componentes_filtrados = componentes.select { |componente| componente[:modelo] }
      agrupados = componentes_filtrados.group_by { |componente| componente[:modelo] }
      somas = agrupados.transform_values do |lista|
        soma = lista.map { |componente| componente[:comprimento].to_f }.sum
        soma.round(2)
      end

      updated_html = ""
      agrupados.each do |modelo, lista|
        soma = somas[modelo]
        updated_html << <<-ROW
          <tr>
            <td>#{modelo}</td>
            <td class="soma">#{soma}</td>
            <td><input type="number" class="barra" value="2.4" step="0.1" onchange="updateTotals()"></td>
            <td class="total">#{(soma / 2.4).ceil}</td>
          </tr>
        ROW
      end

      puts "HTML gerado para a tabela:"
      puts updated_html
      dialog.execute_script("document.querySelector('table tbody').innerHTML = `#{updated_html}`;")
      dialog.execute_script("updateTotals();")
    end
  
    # Callback para exportar a tabela
    dialog.add_action_callback("export_table") do |_context|
      export_to_csv(somas)
    end
  
    # Callback para abrir a pasta de blocos
    dialog.add_action_callback("open_blocks_folder") do |_context|
      if File.directory?(blocks_dir)
        UI.openURL("file://#{blocks_dir}")
      else
        UI.messagebox("Erro: O diretório de blocos não foi encontrado:\n#{blocks_dir}")
      end
    end
  
    dialog.show
  end

end # FM_Rodapes

  

  #################

  toolbar = UI::Toolbar.new('FM - Revestimentos e Rodapés')
  
  # Adicionar botão "Quantitativo de Revestimentos"
  cmd_quantitativo_revestimentos = UI::Command.new('Revestimentos') {
    FM_ProjectMaterials.open_materials_dialog
  }

  icon_quantitativo_revestimentos = File.join(__dir__, 'icones', 'revestimento.png')
  if File.exist?(icon_quantitativo_revestimentos)
    cmd_quantitativo_revestimentos.small_icon = icon_quantitativo_revestimentos
    cmd_quantitativo_revestimentos.large_icon = icon_quantitativo_revestimentos
  else
    UI.messagebox("Ícone não encontrado: #{icon_quantitativo_revestimentos}")
  end

  cmd_quantitativo_revestimentos.tooltip = 'Revestimentos'
  cmd_quantitativo_revestimentos.status_bar_text = 'Abre janela para configurar o quantitativo de revestimentos e exportar para Layout.'
  toolbar.add_item(cmd_quantitativo_revestimentos)

  # Adicionar botão "Rodapes"
  cmd_anotacao_cortes = UI::Command.new('Rodapés') {
      FM_Extensions::FM_Rodapes.open_rodapes_dialog
    }

    icon_anotacao_cortes = File.join(__dir__, 'icones', 'roda.png')
    if File.exist?(icon_anotacao_cortes)
      cmd_anotacao_cortes.small_icon = icon_anotacao_cortes
      cmd_anotacao_cortes.large_icon = icon_anotacao_cortes
    else
      UI.messagebox("Ícone não encontrado: #{icon_anotacao_cortes}")
    end

    cmd_anotacao_cortes.tooltip = 'Rodapés'
    cmd_anotacao_cortes.status_bar_text = 'Blocos Dinâmicos e Relatório de Rodapés.'
    toolbar.add_item(cmd_anotacao_cortes)
  
  toolbar.show

end #FM_Extensions