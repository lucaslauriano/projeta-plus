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

      METERS_PER_INCH = 0.0254
      TEXT_HEIGHT_SCALE = 0.3.cm
      TEXT_OFFSET_FROM_CEILING = -5.0.cm
      PREFERENCE_KEY = "AnotacaoForro"

      # Cria texto 3D invertido no eixo Z para ser legível de baixo para cima
      def self.create_inverted_text(text, position, scale, font, alignment = TextAlignCenter)
        model = Sketchup.active_model
        text_group = model.entities.add_group
        
        # Adiciona texto 3D preto
        add_3d_text_to_group(text_group, text, scale, font, alignment)
        
        # Posiciona o texto no centro desejado
        text_group.transform!(Geom::Transformation.translation(position - text_group.bounds.center))
        
        # Inverte o texto no eixo Z para ficar legível de baixo
        mirror_text_on_z_axis(text_group)
        
        text_group
      end

      # Adiciona texto 3D preto ao grupo
      def self.add_3d_text_to_group(group, text, scale, font, alignment)
        height = TEXT_HEIGHT_SCALE * scale
        group.entities.add_3d_text(text, alignment, font, true, false, height, 0)
        
        black_material = Sketchup.active_model.materials['Black'] || 
                        Sketchup.active_model.materials.add('Black')
        black_material.color = 'black'
        
        group.entities.grep(Sketchup::Face).each do |face|
          face.material = face.back_material = black_material
        end
      end

      # Espelha o texto no eixo Z usando o centro do grupo como pivô
      def self.mirror_text_on_z_axis(text_group)
        bounds = text_group.bounds
        pivot_point = Geom::Point3d.new(bounds.center.x, bounds.center.y, bounds.center.z)
        mirror_transformation = Geom::Transformation.scaling(pivot_point, 1, 1, -1)
        
        text_group.transform!(mirror_transformation)
        text_group.entities.grep(Sketchup::Face).each(&:reverse!)
      end

      def self.process_ceilling_face(face, path, args)
        model = Sketchup.active_model
        layer = get_or_create_annotation_layer(model)
        
        scale = ProjetaPlus::Modules::ProSettingsUtils.get_scale
        font = ProjetaPlus::Modules::ProSettingsUtils.get_font
        floor_level = parse_floor_level(args['floor_level'])
        
        transformation = calculate_accumulated_transformation(path, face)
        area_text = calculate_area_text(face)
        ceiling_height_text = calculate_ceiling_height_text(face, transformation, floor_level)
        
        annotation_text = "#{area_text}\n#{ceiling_height_text}"
        text_position = calculate_text_position(face, transformation)
        
        text_group = create_inverted_text(annotation_text, text_position, scale, font)
        text_group.layer = layer

        model.selection.clear
        model.selection.add(text_group)
        
        { success: true, message: ProjetaPlus::Localization.t("messages.ceiling_annotation_success") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_adding_ceiling_annotation") + ": #{e.message}" }
      end

      # Obtém ou cria a camada de anotação de forro
      def self.get_or_create_annotation_layer(model)
        layer = model.layers.add('-ANOTACAO-FORRO')
        layer.color = Sketchup::Color.new(0, 0, 0)
        layer
      end

      # Converte string de nível do piso para float
      def self.parse_floor_level(floor_level_str)
        normalized_str = floor_level_str.to_s.tr(',', '.')
        normalized_str.to_f
      end

      # Calcula a transformação acumulada ao longo do caminho
      def self.calculate_accumulated_transformation(path, face)
        transformation = Geom::Transformation.new
        path.each do |entity|
          transformation *= entity.transformation if entity.respond_to?(:transformation)
          break if entity == face
        end
        transformation
      end

      # Calcula e formata o texto da área
      def self.calculate_area_text(face)
        area_m2 = face.area * 0.00064516 # Converte polegadas² para m²
        area_formatted = format('%.2f', area_m2).gsub('.', ',')
        "#{ProjetaPlus::Localization.t("messages.area_label")}: #{area_formatted} m²"
      end

      # Calcula e formata o texto da altura (Pé Direito)
      def self.calculate_ceiling_height_text(face, transformation, floor_level)
        face_point_global = face.vertices.first.position.transform(transformation)
        ceiling_height_m = face_point_global.z * METERS_PER_INCH
        pd_m = ceiling_height_m - floor_level
        pd_formatted = format('%.2f', pd_m).gsub('.', ',')
        "#{ProjetaPlus::Localization.t("messages.pd_label")}: #{pd_formatted} m"
      end

      # Calcula a posição do texto (5cm abaixo do centro da face)
      def self.calculate_text_position(face, transformation)
        face_center_global = face.bounds.center.transform(transformation)
        Geom::Point3d.new(
          face_center_global.x,
          face_center_global.y,
          face_center_global.z + TEXT_OFFSET_FROM_CEILING
        )
      end

      # Ferramenta interativa para anotar faces de forro/teto
      class InteractiveCeilingAnnotationTool
        include ProjetaPlus::Modules::ProHoverFaceUtil
        
        def initialize(args, dialog = nil)
          @args = args
          @dialog = dialog
          @valid_pick = false
        end
        
        def activate
          Sketchup.set_status_text(
            ProjetaPlus::Localization.t("messages.ceiling_annotation_prompt"), 
            SB_PROMPT
          )
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
          
          process_annotation_click
        end
        
        def onKeyDown(key, repeat, flags, view)
          deactivate_tool if key == VK_ESCAPE
        end

        private

        def process_annotation_click
          model = Sketchup.active_model
          model.start_operation(
            ProjetaPlus::Localization.t("commands.ceiling_annotation_operation_name"), 
            true
          )
          
          result = ProjetaPlus::Modules::ProCeilingAnnotation.process_ceilling_face(
            @hover_face, 
            @path, 
            @args
          )
          
          handle_result(result, model)
        rescue StandardError => e
          handle_error(e, model)
        end

        def handle_result(result, model)
          if result[:success]
            model.commit_operation
            show_success_message
          else
            model.abort_operation
            show_error_message(result[:message])
          end
          deactivate_tool
        end

        def handle_error(error, model)
          model.abort_operation
          error_message = "#{ProjetaPlus::Localization.t("messages.unexpected_error")}: #{error.message}"
          show_error_message(error_message)
          deactivate_tool
        end

        def show_success_message
          if @dialog
            @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.ceiling_annotation_success")}', 'success');")
          end
        end

        def show_error_message(message)
          if @dialog
            escaped_message = message.gsub("'", "\\\\'")
            @dialog.execute_script("showMessage('#{escaped_message}', 'error');")
          end
        end

        def deactivate_tool
          Sketchup.active_model.select_tool(nil)
        end
      end

      # Inicia a ferramenta interativa de anotação
      def self.start_interactive_annotation(args, dialog = nil)
        return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") } if Sketchup.active_model.nil?
        
        Sketchup.active_model.select_tool(InteractiveCeilingAnnotationTool.new(args, dialog))
        { success: true, message: ProjetaPlus::Localization.t("messages.ceiling_tool_activated") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_activating_tool") + ": #{e.message}" }
      end

    end # module ProCeilingAnnotation
  end # module Modules
end # module ProjetaPlus