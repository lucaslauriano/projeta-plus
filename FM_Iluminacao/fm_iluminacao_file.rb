# encoding: UTF-8
require "sketchup.rb"

# Forçar o uso de UTF-8 como padrão
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

module FM_BlocosDinamicos
  module FM_PontosIluminacao

    # Função para abrir a janela HTML
    def self.open_blocks_dialog
      # Forçar UTF-8 no nome da subpasta
      blocks_dir = File.join(__dir__.dup.force_encoding('UTF-8'), 'blocos'.dup.force_encoding('UTF-8'))

      # Verificar se o diretório existe
      unless File.directory?(blocks_dir)
        UI.messagebox("Erro: O diretório de blocos não foi encontrado:\n#{blocks_dir}".dup.force_encoding("UTF-8"))
        return
      end

      structure_html = ""

      # Obter subpastas forçando UTF-8
      subfolders = Dir.entries(blocks_dir).map { |e| e.dup.force_encoding('UTF-8') }
                     .select { |entry| File.directory?(File.join(blocks_dir, entry)) && !(entry == '.' || entry == '..') }
                     .sort_by { |entry| entry == "Geral" ? "" : entry }

      subfolders.each_with_index do |subfolder, index|
        subfolder_path = File.join(blocks_dir, subfolder).dup.force_encoding('UTF-8')
        skp_files = Dir.entries(subfolder_path).map { |f| f.dup.force_encoding('UTF-8') }
                       .select { |file| File.extname(file).downcase == ".skp" }

        # Obter nomes dos blocos sem extensão
        block_names = skp_files.map { |file| File.basename(file, ".skp") }

        next if block_names.empty?

        # Adicionar subtítulo com funcionalidade de expandir/colapsar
        section_id = "section-#{index}"
        structure_html += <<-HTML
          <h2 onclick="toggleVisibility('#{section_id}')">#{subfolder}</h2>
          <div id="#{section_id}" class="hidden">
        HTML

        # Adicionar botões para os arquivos na subpasta
        block_buttons = block_names.map do |block_name|
          "<button onclick=\"sketchup.import_block('#{subfolder}/#{block_name}')\">#{block_name}</button>"
        end.join("\n")

        structure_html += block_buttons
        structure_html += "</div>"
      end

      # HTML direto para exibição
      html_content = <<-HTML
      <!DOCTYPE html>
      <html lang="en">
      <head>
        <meta charset="UTF-8">
        <title>Pontos Iluminação</title>
        <style>
          body {
            font-family: Century Gothic, sans-serif;
            margin: 10px;
            text-align: center;
          }
          button {
            margin: 3px 0;
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
          }
          h2 {
            font-size: 14px;
            margin-top: 10px;
            cursor: pointer;
          }
          p {
            font-size: 10px;
            margin: 5px 0;
            margin-bottom: 20px;
          }
          .hidden {
            display: none;
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
          function toggleVisibility(id) {
            const section = document.getElementById(id);
            section.classList.toggle('hidden');
          }
        </script>
      </head>
      <body>
        <h1>Pontos de Iluminação</h1>
        <p>Clique no título para acessar <br> e no bloco desejado para importá-lo:</p>
        
        #{structure_html}

        <div style="margin-top: 5px;">
        <button onclick="sketchup.open_blocks_folder()">Abrir Pasta de Blocos</button>
        </div>
        <div style="margin-top: 5px;">
          <button onclick="sketchup.export_report()">Exportar Relatório</button>
        </div>
        <div style="margin-top: 5px;">
          <button onclick="sketchup.export_report_marcenaria()">Exportar Relatório Marcenaria</button>
        </div>

        <footer>
          <p>Desenvolvido por 
            <a href="https://francielimadeira.com" target="_blank" style="text-decoration: none; color: #666; font-weight: bold;">
              Francieli Madeira
            </a> 
            (C) 2024. Todos os direitos reservados.
          </p>
        </footer>
      
      </body>
      </html>
      HTML

      html_content = html_content.dup.force_encoding('UTF-8')

      dialog = UI::HtmlDialog.new({
        dialog_title: "Blocos Dinâmicos - Iluminação".dup.force_encoding('UTF-8'),
        preferences_key: "com.sketchup.quick_blocks".dup.force_encoding('UTF-8'),
        scrollable: true,
        resizable: false,
        width: 300,
        height: 600,
        style: UI::HtmlDialog::STYLE_DIALOG
      })

      # Define o conteúdo HTML
      dialog.set_html(html_content)

      # Callback para importar blocos
      dialog.add_action_callback("import_block") do |_context, block_name|
        import_block(block_name, blocks_dir)
      end

      # Callback para exportar o relatório de iluminação
      dialog.add_action_callback("export_report") do |_context|
        export_report
      end

      # Callback para exportar o relatório de marcenaria
      dialog.add_action_callback("export_report_marcenaria") do |_context|
        export_report_marcenaria
      end

      # Callback para abrir a pasta principal
      dialog.add_action_callback("open_blocks_folder") do |_context|
        if File.directory?(blocks_dir)
          UI.openURL("file://#{blocks_dir}".dup.force_encoding("UTF-8"))
        else
          UI.messagebox("Erro: O diretório de blocos não foi encontrado:\n#{blocks_dir}".dup.force_encoding("UTF-8"))
        end
      end

      # Mostra a janela
      dialog.show
    end

    # Função recursiva para buscar componentes de iluminação e seus atributos
    def self.buscar_componentes(entities, nivel = 0)
      iluminacao_components = []
      return iluminacao_components if nivel >= 5

      entities.each do |entity|
        if entity.is_a?(Sketchup::ComponentInstance)
          definition = entity.definition

          fm_ilu    = definition.get_attribute("dynamic_attributes", "fm_ilu")
          fm_ilu_t1 = definition.get_attribute("dynamic_attributes", "fm_ilu_t1")
          fm_ilu_t2 = definition.get_attribute("dynamic_attributes", "fm_ilu_t2")
          fm_ilu_t3 = definition.get_attribute("dynamic_attributes", "fm_ilu_t3")
          fm_ilu_t4 = definition.get_attribute("dynamic_attributes", "fm_ilu_t4")
          fm_ilu_t5 = definition.get_attribute("dynamic_attributes", "fm_ilu_t5")
          fm_ilu_t6 = definition.get_attribute("dynamic_attributes", "fm_ilu_t6")
          fm_ilu_t7 = definition.get_attribute("dynamic_attributes", "fm_ilu_t7")
          fm_ilu_t8 = definition.get_attribute("dynamic_attributes", "fm_ilu_t8")

          if fm_ilu || fm_ilu_t1 || fm_ilu_t2 || fm_ilu_t3 || fm_ilu_t4 || fm_ilu_t5 || fm_ilu_t6 || fm_ilu_t7 || fm_ilu_t8
            iluminacao_components << {
              fm_ilu: fm_ilu,
              fm_ilu_t1: fm_ilu_t1,
              fm_ilu_t2: fm_ilu_t2,
              fm_ilu_t3: fm_ilu_t3,
              fm_ilu_t4: fm_ilu_t4,
              fm_ilu_t5: fm_ilu_t5,
              fm_ilu_t6: fm_ilu_t6,
              fm_ilu_t7: fm_ilu_t7,
              fm_ilu_t8: fm_ilu_t8
            }
          end

          iluminacao_components.concat(buscar_componentes(entity.definition.entities, nivel + 1))
        elsif entity.is_a?(Sketchup::Group)
          iluminacao_components.concat(buscar_componentes(entity.entities, nivel + 1))
        end
      end

      iluminacao_components
    end

    # Função recursiva para buscar componentes de marcenaria e seus atributos
    def self.buscar_componentes_marcenaria(entities, nivel = 0)
      marcenaria_components = []
      return marcenaria_components if nivel >= 5

      entities.each do |entity|
        if entity.is_a?(Sketchup::ComponentInstance)
          definition = entity.definition

          fm_ilu    = definition.get_attribute("dynamic_attributes", "fm_ilu_mar")
          fm_ilu_t1 = definition.get_attribute("dynamic_attributes", "fm_ilu_mar_t1")
          fm_ilu_t2 = definition.get_attribute("dynamic_attributes", "fm_ilu_mar_t2")
          fm_ilu_t3 = definition.get_attribute("dynamic_attributes", "fm_ilu_mar_t3")
          fm_ilu_t4 = definition.get_attribute("dynamic_attributes", "fm_ilu_mar_t4")
          fm_ilu_t5 = definition.get_attribute("dynamic_attributes", "fm_ilu_mar_t5")
          fm_ilu_t6 = definition.get_attribute("dynamic_attributes", "fm_ilu_mar_t6")
          fm_ilu_t7 = definition.get_attribute("dynamic_attributes", "fm_ilu_mar_t7")
          fm_ilu_t8 = definition.get_attribute("dynamic_attributes", "fm_ilu_mar_t8")

          if fm_ilu || fm_ilu_t1 || fm_ilu_t2 || fm_ilu_t3 || fm_ilu_t4 || fm_ilu_t5 || fm_ilu_t6 || fm_ilu_t7 || fm_ilu_t8
            marcenaria_components << {
              fm_ilu: fm_ilu,
              fm_ilu_t1: fm_ilu_t1,
              fm_ilu_t2: fm_ilu_t2,
              fm_ilu_t3: fm_ilu_t3,
              fm_ilu_t4: fm_ilu_t4,
              fm_ilu_t5: fm_ilu_t5,
              fm_ilu_t6: fm_ilu_t6,
              fm_ilu_t7: fm_ilu_t7,
              fm_ilu_t8: fm_ilu_t8
            }
          end

          marcenaria_components.concat(buscar_componentes_marcenaria(entity.definition.entities, nivel + 1))
        elsif entity.is_a?(Sketchup::Group)
          marcenaria_components.concat(buscar_componentes_marcenaria(entity.entities, nivel + 1))
        end
      end

      marcenaria_components
    end

    def self.export_report
      require 'csv'
    
      # Obter o modelo ativo
      model = Sketchup.active_model
      iluminacao_components = buscar_componentes(model.entities)
    
      if iluminacao_components.empty?
        UI.messagebox("Nenhum componente com atributos relevantes foi encontrado.".dup.force_encoding("UTF-8"))
        return
      end
    
      model_path = model.path
      if model_path.empty?
        UI.messagebox("O modelo precisa ser salvo antes de exportar o relatório.".dup.force_encoding("UTF-8"))
        return
      end
    
      directory = File.dirname(model_path)
      file_path = File.join(directory, 'Iluminação.csv').dup.force_encoding("UTF-8")
    
      # Perguntar ao usuário se deseja converter para maiúsculas
      resposta = UI.messagebox("Deseja converter os valores para maiúsculas?", MB_YESNO, "Exportar Relatório")
      converter_maiusculo = (resposta == IDYES)
    
      # Contar componentes iguais
      componentes_contados = Hash.new(0)
      iluminacao_components.each do |component|
        key = [
          component[:fm_ilu],
          component[:fm_ilu_t1],
          component[:fm_ilu_t2],
          component[:fm_ilu_t3],
          component[:fm_ilu_t4],
          component[:fm_ilu_t5],
          component[:fm_ilu_t6],
          component[:fm_ilu_t7],
          component[:fm_ilu_t8]
        ]
        key = key.map { |k| k.nil? ? nil : k.to_s.dup.force_encoding("UTF-8") }
        key = key.map { |v| converter_maiusculo ? v.upcase : v } unless key.nil?
        componentes_contados[key] += 1
      end
    
      begin
        CSV.open(file_path, 'w') do |csv|
          csv << ['LEGENDA', 'LUMINÁRIA', 'MARCA', 'LÂMPADA', 'MARCA', 'TEMPERATURA', 'IRC', 'LUMENS', 'DÍMER', 'QUANTIDADE']
            .map { |v| converter_maiusculo ? v.upcase : v }
          componentes_contados.each do |key, count|
            csv << (key + [count]).map { |v| v.nil? ? "" : v }
          end
        end
        UI.messagebox("Relatório exportado com sucesso: #{file_path}".dup.force_encoding("UTF-8"))
      rescue => error
        UI.messagebox("Erro ao exportar o relatório: #{error.message}".dup.force_encoding("UTF-8"))
      end
    end

    def self.export_report_marcenaria
      require 'csv'
    
      # Obter o modelo ativo
      model = Sketchup.active_model
      marcenaria_components = buscar_componentes_marcenaria(model.entities)
    
      if marcenaria_components.empty?
        UI.messagebox("Nenhum componente com atributos relevantes foi encontrado.".dup.force_encoding("UTF-8"))
        return
      end
    
      model_path = model.path
      if model_path.empty?
        UI.messagebox("O modelo precisa ser salvo antes de exportar o relatório.".dup.force_encoding("UTF-8"))
        return
      end
    
      directory = File.dirname(model_path)
      file_path = File.join(directory, 'Marcenaria.csv').dup.force_encoding("UTF-8")
    
      # Perguntar ao usuário se deseja converter para maiúsculas
      resposta = UI.messagebox("Deseja converter os valores para maiúsculas?", MB_YESNO, "Exportar Relatório")
      converter_maiusculo = (resposta == IDYES)
    
      # Contar componentes iguais
      componentes_contados = Hash.new(0)
      marcenaria_components.each do |component|
        key = [
          component[:fm_ilu],
          component[:fm_ilu_t1],
          component[:fm_ilu_t2],
          component[:fm_ilu_t3],
          component[:fm_ilu_t4],
          component[:fm_ilu_t5],
          component[:fm_ilu_t6],
          component[:fm_ilu_t7],
          component[:fm_ilu_t8]
        ]
        key = key.map { |k| k.nil? ? nil : k.to_s.dup.force_encoding("UTF-8") }
        key = key.map { |v| converter_maiusculo ? v.upcase : v } unless key.nil?
        componentes_contados[key] += 1
      end
    
      begin
        CSV.open(file_path, 'w') do |csv|
          csv << ['LEGENDA', 'LUMINÁRIA', 'MARCA', 'LÂMPADA', 'MARCA', 'TEMPERATURA', 'IRC', 'LUMENS', 'DÍMER', 'QUANTIDADE']
            .map { |v| converter_maiusculo ? v.upcase : v }
          componentes_contados.each do |key, count|
            csv << (key + [count]).map { |v| v.nil? ? "" : v }
          end
        end
        UI.messagebox("Relatório exportado com sucesso: #{file_path}".dup.force_encoding("UTF-8"))
      rescue => error
        UI.messagebox("Erro ao exportar o relatório: #{error.message}".dup.force_encoding("UTF-8"))
      end
    end

    # Função para importar um bloco
    def self.import_block(block_name, blocks_dir)
      block_name = block_name.dup.force_encoding('UTF-8')
      blocks_dir = blocks_dir.dup.force_encoding('UTF-8')

      subfolder, block_file = File.split(block_name)
      subfolder = subfolder.dup.force_encoding('UTF-8')
      block_file = block_file.dup.force_encoding('UTF-8')

      block_path = File.join(blocks_dir, subfolder, "#{block_file}.skp").dup.force_encoding('UTF-8')

      if File.exist?(block_path)
        model = Sketchup.active_model
        definitions = model.definitions

        # Carregar o bloco, permitindo modelos de versões mais novas
        definition = definitions.load(block_path, allow_newer: true)

        # Deixar o bloco "pendente" no cursor
        model.place_component(definition) if definition.is_a?(Sketchup::ComponentDefinition)
      else
        UI.messagebox("Bloco não encontrado: #{block_path}".dup.force_encoding("UTF-8"))
      end
    end

  end # FM_PontosIluminacao

  # Criar a barra de ferramentas flutuante
  toolbar = UI::Toolbar.new('FM - Blocos Iluminação'.dup.force_encoding('UTF-8'))

  # Adicionar botão da extensão
  cmd_ilumi = UI::Command.new('Pontos de Iluminação'.dup.force_encoding('UTF-8')) {
    FM_PontosIluminacao.open_blocks_dialog
  }

  icon_ilumi = File.join(__dir__.dup.force_encoding('UTF-8'), 'icons', 'ilumi.png'.dup.force_encoding('UTF-8'))
  if File.exist?(icon_ilumi)
    cmd_ilumi.small_icon = icon_ilumi
    cmd_ilumi.large_icon = icon_ilumi
  else
    UI.messagebox("Erro: O ícone da extensão não foi encontrado:\n#{icon_ilumi}".dup.force_encoding("UTF-8"))
  end

  cmd_ilumi.tooltip = 'Pontos de Iluminação'.dup.force_encoding('UTF-8')
  cmd_ilumi.status_bar_text = 'Blocos Dinâmicos de Pontos de Iluminação.'.dup.force_encoding('UTF-8')
  toolbar.add_item(cmd_ilumi)

  # Mostrar a barra de ferramentas flutuante
  toolbar.show

end # FM_BlocosDinamicos
