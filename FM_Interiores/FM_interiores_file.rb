# encoding: UTF-8

require_relative 'exportar_layout_customizado'
require_relative 'fm_exportar_imagens'

module FM
module ExtensaoSkp
    
    def self.estilos(nome_estilo)
        # Ajuste o caminho da pasta 'Estilos' caso precise.
        caminho_estilo = File.join(__dir__, 'Estilos', "#{nome_estilo}.style")
        return unless File.exist?(caminho_estilo)

        Sketchup.active_model.styles.add_style(caminho_estilo, true)
        rescue StandardError => e
        puts "Erro ao importar estilo '#{nome_estilo}': #{e.message}"
    end

    def self.configurar_sombras_e_atualizar_cena
        model = Sketchup.active_model
        sombras = model.shadow_info

        # Definir os valores desejados
        sombras["Light"] = 0
        sombras["Dark"] = 80
        sombras["UseSunForAllShading"] = true

        # Obter a cena atual
        cena = model.pages.selected_page
        if cena
            cena.update
        else
            UI.messagebox("Nenhuma cena selecionada.")
        end
    end
        
    def self.criar_camadas_padrao
        model = Sketchup.active_model
        manager = model.layers
        root_entities = model.entities

        grupos_camadas = {
            "2D" => [
            "-2D-ESQUADRIA", "-2D-MOBILIARIO", "-2D-LEGENDA ESQUADRIA",
            "-2D-LEGENDA CORTES", "-2D-XREF", "-2D-LEGENDA AMBIENTE", "-2D-PROJECOES","-2D-LEGENDA ESQUADRIA TRACEJADO",'-2D-SIMBOLOGIAS',"-2D-ETIQUETAS"
            ],
            "ZOOM" => [
            "-ZOOM-VISTA", "-ZOOM-MARGEM"
            ],
            "ARQUITETURA" => [
            "-ARQUITETURA-CHURRASQUEIRA", "-ARQUITETURA-ESCADA", "-ARQUITETURA-ESQUADRIA",
            "-ARQUITETURA-PAREDE", "-ARQUITETURA-PILAR", "-ARQUITETURA-PISO",
            "-ARQUITETURA-REVESTIMENTO", "-ARQUITETURA-VIGA", "-ARQUITETURA-GUARDA CORPO", "-ARQUITETURA-VIDRACARIA", '-ARQUITETURA-DRYWALL'
            ],
            "TERRENO" => [
            "-TERRENO-CALÇADAS", "-TERRENO-ESTRADA", "-TERRENO-GRAMA",
            "-TERRENO-MURO FRONTAL", "-TERRENO-MURO LATERAL", "-TERRENO-PISCINA",
            "-TERRENO-VIZINHOS",'-TERRENO-ALINHAMENTO'
            ],
            "BANHEIRO" => [
            "-BANHEIRO-BACIA", "-BANHEIRO-BOX", "-BANHEIRO-CHUVEIRO",
            "-BANHEIRO-METAIS", "-BANHEIRO-NICHO BOX", "-BANHEIRO-ACESSORIOS", "-BANHEIRO-RALO"
            ],
            "CIVIL" => [
            "-CIVIL-CONSTRUIR", "-CIVIL-DEMOLIR",'-CIVIL-DRYWALL'
            ],
            "LOCAL" => [
            "-LOCAL-INTERIOR", "-LOCAL-EXTERIOR"
            ],
            "COBERTURA" => [
            "-COBERTURA-TELHADO", "-COBERTURA-EQUIPAMENTOS", "-COBERTURA-CAIXA"
            ],
            "OUTRO" => [
            "-OUTRO-ARVORE","-OUTRO-RENDER", "-OUTRO-VEGETACAO"
            ],
            "ILUMINACAO" => [
            "-ILUMINACAO-HACHURA LUZ LINEAR", "-ILUMINACAO-LEGENDA", "-ILUMINACAO-LUMINARIA",
            "-ILUMINACAO-DECORATIVO MARCENARIA", "-ILUMINACAO-HACHURA LUZ MARCENARIA",
            "-ILUMINACAO-MARCENARIA", "-ILUMINACAO-SPOTLIGTH ENSCAPE", "-ILUMINACAO-SPOTLIGTH VRAY", "-ILUMINACAO-2D-CIRCUITOS", "-ILUMINACAO-2D-CIRCUITOS-LINHAS"
            ],
            "INTERIORES" => [
            "-INTERIORES-ADORNO", "-INTERIORES-CORTINA", "-INTERIORES-EXISTENTE",
            "-INTERIORES-MOBILIARIO", "-INTERIORES-QUADRO", "-INTERIORES-TAPETE",
            "-INTERIORES-ELETRO (AEREO)", "-INTERIORES-ELETRO (MARMORARIA)",
            "-INTERIORES-ELETRO (PISO)", "-INTERIORES-ELETRO (MARCENARIA)"
            ],
            "MARCENARIA" => [
            "-MARCENARIA-AEREO", "-MARCENARIA-GERAL", "-MARCENARIA-PORTA", "-MARCENARIA-SERRALHERIA"
            ],
            "MARMORARIA" => [
            "-MARMORARIA-BANCADA", "-MARMORARIA-CUBA E METAIS", "-MARMORARIA-SOLEIRAS"
            ],
            "TECNICO" => [
            "-TECNICO-PONTO AR-COND", "-TECNICO-PONTO ESPELHO", "-TECNICO-PONTO HIDRO",
            "-TECNICO-PONTO ILUMINACAO", "-TECNICO-PONTO REGISTRO", "-TECNICO-LEGENDA GUIA ILUMINACAO",
            "-TECNICO-LEGENDA AR-COND", "-TECNICO-LEGENDA COMPLETA", "-TECNICO-LEGENDA HIDRO",
            "-TECNICO-LEGENDA ILUMINACAO", "-TECNICO-LEGENDA OCULTAR", "-TECNICO-LEGENDA VISTA", "-TECNICO-REGISTRO ACABAMENTO"
            ],
            "RODAPE" => [
            "-RODAPE-ACABAMENTO", "-RODAPE-BASE ALVENARIA", "-RODAPE-MARMORARIA"
            ],
            "TETO" => [
            "-TETO-COMPLETO", "-TETO-LAJE","-FORRO-NOVO","-FORRO-EXISTENTE",'-FORRO-TABICA','-FORRO-CORTINEIRO',
            '-FORRO-CORTINEIRO ILUMINADO','-FORRO-SANCA','-FORRO-NEGATIVO'
            ],
            "NIVEL" => [
            "-NIVEL-01", "-NIVEL-02", "-NIVEL-03", "-NIVEL-04"
            ]
        }

        # Cores suaves por grupo (tons claros, baixa saturação)
        cores_por_grupo = {
            "2D" => Sketchup::Color.new(244, 244, 244),
            "ZOOM" => Sketchup::Color.new(244, 244, 244),
            "ARQUITETURA" => Sketchup::Color.new(244, 244, 244),
            "TERRENO" => Sketchup::Color.new(244, 244, 244),
            "BANHEIRO" => Sketchup::Color.new(244, 244, 244),
            "CIVIL" => Sketchup::Color.new(244, 244, 244),
            "LOCAL" => Sketchup::Color.new(244, 244, 244),
            "COBERTURA" => Sketchup::Color.new(244, 244, 244),
            "OUTRO" => Sketchup::Color.new(244, 244, 244),
            "ILUMINACAO" => Sketchup::Color.new(242, 225, 140),
            "MARCENARIA" => Sketchup::Color.new(244, 244, 244),
            "MARMORARIA" => Sketchup::Color.new(244, 244, 244),
            "TECNICO" => Sketchup::Color.new(244, 244, 244),
            "RODAPE" => Sketchup::Color.new(244, 244, 244),
            "TETO" => Sketchup::Color.new(244, 244, 244),
            "NIVEL" => Sketchup::Color.new(244, 244, 244)
        }

        # Cores específicas por layer de interiores
        cores_interiores = {
            "-INTERIORES-ADORNO" => Sketchup::Color.new(255, 235, 215),
            "-INTERIORES-CORTINA" => Sketchup::Color.new(245, 220, 235),
            "-INTERIORES-EXISTENTE" => Sketchup::Color.new(200, 200, 200),
            "-INTERIORES-MOBILIARIO" => Sketchup::Color.new(220, 200, 180),
            "-INTERIORES-QUADRO" => Sketchup::Color.new(230, 230, 255),
            "-INTERIORES-TAPETE" => Sketchup::Color.new(245, 245, 220),
            "-INTERIORES-ELETRO (AEREO)" => Sketchup::Color.new(220, 240, 255),
            "-INTERIORES-ELETRO (MARMORARIA)" => Sketchup::Color.new(225, 240, 230),
            "-INTERIORES-ELETRO (PISO)" => Sketchup::Color.new(235, 235, 215),
            "-INTERIORES-ELETRO (MARCENARIA)" => Sketchup::Color.new(240, 225, 210)
        }

        cores_teto = {
            "-FORRO-NOVO" => Sketchup::Color.new(255, 255, 255),
            "-FORRO-EXISTENTE" => Sketchup::Color.new(127, 127, 127),
            "-TETO-COMPLETO" => Sketchup::Color.new(255, 255, 255),
            "-TETO-LAJE" => Sketchup::Color.new(190, 190, 190   ),
            "-FORRO-TABICA" => Sketchup::Color.new(147, 96, 130),
            "-FORRO-CORTINEIRO" => Sketchup::Color.new(165, 183, 147),
            "-FORRO-CORTINEIRO ILUMINADO" => Sketchup::Color.new(235, 195, 95),
            "-FORRO-SANCA" => Sketchup::Color.new(113, 158, 186),
            "-FORRO-NEGATIVO" => Sketchup::Color.new(239, 177, 122)

            
        }

        cores_civil = {
            "-CIVIL-CONSTRUIR" => Sketchup::Color.new(80, 140, 195),
            "-CIVIL-DEMOLIR"   => Sketchup::Color.new(215, 70, 75),
            "-CIVIL-DRYWALL"   => Sketchup::Color.new(120, 150, 105)
        }

        model.start_operation("Criar Camadas e Indicadores", true)

        # Garante que a camada '-2D-ETIQUETAS' existe
        layer_etiquetas = manager.layers.find { |l| l.name == "-2D-ETIQUETAS" } || manager.add_layer("-2D-ETIQUETAS")

        # Cria grupo "Indicadores_Camadas" e o coloca na camada de etiquetas
        grupo_indicadores = root_entities.add_group
        grupo_indicadores.name = "Indicadores_Camadas"
        grupo_indicadores.layer = layer_etiquetas
        entidades_indicadores = grupo_indicadores.entities

        grupos_camadas.each do |grupo, camadas|
            folder = manager.folders.find { |f| f.name == grupo } || manager.add_folder(grupo)

            camadas.each_with_index do |nome, index|
            layer = manager.layers.find { |l| l.name == nome } || manager.add_layer(nome)
            folder.add_layer(layer) unless folder.layers.include?(layer)

            if grupo == "INTERIORES"
            layer.color = cores_interiores[nome] || Sketchup::Color.new(200, 200, 200)
            elsif grupo == "TETO"
            layer.color = cores_teto[nome] || Sketchup::Color.new(200, 200, 200)
            elsif grupo == "CIVIL"
            layer.color = cores_civil[nome] || Sketchup::Color.new(240, 220, 220) # ou qualquer cor padrão que queira
            else
            layer.color = cores_por_grupo[grupo] || Sketchup::Color.new(180, 180, 180)
            end


            # Cria quadrado de 5x5mm
            size = 5.mm
            x = (index % 20) * size * 2
            y = (grupos_camadas.keys.index(grupo) || 0) * size * 2
            pt = Geom::Point3d.new(x, y, 0)

            square = [
                pt,
                pt + Geom::Vector3d.new(size, 0, 0),
                pt + Geom::Vector3d.new(size, size, 0),
                pt + Geom::Vector3d.new(0, size, 0)
            ]

            face = entidades_indicadores.add_face(square)
            face.layer = layer if face

            puts "Camada '#{nome}' criada."
            end
        end

        model.commit_operation
        UI.messagebox("Camadas e pastas criados com sucesso na etiqueta '-2D-ETIQUETAS'!")
    end

    def self.aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        model = Sketchup.active_model
        model.layers.each do |layer|
            nome = layer.name.upcase

            if camadas_visiveis.include?(nome)
            layer.visible = true
            elsif camadas_ocultas.include?(nome) || grupos_ocultar.any? { |g| nome.include?(g) }
            layer.visible = false
            end
        end
    end

    # -------------------------------------------------------------------------

    def self.configurar_camera_iso(cena)
        model = Sketchup.active_model
        entidades = model.entities
            
        entidades.each do |entidade|
            entidade.hidden = false if entidade.hidden?
        end

        view = Sketchup.active_model.active_view
        eye = Geom::Point3d.new(-1000, -1000, 1000)
        target = Geom::Point3d.new(0, 0, 0)
        up = Geom::Vector3d.new(0, 0, 1)

        view.camera.set(eye, target, up)
        view.camera.perspective = true
        cena.update if cena
    end

    def self.configurar_camera_topo(cena)
        model = Sketchup.active_model
        entidades = model.entities
            
        entidades.each do |entidade|
            entidade.hidden = false if entidade.hidden?
        end

        view = Sketchup.active_model.active_view
        eye = Geom::Point3d.new(0, 0, 1000)
        target = Geom::Point3d.new(0, 0, 0)
        up = Geom::Vector3d.new(0, 1, 0)

        view.camera.set(eye, target, up)
        view.camera.perspective = false
        view.zoom_extents
        cena.update if cena
    end


    # -------------------------------------------------------------------------

    def self.cenas_zoom
        
        modelo = Sketchup.active_model
        cenas = modelo.pages.to_a

            cenas.each do |cena|
                next if cena.name.downcase.include?('imag')

                modelo.pages.selected_page = cena

                sketchup_window = Sketchup.active_model.active_view
                sketchup_window.zoom_extents
                cena.update
            end

        # Exibir mensagem de conclusão
        UI.messagebox("Processo concluído! Todas as cenas foram recentralizadas e atualizadas.")

    end

    # -------------------------------------------------------------------------

    def self.cena_geral
        model = Sketchup.active_model
        nome_cena = "geral"
        estilo_nome = 'FM_VISTAS'

        estilos('FM_VISTAS') 
        estilos('FM_VISTAS_PB') 

        # Verificar se a cena já existe
        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena = model.pages.add(nome_cena)
            model.pages.selected_page = cena
        end

        configurar_camera_iso(cena)
        cena.update

        # Tornar todas as camadas visíveis
        camadas = model.layers.to_a
        camadas.each { |camada| camada.visible = true }
        cena.update        

        # Aplicar o estilo ao modelo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        UI.messagebox("Cena já existe no modelo, apenas foi atualizada.") if cena_existente
        UI.messagebox("Cena criada com sucesso!") unless cena_existente

    end
      
    def self.cena_desenhar

        model = Sketchup.active_model
        nome_cena = "desenhar"
        estilo_nome = 'FM_VISTAS'

        estilos('FM_VISTAS')

        # Verificar se a cena já existe
        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena = model.pages.add(nome_cena)
            model.pages.selected_page = cena
        end

        cena = Sketchup.active_model.pages.selected_page
        configurar_camera_iso(cena)
        cena.update

        # Tornar todas as camadas visíveis
        camadas = model.layers.to_a
        camadas.each { |camada| camada.visible = true }
        cena.update

        # Ocultar grupos e camadas com função centralizada
        grupos_ocultar = ["TETO", "COBERTURA", "CIVIL"]
        camadas_ocultas = ["-2D-ETIQUETAS"]
        camadas_visiveis = []
        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        
        
        # Aplicar o estilo ao modelo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        UI.messagebox("Cena já existe no modelo, apenas foi atualizada.") if cena_existente
        UI.messagebox("Cena criada com sucesso!") unless cena_existente

    end 
    
    def self.cena_etiquetar
        model = Sketchup.active_model
        nome_cena = "etiquetar"
        estilo_nome = 'FM_VISTAS'

        estilos('FM_VISTAS') 

        # Verificar se a cena já existe
        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena = model.pages.add(nome_cena)
            model.pages.selected_page = cena
        end

        configurar_camera_iso(cena)
        cena.update

        # Tornar todas as camadas invisíveis
        camadas = model.layers.to_a
        camadas.each { |camada| camada.visible = false }
        cena.update        

        # Aplicar o estilo ao modelo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        UI.messagebox("Cena já existe no modelo, apenas foi atualizada.") if cena_existente
        UI.messagebox("Cena criada com sucesso!") unless cena_existente
                
    end
    
    def self.cena_planos

        model = Sketchup.active_model
        nome_cena = "planos"
        estilo_nome = 'FM_PLANOS'

        estilos('FM_PLANOS')

        # Verificar se a cena já existe
        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena = model.pages.add(nome_cena)
            model.pages.selected_page = cena
        end

        configurar_camera_iso(cena)
        cena.update

        # Tornar todas as camadas visíveis
        camadas = model.layers.to_a
        camadas.each { |camada| camada.visible = true }
        cena.update

        # Ocultar grupos e camadas com função centralizada
        grupos_ocultar = ["TETO", "COBERTURA",'TECNICO','ADORNO','ILUMINACAO']
        camadas_ocultas = ["-2D-ETIQUETAS"]
        camadas_visiveis = []
        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        
        
        # Aplicar o estilo ao modelo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        UI.messagebox("Cena já existe no modelo, apenas foi atualizada.") if cena_existente
        UI.messagebox("Cena criada com sucesso!") unless cena_existente

    end

    # -------------------------------------------------------------------------
    
    def self.cena_base
        model = Sketchup.active_model
        nome_cena = "base"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')
        estilos('FM_PLANTAS_PB')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            # Solicitar altura do piso
            prompts = ["Altura do piso (em metros):"]
            defaults = ["0,00"]
            input = UI.inputbox(prompts, defaults, "Altura do piso (Z)")
            return unless input

            altura_metros = input[0].tr(',', '.').to_f
            altura_polegadas = altura_metros * 39.3701
            altura_total = 61.024 + altura_polegadas

            # Criar nova cena
            cena = model.pages.add(nome_cena)
            model.pages.selected_page = cena

            # Adicionar plano de corte
            sp = model.entities.add_section_plane([0, 0, altura_total], [0, 0, -1])
            sp.name = nome_cena
            sp.activate
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        # Ocultar grupos e camadas específicas
        grupos_ocultar = [
            '2D', 'MARMORARIA', 'MARCENARIA', 'INTERIORES', 'BANHEIRO', 'PISO',
            'LEGENDA', 'TETO', 'COBERTURA', 'ADORNO', 'ILUMINACAO', 'AEREO',
            'TECNICO', 'ESCALA', 'EXTERNO', 'XREF', 'CIVIL', 'RODAPE', 'OUTRO'
        ]
        camadas_ocultas = ['-TERRENO-ESTRADA', '-TERRENO-VIZINHOS', '-TERRENO-GRAMA',"-2D-ETIQUETAS"]
        camadas_visiveis = []
        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)

        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end
    end

    def self.cena_layout
        model = Sketchup.active_model
        nome_cena = "layout"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')
        estilos('FM_MOBILIARIO_ARTISTICO')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente

            model.pages.selected_page = cena

        else

            #Duplicar BASE e criar novo
            model = Sketchup.active_model
            cena_base = model.pages.find { |cena| cena.name.downcase == 'base' }

            if cena_base

                model = Sketchup.active_model
                model.pages.selected_page = cena_base
                model.pages.add(nome_cena)
                cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }

            end
            
        end

        configurar_camera_topo(cena)

        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            'ADORNO','TERRENO','AEREO',"TETO","COBERTURA",'ILUMINACAO','TECNICO',
            'EXTERNO','XREF','CIVIL','EXTERIOR','OUTRO'
        ]
        camadas_ocultas = ["-2D-ETIQUETAS",'-RODAPE-ACABAMENTO']
        camadas_visiveis = ['-ILUMINACAO-LUMINARIA','-TERRENO-ALINHAMENTO','-TERRENO-CALÇADAS']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)

        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end
    end
    
    def self.cena_arq
        model = Sketchup.active_model
        nome_cena = "arq"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente

            model.pages.selected_page = cena

        else

            #Duplicar BASE e criar novo
            model = Sketchup.active_model
            cena_base = model.pages.find { |cena| cena.name.downcase == 'base' }

            if cena_base

                model = Sketchup.active_model
                model.pages.selected_page = cena_base
                model.pages.add(nome_cena)
                cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }

            end
            
        end

        configurar_camera_topo(cena)

        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            "TETO", "TERRENO", "COBERTURA", "TOALHEIRO", "ADORNO", "ILUMINACAO", "AEREO",
            "TECNICO", "ESCALA", "EXTERNO", "XREF", "CIVIL", "RODAPE", "MARCENARIA",
            "MARMORARIA", "INTERIORES", "EXTERIOR", "OUTRO"
        ]
        camadas_ocultas = ['-TERRENO-ESTRADA','-TERRENO-VIZINHOS','-2D-MOBILIARIO',"-2D-ETIQUETAS",'-ARQUITETURA-PISO']
        camadas_visiveis = []

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)

        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end
    end

    def self.cena_arq_piso

        model = Sketchup.active_model
        nome_cena = "arq piso"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente

            model.pages.selected_page = cena

        else

            #Duplicar BASE e criar novo
            model = Sketchup.active_model
            cena_base = model.pages.find { |cena| cena.name.downcase == 'base' }

            if cena_base

                model = Sketchup.active_model
                model.pages.selected_page = cena_base
                model.pages.add(nome_cena)
                cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }

            end
            
        end

        configurar_camera_topo(cena)

        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            "TETO", "TERRENO", "COBERTURA", "TOALHEIRO", "ADORNO", "ILUMINACAO", "AEREO",
            "TECNICO", "ESCALA", "EXTERNO", "XREF", "CIVIL", "RODAPE", "MARCENARIA",
            "MARMORARIA", "INTERIORES", "EXTERIOR", "OUTRO"
        ]
        camadas_ocultas = ['-TERRENO-ESTRADA','-TERRENO-VIZINHOS','-2D-MOBILIARIO',"-2D-ETIQUETAS"]
        camadas_visiveis = ['-ARQUITETURA-PISO']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)

        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end
    end
    
    def self.cena_mobi

        model = Sketchup.active_model
        nome_cena = "mobi"
        estilo_nome = 'FM_MOBILIARIO_LINHAS'

        estilos('FM_MOBILIARIO_LINHAS')
        estilos('FM_MOBILIARIO_OPACO')
        estilos('FM_MOBILIARIO_ARTISTICO')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente

            model.pages.selected_page = cena

        else

            #Duplicar BASE e criar novo
            model = Sketchup.active_model
            cena_base = model.pages.find { |cena| cena.name.downcase == 'base' }

            if cena_base

                model = Sketchup.active_model
                model.pages.selected_page = cena_base
                model.pages.add(nome_cena)
                cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }

            end
            
        end

        configurar_camera_topo(cena)

        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            '2D', 'ARQUITETURA', 'TETO', 'COBERTURA', 'ADORNO', 'ILUMINACAO',
            'AEREO', 'TECNICO', 'ESCALA', 'EXTERNO', 'XREF', 'CIVIL', 'RODAPE', 'OUTRO','TERRENO'
        ]
        camadas_ocultas = ["-2D-ETIQUETAS"]
        camadas_visiveis = ['-2D-MOBILIARIO','-TERRENO-ALINHAMENTO']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)

        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    # -------------------------------------------------------------------------

    def self.cena_construir

        model = Sketchup.active_model
        nome_cena = "construir"
        estilo_nome = 'FM_CIVIL'

        estilos('FM_CIVIL')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end


        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
                '2D', 'ARQUITETURA', 'BANHEIRO', 'TETO', 'COBERTURA', 'ADORNO', 'ILUMINACAO', 'AEREO',
                'TECNICO', 'ESCALA', 'EXTERNO', 'XREF', 'RODAPE', 'MARCENARIA', 'MARMORARIA',
                'INTERIORES', 'EXTERIOR', 'OUTRO', 'TERRENO'
            ]
        camadas_ocultas = ['-ARQUITETURA-PISO', '-CIVIL-DEMOLIR', '-CIVIL-DRYWALL',"-2D-ETIQUETAS"]
        camadas_visiveis = ['-TERRENO-ALINHAMENTO','-ZOOM-VISTA']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    def self.cena_demolir

        model = Sketchup.active_model
        nome_cena = "demolir"
        estilo_nome = 'FM_CIVIL'

        estilos('FM_CIVIL')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
                '2D', 'ARQUITETURA', 'BANHEIRO', 'TETO', 'COBERTURA', 'ADORNO', 'ILUMINACAO', 'AEREO',
                'TECNICO', 'ESCALA', 'EXTERNO', 'XREF', 'RODAPE', 'MARCENARIA', 'MARMORARIA',
                'INTERIORES', 'EXTERIOR', 'OUTRO', 'TERRENO'
            ]
        camadas_ocultas = ['-ARQUITETURA-PISO', '-CIVIL-CONSTRUIR', '-CIVIL-DRYWALL',"-2D-ETIQUETAS"]
        camadas_visiveis = ['-TERRENO-ALINHAMENTO','-ZOOM-VISTA']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    def self.cena_drywall

        model = Sketchup.active_model
        nome_cena = "drywall"
        estilo_nome = 'FM_CIVIL'

        estilos('FM_CIVIL')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
                '2D', 'ARQUITETURA', 'BANHEIRO', 'TETO', 'COBERTURA', 'ADORNO', 'ILUMINACAO', 'AEREO',
                'TECNICO', 'ESCALA', 'EXTERNO', 'XREF', 'RODAPE', 'MARCENARIA', 'MARMORARIA',
                'INTERIORES', 'EXTERIOR', 'OUTRO', 'TERRENO'
            ]
        camadas_ocultas = ['-ARQUITETURA-PISO', '-CIVIL-CONSTRUIR', '-CIVIL-DEMOLIR',"-2D-ETIQUETAS"]
        camadas_visiveis = ['-TERRENO-ALINHAMENTO','-ZOOM-VISTA']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    def self.cena_civil

        model = Sketchup.active_model
        nome_cena = "civil"
        estilo_nome = 'FM_CIVIL'

        estilos('FM_CIVIL')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end


        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
                '2D', 'ARQUITETURA', 'BANHEIRO', 'TETO', 'COBERTURA', 'ADORNO', 'ILUMINACAO', 'AEREO',
                'TECNICO', 'ESCALA', 'EXTERNO', 'XREF', 'RODAPE', 'MARCENARIA', 'MARMORARIA',
                'INTERIORES', 'EXTERIOR', 'OUTRO', 'TERRENO'
            ]
        camadas_ocultas = []
        camadas_visiveis = ['-TERRENO-ALINHAMENTO','-ZOOM-VISTA']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    # -------------------------------------------------------------------------

    def self.cena_pontostec

        model = Sketchup.active_model
        nome_cena = "tecnico"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            '2D',"TETO", "COBERTURA",'ADORNO','ILUMINACAO','AEREO','EXTERNO',
            'XREF','CIVIL','RODAPE','MARCENARIA','MARMORARIA',
            'INTERIORES','EXTERIOR','PONTO','BANHEIRO','OUTRO'
        ]
        camadas_ocultas = ['-ARQUITETURA-PISO', '-TECNICO-LEGENDA VISTA','-TERRENO-VIZINHOS','-TERRENO-ESTRADA','-TERRENO-GRAMA',"-2D-ETIQUETAS"]
        camadas_visiveis = ['-TECNICO-LEGENDA ILUMINACAO', '-2D-LEGENDA AMBIENTE','-2D-ESQUADRIA']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    def self.cena_eletrica

        model = Sketchup.active_model
        nome_cena = "eletrico"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            '2D', "TETO", "COBERTURA", 'ADORNO', 'AEREO', 'EXTERNO', 'XREF', 'CIVIL',
            'RODAPE', 'MARCENARIA', 'MARMORARIA', 'INTERIORES', 'EXTERIOR', 'PONTO',
            'BANHEIRO', 'OUTRO', 'HACHURA', 'LUMINARIA', 'SPOTLIGTH', 'CIRCUITOS'
        ]
        camadas_ocultas = [
            '-ARQUITETURA-PISO', '-TECNICO-LEGENDA HIDRO', '-TECNICO-LEGENDA VISTA','-TERRENO-VIZINHOS','-TERRENO-ESTRADA','-TERRENO-GRAMA',"-2D-ETIQUETAS"
        ]
        camadas_visiveis = ['-2D-LEGENDA AMBIENTE','-2D-ESQUADRIA']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end
    end

    def self.cena_hidro

        model = Sketchup.active_model
        nome_cena = "hidro"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            '2D', "TETO", "COBERTURA", 'ADORNO', 'ILUMINACAO', 'AEREO', 'EXTERNO', 'XREF',
            'CIVIL', 'RODAPE', 'MARCENARIA', 'MARMORARIA', 'INTERIORES', 'EXTERIOR',
            'PONTO', 'BANHEIRO', 'OUTRO', 'CIRCUITOS'
        ]

        camadas_ocultas = [
            '-ARQUITETURA-PISO', '-TECNICO-GUIA', '-TECNICO-LEGENDA INTERRUPTOR',
            '-TECNICO-LEGENDA AR-COND', '-TECNICO-LEGENDA ELETRICA',
            '-TECNICO-LEGENDA ILUMINACAO', '-TECNICO-LEGENDA VISTA',"-2D-ETIQUETAS",
            '-TECNICO-LEGENDA COMPLETA','-TERRENO-VIZINHOS','-TERRENO-ESTRADA','-TERRENO-GRAMA'
        ]

        camadas_visiveis = ['-2D-LEGENDA AMBIENTE','-2D-ESQUADRIA']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end
        
    end

    def self.cena_climatizacao

        model = Sketchup.active_model
        nome_cena = "clima"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            '2D', "TETO", "COBERTURA", 'ADORNO', 'ILUMINACAO', 'AEREO', 'EXTERNO', 'XREF',
            'CIVIL', 'RODAPE', 'MARCENARIA', 'MARMORARIA', 'INTERIORES', 'EXTERIOR',
            'PONTO', 'BANHEIRO', 'OUTRO'
        ]

        camadas_ocultas = [
            '-ARQUITETURA-PISO', '-TECNICO-GUIA', '-TECNICO-LEGENDA HIDRO',
            '-TECNICO-LEGENDA ILUMINACAO', '-TECNICO-LEGENDA INTERRUPTOR',"-2D-ETIQUETAS",
            '-TECNICO-LEGENDA ELETRICA', '-TECNICO-LEGENDA VISTA', '-TECNICO-LEGENDA COMPLETA','-TERRENO-VIZINHOS','-TERRENO-ESTRADA','-TERRENO-GRAMA'
        ]

        camadas_visiveis = ['-2D-LEGENDA AMBIENTE','-2D-ESQUADRIA']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    # -------------------------------------------------------------------------

    def self.cena_iluminacao

        model = Sketchup.active_model
        nome_cena = "iluminacao"
        estilo_nome = 'FM_VISTAS'

        estilos('FM_VISTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            'LAJE', 'FORRO', 'COBERTURA', 'ADORNO', 'AEREO', 'EXTERNO', 'XREF', 'CIVIL', 'RODAPE',
            'MARCENARIA', 'MARMORARIA', 'INTERIORES', 'EXTERIOR', 'PONTO', 'BANHEIRO', '2D',
            'SPOTLIGTH', 'OUTRO', 'ARQUITETURA'
        ]

        camadas_ocultas = [
            '-TECNICO-LEGENDA OCULTAR', '-ARQUITETURA-PISO', '-TECNICO-GUIA',
            '-TECNICO-LEGENDA ELETRICA', '-TECNICO-LEGENDA HIDRO', '-TECNICO-LEGENDA VISTA',
            '-2D-LEGENDA AMBIENTE','-TERRENO-VIZINHOS','-TERRENO-ESTRADA','-TERRENO-GRAMA',"-2D-ETIQUETAS"
        ]

        camadas_visiveis = []

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    def self.cena_iluminacao_cir

         model = Sketchup.active_model
        nome_cena = "circuitos"
        estilo_nome = 'FM_VISTAS'

        estilos('FM_VISTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            'LAJE', 'FORRO', 'COBERTURA', 'ADORNO', 'AEREO', 'EXTERNO', 'XREF', 'CIVIL',
            'RODAPE', 'MARCENARIA', 'MARMORARIA', 'INTERIORES', 'EXTERIOR', 'PONTO',
            'BANHEIRO', '2D', 'SPOTLIGTH', 'OUTRO', 'ARQUITETURA'
        ]

        camadas_ocultas = [
            '-TECNICO-LEGENDA OCULTAR', '-ARQUITETURA-PISO', '-TECNICO-GUIA',
            '-TECNICO-LEGENDA ELETRICA', '-TECNICO-LEGENDA HIDRO', '-TECNICO-LEGENDA VISTA',
            '-2D-LEGENDA AMBIENTE','-TERRENO-VIZINHOS','-TERRENO-ESTRADA','-TERRENO-GRAMA',"-2D-ETIQUETAS"
        ]

        camadas_visiveis = [
            '-ILUMINACAO-2D-CIRCUITOS', '-ILUMINACAO-2D-CIRCUITOS-LINHAS'
        ]

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    def self.cena_forro
        model = Sketchup.active_model
        nome_cena = "forro"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')

        cena_existente = model.pages.find { |cena| cena.name.downcase == nome_cena.downcase }

        if cena_existente
            cena = model.pages.find { |page| page.name.downcase == nome_cena.downcase }
            model.pages.selected_page = cena
        else
            # Solicitar altura do piso
            prompts = ["Altura do piso (em metros):"]
            defaults = ["0,00"]
            input = UI.inputbox(prompts, defaults, "Altura do piso para posicionar corte do forro")

            return unless input

            altura_metros = input[0].tr(',', '.').to_f
            altura_polegadas = altura_metros * 39.3701
            altura_forro = altura_polegadas + 65  # 2,5m em polegadas

            # Criar nova cena
            cena = model.pages.add(nome_cena)
            model.pages.selected_page = cena

            # Adicionar plano de corte no nível do forro
            sp = model.entities.add_section_plane([0, 0, altura_forro], [0, 0, 1])
            sp.name = nome_cena
            sp.activate
        end

        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }

        # Configurar câmera olhando de baixo pra cima
        eye = [0, 0, -1000]
        target = [0, 0, 0]
        up = [0, 1, 0]
        model.active_view.camera = Sketchup::Camera.new(eye, target, up, true)
        model.active_view.camera.perspective = false
        model.active_view.zoom_extents

        # Todas etiquetas visíveis inicialmente
        camadas = model.layers.to_a
        camadas.each { |camada| camada.visible = true }
        cena.update

        # Ocultar etiquetas/grupos indesejados
        grupos_ocultar = [
            "COBERTURA", "ESCALA", "ADORNO", "AEREO", "TECNICO", "EXTERNO", "XREF",
            "CIVIL", "RODAPE", "OUTRO", "MARCENARIA", "MARMORARIA", "INTERIORES",
            "BANHEIRO", "SPOTLIGTH", "HACHURA", "CIRCUITOS"
        ]
        camadas.each do |camada|
            camada.visible = false if grupos_ocultar.any? { |item| camada.name.include?(item) }
        end
        cena.update

        # Ativar camadas específicas
        camadas_ativas = ['-TECNICO-PONTO AR-COND']
        camadas_ativas.each do |nome_camada|
            camada = camadas.find { |c| c.name == nome_camada }
            camada.visible = true if camada
        end
        cena.update

        # Ativar camadas específicas
        camadas_ocultas = ['-2D-ETIQUETAS']
        camadas_ocultas.each do |nome_camada|
            camada = camadas.find { |c| c.name == nome_camada }
            camada.visible = false if camada
        end
        cena.update

        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        UI.messagebox(cena_existente ? "Cena já existia no modelo e foi atualizada." : "Cena de forro criada com sucesso!")
    end

    def self.cena_forro_cores

        model = Sketchup.active_model
        nome_cena = "forro cor"
        estilo_nome = 'FM_PLANTAS_CORES'

        estilos('FM_PLANTAS_CORES')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'forro' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            "COBERTURA", "ESCALA", "ADORNO", "AEREO", "TECNICO", "EXTERNO", "XREF",
            "CIVIL", "RODAPE", "OUTRO", "MARCENARIA", "MARMORARIA", "INTERIORES",
            "BANHEIRO", "SPOTLIGTH", "HACHURA", "CIRCUITOS"
        ]
        camadas_visiveis = ['-TECNICO-PONTO AR-COND']

        camadas_ocultas = ["-2D-ETIQUETAS",'-ARQUITETURA-ESQUADRIA']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    # -------------------------------------------------------------------------

    def self.cena_revestimentos

        model = Sketchup.active_model
        nome_cena = "reves"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = [
            "TETO", '2D', 'BANHEIRO', "COBERTURA", 'ESCALA', 'ADORNO', 'ILUMINACAO', 'AEREO',
            'TECNICO', 'EXTERNO', 'XREF', 'CIVIL', 'RODAPE', 'MARCENARIA', 'MARMORARIA',
            'INTERIORES', 'EXTERIOR', 'OUTRO'
        ]
        camadas_visiveis = ['-RODAPE-ACABAMENTO', "-2D-LEGENDA AMBIENTE", '-ARQUITETURA-PISO']

        camadas_ocultas = ['-TERRENO-VIZINHOS', '-TERRENO-ESTRADA',"-2D-ETIQUETAS"]

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    # -------------------------------------------------------------------------

    def self.cena_marcenaria

        model = Sketchup.active_model
        nome_cena = "marcenaria"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = ["TETO", "BANHEIRO", "2D", "COBERTURA", "ADORNO", "ILUMINACAO", "AEREO", "TECNICO", "ESCALA",
                            "EXTERNO", "XREF", "CIVIL", "RODAPE", "INTERIORES", "EXTERIOR", "OUTRO"]

        camadas_visiveis = ['-ILUMINACAO-MARCENARIA', '-ILUMINACAO-DECORATIVO MARCENARIA']

        camadas_ocultas = ['-TERRENO-VIZINHOS', '-TERRENO-ESTRADA',"-2D-ETIQUETAS"]

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    # -------------------------------------------------------------------------

    def self.cena_marmoraria

         model = Sketchup.active_model
        nome_cena = "marmoraria"
        estilo_nome = 'FM_PLANTAS'

        estilos('FM_PLANTAS')

        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }
        cena_existente = !cena.nil?

        if cena_existente
            model.pages.selected_page = cena
        else
            cena_base = model.pages.find { |c| c.name.downcase == 'base' }
            if cena_base
            model.pages.selected_page = cena_base
            nova_cena = model.pages.add(nome_cena)
            model.pages.selected_page = nova_cena
            cena = nova_cena 
            end
        end

        configurar_camera_topo(cena)
        # Tornar visíveis entidades ocultas
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        # Tornar todas as camadas visíveis
        model.layers.each { |layer| layer.visible = true }

        grupos_ocultar = ['2D', 'TETO', 'BANHEIRO', 'COBERTURA', 'ESCALA', 'ADORNO', 'ILUMINACAO', 'AEREO',
                            'TECNICO', 'EXTERNO', 'XREF', 'CIVIL', 'RODAPE', 'INTERIORES', 'EXTERIOR', 'OUTRO', 'MARCENARIA']

        camadas_visiveis = []
                    
        camadas_ocultas = ['-TERRENO-VIZINHOS', '-TERRENO-ESTRADA',"-2D-ETIQUETAS"]

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)
        # Aplicar estilo
        model.styles.selected_style = model.styles[estilo_nome]
        model.active_view.zoom_extents
        cena.update

        # Mensagem final
        if cena_existente
            UI.messagebox("Cena já existia no modelo e foi atualizada.")
        else
            UI.messagebox("Cena criada com sucesso!")
        end

    end

    # -------------------------------------------------------------------------

    def self.isolar_marcenaria

        model = Sketchup.active_model
        nome_cena = "isolar"
        estilo_nome = 'FM_VISTAS'
        estilos('FM_VISTAS')

        # Verificar se a cena já existe
        cena_existente = model.pages.find { |cena| cena.name.downcase == nome_cena.downcase }

        if cena_existente

            #achar a cena com o nome especifico
            model = Sketchup.active_model
            cena = model.pages.find { |page| page.name.downcase == nome_cena.downcase }
            model.pages.selected_page = cena  

            entidades = model.entities
            
            entidades.each do |entidade|
                entidade.hidden = false if entidade.hidden?
            end

            #voltar orientação para cima
            eye = [0, 0, 1000]
            target = [0, 0, 0]
            up = [0, 1, 0]
        
            model.active_view.camera = Sketchup::Camera.new(eye, target, up, true)
            model.active_view.camera.perspective = false
            model.active_view.zoom_extents

            #todas camadas visiveis
            cena = Sketchup.active_model.pages.selected_page
            camadas = model.layers.to_a
            camadas.each { |camada| camada.visible = true }
            cena.update

            grupos_ocultar = ["TETO","2D",'BANHEIRO', "COBERTURA",'ESCALA','ADORNO','TECNICO',
            'EXTERNO','XREF','CIVIL','RODAPE','INTERIORES','ZOOM','INTERIORES','EXTERIOR','OUTRO','ARQUITETURA','SPOTLIGTH']
            camadas.each do |camada|
                camada.visible = false if grupos_ocultar.any? { |item| camada.name.include?(item) }
            end
            cena.update

            camadas_ocultas = ['-ILUMINACAO-HACHURA LUZ LINEAR','-ILUMINACAO-LEGENDA','-ILUMINACAO-LUMINARIA','-2D-ETIQUETAS']
            camadas_ocultas.each do |nome_camada|
                camada = camadas.find { |c| c.name == nome_camada }
                camada.visible = false if camada
            end
            cena.update

            camadas_visivel = ['-INTERIORES-ELETRO (AEREO)','-INTERIORES-ELETRO (MARMORARIA)',
            '-INTERIORES-ELETRO (PISO)','-INTERIORES-ELETRO (MARCENARIA)','-RODAPE-BASE ALVENARIA','-RODAPE-MARMORARIA',
            '-MARCENARIA-AEREO','-MARCENARIA-GERAL','-MARCENARIA-PORTA','-MARMORARIA-BANCADA','-MARMORARIA-CUBA E METAIS']
            camadas_visivel.each do |nome_camada|
                camada = camadas.find { |c| c.name == nome_camada }
                camada.visible = true if camada
            end
            cena.update      

            #configurar estilo da cena
            
            model.styles.selected_style = model.styles[estilo_nome]
            model.active_view.zoom_extents
            cena.update

            UI.messagebox("Cena foi atualizada. Agora faça os grupos e adicione os DETALHES")
          
        else

            model = Sketchup.active_model
            entidades = model.entities

            entidades.each do |entidade|
                entidade.hidden = false if entidade.hidden?
            end

                #duplicar layout e criar novo
                model = Sketchup.active_model
                cena_base = model.pages.find { |cena| cena.name.downcase == 'base' }

                if cena_base

                    model.pages.selected_page = cena_base
                    model.pages.add(nome_cena)
                    
                    #todas camadas visiveis
                    cena = Sketchup.active_model.pages.selected_page
                    camadas = model.layers.to_a
                    camadas.each { |camada| camada.visible = true }

                    cena.update

                    grupos_ocultar = ["TETO","2D",'BANHEIRO', "COBERTURA",'ESCALA','ADORNO','TECNICO','ESCALA','EXTERNO','XREF','CIVIL','RODAPE','INTERIORES','ZOOM','INTERIORES','EXTERIOR','OUTRO','ARQUITETURA','SPOTLIGTH']
                    camadas.each do |camada|
                        camada.visible = false if grupos_ocultar.any? { |item| camada.name.include?(item) }
                    end
                    cena.update

                    camadas_ocultas = ['-ILUMINACAO-HACHURA LUZ LINEAR','-ILUMINACAO-LEGENDA','-ILUMINACAO-LUMINARIA','-2D-ETIQUETAS']
                    camadas_ocultas.each do |nome_camada|
                        camada = camadas.find { |c| c.name == nome_camada }
                        camada.visible = false if camada
                    end
                    cena.update

                    camadas_visivel = ['-INTERIORES-ELETRO (AEREO)','-INTERIORES-ELETRO (MARMORARIA)','-INTERIORES-ELETRO (PISO)','-INTERIORES-ELETRO (MARCENARIA)','-RODAPE-BASE ALVENARIA','-RODAPE-MARMORARIA',
                    '-MARCENARIA-AEREO','-MARCENARIA-GERAL','-MARCENARIA-PORTA','-MARMORARIA-BANCADA','-MARMORARIA-CUBA E METAIS']
                    camadas_visivel.each do |nome_camada|
                        camada = camadas.find { |c| c.name == nome_camada }
                        camada.visible = true if camada
                    end
                    cena.update      

                    model.styles.selected_style = model.styles[estilo_nome]
                    model.active_view.zoom_extents
                    cena.update

                    UI.messagebox("Cena criada. Agora faça os grupos e adicione os DETALHES")
            
                else
                UI.messagebox("Cena Base não encontrada.") 
            end
         end
    end

    # -------------------------------------------------------------------------

    def self.detalhamento_marcenaria

        #reexibir tudo
        model = Sketchup.active_model
        entidades = model.entities

        entidades.each do |entidade|
            if entidade.hidden?
                entidade.hidden = false
            end
        end

        # Obtém a referência para o modelo ativo
        modelo = Sketchup.active_model

        # Obtém a referência para a seleção atual
        selecao = modelo.selection

        # Verifica se há um grupo ou componente selecionado
        if selecao.length == 1 && (selecao.first.is_a?(Sketchup::Group) || selecao.first.is_a?(Sketchup::ComponentInstance))
        # Obtém o grupo ou componente selecionado
        grupo_ou_componente = selecao.first

        # Obtém a referência para o contexto do modelo
        contexto_modelo = modelo.active_entities

        # Cria uma linha de 1 cm no eixo 0,0,0
        linha = contexto_modelo.add_line([0, 0, 0], [1.cm, 0, 0])

        # Cria um grupo com a linha e o grupo ou componente selecionado
        novo_grupo = contexto_modelo.add_group([linha, grupo_ou_componente])

        # Apaga a linha
        contexto_modelo.erase_entities(linha)

        # Define o prefixo para as camadas
        prefixo_camada = '-DET-'
        
        # Obtém todas as camadas existentes no modelo
        todas_camadas = modelo.layers.to_a
        
        # Encontra a próxima camada disponível no padrão 'DET-xx'
        numero_camada = (1..Float::INFINITY).find do |numero|
            nome_camada = "#{prefixo_camada}#{numero}"
            !todas_camadas.any? { |camada| camada.name == nome_camada }
        end

        # Cria a camada com o próximo número disponível
        nome_camada = "#{prefixo_camada}#{numero_camada}"
        nova_camada = modelo.layers.add(nome_camada)

        # Atribui o novo grupo à camada criada
        novo_grupo.layer = nova_camada

        # Atualiza a seleção para incluir o novo grupo
        selecao.clear
        selecao.add(novo_grupo)

        UI.messagebox("Detalhe #{nome_camada.upcase} criado.")

        else
        puts 'Selecione um único grupo ou componente para executar este comando.'
        end

    end 

    # -------------------------------------------------------------------------

    def self.detalhamento

        model = Sketchup.active_model
        estilos('FM_VISTAS')
        camadas = model.layers.to_a
        entidades = model.entities
        paginas = model.pages

        # Garante que nenhuma entidade fique oculta
        entidades.each do |entidade|
            entidade.hidden = false if entidade.hidden?
        end

        # Pega o nome de todas as cenas já existentes
        nomes_existentes = paginas.map { |p| p.name.downcase }

        # Percorre cada camada
        camadas.each do |camada_atual|
            if camada_atual.name.start_with?('-DET-')
                nome_cena = camada_atual.name[1..-1].downcase
                cena = paginas.find { |p| p.name.downcase == nome_cena }

                criando_nova = cena.nil?

                cena ||= paginas.add(nome_cena) # cria se não existir
                paginas.selected_page = cena   # ativa para modificar

                # Define a câmera
                eye = [-1000, -1000, 1000]
                target = [0, 0, 0]
                up = [0, 0, 1]

                model.active_view.camera = Sketchup::Camera.new(eye, target, up, true)
                model.active_view.camera.perspective = false
                model.active_view.zoom_extents

                # Desativa todas as camadas
                camadas.each { |c| c.visible = false }

                # Ativa a camada correspondente
                camada_atual.visible = true

                # Ativa grupos adicionais
                grupos_visivel = ["MARCENARIA", "MARMORARIA"]
                camadas.each do |c|
                    c.visible = true if grupos_visivel.any? { |item| c.name.include?(item) }
                end

                # Ativa outras camadas específicas
                camadas_visivel = [
                    '-INTERIORES-ELETRO (AEREO)','-INTERIORES-ELETRO (MARMORARIA)','-INTERIORES-ELETRO (PISO)',
                    '-INTERIORES-ELETRO (MARCENARIA)','-RODAPE-BASE ALVENARIA','-RODAPE-MARMORARIA',
                    '-MARCENARIA-AEREO','-MARCENARIA-GERAL','-MARCENARIA-PORTA',
                    '-MARMORARIA-BANCADA','-MARMORARIA-CUBA E METAIS'
                ]
                camadas_visivel.each do |nome_camada|
                    camada = camadas.find { |c| c.name == nome_camada }
                    camada.visible = true if camada
                end

                # Estilo e zoom
                model.styles.selected_style = model.styles['FM_VISTAS']
                model.active_view.zoom_extents

                # Atualiza a cena com a visibilidade configurada
                cena.update

            end
            
        end
    end

    def self.duplicar_cenas

            model = Sketchup.active_model
            estilos('FM_VISTAS')
            camadas = model.layers.to_a
            entidades = model.entities

            model = Sketchup.active_model
            pagina_atual = model.pages.selected_page
            return unless pagina_atual # Garante que há uma cena selecionada
        
            # Verifica se a cena segue o padrão DET-
            if pagina_atual.name.start_with?('det-')
                # Criar novo nome da cena com sufixo adequado
                base_name = pagina_atual.name
                sufixo = "-a"
                contador = "a".ord
                paginas = model.pages.to_a
                
                # Garante que o novo nome seja único
                while paginas.any? { |p| p.name == "#{base_name}#{sufixo}" }
                    contador += 1
                    sufixo = "-#{contador.chr}" # Vai gerar -a, -b, -c...
                end
                
                #configurar estilo da cena
                model.styles.selected_style = model.styles['FM_VISTAS']
                
                model.active_view.zoom_extents

                novo_nome = "#{base_name}#{sufixo}"
                nova_cena = model.pages.add(novo_nome)    
                
            end
    end

    def self.duplicar_cenas_cortes

        model = Sketchup.active_model
        estilos('FM_PLANTAS')
        camadas = model.layers.to_a
        entidades = model.entities

        model = Sketchup.active_model
        pagina_atual = model.pages.selected_page
        return unless pagina_atual # Garante que há uma cena selecionada
    
        # Verifica se a cena segue o padrão DET-
        if pagina_atual.name.start_with?('det-')
            # Criar novo nome da cena com sufixo adequado
            base_name = pagina_atual.name
            sufixo = "-a"
            contador = "a".ord
            paginas = model.pages.to_a
            
            # Garante que o novo nome seja único
            while paginas.any? { |p| p.name == "#{base_name}#{sufixo}" }
                contador += 1
                sufixo = "-#{contador.chr}" # Vai gerar -a, -b, -c...
            end
            
            #configurar estilo da cena
            model.styles.selected_style = model.styles['FM_PLANTAS']
            
            model.active_view.zoom_extents

            novo_nome = "#{base_name}#{sufixo}"
            nova_cena = model.pages.add(novo_nome)    
            
        end
    end

    # -------------------------------------------------------------------------

    def self.imagem_inicial
        model = Sketchup.active_model
        nome_cena = "imagem"

        estilos('FM_IMAGENS_VISTAS')
        estilos('FM_IMAGENS_CORTES')
        estilos('FM_IMAGENS_CORTES_AO')
        estilos('FM_IMAGENS_VISTAS_AO')
        

        # Encontrar a cena se existir
        cena = model.pages.find { |c| c.name.downcase == nome_cena.downcase }

        # Se não existir, cria a cena
        unless cena
            cena = model.pages.add(nome_cena)

            eye = [-1000, -1000, 0]
            target = [0, 0, 0]
            up = [0, 0, 1]

            model.active_view.camera = Sketchup::Camera.new(eye, target, up, true)
            model.active_view.camera.perspective = true
            model.active_view.camera.fov = 50
            model.active_view.zoom_extents

            cena.update
        end

        # Selecionar a cena para trabalhar
        model.pages.selected_page = cena

        # Pré-carregar os estilos necessários
        estilos('FM_IMAGENS_VISTAS')
        estilos('FM_IMAGENS_CORTES')
        estilos('FM_IMAGENS_CORTES_AO')
        estilos('FM_IMAGENS_VISTAS_AO')

        # Sempre perguntar ao usuário qual renderizador usar
        opcoes = ["Enscape", "Vray", "Skt"]
        escolha = UI.inputbox(["Escolha o tipo de renderizador:"], [opcoes[0]], ["#{opcoes.join('|')}"], "Exibir")
        tipo_escolhido = escolha[0].upcase

        # Escolha do estilo de visualização
        estilos_disponiveis = {
            "Vistas" => 'FM IMAGENS VISTAS',
            "Cortes" => 'FM IMAGENS CORTES',
            "Vistas AO" => 'FM IMAGENS VISTAS AO',
            "Cortes AO" => 'FM IMAGENS CORTES AO'
        }

        opcoes_estilo = estilos_disponiveis.keys
        escolha_estilo = UI.inputbox(
            ["Escolha o estilo de visualização:"],
            [opcoes_estilo[0]],
            ["#{opcoes_estilo.join('|')}"],
            "Escolher Estilo"
        )
        return unless escolha_estilo
        estilo_selecionado = estilos_disponiveis[escolha_estilo[0]]

        # Mostrar todas as entidades ocultas
        model.entities.each { |e| e.hidden = false if e.hidden? }

        # Mostrar todas as camadas
        camadas = model.layers.to_a
        camadas.each { |camada| camada.visible = true }

        etiquetas_por_tipo = {
            "VRAY" => ["ENSCAPE",'HACHURA'],
            "ENSCAPE" => ["VRAY",'HACHURA'],
            "SKT" => ["ENSCAPE",'VRAY']
        }
        etiquetas_ocultas_extras = ['ESCALA', 'CIVIL', 'LEGENDA', "ZOOM", "2D"]
        etiquetas_pontos_tecnicos = ['-TECNICO-PONTO HIDRO', '-TECNICO-PONTO ILUMINACAO']

        # Montar lista de camadas para ocultar
        grupos_ocultar = etiquetas_ocultas_extras + etiquetas_por_tipo[tipo_escolhido]

        camadas.each do |camada|
            camada.visible = false if grupos_ocultar.any? { |item| camada.name.include?(item) }
        end

        etiquetas_pontos_tecnicos.each do |nome_camada|
            camada = camadas.find { |c| c.name == nome_camada }
            camada.visible = false if camada
        end

        # Aplicar estilo
        estilo_objeto = model.styles.to_a.find { |s| s.name == estilo_selecionado }
        if estilo_objeto
            model.styles.selected_style = estilo_objeto
        else
            UI.messagebox("Estilo '#{estilo_selecionado}' não encontrado no modelo.")
        end

        # Finalizar com zoom e update
        model.active_view.zoom_extents
        cena.update
    end

    # -------------------------------------------------------------------------

    def self.adicionar_imagem

        # Obtém o modelo ativo
        model = Sketchup.active_model

        # Define o prefixo para o nome da cena
        prefixo = "imag "

        # Encontra o próximo número sequencial disponível
        numero_cena = (1..Float::INFINITY).find do |numero|
        nome_cena = "#{prefixo}#{format('%02d', numero)}"
        !model.pages.find { |cena| cena.name.downcase == nome_cena }
        end

        # Define o nome da cena com o número sequencial encontrado
        nome_cena = "#{prefixo}#{format('%02d', numero_cena)}"

        # Adiciona a cena com o nome sequencial ao modelo
        model.pages.add(nome_cena)

        # Atualiza a visualização para refletir a mudança
        Sketchup.active_model.active_view.refresh


    end

    def self.atualizar_cena_selecionada_imagem
        model = Sketchup.active_model
        cena = model.pages.selected_page
        return UI.messagebox("Nenhuma cena selecionada.") unless cena

        # Pré-carregar os estilos necessários
        estilos('FM_IMAGENS_VISTAS')
        estilos('FM_IMAGENS_CORTES')
        estilos('FM_IMAGENS_CORTES_AO')
        estilos('FM_IMAGENS_VISTAS_AO')

        # Escolha do tipo de renderizador
        opcoes_render = ["Enscape", "Vray", "Skt"]
        escolha_render = UI.inputbox(
            ["Escolha o tipo de renderizador:"],
            [opcoes_render[0]],
            ["#{opcoes_render.join('|')}"],
            "Atualizar Cena"
        )
        return unless escolha_render
        tipo_escolhido = escolha_render[0].upcase

        # Escolha do estilo de visualização
        estilos_disponiveis = {
            "Vistas" => 'FM IMAGENS VISTAS',
            "Cortes" => 'FM IMAGENS CORTES',
            "Vistas AO" => 'FM IMAGENS VISTAS AO',
            "Cortes AO" => 'FM IMAGENS CORTES AO'
        }

        opcoes_estilo = estilos_disponiveis.keys
        escolha_estilo = UI.inputbox(
            ["Escolha o estilo de visualização:"],
            [opcoes_estilo[0]],
            ["#{opcoes_estilo.join('|')}"],
            "Escolher Estilo"
        )
        return unless escolha_estilo
        estilo_selecionado = estilos_disponiveis[escolha_estilo[0]]

        # Mapas de etiquetas a ocultar
        etiquetas_por_tipo = {
            "VRAY" => ["ENSCAPE", "HACHURA"],
            "ENSCAPE" => ["VRAY", "HACHURA"],
            "SKT" => ["ENSCAPE", "VRAY"]
        }

        etiquetas_ocultas_extras = ["ESCALA", "CIVIL", "LEGENDA", "ZOOM", "2D"]
        etiquetas_pontos_tecnicos = ["-TECNICO-PONTO HIDRO", "-TECNICO-PONTO ILUMINACAO"]

        # Mostrar tudo primeiro
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }

        camadas = model.layers.to_a
        camadas.each { |camada| camada.visible = true }

        # Ocultar camadas com base nas escolhas
        etiquetas_a_ocultar = (etiquetas_por_tipo[tipo_escolhido] || []) + etiquetas_ocultas_extras
        camadas.each do |camada|
            camada.visible = false if etiquetas_a_ocultar.any? { |nome| camada.name.include?(nome) }
        end

        etiquetas_pontos_tecnicos.each do |nome_camada|
            camada = camadas.find { |c| c.name == nome_camada }
            camada.visible = false if camada
        end

        # Aplicar estilo
        estilo_objeto = model.styles.to_a.find { |s| s.name == estilo_selecionado }
        if estilo_objeto
            model.styles.selected_style = estilo_objeto
        else
            UI.messagebox("Estilo '#{estilo_selecionado}' não encontrado no modelo.")
        end

        # Finalizar com zoom e update
        cena.update
    end

    def self.exportar_imagens

        FM::ExportarImagens.mostrar_janela

    end  
    
    def self.aplicar_sombra
        model = Sketchup.active_model
        shadow_info = model.shadow_info
        page = model.pages.selected_page

        shadow_info["DisplayShadows"] = false        # NÃO exibir sombras visuais
        shadow_info["UseSunForAllShading"] = true   # Ativa sombreamento solar para todas as faces
        shadow_info["Light"] = 0                     # Luz clara
        shadow_info["Dark"] = 80                     # Sombra escura

        # Ajuste de data e hora para o sombreamento solar
        shadow_info["ShadowTime"] = Time.new(2025, 11, 8, 10, 30, 0)
        shadow_info["ShadowDate"] = Date.new(2025, 11, 8)

        # Força a cena atual a atualizar e refletir as configurações
        if page
        page.use_shadow_info = true
        page.update
        UI.messagebox("Configurações aplicadas e cena '#{page.name}' atualizada.")
        else
        UI.messagebox("Nenhuma cena ativa para atualizar.")
        end
    end

    # -------------------------------------------------------------------------
    
    def self.criar_cortes_padroes
        estilos('FM_PLANTAS')
        estilos('FM_PLANTAS_PB')

        cortes = {
            'a' => [[0, 40, 0], [0, 1, 0]],
            'b' => [[40, 0, 0], [1, 0, 0]],
            'c' => [[0, 80, 0], [0, -1, 0]],
            'd' => [[80, 0, 0], [-1, 0, 0]]
        }

        cortes.each do |nome, (pos, dir)|
            criar_ou_atualizar_corte(nome, pos, dir)
        end

        model = Sketchup.active_model
        entidades = model.entities
        cena_planos = model.pages.find { |cena| cena.name.downcase == 'planos' }
        model.pages.selected_page = cena_planos

    end

    def self.atualizar_todos_cortes
        model = Sketchup.active_model
        pages = model.pages
        camadas = model.layers.to_a

        grupos_ocultar = %w[2D LINEAR ESCALA ADORNO SPOTLIGTH VISTA EXTERNO XREF CIVIL OUTRO EXTERIOR LEGENDA GUIA CIRCUITOS]
        camadas_ocultas = ['-TECNICO-PONTO ILUMINACAO', '-2D-LEGENDA AMBIENTE', '-ZOOM-MARGEM', '-TECNICO-PONTO HIDRO', '-TERRENO-VIZINHOS', '-TERRENO-ESTRADA']
        camadas_visiveis = ['-ILUMINACAO-HACHURA LUZ LINEAR']

        pages.each do |cena|
            nome = cena.name.downcase

            # Só atualiza cenas com nome de uma única letra
            if nome.match?(/\A[a-z]\z/)
            pages.selected_page = cena

            remover_ocultamentos(model)
            aplicar_visibilidades(camadas, grupos_ocultar, camadas_ocultas, camadas_visiveis)

            model.styles.selected_style = model.styles['FM_PLANTAS'] if model.styles['FM_PLANTAS']

            model.active_view.zoom_extents
            cena.update

            puts "Cena #{nome.upcase} atualizada com sucesso."
            end
        end

        UI.messagebox("Todas os cortes foram atualizados.")
    end


    def self.criar_ou_atualizar_corte(name, position, direction)
        model = Sketchup.active_model
        pages = model.pages
        camadas = model.layers.to_a
        cena = pages.find { |c| c.name.downcase == name.downcase }

        grupos_ocultar = %w[2D LINEAR ESCALA ADORNO SPOTLIGTH VISTA EXTERNO XREF CIVIL OUTRO EXTERIOR LEGENDA GUIA CIRCUITOS]
        camadas_ocultas = ['-TECNICO-PONTO ILUMINACAO', '-2D-LEGENDA AMBIENTE', '-ZOOM-MARGEM', '-TECNICO-PONTO HIDRO', '-TERRENO-VIZINHOS', '-TERRENO-ESTRADA']
        camadas_visiveis = ['-ILUMINACAO-HACHURA LUZ LINEAR']

        eye = direction.map { |v| v * -1000 }
        target = [0, 0, 0]
        up = [0, 0, 1]

        if cena
            pages.selected_page = cena
            remover_ocultamentos(model)
            aplicar_camera(model, eye, target, up)
            aplicar_visibilidades(camadas, grupos_ocultar, camadas_ocultas, camadas_visiveis)
            model.styles.selected_style = model.styles['FM_PLANTAS']
            model.active_view.zoom_extents
            cena.update
            UI.messagebox("Cena #{name.upcase} já existia e foi atualizada.")
        else
            remover_ocultamentos(model)
            sp = model.entities.add_section_plane(position, direction)
            sp.name = name
            sp.activate
            nova_cena = pages.add(name)
            pages.selected_page = nova_cena
            aplicar_camera(model, eye, target, up)
            aplicar_visibilidades(camadas, grupos_ocultar, camadas_ocultas, camadas_visiveis)
            model.styles.selected_style = model.styles['FM_PLANTAS']
            model.active_view.zoom_extents
            nova_cena.update
            UI.messagebox("Cena #{name.upcase} criada com sucesso!")
        end
    end

    def self.remover_ocultamentos(model)
        model.entities.each { |ent| ent.hidden = false if ent.hidden? }
        end

        def self.aplicar_camera(model, eye, target, up)
        camera = Sketchup::Camera.new(eye, target, up, true)
        camera.perspective = false
        model.active_view.camera = camera
        end

        def self.aplicar_visibilidades(camadas, grupos_ocultar, camadas_ocultas, camadas_visiveis)
        camadas.each { |cam| cam.visible = true }

        camadas.each do |camada|
            camada.visible = false if grupos_ocultar.any? { |filtro| camada.name.include?(filtro) }
        end

        camadas_ocultas.each do |nome|
            camada = camadas.find { |c| c.name == nome }
            camada.visible = false if camada
        end

        camadas_visiveis.each do |nome|
            camada = camadas.find { |c| c.name == nome }
            camada.visible = true if camada
        end
    end

    def self.corte_individual
        estilos('FM_PLANTAS')
    
        result = UI.inputbox(['Selecione uma opção'], ['Frente|Esquerda|Voltar|Direita'], ['Frente|Esquerda|Voltar|Direita'])
    
        # Verifica se houve uma seleção
        if result
            opcao_selecionada = result[0].split('|').first
            nome = UI.inputbox(['Digite um nome para a cena:'], [''])[0]
    
            # Mapeamento das opções para os cortes correspondentes
            case opcao_selecionada
            when 'Frente'
                corte_abcd_4('a', [0, 40, 0], [0, 1, 0], nome)
            when 'Esquerda'
                corte_abcd_4('b', [40, 0, 0], [1, 0, 0], nome)
            when 'Voltar'
                corte_abcd_4('c', [0, 80, 0], [0, -1, 0], nome)
            when 'Direita'
                corte_abcd_4('d', [80, 0, 0], [-1, 0, 0], nome)
            else
                UI.messagebox('Opção inválida.')
            end
        else
            UI.messagebox('Nenhuma opção selecionada.')
        end
    end
    
    def self.corte_abcd_4(name, position, direction, nome)
        model = Sketchup.active_model
        entidades = model.entities
    
        # Adicionar plano de seção
        sp = entidades.add_section_plane(position, direction)
        sp.name = nome
        sp.activate
    
        # Adicionar cena
        model.pages.add(sp.name)
    
        # Configurar a vista
        eye = [direction[0] * -1000, direction[1] * -1000, direction[2] * -1000]
        target = [0, 0, 0]
        up = [0, 0, 1]
    
        model.active_view.camera = Sketchup::Camera.new(eye, target, up, true)
        model.active_view.camera.perspective = false
        model.active_view.zoom_extents
    
        # Configurar camadas e estilos da cena
        cena = Sketchup.active_model.pages.selected_page
        camadas = model.layers.to_a
        camadas.each { |camada| camada.visible = true }
    
        # Ocultar camadas e estilos específicos
        grupos_ocultar = ['2D', "MARGEM",'LINEAR','ESCALA', 'ADORNO', 'SPOTLIGTH', 'VISTA', 'ESCALA', 'EXTERNO', 
        'XREF', 'CIVIL', 'OUTRO', 'EXTERIOR', 'LEGENDA', 'GUIA','CIRCUITOS']
        camadas.each { |camada| camada.visible = false if grupos_ocultar.any? { |item| camada.name.include?(item) } }

        camadas_ocultas = ['-TECNICO-PONTO ILUMINACAO','-2D-LEGENDA AMBIENTE','-ZOOM-MARGEM','-TECNICO-PONTO HIDRO']
            camadas_ocultas.each do |nome_camada|
                camada = camadas.find { |c| c.name == nome_camada }
                camada.visible = false if camada
            end
            cena.update 
    
    
        model.styles.selected_style = model.styles['FM_PLANTAS']
        model.active_view.zoom_extents
        cena.update

        model = Sketchup.active_model
        entidades = model.entities
        cena_planos = model.pages.find { |cena| cena.name.downcase == 'planos' }
        model.pages.selected_page = cena_planos

        UI.messagebox("Cena criada com sucesso!")

    end

    def self.cortes_tecnicos
        # Pega o modelo atual
        model = Sketchup.active_model
      
        # Para cada letra de 'a' até 'm'
        ('a'..'m').each do |letra|
          # Localiza a cena base com nome igual à letra
          cena_base = model.pages.find { |cena| cena.name.downcase == letra }
      
          # Se existir, cria/atualiza a cena TEC
          if cena_base
            corte_tec(cena_base, "#{letra} tec")
          end
        end
      end
      
      def self.corte_tec(cena_base, cena_nova_nome)
        model = Sketchup.active_model
      
        # Seleciona a cena base (para herdar câmera, seção etc. se for esse o intuito)
        model.pages.selected_page = cena_base
      
        # Verifica se a cena nova (por exemplo, "a tec") já existe
        cena_nova = model.pages.find { |pg| pg.name.downcase == cena_nova_nome.downcase }
      
        # Se não existe, cria. Se já existe, só seleciona para atualizar.
        if cena_nova
          model.pages.selected_page = cena_nova
        else
          cena_nova = model.pages.add(cena_nova_nome)
          model.pages.selected_page = cena_nova
        end
      
        # A partir daqui, 'cena_nova' é a cena ativa, então ajustamos camadas e estilo
        cena = model.pages.selected_page
        camadas = model.layers.to_a
      
        # 1) Deixar todas as camadas visíveis inicialmente
        camadas.each { |camada| camada.visible = true }
        cena.update
      
        # 2) Ocultar grupos/camadas que não queremos ver
        grupos_ocultar = [
          '2D', 'MARGEM', 'REGISTRO', 'BANHEIRO', 'HACHURA', 
          'ESCALA', 'XREF', 'CIVIL', 'OUTRO',
          'SPOTLIGTH', 'EXTERNO', 'RODAPE', 'MARCENARIA',
          'MARMORARIA', 'INTERIORES','CIRCUITOS'
        ]
        camadas.each do |camada|
          camada.visible = false if grupos_ocultar.any? { |item| camada.name.include?(item) }
        end
        cena.update

        camadas_ocultas = ['-ILUMINACAO-HACHURA LUZ LINEAR', '-BANHEIRO-TOALHEIRO', '-TERRENO-VIZINHOS', '-TERRENO-ESTRADA']

        camadas_ocultas.each do |nome_camada|
        camada = camadas.find { |c| c.name == nome_camada }
        camada.visible = false if camada
        end

        cena.update

        # 4) Ajustar estilo
        model.styles.selected_style = model.styles['FM_PLANTAS']
        model.active_view.zoom_extents
        cena.update

        UI.messagebox("Cena criada ou atualizada com sucesso!")

    end
