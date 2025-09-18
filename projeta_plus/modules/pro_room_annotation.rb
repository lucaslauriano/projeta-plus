# encoding: UTF-8
require 'sketchup.rb'
require_relative 'pro_settings.rb' 
require_relative 'pro_settings_utils.rb'
require_relative 'pro_hover_face_util.rb'
require_relative '../localization.rb'

module ProjetaPlus
  module Modules
    module ProRoomAnnotation
      include ProjetaPlus::Modules::ProHoverFaceUtil 

      DEFAULT_ROOM_ANNOTATION_SCALE   = ProjetaPlus::Modules::ProSettingsUtils.get_scale
      DEFAULT_ROOM_ANNOTATION_FONT    = ProjetaPlus::Modules::ProSettingsUtils.get_font
      DEFAULT_ROOM_ANNOTATION_FLOOR_HEIGHT_STR = "0,00" 
      DEFAULT_ROOM_ANNOTATION_SHOW_CEILLING_HEIGHT = "Sim" 
      DEFAULT_ROOM_ANNOTATION_CEILLING_HEIGHT_STR  = "0,00" 
      DEFAULT_ROOM_ANNOTATION_SHOW_LEVEL = "Sim" 
      DEFAULT_ROOM_ANNOTATION_LEVEL_STR = "0,00" 

      METERS_PER_INCH = 0.0254

      def self.get_defaults
        {
          floor_height: Sketchup.read_default("RoomAnnotation", "floor_height", DEFAULT_ROOM_ANNOTATION_FLOOR_HEIGHT_STR),
          show_ceilling_height: Sketchup.read_default("RoomAnnotation", "show_ceilling_height", DEFAULT_ROOM_ANNOTATION_SHOW_CEILLING_HEIGHT),
          ceilling_height: Sketchup.read_default("RoomAnnotation", "ceilling_height", DEFAULT_ROOM_ANNOTATION_CEILLING_HEIGHT_STR),
          show_level: Sketchup.read_default("RoomAnnotation", "show_level", DEFAULT_ROOM_ANNOTATION_SHOW_LEVEL),
          level: Sketchup.read_default("RoomAnnotation", "level", DEFAULT_ROOM_ANNOTATION_LEVEL_STR)
        }
      end

      def self.calculate_area_of_group(group)
        total_area = 0.0
        group.entities.each do |entity|
          total_area += entity.area if entity.is_a?(Sketchup::Face)
        end
        total_area * 0.00064516 # convert to m²
      end

      def self.test_text(text, position, scale, font, alignment = TextAlignCenter)
        model = Sketchup.active_model
        g = model.entities.add_group
        ents = g.entities
        height = 0.3.cm * scale # 0.3 cm as base for height
        
        ents.add_3d_text(text, alignment, font, true, false, height, 0)
        
        black_material = model.materials['Black'] || model.materials.add('Black')
        black_material.color = 'black'
        ents.grep(Sketchup::Face).each { |f| f.material = f.back_material = black_material }
       
        g.transform!(Geom::Transformation.translation(position - g.bounds.center))
        g
      end

      def self.import_nivel_symbol(center, scale)
        model = Sketchup.active_model
        defs  = model.definitions
        
        candidates = []
        candidates << File.join(File.dirname(model.path), 'components', 'plan_level.skp') if model.path && !model.path.empty?
        candidates << File.join(ProjetaPlus::PATH, 'projeta_plus', 'components', 'plan_level.skp')
        
        # Finds the first existing path (first existing path)
        path = candidates.find { |p| File.exist?(p) }
        return nil unless path
        
        # Loads the definition if it is not already loaded (loads the definition if it 
        #is not already loaded)
        sym_def = defs.load(path)
        
        # Creates the instance and applies the scale transformation (creates the instance 
        #and applies the scale transformation)
        inst = model.entities.add_instance(sym_def, Geom::Transformation.translation(center))
        # The scale must be applied from the center of the instance so that it 
        # expands/contracts correctly (the scale must be applied from the center of the 
        #instance so that it expands/contracts correctly) (the scale must be applied 
        #from the center of the instance so that it expands/contracts correctly)
        inst.transform!(Geom::Transformation.scaling(inst.bounds.center, scale.to_f))
        inst
      end
      
      # Removed parse_num (use to_f directly, or methods of Localization)
      # Removed global_transformation e global_piso_z (simplest Bounds logic used in processar_grupo)
      # Removed coletar_config (settings come from Next.js)

      # Now accepts 'args' from the Next.js frontend.
      def self.processar_grupo(grupo, args, hover_face = nil, hover_extents = nil)
        model = Sketchup.active_model
        # Uses a layer '-2D-LEGENDA AMBIENTE' (Environment Legend)
        layer = model.layers.add('-2D-LEGENDA AMBIENTE')

        # Extracts parameters from the frontend args
        enviroment_name   = args['enviroment_name'].to_s
        scale           = args['scale'].to_f
        font            = args['font'].to_s
        show_ceilling_height      = args['show_ceilling_height'].to_s.strip.downcase == "sim"
        ceilling_height_str          = args['ceilling_height'].to_s
        mostrar_nivel   = args['show_level'].to_s.strip.downcase == "sim"
        manual_level    = args['level'].to_s # What was 'manual_level' is now 'level' in the UI
        
        # Persist module-specific values (Sketchup.read_default/write_default)
        # Note: scale and font are passed from the frontend, which may be using global values
        Sketchup.write_default("RoomAnnotation", "floor_height", args['floor_height'].to_s)
        Sketchup.write_default("RoomAnnotation", "show_ceilling_height", args['show_ceilling_height'].to_s)
        Sketchup.write_default("RoomAnnotation", "ceilling_height", args['ceilling_height'].to_s)
        Sketchup.write_default("RoomAnnotation", "show_level", args['show_level'].to_s)
        Sketchup.write_default("RoomAnnotation", "level", args['level'].to_s)

        # --------------------- Area logic ---------------------
        if hover_face
          area_inch = hover_face.area
          area_m2 = area_inch * 0.00064516
          area_str = format('%.2f', area_m2).gsub('.', ',')
        else
          area_str = "0,00"
        end
        
        main_text = "#{enviroment_name}\n#{ProjetaPlus::Localization.t("messages.area_label")}: #{area_str} m²"
        main_text += "\n#{ProjetaPlus::Localization.t("messages.ceilling_height_label")}: #{ceilling_height_str}m" if show_ceilling_height

        # --------------------- Centro XY e Altura Z ---------------------
        # Use the floor height (floor_height) from the global settings or the form
        floor_height_from_form_str = args['floor_height'].to_s.tr(',', '.')
        floor_height_from_form = floor_height_from_form_str.to_f # Altura do piso em metros
        
        # Use the cut height from the global settings
        cut_height_from_settings = ProjetaPlus::Modules::ProSettings.read("cut_height", ProjetaPlus::Modules::ProSettings::DEFAULT_CUT_HEIGHT).to_f
        
        z_height = (floor_height_from_form + cut_height_from_settings).m # Convert to meters, then to inches (internal unit of SketchUp)

        if hover_face && hover_extents
          bb_global = hover_extents 
          center_xy = Geom::Point3d.new(bb_global.center.x, bb_global.center.y, 0)
        else
          center_xy = grupo.bounds.center
        end
        center = Geom::Point3d.new(center_xy.x, center_xy.y, z_height)

        # --------------------- Level ---------------------
        nivel_label = "#{manual_level} m" 

        # --------------------- Creating objects ---------------------
        text_group = test_text(main_text, center, scale, font)
        text_group.layer = layer

        if mostrar_nivel
          nivel_instance = import_nivel_symbol(center, scale)
          unless nivel_instance
            model.selection.clear; model.selection.add(text_group)
            return { success: false, message: ProjetaPlus::Localization.t("messages.error_nivel_symbol_not_found") }
          end
          nivel_instance.layer = layer

          margin = 0.2.cm * scale
          text_bb = text_group.bounds
          sym_bb  = nivel_instance.bounds
          dy_sym = text_bb.min.y - sym_bb.max.y - margin
          nivel_instance.transform!(Geom::Transformation.translation([0, dy_sym, 0]))
          sym_bb  = nivel_instance.bounds
          dx_sym  = text_bb.center.x - sym_bb.center.x
          nivel_instance.transform!(Geom::Transformation.translation([dx_sym, 0, 0]))

          sym_center = nivel_instance.bounds.center
          dx = 0.20.cm * scale
          dy = 0.20.cm * scale
          text_pos = Geom::Point3d.new(sym_center.x + dx, sym_center.y + dy, sym_center.z)
          nivel_text_group = test_text(nivel_label, text_pos, scale, font, TextAlignLeft)
          nivel_text_group.layer = layer

          final_group = model.entities.add_group
          fents = final_group.entities
          
          fents.add_instance(text_group.entities.parent,        text_group.transformation)
          fents.add_instance(nivel_instance.definition,         nivel_instance.transformation)
          fents.add_instance(nivel_text_group.entities.parent,  nivel_text_group.transformation)

          text_group.erase! 
          nivel_instance.erase!
          nivel_text_group.erase!

          final_group.layer = layer
          model.selection.clear; model.selection.add(final_group)
        else
          model.selection.clear; model.selection.add(text_group)
        end
        { success: true, message: ProjetaPlus::Localization.t("messages.room_annotation_success") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_adding_room_name") + ": #{e.message}" }
      end

      class InteractiveRoomAnnotationTool
        include ProjetaPlus::Modules::ProHoverFaceUtil 
        
        def initialize(args)
          @args = args 
          @valid_pick = false
        end

        def activate
          Sketchup.set_status_text(ProjetaPlus::Localization.t("messages.room_annotation_prompt"), SB_PROMPT)
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
          model.start_operation(ProjetaPlus::Localization.t("commands.room_annotation_operation_name"), true)
          
        
          holder = @hover_face.parent.instances[0] rescue @hover_face.parent
          if holder.is_a?(Sketchup::Model)
             holder = model
          end

          result = ProjetaPlus::Modules::ProRoomAnnotation.processar_grupo(holder, @args, @hover_face, hover_extents)
          if result[:success]
            model.commit_operation
            UI.messagebox(ProjetaPlus::Localization.t("messages.room_annotation_success"), MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          else
            model.abort_operation
            UI.messagebox(result[:message], MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          end
          Sketchup.active_model.select_tool(nil) # Desativa a ferramenta após o clique
        rescue StandardError => e
          model.abort_operation
          UI.messagebox("#{ProjetaPlus::Localization.t("messages.unexpected_error")}: #{e.message}", MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          Sketchup.active_model.select_tool(nil)
        end

        def onKeyDown(key, repeat, flags, view)
          if key == VK_ESCAPE # Tecla ESC para sair
            Sketchup.active_model.select_tool(nil)
          end
        end
      end

      def self.start_interactive_annotation(args)
        if Sketchup.active_model.nil?
          return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") }
        end
        Sketchup.active_model.select_tool(InteractiveRoomAnnotationTool.new(args))
        { success: true, message: ProjetaPlus::Localization.t("messages.room_tool_activated") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_activating_tool") + ": #{e.message}" }
      end

    end # module ProRoomAnnotation
  end # module Modules
end # module ProjetaPlus