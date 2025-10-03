# encoding: UTF-8
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../pro_hover_face_util.rb' 
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProCeilingAnnotation
      include ProjetaPlus::Modules::ProHoverFaceUtil 

      DEFAULT_CEILING_ANNOTATION_SCALE = ProjetaPlus::Modules::ProSettingsUtils.get_scale
      DEFAULT_CEILING_ANNOTATION_FONT = ProjetaPlus::Modules::ProSettingsUtils.get_font
      DEFAULT_CEILING_ANNOTATION_FLOOR_LEVEL_STR = ProjetaPlus::Modules::ProSettingsUtils.get_floor_level

      METERS_PER_INCH = 0.0254

      def self.get_defaults
        {
          floor_level: Sketchup.read_default("AnotacaoForro", "floor_level", DEFAULT_CEILING_ANNOTATION_FLOOR_LEVEL_STR)
        }
      end

      # Adaptação de FM_Extensions::AnotacaoForro.test_text_inverted
      def self.test_text_inverted(text, position, scale, font, alignment = TextAlignCenter)
        model = Sketchup.active_model
        g = model.entities.add_group
        ents = g.entities
        height = 0.3.cm * scale # 0.3 cm como base para altura
        
        ents.add_3d_text(text, alignment, font, true, false, height, 0)
        
        black_material = model.materials['Black'] || model.materials.add('Black')
        black_material.color = 'black'
        ents.grep(Sketchup::Face).each { |f| f.material = f.back_material = black_material }
        
        g.transform!(Geom::Transformation.translation(position - g.bounds.center))
        
        # Inverter no eixo Z para ficar legível de baixo para cima
        # A inversão deve ocorrer após o posicionamento inicial
        bb = g.bounds
        pivot_z = bb.center.z # Ponto médio em Z do texto
        
        # Cria uma transformação de espelhamento no eixo Z, com pivô no centro Z do texto
        tr = Geom::Transformation.scaling(Geom::Point3d.new(bb.center.x, bb.center.y, pivot_z), 1, 1, -1)
        
        model.start_operation(ProjetaPlus::Localization.t("commands.ceiling_mirror_z_operation_name"), true)
        g.transform!(tr) # Aplica a transformação ao grupo

        # Inverte as faces para que fiquem visíveis após o espelhamento
        g.entities.grep(Sketchup::Face).each(&:reverse!)
        
        model.commit_operation
        g
      end

      def self.process_ceilling_face(face, path, args)
        model = Sketchup.active_model
        layer = model.layers.add('-ANOTACAO-FORRO')
        layer.color = Sketchup::Color.new(0, 0, 0) 

        # Extrai parâmetros dos args do frontend
        scale = args['scale'].to_f
        font = args['font'].to_s
        floor_level_str = args['floor_level'].to_s.tr(',', '.')
        floor_level = floor_level_str.to_f # Nível do piso em metros

        # Persist module-specific values
        Sketchup.write_default("AnotacaoForro", "floor_level", floor_level_str)

        # --------------------- Lógica de Área ---------------------
        area_inch = face.area
        area_m2 = area_inch * 0.00064516 # Converter polegadas² para metros²
        area_str = format('%.2f', area_m2).gsub('.', ',')

        # --------------------- Calcular Altura Z (PD) ---------------------
        # Pegar a transformação acumulada para coordenadas globais da face
        tr = Geom::Transformation.new
        path.each do |e|
          tr *= e.transformation if e.respond_to?(:transformation)
          break if e == face
        end
        
        # Pega um ponto da face e transforma para coordenadas globais
        face_point = face.vertices.first.position
        face_point_global = face_point.transform(tr)
        altura_face_m = face_point_global.z * METERS_PER_INCH # Altura da face em metros
        
        # Desconta o nível do piso para obter o Pé Direito (PD)
        pd_m = altura_face_m - floor_level
        pd_str = format('%.2f', pd_m).gsub('.', ',')

        texto = "#{ProjetaPlus::Localization.t("messages.area_label")}: #{area_str} m²\n#{ProjetaPlus::Localization.t("messages.pd_label")}: #{pd_str} m"

        # Calcular centro da face e posição do texto
        face_center_global = face.bounds.center.transform(tr)
        
        # Posição 5cm abaixo da face (em unidades internas do SketchUp)
        offset_z_internal = -5.0.cm # Convert 5cm to internal units (inches)
        text_position = Geom::Point3d.new(
          face_center_global.x,
          face_center_global.y,
          face_center_global.z + offset_z_internal
        )

        # Criar texto invertido
        text_group = test_text_inverted(texto, text_position, scale, font)
        text_group.layer = layer

        model.selection.clear
        model.selection.add(text_group)
        { success: true, message: ProjetaPlus::Localization.t("messages.ceiling_annotation_success") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_adding_ceiling_annotation") + ": #{e.message}" }
      end

      # --------------------- Ferramenta Interativa ---------------------
      class InteractiveCeilingAnnotationTool
        include ProjetaPlus::Modules::ProHoverFaceUtil # Inclui o utilitário de hover
        
        # 'cfg' agora contém os 'args' vindos do frontend
        def initialize(args)
          @args = args 
          @valid_pick = false
        end
        
        def activate
          Sketchup.set_status_text(ProjetaPlus::Localization.t("messages.ceiling_annotation_prompt"), SB_PROMPT)
          @view = Sketchup.active_model.active_view
        end
        
        def deactivate(view)
          view.invalidate
        end
        
        def onMouseMove(flags, x, y, view)
          update_hover(view, x, y)
          @valid_pick = @hover_face && @path
          view.invalidate
        end
        
        def draw(view)
          draw_hover(view)
        end
        
        def onLButtonDown(flags, x, y, view)
          return unless @valid_pick
          
          model = Sketchup.active_model
          model.start_operation(ProjetaPlus::Localization.t("commands.ceiling_annotation_operation_name"), true)
          
          result = ProjetaPlus::Modules::ProCeilingAnnotation.process_ceilling_face(@hover_face, @path, @args)
          if result[:success]
            model.commit_operation
            ::UI.messagebox(ProjetaPlus::Localization.t("messages.ceiling_annotation_success"), MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          else
            model.abort_operation
            ::UI.messagebox(result[:message], MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          end
          Sketchup.active_model.select_tool(nil)
        rescue StandardError => e
          model.abort_operation
          ::UI.messagebox("#{ProjetaPlus::Localization.t("messages.unexpected_error")}: #{e.message}", MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          Sketchup.active_model.select_tool(nil)
        end
        
        def onKeyDown(key, repeat, flags, view)
          if key == VK_ESCAPE
            Sketchup.active_model.select_tool(nil)
          end
        end
      end

      def self.start_interactive_annotation(args)
        if Sketchup.active_model.nil?
          return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") }
        end
        Sketchup.active_model.select_tool(InteractiveCeilingAnnotationTool.new(args))
        { success: true, message: ProjetaPlus::Localization.t("messages.ceiling_tool_activated") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_activating_tool") + ": #{e.message}" }
      end

    end # module ProCeilingAnnotation
  end # module Modules
end # module ProjetaPlus