# -------------------------------------------------------------------------

    def self.gerar_fachadas
        model = Sketchup.active_model
        estilos('FM_VISTAS')
        estilos('FM_VISTAS_PB')

        # Ir para a cena de base 'geral'
        cena_base = model.pages.find { |c| c.name.downcase == 'geral' }
        model.pages.selected_page = cena_base if cena_base

        # Direções das vistas
        vistas = {
            "frente"    => [0, -1000, 0],
            "posterior" => [0, 1000, 0],
            "direita"   => [1000, 0, 0],
            "esquerda"  => [-1000, 0, 0],
            "cobertura" => [0, 0, 1000]
        }

        # Direção "para cima" da câmera para cada vista
        up_direcoes = {
            "frente"    => [0, 0, 1],
            "posterior" => [0, 0, 1],
            "direita"   => [0, 0, 1],
            "esquerda"  => [0, 0, 1],
            "cobertura" => [0, 1, 0]
        }

        vistas.each do |nome, direcao|
            cena_existente = model.pages.find { |c| c.name.downcase == nome }

            unless cena_existente
            eye = direcao
            target = [0, 0, 0]
            up = up_direcoes[nome]

            camera = Sketchup::Camera.new(eye, target, up, true)
            camera.perspective = false
            model.active_view.camera = camera
            end

            model.active_view.zoom_extents

            # Mostrar todos os elementos e camadas antes de ocultar o que precisa
            model.entities.each { |ent| ent.hidden = false if ent.hidden? }

            camadas = model.layers.to_a
            camadas.each { |camada| camada.visible = true }

            grupos_ocultar = ['2D','VIZINHOS','LINEAR','ESCALA','ADORNO','SPOTLIGTH','VISTA','EXTERNO','XREF','CIVIL','OUTRO','EXTERIOR','LEGENDA','GUIA','CIRCUITOS']
            camadas.each do |camada|
            camada.visible = false if grupos_ocultar.any? { |item| camada.name.include?(item) }
            end

            camadas_ocultas = ['-TECNICO-PONTO ILUMINACAO','-2D-LEGENDA AMBIENTE','-ZOOM-MARGEM','-TECNICO-PONTO HIDRO','-TERRENO-ESTRADA']
            camadas_ocultas.each do |nome_camada|
            camada = camadas.find { |c| c.name == nome_camada }
            camada.visible = false if camada
            end

            camadas_visiveis = ['-ILUMINACAO-HACHURA LUZ LINEAR']
            camadas_visiveis.each do |nome_camada|
            camada = camadas.find { |c| c.name == nome_camada }
            camada.visible = true if camada
            end

            estilo = model.styles.find { |s| s.name == 'FM IMAGENS VISTAS' }
            model.styles.selected_style = estilo if estilo

            model.active_view.zoom_extents

            if cena_existente
            model.pages.selected_page = cena_existente
            cena_existente.update
            puts "Cena '#{nome}' atualizada."
            else
            nova_cena = model.pages.add(nome)
            model.pages.selected_page = nova_cena
            nova_cena.update
            puts "Cena '#{nome}' criada."
            end
        end
    end

    def self.atulizar_cortes_arq
        model = Sketchup.active_model
        pages = model.pages
        cena = pages.selected_page

        estilos('FM_PLANTAS_PB')

        if cena
        # Torna todas as camadas visíveis
        camadas = model.layers.to_a
        camadas.each { |camada| camada.visible = true }

        # Oculta camadas por grupos
        grupos_ocultar = ['2D', 'ESCALA', 'ADORNO', 'SPOTLIGTH', 'VISTA', 'XREF', 'CIVIL', 'OUTRO', 'LEGENDA', 'GUIA', 'CIRCUITOS']
        camadas.each do |camada|
            camada.visible = false if grupos_ocultar.any? { |item| camada.name.include?(item) }
        end

        # Camadas específicas a ocultar
        camadas_ocultas = ['-TECNICO-PONTO ILUMINACAO', '-2D-LEGENDA AMBIENTE', '-ZOOM-MARGEM', '-TECNICO-PONTO HIDRO', '-TERRENO-ESTRADA']
        camadas_ocultas.each do |nome_camada|
            camada = camadas.find { |c| c.name == nome_camada }
            camada.visible = false if camada
        end

        # Camadas específicas a mostrar
        camadas_visiveis = ['-ILUMINACAO-HACHURA LUZ LINEAR']
        camadas_visiveis.each do |nome_camada|
            camada = camadas.find { |c| c.name == nome_camada }
            camada.visible = true if camada
        end

        model.active_view.zoom_extents

        # Atualiza a cena
        cena.update

        # Renomeia somente se ainda não terminar com 'arq' (minúsculo ou maiúsculo, com ou sem espaço)
        unless cena.name.strip.downcase.end_with?("arq")
            cena.name = "#{cena.name.strip} arq"
        end

        model.styles.selected_style = model.styles['FM PLANTAS PB']
        model.active_view.zoom_extents
        cena.update

        UI.messagebox("Cena atualizada e nome final: '#{cena.name}'.")
        else
        UI.messagebox("Nenhuma cena selecionada.")
        end

    end

    def self.detalhes_extras

        model = Sketchup.active_model
        entities = model.active_entities
        selection = model.selection

        selection.invert

        model = Sketchup.active_model
        selection = model.selection

        selection.each do |entity|
        # Define a entidade como oculta
        entity.hidden = true
        end

        selection = model.selection

        selection.clear

        nome = UI.inputbox(['Digite um nome para a cena:'], [''])[0]

        nova_cena = model.pages.add(nome)

        #configurar estilo da cena
        model.styles.selected_style = model.styles['FM VISTAS']

        model.active_view.zoom_extents

        # Atualiza a cena
        nova_cena.update

        model = Sketchup.active_model
        model.active_path = nil

        UI.messagebox("Cena de delalhe criado com sucesso!")

    end


    def self.hide_door

        model = Sketchup.active_model
        entities = model.active_entities

         # Obter a lista de camadas
        camadas = model.layers

        # Obter a cena atual
        cena = model.pages.selected_page

        # Verificar se a camada '-MARCENARIA-PORTA' existe
        camada_marcenaria_porta = camadas.find { |c| c.name == '-MARCENARIA-PORTA' }

        # Se a camada existir, alternar a visibilidade
        if camada_marcenaria_porta
        if camada_marcenaria_porta.visible?
            camada_marcenaria_porta.visible = false # Se estiver visível, ocultar
        else
            camada_marcenaria_porta.visible = true # Se estiver oculta, reexibir
        end
        end


    end

    def self.perspectivetoggle
        model = Sketchup.active_model
        view = model.active_view
        
        # Define os ângulos de câmera possíveis
        angles = [
          [1000, 1000, 1000],
          [-1000, -1000, 1000],
          [-1000, 1000, 1000],
          [1000, -1000, 1000]
        ]
        
        # Armazena o índice atual em uma variável global ou de classe para persistir entre execuções
        @camera_index ||= 0
        
        # Define o próximo ângulo de câmera
        next_index = (@camera_index + 1) % angles.length
        next_eye = angles[next_index]
        
        # Define a nova câmera
        my_camera = Sketchup::Camera.new(next_eye, [0, 0, 0], [0, 0, 1])
        view.camera = my_camera
        
        # Ajusta a perspectiva
        view.camera.perspective = false
        
        # Dá um zoom extents
        view.zoom_extents
        
        # Atualiza a página selecionada
        selected_page = model.pages.selected_page
        selected_page.update if selected_page

        grupos_ocultar = ["TETO", "BANHEIRO", "2D", "COBERTURA", "ADORNO", "ILUMINACAO", "TECNICO",
                            "EXTERNO", "XREF", "CIVIL", "RODAPE", "INTERIORES", "EXTERIOR", "OUTRO"]

        camadas_visiveis = ['-INTERIORES-ELETRO (AEREO)','-INTERIORES-ELETRO (MARMORARIA)','-INTERIORES-ELETRO (PISO)','-INTERIORES-ELETRO (MARCENARIA)','-RODAPE-BASE ALVENARIA','-RODAPE-MARMORARIA',
                    '-MARCENARIA-AEREO','-MARCENARIA-GERAL','-MARCENARIA-PORTA','-MARMORARIA-BANCADA','-MARMORARIA-CUBA E METAIS']

        camadas_ocultas = ['-2D-ETIQUETAS''-TERRENO-VIZINHOS', '-TERRENO-ESTRADA']

        aplicar_visibilidade(grupos_ocultar, camadas_ocultas, camadas_visiveis)

        selected_page.update
        
        # Atualiza o índice da câmera
        @camera_index = next_index
        
    end

    def self.importar_margem

        blocks_dir  = File.join(__dir__, "blocos")
        blocks_dir  = blocks_dir.dup.force_encoding('UTF-8')
      
        # Nome fixo do bloco
        block_path = File.join(blocks_dir, "margem.skp").dup.force_encoding('UTF-8')
      
        if File.exist?(block_path)
          model       = Sketchup.active_model
          definitions = model.definitions
          definition  = definitions.load(block_path, allow_newer: true)
          model.place_component(definition) if definition.is_a?(Sketchup::ComponentDefinition)
        else
          UI.messagebox("Bloco não encontrado: #{block_path}")
        end
    end
      

    # 3) MÉTODO QUE ABRE O DIALOG HTML
    # -------------------------------------------------------------------------
    def self.abrir_janela_html
      # Para SketchUp 2017+ use HtmlDialog. Se for versão antiga, mude para WebDialog.
      dlg = UI::HtmlDialog.new(
        {
          :dialog_title    => "FM - Sketchup Inteligente",
          :preferences_key => "fm_extensao_html",
          :scrollable      => true,
          :resizable       => false,
          :width           => 300,
          :height          => 700
        }
      )

      # Aponta para o arquivo interface.html na pasta HTML
      caminho_html = File.join(__dir__, "HTML", "interface.html")
      dlg.set_file(caminho_html)

      # REGISTRA OS CALLBACKS: nome em JavaScript => método Ruby

      
        dlg.add_action_callback("atualizar_imagem") do |_dialog, _params|
        self.atualizar_cena_selecionada_imagem
      end

      dlg.add_action_callback("criar_camadas_padrao") do |_dialog, _params|
        self.criar_camadas_padrao
      end

      dlg.add_action_callback("cenas_zoom") do |_dialog, _params|
        self.cenas_zoom
      end

      dlg.add_action_callback("cena_geral") do |_dialog, _params|
        self.cena_geral
      end

      dlg.add_action_callback("cena_desenhar") do |_dialog, _params|
        self.cena_desenhar
      end

      dlg.add_action_callback("cena_etiquetar") do |_dialog, _params|
        self.cena_etiquetar
      end

      dlg.add_action_callback("cena_planos") do |_dialog, _params|
        self.cena_planos
      end

      dlg.add_action_callback("cena_base") do |_dialog, _params|
        self.cena_base
      end

      dlg.add_action_callback("cena_arq") do |_dialog, _params|
        self.cena_arq
      end

      dlg.add_action_callback("cena_arq_piso") do |_dialog, _params|
        self.cena_arq_piso
      end

      dlg.add_action_callback("cena_mobi") do |_dialog, _params|
        self.cena_mobi
      end

      dlg.add_action_callback("cena_construir") do |_dialog, _params|
        self.cena_construir
      end

      dlg.add_action_callback("cena_demolir") do |_dialog, _params|
        self.cena_demolir
      end

      dlg.add_action_callback("cena_drywall") do |_dialog, _params|
        self.cena_drywall
      end

      dlg.add_action_callback("cena_civil") do |_dialog, _params|
        self.cena_civil
      end

      dlg.add_action_callback("cena_layout") do |_dialog, _params|
        self.cena_layout
      end

      dlg.add_action_callback("cena_pontostec") do |_dialog, _params|
        self.cena_pontostec
      end

      dlg.add_action_callback("cena_eletrica") do |_dialog, _params|
        self.cena_eletrica
      end

      dlg.add_action_callback("cena_hidro") do |_dialog, _params|
        self.cena_hidro
      end

      dlg.add_action_callback("cena_climatizacao") do |_dialog, _params|
        self.cena_climatizacao
      end

      dlg.add_action_callback("cena_iluminacao") do |_dialog, _params|
        self.cena_iluminacao
      end

      dlg.add_action_callback("cena_iluminacao_cir") do |_dialog, _params|
        self.cena_iluminacao_cir
      end

      dlg.add_action_callback("cena_forro") do |_dialog, _params|
        self.cena_forro
      end

      dlg.add_action_callback("cena_forro_cores") do |_dialog, _params|
        self.cena_forro_cores
      end

      dlg.add_action_callback("cena_revestimentos") do |_dialog, _params|
        self.cena_revestimentos
      end

      dlg.add_action_callback("cena_marcenaria") do |_dialog, _params|
        self.cena_marcenaria
      end

      dlg.add_action_callback("cena_marmoraria") do |_dialog, _params|
        self.cena_marmoraria
      end

      dlg.add_action_callback("isolar_marcenaria") do |_dialog, _params|
        self.isolar_marcenaria
      end

      dlg.add_action_callback("detalhamento_marcenaria") do |_dialog, _params|
        self.detalhamento_marcenaria
      end

      dlg.add_action_callback("detalhes_extras") do |_dialog, _params|
        self.detalhes_extras
      end

      dlg.add_action_callback("duplicar_cenas") do |_dialog, _params|
        self.duplicar_cenas
      end

      dlg.add_action_callback("duplicar_cenas_cortes") do |_dialog, _params|
        self.duplicar_cenas_cortes
      end

      dlg.add_action_callback("imagem_inicial") do |_dialog, _params|
        self.imagem_inicial
      end

      dlg.add_action_callback("adicionar_imagem") do |_dialog, _params|
        self.adicionar_imagem
      end

      dlg.add_action_callback("exportar_imagens") do |_dialog, _params|
        self.exportar_imagens
      end

      dlg.add_action_callback("aplicar_sombra") do |_dialog, _params|
        self.aplicar_sombra
      end


      dlg.add_action_callback("criar_cortes_padroes") do |_dialog, _params|
        self.criar_cortes_padroes
        end

        dlg.add_action_callback("atualizar_todos_cortes") do |_dialog, _params|
        self.atualizar_todos_cortes
        end

      dlg.add_action_callback("cortes_tecnicos") do |_dialog, _params|
        self.cortes_tecnicos
      end

      dlg.add_action_callback("corte_individual") do |_dialog, _params|
        self.corte_individual
      end

      dlg.add_action_callback("detalhamento") do |_dialog, _params|
        self.detalhamento
      end

      dlg.add_action_callback("perspectivetoggle") do |_dialog, _params|
        self.perspectivetoggle
      end

      dlg.add_action_callback("hide_door") do |_dialog, _params|
        self.hide_door
      end

      dlg.add_action_callback("importar_margem") do |_dialog, _params|
        self.importar_margem
      end

      dlg.add_action_callback("gerar_fachadas") do |_dialog, _params|
        self.gerar_fachadas
      end

      dlg.add_action_callback("atu_cortes_arq") do |_dialog, _params|
        self.atulizar_cortes_arq
      end

      dlg.show
    end

    # -------------------------------------------------------------------------
    # 4) CRIA SÓ UM BOTÃO NA TOOLBAR, QUE ABRE O DIALOG
    # -------------------------------------------------------------------------
    unless @toolbar_loaded
      @toolbar_loaded = true

      toolbar = UI::Toolbar.new("FM - Sketchup Inteligente".dup.force_encoding('UTF-8'))

      cmd = UI::Command.new("Menu") {
        self.abrir_janela_html
      }

      # Ajuste o ícone caso queira exibir alguma imagem
      icone = File.join(__dir__, "icones", "menu.png")
      if File.exist?(icone)
        cmd.small_icon = icone
        cmd.large_icon = icone
      end

      cmd.tooltip         = "Abrir Menu"
      cmd.status_bar_text = "Abre a janela com todos os comandos para projeto de interiores"
      cmd.menu_text       = "Menu"

      toolbar.add_item(cmd)

      ##### 

      cmd = UI::Command.new("Ocultar Portas") {
        self.hide_door
      }

      # Ajuste o ícone caso queira exibir alguma imagem
      icone = File.join(__dir__, "icones", "porta.png")
      if File.exist?(icone)
        cmd.small_icon = icone
        cmd.large_icon = icone
      end

      cmd.tooltip         = "Ocultar e Reexibir Portas"
      cmd.status_bar_text = "Ocultar e reexibir portas que estão etiquetadas corretamente."
      cmd.menu_text       = "Ocultar Portas"

      toolbar.add_item(cmd)

      cmd = UI::Command.new("Exportar LayOut") {
        self.abrir_janela_exportar_layout # Esse método está definido no outro arquivo
        }

        icone = File.join(__dir__, "icones", "exporte.png") # ou o nome do ícone que você tiver
        if File.exist?(icone)
        cmd.small_icon = icone
        cmd.large_icon = icone
        end

        cmd.tooltip         = "Exportar para LayOut"
        cmd.status_bar_text = "Abre a janela de exportação para LayOut"
        cmd.menu_text       = "Exportar LayOut"

        toolbar.add_item(cmd)



      toolbar.show
    end

  end # module ExtensaoSkp
end # module FM
