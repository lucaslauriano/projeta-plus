# encoding: UTF-8
require "sketchup.rb"

# [OPCIONAL] Forçar o uso de UTF-8 como padrão:
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

module FM_BlocosDinamicos
  module FM_PontosEletrica

    # ======== 1) MÉTODO PARA ABRIR A JANELA HTML  ===================
    def self.open_blocks_dialog
      puts ">> Iniciando open_blocks_dialog (Elétrica)..."

      # 1.1) Caminho para a pasta de blocos
      #     Usamos File.join com __dir__, assumindo que este .rb está em
      #     \Plugins\FM_PontosEletrica\
      blocks_dir = File.join(__dir__, "blocos")

      unless File.directory?(blocks_dir)
        UI.messagebox("Erro: O diretório de blocos não foi encontrado:\n#{blocks_dir}")
        return
      end

      # 1.2) Obter as subpastas (excluindo . e ..) e ordenar, deixando "Geral" em primeiro se quiser
      begin
        subfolders = Dir.entries(blocks_dir)
                        .select { |entry|
                          File.directory?(File.join(blocks_dir, entry)) &&
                          entry != '.' && entry != '..'
                        }
                        .sort_by { |entry| entry == "Geral" ? "" : entry }
      rescue => e
        UI.messagebox("Erro ao acessar o diretório de blocos:\n#{e.message}")
        return
      end

      # 1.3) Montar a parte dinâmica do HTML com botões para cada .skp
      structure_html = ""

      subfolders.each_with_index do |subfolder, index|
        subfolder_path = File.join(blocks_dir, subfolder)

        next unless File.directory?(subfolder_path)

        # Pegar apenas arquivos .skp
        begin
          skp_files = Dir.entries(subfolder_path).select { |file|
            File.extname(file).downcase == ".skp"
          }
        rescue => e
          UI.messagebox("Erro lendo arquivos da subpasta '#{subfolder}':\n#{e.message}")
          next
        end

        # Se não houver nenhum .skp, pula
        next if skp_files.empty?

        # ID para colapsar
        section_id = "section-#{index}"

        structure_html << <<-HTML
          <h2 onclick="toggleVisibility('#{section_id}')">#{subfolder}</h2>
          <div id="#{section_id}" class="hidden">
        HTML

        skp_files.each do |skp_file|
          block_name = File.basename(skp_file, ".skp")
          structure_html << <<-HTML
            <button onclick="sketchup.import_block('#{subfolder}/#{block_name}')">#{block_name}</button>
          HTML
        end

        structure_html << "</div>"
      end

      # Caso não haja subpastas ou .skp
      if structure_html.empty?
        structure_html = %(
          <p style="color:red;">
            Nenhuma subpasta ou arquivo .skp foi encontrado em:
            <br><strong>#{blocks_dir}</strong>
          </p>
        )
      end

      # 1.4) HTML completo
      html = <<-HTML
      <!DOCTYPE html>
      <html lang="pt-BR">
      <head>
        <meta charset="UTF-8">
        <title>Pontos Elétricos</title>
        <style>
          body {
            font-family: "Century Gothic", sans-serif;
            margin: 10px;
            text-align: center;
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
            var section = document.getElementById(id);
            if (section) section.classList.toggle('hidden');
          }
        </script>
      </head>
      <body>
        <h1>Pontos Elétricos</h1>
        <p>Clique no título para expandir e nos botões para importar blocos .skp.</p>

        #{structure_html}

        <button onclick="sketchup.open_blocks_folder()" style="margin-top: 20px;">
          Abrir Pasta de Blocos
        </button>

        <footer>
          <p>Desenvolvido por 
            <a href="https://francielimadeira.com" target="_blank" 
               style="text-decoration: none; color: #666; font-weight: bold;">
              Francieli Madeira
            </a> 
            © 2024. Todos os direitos reservados.
          </p>
        </footer>
      </body>
      </html>
      HTML

      # 1.5) Criar o HtmlDialog
      dialog = UI::HtmlDialog.new(
        dialog_title:     "Blocos Dinâmicos - Elétrica",
        preferences_key:  "com.sketchup.quick_blocks_e",
        scrollable:       true,
        resizable:        false,
        width:            300,
        height:           600,
        style:            UI::HtmlDialog::STYLE_DIALOG
      )

      # 1.6) Definir o HTML
      dialog.set_html(html)

      # 1.7) Callbacks para comunicação JS <-> Ruby
      dialog.add_action_callback("import_block") do |_ctx, block_param|
        import_block(block_param, blocks_dir)
      end

      dialog.add_action_callback("open_blocks_folder") do |_ctx|
        if File.directory?(blocks_dir)
          UI.openURL("file://#{blocks_dir}")
        else
          UI.messagebox("Erro: O diretório de blocos não foi encontrado:\n#{blocks_dir}")
        end
      end

      dialog.show
    end

    # ======== 2) IMPORTAR BLOCO .SKP  =============================
    def self.import_block(block_name, blocks_dir)
      subfolder, block_file = File.split(block_name)
      block_path = File.join(blocks_dir, subfolder, "#{block_file}.skp")

      unless File.exist?(block_path)
        UI.messagebox("Bloco não encontrado:\n#{block_path}")
        return
      end

      model       = Sketchup.active_model
      definitions = model.definitions

      begin
        definition = definitions.load(block_path, allow_newer: true)
      rescue => e
        UI.messagebox("Erro ao carregar o bloco:\n#{e.message}")
        return
      end

      if definition.is_a?(Sketchup::ComponentDefinition)
        model.place_component(definition)
      else
        UI.messagebox("O arquivo não é um componente válido:\n#{block_path}")
      end
    end


  end # FM_PontosEletrica

  # ======== 3) CRIAR A TOOLBAR =============================
  if !file_loaded?(__FILE__)
    toolbar = UI::Toolbar.new("FM - Blocos Elétricos")

    cmd_eletric = UI::Command.new("Pontos Elétricos") {
      FM_PontosEletrica.open_blocks_dialog
    }

    # Ícone do botão: "eletric.png" deve existir em "...\FM_PontosEletrica\icons\eletric.png"
    icon_eletric = File.join(__dir__, "icons", "eletric.png")
    if File.exist?(icon_eletric)
      cmd_eletric.small_icon = icon_eletric
      cmd_eletric.large_icon = icon_eletric
    else
      # Se o ícone não for encontrado, avise ou ignore
      UI.messagebox("Ícone não encontrado em: #{icon_eletric}")
    end

    cmd_eletric.tooltip         = "Pontos Elétricos"
    cmd_eletric.status_bar_text = "Blocos Dinâmicos de Pontos Elétricos."
    toolbar.add_item(cmd_eletric)
    toolbar.show

    file_loaded(__FILE__)
  end

end # FM_BlocosDinamicos
