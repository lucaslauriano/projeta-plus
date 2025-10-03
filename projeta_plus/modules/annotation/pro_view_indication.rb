# encoding: UTF-8
require_relative '../pro_hover_face_util.rb'

module ProjetaPlus
  module Modules
    module ProViewIndication
    CUT_LEVEL = 1.45
    DEFAULT_SCALE = 25.0
    BLOCK_NAME = 'proViewIndication_abcd.skp'
    
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
      
      definitions.load(path)
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

    class ViewIndicationTool
      include ProjetaPlus::Modules::ProHoverFaceUtil
      
      def activate
        @hover_face = nil
        @path = nil
        @world_transformation = Geom::Transformation.new
        Sketchup.set_status_text(ProjetaPlus::Localization.t("messages.view_indication_prompt"), SB_PROMPT)
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
        
        # Use the BoundingBox that was already calculated in ProHoverFaceUtil
        bounding_box = hover_extents
        
        # Get the exact center of the face using the BoundingBox
        center_point = Geom::Point3d.new(
          bounding_box.center.x, 
          bounding_box.center.y, 
          bounding_box.min.z
        )
        
        # Calculate world normal
        world_normal = @hover_face.normal.transform(@world_transformation).normalize
        
        # Get axes from normal
        x_axis, y_axis, z_axis = ProjetaPlus::Modules::ProViewIndication.axes_from_normal(world_normal)
        
        # Load the block definition
        component_definition = ProjetaPlus::Modules::ProViewIndication.load_definition
        unless component_definition
          ::UI.messagebox(ProjetaPlus::Localization.t("messages.view_indication_block_not_found"), 
                         MB_OK, ProjetaPlus::Localization.t("app_message_title"))
          return
        end
        
        model.start_operation(ProjetaPlus::Localization.t("commands.view_indication_operation_name"), true)
        
        # Offset the center point by cut level
        center_point = center_point.offset(z_axis, CUT_LEVEL.m)
        
        # Create transformation
        transformation = Geom::Transformation.axes(center_point, x_axis, y_axis, z_axis)
        
        # Create instance
        instance = model.active_entities.add_instance(component_definition, transformation)
        
        # Scale the instance
        instance.transform!(Geom::Transformation.scaling(instance.bounds.center, DEFAULT_SCALE.to_f))
        
        # Select the instance
        model.selection.clear
        model.selection.add(instance)
        
        model.commit_operation
        view.invalidate
        
        ::UI.messagebox(ProjetaPlus::Localization.t("messages.view_indication_success"), 
                       MB_OK, ProjetaPlus::Localization.t("app_message_title"))
      end
      
      def onKeyDown(key, repeat, flags, view)
        if key == 27 # ESC key
          Sketchup.active_model.select_tool(nil)
        end
      end
    end
    end # module ProViewIndication
  end # module Modules
end # module ProjetaPlus
