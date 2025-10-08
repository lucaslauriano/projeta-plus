# encoding: UTF-8
Encoding.default_external = Encoding::UTF_8
Encoding.default_internal = Encoding::UTF_8

require 'sketchup'
require 'csv'

module FM_Esquadrias
  #TODO: Levar para modulo Anotação
  module Anotacao_esquadria

      def self.criarcodigo
        model = Sketchup.active_model
        selection = model.selection.to_a

        if selection.empty?
          UI.messagebox("Nenhum componente selecionado.")
          return
        end

        componentes_validos = selection.select do |e|
          e.is_a?(Sketchup::ComponentInstance) && e.attribute_dictionaries["dynamic_attributes"]
        end

        if componentes_validos.empty?
          UI.messagebox("Nenhum dos componentes selecionados tem atributos dinâmicos.")
          return
        end

        # Leitura de preferências salvas
        tipo_default       = Sketchup.read_default("AnotacaoEsquadrias", "tipo", "Porta")
        escala_default     = Sketchup.read_default("AnotacaoEsquadrias", "escala", "25")
        posicao_default    = Sketchup.read_default("AnotacaoEsquadrias", "posicao", "Cima/Esquerda")
        altura_default     = Sketchup.read_default("AnotacaoEsquadrias", "altura", "145")
        nivel_default      = Sketchup.read_default("AnotacaoEsquadrias", "nivel", "0")
        orientacao_default = Sketchup.read_default("AnotacaoEsquadrias", "orientacao", "Horizontal")

        prompts = [
          "Tipo:",
          "Escala do Texto:",
          "Posicionamento:",
          "Altura Anotação (cm):",
          "Nível Piso (cm):",
          "Orientação do Texto:"
        ]

        defaults = [
          tipo_default,
          escala_default,
          posicao_default,
          altura_default,
          nivel_default,
          orientacao_default
        ]

        lists = [
          "Porta|Janela",
          "",
          "Cima/Esquerda|Abaixo/Esquerda",
          "",
          "",
          "Horizontal|Vertical"
        ]

        input = UI.inputbox(prompts, defaults, lists, "Dados para Marcação de Esquadrias")
        return unless input

        tipo, escala_str, posicao, alt, nivel, orientacao = input.map(&:strip)
        scale = escala_str.to_f

        # Salvar preferências
        Sketchup.write_default("AnotacaoEsquadrias", "tipo", tipo)
        Sketchup.write_default("AnotacaoEsquadrias", "escala", escala_str)
        Sketchup.write_default("AnotacaoEsquadrias", "posicao", posicao)
        Sketchup.write_default("AnotacaoEsquadrias", "altura", alt)
        Sketchup.write_default("AnotacaoEsquadrias", "nivel", nivel)
        Sketchup.write_default("AnotacaoEsquadrias", "orientacao", orientacao)

        offset_distancia = 15.cm * (scale / 25.0)

        offset_vector = if orientacao.downcase == "vertical"
          Geom::Vector3d.new(offset_distancia, 0, 0) # desloca no eixo X
        else
          posicao.downcase == "cima/esquerda" ? 
            Geom::Vector3d.new(0, offset_distancia, 0) :  # eixo Y positivo
            Geom::Vector3d.new(0, -offset_distancia, 0)   # eixo Y negativo
        end

        model.start_operation("Criar Anotações", true)

        componentes_validos.each do |comp|
          dict = comp.attribute_dictionaries["dynamic_attributes"]

          codigo     = dict["pro_esq_codigo"]
          largura    = dict["pro_esq_largura"]
          altura     = dict["pro_esq_altura"]
          peitoril   = dict["pro_esq_peitoril"]

          next unless codigo

          largura_val  = largura.to_s.strip.empty?  ? 100 : largura.to_f.round
          altura_val   = altura.to_s.strip.empty?   ? 200 : altura.to_f.round
          peitoril_val = peitoril.to_s.strip.empty? ? nil : peitoril.to_f.round

          texto = if tipo.downcase == "janela" && peitoril_val
                    "#{codigo} - #{largura_val} X #{altura_val} / #{peitoril_val}"
                  else
                    "#{codigo} - #{largura_val} X #{altura_val}"
                  end

          centro_modelo = comp.bounds.center
          world_pos = centro_modelo + offset_vector
          world_pos.z = (alt.to_f + nivel.to_f).cm

          group     = model.entities.add_group
          entities  = group.entities
          height_pt = 0.3.cm * scale

          text = entities.add_3d_text(
            texto,
            TextAlignCenter,
            "Century Gothic",
            true,
            false,
            height_pt,
            0
          )

          # Rotação se necessário
          if orientacao.downcase == "vertical"
            center = group.bounds.center
            rot = Geom::Transformation.rotation(center, [0, 0, 1], 90.degrees)
            group.transform!(rot)
          end

          centro_texto = group.bounds.center
          move = Geom::Transformation.translation(world_pos - centro_texto)
          group.transform!(move)

          # Estilo visual
          material = model.materials["Black"] || model.materials.add("Black")
          material.color = "black"
          group.material = material

          layer = model.layers["-2D-LEGENDA ESQUADRIA"] || model.layers.add("-2D-LEGENDA ESQUADRIA")
          group.layer = layer

          # Salva código
          comp.set_attribute("dynamic_attributes", "pro_codigo", codigo)
        end

        model.commit_operation
        UI.messagebox("Anotações criadas para #{componentes_validos.size} componentes.")
      end


  end
  #TODO: Levar para modulo Relatórios
  module Export_esquadrias

    @@dados_cache = nil
    @@modo_metros = false

    def self.coletar_dados
      model = Sketchup.active_model
      dados = []

      model.definitions.each do |definition|
        definition.instances.each do |inst|
          ad = inst.attribute_dictionaries
          next unless ad && ad["dynamic_attributes"]
          dict = ad["dynamic_attributes"]

          codigo     = dict["pro_esq_codigo"]
          ambiente   = dict["pro_esq_ambiente"]
          largura    = dict["pro_esq_largura"]
          altura     = dict["pro_esq_altura"]
          peitoril   = dict["pro_esq_peitoril"]
          descricao  = dict["pro_esq_descricao"]
          acabamento = dict["pro_esq_acabamento"]

          next unless codigo && altura && acabamento

          dados << {
            codigo: codigo.to_s,
            ambiente: ambiente.to_s,
            largura: largura.to_s,
            altura: altura.to_s,
            peitoril: peitoril.to_s,
            descricao: descricao.to_s,
            acabamento: acabamento.to_s
          }
        end
      end

      agrupados = {}
      dados.each do |item|
        chave = [item[:codigo], item[:largura], item[:altura], item[:peitoril], item[:descricao], item[:acabamento]].join("|")
        agrupados[chave] ||= item.merge({ quantidade: 0, ambientes: [] })
        agrupados[chave][:quantidade] += 1
        agrupados[chave][:ambientes] << item[:ambiente] unless item[:ambiente].to_s.strip.empty?
      end

      @@dados_cache = agrupados.values.map do |d|
        d[:ambiente] = d[:ambientes].uniq.join(", ")
        d.delete(:ambientes)
        d
      end.sort_by { |item| item[:codigo].to_s.upcase }

    end

    def self.salvar_dados_no_modelo(dados)
      @@dados_cache = dados
    end

    def self.carregar_dados_salvos
      @@dados_cache
    end

    def self.converter_para_maiusculas
      dados = carregar_dados_salvos
      return unless dados

      dados_maiusculos = dados.map do |d|
        d.transform_values { |v| v.is_a?(String) ? v.upcase : v }
      end

      salvar_dados_no_modelo(dados_maiusculos)
      dados_maiusculos
    end

    def self.converter_dimensoes
      dados = carregar_dados_salvos
      return unless dados

      @@modo_metros = !@@modo_metros

      dados_convertidos = dados.map do |d|
        novo = d.dup
        [:largura, :altura, :peitoril].each do |campo|
          valor = d[campo]
          next if valor.to_s.strip.empty?

          if @@modo_metros
            novo[campo] = format('%.2f', valor.to_f / 100.0)
          else
            novo[campo] = (valor.to_f * 100.0).round.to_s
          end
        end
        novo
      end

      salvar_dados_no_modelo(dados_convertidos)
      dados_convertidos
    end

    def self.gerar_tabela(dados)
      unidade = @@modo_metros ? "(m)" : "(cm)"

      linhas = dados.map do |d|
        "<tr>" +
          "<td>#{d[:codigo]}</td>" +
          "<td>#{d[:ambiente]}</td>" +
          "<td>#{d[:largura]}</td>" +
          "<td>#{d[:altura]}</td>" +
          "<td>#{d[:peitoril]}</td>" +
          "<td>#{d[:descricao]}</td>" +
          "<td>#{d[:acabamento]}</td>" +
          "<td>#{d[:quantidade]}</td>" +
        "</tr>"
      end.join

      <<-HTML
        <table border="1" style="border-collapse: collapse; width: 100%; text-align: center;" id="tabela">
          <thead>
            <tr>
              <th>CÓDIGO</th>
              <th>AMBIENTE</th>
              <th>LARGURA #{unidade}</th>
              <th>ALTURA #{unidade}</th>
              <th>PEITORIL #{unidade}</th>
              <th>DESCRIÇÃO</th>
              <th>ACABAMENTO</th>
              <th>QUANTIDADE</th>
            </tr>
          </thead>
          <tbody>
            #{linhas}
          </tbody>
        </table>
      HTML
    end

    def self.exportar_csv(dados)
      model = Sketchup.active_model
      model_path = model.path
      return UI.messagebox("⚠️ Salve o arquivo antes de exportar.") if model_path.empty?

      dir = File.dirname(model_path)
      file = File.join(dir, "Esquadrias.csv")

      begin
        CSV.open(file, "w:UTF-8") do |csv|
          csv << ["Código", "Ambiente", "Largura", "Altura", "Peitoril", "Descrição", "Acabamento", "Quantidade"]
          dados.each do |d|
            csv << [d[:codigo], d[:ambiente], d[:largura], d[:altura], d[:peitoril], d[:descricao], d[:acabamento], d[:quantidade]]
          end
        end
        UI.messagebox("✅ Arquivo exportado com sucesso!\n\n#{file}")
      rescue => e
        UI.messagebox("Erro ao exportar CSV: #{e.message}")
      end
    end

    def self.mostrar_janela
      coletar_dados
      dados = carregar_dados_salvos
      html = <<-HTML
        <!DOCTYPE html>
        <html lang="pt">
        <head>
          <meta charset="UTF-8">
          <title>Relatório de Esquadrias</title>
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
              gap: 10px;
              margin-bottom: 10px;
            }
            table {
              width: auto;
              border-collapse: collapse;
              margin: auto;
              font-size: 12px;
            }
            th, td {
              border: 1px solid #ddd;
              padding: 5px;
              text-align: center;
              white-space: nowrap;
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
          </style>
        </head>
        <body>
          <h1>Relatório de Esquadrias</h1>
          <div class="button-container">
            <button onclick="sketchup.atualizar()">Atualizar</button>
            <button onclick="sketchup.exportar()">Exportar CSV</button>
            <button onclick="sketchup.maiusculas()">Converter para MAIÚSCULAS</button>
            <button id="botao-converter" onclick="sketchup.converter_dimensoes()">Converter para METROS</button>
          </div>
          <div id="tabela">
            #{gerar_tabela(dados)}
          </div>
        </body>
        <script>
          function atualizarTabela(html) {
            document.getElementById("tabela").innerHTML = html;
          }
          function atualizarBotaoConversao(texto) {
            document.getElementById("botao-converter").innerText = texto;
          }
        </script>
        </html>
      HTML

      dlg = UI::HtmlDialog.new(
        dialog_title: "Relatório de Esquadrias",
        width: 1200,
        height: 700,
        scrollable: true,
        resizable: true,
        style: UI::HtmlDialog::STYLE_DIALOG
      )

      dlg.set_html(html)
      dlg.add_action_callback("atualizar") {
        coletar_dados
        dlg.execute_script("atualizarTabela(#{gerar_tabela(@@dados_cache).inspect})")
      }
      dlg.add_action_callback("exportar") {
        exportar_csv(@@dados_cache)
      }
      dlg.add_action_callback("maiusculas") {
        dados = converter_para_maiusculas
        dlg.execute_script("atualizarTabela(#{gerar_tabela(dados).inspect})")
      }
      dlg.add_action_callback("converter_dimensoes") {
        dados = converter_dimensoes
        texto_botao = @@modo_metros ? "Converter para CENTÍMETROS" : "Converter para METROS"
        dlg.execute_script("atualizarTabela(#{gerar_tabela(dados).inspect})")
        dlg.execute_script("atualizarBotaoConversao('#{texto_botao}')")
      }

      dlg.show
    end

  end # module
  #TODO: Importar - mesma base light e techpoints
  module FM_BlocosEsquadrias

    # 1) Abrir a janela HTML
    def self.open_blocks_dialog
      puts ">> Iniciando open_blocks_dialog (Esquadrias)..."

      blocks_dir = File.join(__dir__, "blocos")
      unless File.directory?(blocks_dir)
        UI.messagebox("Erro: O diretório de blocos não foi encontrado:\n#{blocks_dir}")
        return
      end

      # Obtém as subpastas de blocos
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

      # Monta o HTML de botões
      structure_html = ""

      subfolders.each_with_index do |subfolder, index|
        subfolder_path = File.join(blocks_dir, subfolder)
        next unless File.directory?(subfolder_path)

        # Pega somente arquivos .skp
        begin
          skp_files = Dir.entries(subfolder_path).select { |file|
            File.extname(file).downcase == ".skp"
          }
        rescue => e
          UI.messagebox("Erro lendo arquivos da subpasta '#{subfolder}':\n#{e.message}")
          next
        end

        next if skp_files.empty?

        section_id = "section-#{index}"

        structure_html << <<-HTML
          <h2 onclick="toggleVisibility('#{section_id}')">#{subfolder}</h2>
          <div id="#{section_id}" class="hidden">
        HTML

        skp_files.each do |skp_file|
          block_name = File.basename(skp_file, ".skp")
          structure_html << <<-HTML
            <button onclick="sketchup.import_block('#{subfolder}/#{block_name}')">
              #{block_name}
            </button>
          HTML
        end

        structure_html << "</div>"
      end

      # Se não achar nada...
      if structure_html.empty?
        structure_html = %(
          <p style="color:red;">
            Nenhuma subpasta ou arquivo .skp foi encontrado em:
            <br><strong>#{blocks_dir}</strong>
          </p>
        )
      end

      # HTML completo
      html = <<-HTML
      <!DOCTYPE html>
      <html lang="pt-BR">
      <head>
        <meta charset="UTF-8">
        <title>Blocos de Esquadrias</title>
        <style>
          body {
            font-family: "Century Gothic", sans-serif;
            margin: 10px;
            text-align: center;
          }
          h1 {
            font-size: 18px;
            margin: 10px 5px;
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
        <h1>Blocos de Esquadrias</h1>
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

      # Cria o HtmlDialog
      dialog = UI::HtmlDialog.new(
        dialog_title:     "Blocos Dinâmicos - Esquadrias",
        preferences_key:  "com.sketchup.quick_blocks_es",
        scrollable:       true,
        resizable:        false,
        width:            300,
        height:           600,
        style:            UI::HtmlDialog::STYLE_DIALOG
      )

      dialog.set_html(html)

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

    # 2) Importar o bloco selecionado
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

  end # module FM_BlocosEsquadrias


    unless file_loaded?(__FILE__)

    toolbar = UI::Toolbar.new('FM - Esquadrias'.force_encoding('UTF-8'))

    # 1) Botão de Importação de Blocos
    cmd_importar_blocos = UI::Command.new('Importar Blocos') {
      FM_Esquadrias::FM_BlocosEsquadrias.open_blocks_dialog
    }
    icon_blocos = File.join(__dir__, "icones", "janela.png")
    if File.exist?(icon_blocos)
      cmd_importar_blocos.small_icon = icon_blocos
      cmd_importar_blocos.large_icon = icon_blocos
    end
    cmd_importar_blocos.tooltip = 'Importar Blocos de Esquadrias'
    cmd_importar_blocos.status_bar_text = 'Abre a janela para importar os blocos dinâmicos.'
    toolbar.add_item(cmd_importar_blocos)

    # 2) Botão de Anotação de Esquadrias
    cmd_anotacao = UI::Command.new('Anotação de Esquadrias') {
      FM_Esquadrias::Anotacao_esquadria.criarcodigo
    }
    icon_anotacao = File.join(__dir__, "icones", "esquadrias.png")
    if File.exist?(icon_anotacao)
      cmd_anotacao.small_icon = icon_anotacao
      cmd_anotacao.large_icon = icon_anotacao
    end
    cmd_anotacao.tooltip = 'Anotação de Esquadrias'
    cmd_anotacao.status_bar_text = 'Cria a anotação com código e dimensões da esquadria.'
    toolbar.add_item(cmd_anotacao)

    # 3) Botão de Exportação do Relatório
    cmd_export = UI::Command.new("Exportar Esquadrias") {
      FM_Esquadrias::Export_esquadrias.mostrar_janela
    }
    icon_export = File.join(__dir__, "icones", "exporte.png")
    if File.exist?(icon_export)
      cmd_export.small_icon = icon_export
      cmd_export.large_icon = icon_export
    end
    cmd_export.tooltip = "Exportar relatório de esquadrias"
    cmd_export.status_bar_text = "Abre a janela com a tabela de esquadrias e opção de exportar CSV."
    toolbar.add_item(cmd_export)

    toolbar.show

    file_loaded(__FILE__)
  end

end

