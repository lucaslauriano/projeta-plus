# encoding: UTF-8
require_relative '../pro_hover_face_util.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProViewAnnotation
    CUT_LEVEL = ProjetaPlus::Modules::ProSettingsUtils.get_cut_height_cm
    CM_TO_INCHES_CONVERSION_FACTOR = 2.54
    BLOCK_NAME = 'ProViewAnnotation_abcd.skp'
    
    def self.global_transformation(path, face)
      idx = path.index(face)
      return Geom::Transformation.new unless idx
      
      tr = Geom::Transformation.new
      path[0..idx].each do |entity|
        tr *= entity.transformation if entity.respond_to?(:transformation)
      end
      tr
    end

    def self.load_definition
      model = Sketchup.active_model
      definitions = model.definitions
      candidates = []
      
      # Try to load from model directory first
      if model.path && !model.path.empty?
        model_blocks_path = File.join(File.dirname(model.path), 'components', BLOCK_NAME)
        candidates << model_blocks_path
      end
      
      # Try to load from plugin directory
      plugin_blocks_path = File.join(ProjetaPlus::PATH, 'projeta_plus', 'components', BLOCK_NAME)
      candidates << plugin_blocks_path
      
      # Try to load from SketchUp plugins directory
      plugins_dir = Sketchup.find_support_file('Plugins')
      if plugins_dir
        sketchup_blocks_path = File.join(plugins_dir, 'components', BLOCK_NAME)
        candidates << sketchup_blocks_path
      end
      
      # Find the first existing path
      path = candidates.find { |p| File.exist?(p) }
      return nil unless path
      
      definition = definitions.load(path, allow_newer: true)

    end
    
    def self.axes_from_normal(normal)
      z_axis = normal.normalize
      auxiliary_axis = z_axis.parallel?(Z_AXIS) ? X_AXIS : Z_AXIS
      
      x_axis = auxiliary_axis.cross(z_axis)
      if x_axis.length == 0
        x_axis = X_AXIS.clone
      else
        x_axis.normalize!
      end
      
      y_axis = z_axis.cross(x_axis)
      y_axis.normalize!
      
      [x_axis, y_axis, z_axis]
    end

    class ViewAnnotationTool
      include ProjetaPlus::Modules::ProHoverFaceUtil
      
      def initialize(dialog = nil)
        @dialog = dialog
      end
      
      def activate
        @hover_face = nil
        @path = nil
        @world_transformation = Geom::Transformation.new
        Sketchup.set_status_text(ProjetaPlus::Localization.t("messages.view_annotation_prompt"), SB_PROMPT)
      end
      
      def onMouseMove(flags, x, y, view)
        update_hover(view, x, y)
        view.invalidate
      end
      
      def draw(view)
        draw_hover(view)
      end
      
      def onLButtonDown(flags, x, y, view)
        return unless @hover_face
        
        model = Sketchup.active_model
        
        bounding_box = hover_extents
        
        center_point = Geom::Point3d.new(
          bounding_box.center.x, 
          bounding_box.center.y, 
          bounding_box.min.z
        )

        world_normal = @hover_face.normal.transform(@world_transformation).normalize

        x_axis, y_axis, z_axis = ProjetaPlus::Modules::ProViewAnnotation.axes_from_normal(world_normal)

        component_definition = ProjetaPlus::Modules::ProViewAnnotation.load_definition
        unless component_definition
          if @dialog
            @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.view_annotation_block_not_found")}', 'error');")
          end
          return
        end
        
        model.start_operation(ProjetaPlus::Localization.t("commands.view_annotation_operation_name"), true)

        center_point = center_point.offset(z_axis, CUT_LEVEL.to_f / CM_TO_INCHES_CONVERSION_FACTOR)

        transformation = Geom::Transformation.axes(center_point, x_axis, y_axis, z_axis)

        instance = model.active_entities.add_instance(component_definition, transformation)

        instance.transform!(Geom::Transformation.scaling(instance.bounds.center, ProjetaPlus::Modules::ProSettingsUtils.get_scale))

        model.selection.clear
        model.selection.add(instance)
        
        model.commit_operation
        view.invalidate
        
        if @dialog
          @dialog.execute_script("showMessage('#{ProjetaPlus::Localization.t("messages.view_annotation_success")}', 'success');")
        end
      end
      
      def onKeyDown(key, repeat, flags, view)
        if key == 27 # ESC key
          Sketchup.active_model.select_tool(nil)
        end
      end
    end
    end # module ProViewAnnotation
  end # module Modules
end # module ProjetaPlus
