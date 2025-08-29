# coding: utf-8
require 'sketchup.rb'
require 'csv'
require 'json'

module FM_Extensions
  module Exportar
    PREFIX = "pro_mob_".freeze

    

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

    # Coleta todos os componentes/grupos com atributo pro_mob_ até 10 níveis
    def self.collect_all_pro_mob_instances(entities, arr, level=0)
      return if level > 10
      entities.each do |e|
        comp = case e
               when Sketchup::Group then e.to_component
               when Sketchup::ComponentInstance then e
               else next
               end

        tipo = comp.get_attribute("dynamic_attributes", "#{PREFIX}tipo", "").to_s.strip
        arr << comp unless tipo.empty?

        collect_all_pro_mob_instances(comp.definition.entities, arr, level+1)
      end
    end

    # Procura componente ou grupo por ID recursivamente
    def self.find_component_by_id(entities, target_id, level=0)
      return nil if level > 10
      entities.each do |e|
        next unless e.is_a?(Sketchup::ComponentInstance) || e.is_a?(Sketchup::Group)
        comp = e.is_a?(Sketchup::Group) ? e.to_component : e
        return comp if comp.entityID == target_id
        found = find_component_by_id(comp.definition.entities, target_id, level+1)
        return found if found
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
        tipo = inst.get_attribute("dynamic_attributes", "#{PREFIX}tipo", "").to_s.strip
        next if tipo.empty? || tipo != categoria

        key = [
          inst.get_attribute("dynamic_attributes", "#{PREFIX}nome", ""),
          inst.get_attribute("dynamic_attributes", "#{PREFIX}cor", ""),
          inst.get_attribute("dynamic_attributes", "#{PREFIX}marca", ""),
          tipo,
          inst.get_attribute("dynamic_attributes", "#{PREFIX}dimensao", ""),
          inst.get_attribute("dynamic_attributes", "#{PREFIX}ambiente", ""),
          inst.get_attribute("dynamic_attributes", "#{PREFIX}observacoes", ""),
          inst.get_attribute("dynamic_attributes", "#{PREFIX}link", "")
        ]

        dados[key][:qtd] += 1
        dados[key][:ids] << inst.entityID
      end

      if dados.empty?
        "<tr><td colspan='11' style='color:red;'>Nenhum dado encontrado.</td></tr>"
      else
        index = 1
        dados.map do |key, info|
          nome, cor, marca, tipo, dimensao, ambiente, obs, link = key
          id = info[:ids].first # usa o primeiro ID só como referência
          html = "<tr id='linha-#{id}'>
            <td class='seq'>#{index}</td>
            <td>#{nome}</td>
            <td>#{cor}</td>
            <td>#{marca}</td>
            <td>#{tipo}</td>
            <td>#{dimensao}</td>
            <td>#{ambiente}</td>
            <td>#{link}</td>
            <td>#{obs}</td>
            <td>#{info[:qtd]}</td>
            <td><button onclick='isolateItem(#{id})'>Isolar</button></td>
            <td><button onclick='deleteItem(#{id})'>Excluir</button></td>
          </tr>"
          index += 1
          html
        end.join
      end
    end

    def self.format_number(num)
      arred = num.round(2)
      if arred.to_i == arred
        arred.to_i.to_s
      else
        sprintf('%.2f', arred).gsub('.', ',').sub(/,?0+$/, '')
      end
    end


    # ---------- Edição de atributos ----------
    def self.edit_component_attributes(comp)
      bounds = comp.bounds
      largura = format_number(bounds.width.to_f * 2.54)
      altura  = format_number(bounds.height.to_f * 2.54)
      profund = format_number(bounds.depth.to_f * 2.54)

      

      dimensao = "#{largura} x #{altura} x #{profund} cm"



      nome     = comp.get_attribute("dynamic_attributes", "#{PREFIX}nome", "")
      cor      = comp.get_attribute("dynamic_attributes", "#{PREFIX}cor", "")
      marca    = comp.get_attribute("dynamic_attributes", "#{PREFIX}marca", "")
      tipo     = comp.get_attribute("dynamic_attributes", "#{PREFIX}tipo", "")
      obs      = comp.get_attribute("dynamic_attributes", "#{PREFIX}observacoes", "")
      ambiente = comp.get_attribute("dynamic_attributes", "#{PREFIX}ambiente", "")
      link = comp.get_attribute("dynamic_attributes", "#{PREFIX}link", "")



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
              <option value="Louças" #{'selected' if tipo=="Louças"}>Louças</option>
              <option value="Metais" #{'selected' if tipo=="Metais"}>Metais</option>
              <option value="Acessórios" #{'selected' if tipo=="Acessórios"}>Acessórios</option>
              <option value="Decoração" #{'selected' if tipo=="Decoração"}>Decoração</option>
            </select>
          </label>
          <label>Dimensão (LxAxP):</label>
          <input id="dimensao" type="text" value="#{dimensao}" readonly>
          <label>Ambiente: <input id="ambiente" type="text" value="#{ambiente}"></label>
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
                ambiente: document.getElementById("ambiente").value,
                observacoes: document.getElementById("observacoes").value,
                link: document.getElementById("link").value
              };
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
        dados.each { |k,v| comp.set_attribute("dynamic_attributes", "#{PREFIX}#{k}", v) }
        comp.set_attribute("dynamic_attributes", "#{PREFIX}dimensao", dimensao)
        new_name = "#{dados['nome']} - #{dados['marca']} - #{dimensao}"
        comp.definition.name = new_name
        UI.messagebox("Atributos atualizados e definição renomeada para:\n#{new_name}")
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
        tipo = inst.get_attribute("dynamic_attributes", "#{PREFIX}tipo", "").to_s.strip
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
        <<-HTML
        <div class="categoria">
          <h2>#{tipo}</h2>
          <table id="table-#{tipo.gsub(' ', '-')}">
            <thead>
              <tr>
              <th>#</th>
              <th>Nome</th><th>Cor</th><th>Marca</th><th>Tipo</th>
              <th>Dimensão</th><th>Ambiente</th><th>Link</th><th>Observações</th>
              <th>Qtd</th><th>Isolar</th><th>Excluir</th>
              </tr>
            </thead>
            <tbody></tbody>
          </table>
          <button onclick="updateCategory('#{tipo}')">Atualizar Tabela</button>
          <button onclick="exportCategory('#{tipo}')">Exportar CSV</button>
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
            body{font-family:'Century Gothic',sans-serif;margin:10px;text-align:center;background-color:#f6f6f6;}
            table{font-size:12px;width:100%;border-collapse:collapse;margin:10px 0;background:#fff;}
            th,td{border:1px solid #ddd;padding:8px;text-align:left;}
            th{background-color:#eee;}
            button{margin:2px;padding:4px 8px;font-size:12px;cursor:pointer;border-radius:8px;background:#dee9b6;border:0;}
            button:hover{background:#becc8a;}
          </style>
        </head>
        <body>
          <h1>Relatórios de Componentes por Tipo</h1>
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

      dialog.add_action_callback("update_category") do |_ctx, categoria|
        updated_html = update_category_data(model, categoria)
        script = "document.querySelector('#table-"+categoria.gsub(' ','-')+" tbody').innerHTML = `#{updated_html}`;"
        dialog.execute_script(script)
      end

      dialog.add_action_callback("export_category") do |_ctx, categoria|
          dados = Hash.new { |h, k| h[k] = { qtd: 0 } }

          instances = []
          collect_all_pro_mob_instances(model.entities, instances)
          instances.each do |inst|
            tipo = inst.get_attribute("dynamic_attributes", "#{PREFIX}tipo", "").to_s.strip
            next if tipo.empty? || tipo != categoria

            key = [
              inst.get_attribute("dynamic_attributes", "#{PREFIX}nome", ""),
              inst.get_attribute("dynamic_attributes", "#{PREFIX}cor", ""),
              inst.get_attribute("dynamic_attributes", "#{PREFIX}marca", ""),
              tipo,
              inst.get_attribute("dynamic_attributes", "#{PREFIX}dimensao", ""),
              inst.get_attribute("dynamic_attributes", "#{PREFIX}ambiente", ""),
              inst.get_attribute("dynamic_attributes", "#{PREFIX}observacoes", ""),
              inst.get_attribute("dynamic_attributes", "#{PREFIX}link", "")
            ]

            dados[key][:qtd] += 1
          end

          if dados.empty?
            UI.messagebox("Nenhum dado para exportar em #{categoria}.")
            next
          end

          file_path = File.join(File.dirname(model.path), "#{categoria}.csv")
          CSV.open(file_path, "w") do |csv|
          csv << ["Código","Nome","Cor","Marca","Tipo","Dimensão","Ambiente","Observações","Link","Qtd"]
          dados.each_with_index do |(key, info), i|
            nome, cor, marca, tipo, dimensao, ambiente, obs, link = key
            codigo = i + 1   # número sequencial simples
            csv << [codigo, nome, cor, marca, tipo, dimensao, ambiente, obs, link, info[:qtd]]
          end
        end
      end



      dialog.add_action_callback("isolate_item") do |_ctx, id|
        model = Sketchup.active_model
        target = find_component_by_id(model.entities, id.to_i)
        next unless target

        FM_Extensions::Exportar.isolate_item(target)
      end



      dialog.show
    end

  end # module Exportar

  # ---------- Toolbar ----------
  toolbar = UI::Toolbar.new('FM - Mobiliário')

  cmd_atributos = UI::Command.new('Editar Atributos') {
    selection = Sketchup.active_model.selection
    if selection.empty?
      UI.messagebox("Selecione um componente ou grupo.")
    else
      ent = selection.first
      comp = ent.is_a?(Sketchup::Group) ? ent.to_component : ent
      FM_Extensions::Exportar.edit_component_attributes(comp)
    end
  }
  icon_attr = File.join(__dir__, 'icones', 'itemmob.png')
  cmd_atributos.small_icon = cmd_atributos.large_icon = File.exist?(icon_attr) ? icon_attr : nil
  cmd_atributos.tooltip = "Editar Atributos e Renomear"
  toolbar.add_item(cmd_atributos)

  cmd_exportar = UI::Command.new('Exportar Dados') { FM_Extensions::Exportar.open_export_dialog }
  icon_exp = File.join(__dir__, 'icones', 'exporte.png')
  cmd_exportar.small_icon = cmd_exportar.large_icon = File.exist?(icon_exp) ? icon_exp : nil
  cmd_exportar.tooltip = "Exportar Relatórios"
  toolbar.add_item(cmd_exportar)

  toolbar.show

end # module FM_Extensions
