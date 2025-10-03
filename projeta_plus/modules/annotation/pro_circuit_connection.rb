# encoding: UTF-8
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProCircuitConnection

      # Color constants
      HOVER_COLOR = Sketchup::Color.new(167, 175, 139)  # Light green
      SELECTED_COLOR = "#803965"
      PREVIEW_COLOR = "#803965"
      
      DEFAULT_INTENSITIES = [30.cm, 50.cm, 70.cm, 90.cm]  # Different intensities
      DEFAULT_SEGMENTS = 12

      def self.process_circuit_connection(first_object, second_object, connection_args)
        model = Sketchup.active_model
        
        # Extract connection parameters
        curve_type = connection_args['curve_type'].to_i  # 0=up, 1=down, 2=right, 3=left
        current_intensity = connection_args['intensity'].to_i
        straight_line = connection_args['straight_line'] == true
        segments = connection_args['segments'].to_i
        
        intensities = DEFAULT_INTENSITIES
        
        # Calculate connection points
        p1 = first_object.bounds.center
        p2 = second_object.bounds.center
        
        preview_points = []
        
        if straight_line
          # Straight line style (orthogonal)
          preview_points = calculate_whimsical_line(p1, p2, curve_type, current_intensity)
        else
          # Curved line
          arc_height = intensities[current_intensity]
          preview_points = calculate_curve(p1, p2, curve_type, arc_height, segments)
        end
        
        return { success: false, message: "Invalid connection points" } if preview_points.length < 2
        
        # Create connection layer
        layer_name = "-ANOTACAO-ILUMINACAO LINHAS"
        layer = model.layers[layer_name] || model.layers.add(layer_name)
        
        # Create connection group
        line_group = model.entities.add_group
        line_group.name = straight_line ? "Circuit Connection - Whimsical" : "Circuit Connection - Curve"
        line_group.layer = layer
        
        if straight_line
          # For whimsical line, create multiple connected straight lines
          (0...preview_points.length-1).each do |i|
            line_group.entities.add_line(preview_points[i], preview_points[i+1])
          end
        else
          # For curve, use add_curve
          line_group.entities.add_curve(preview_points)
        end
        
        model.selection.clear
        model.selection.add(line_group)
        
        { success: true, message: ProjetaPlus::Localization.t("messages.circuit_connection_success") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_adding_circuit_connection") + ": #{e.message}" }
      end

      # Calculate whimsical line points
      def self.calculate_whimsical_line(p1, p2, curve_type, current_intensity)
        # Intensity 0 = straight line, 1-3 = increasing deviations
        if current_intensity == 0
          # Completely straight line
          return [p1, p2]
        end
        
        # Calculate deviation based on intensity (20cm, 40cm, 60cm)
        deviation = current_intensity * 20.cm
        
        # Deviation direction based on curve_type (arrows)
        case curve_type
        when 0  # Horizontal first, then vertical (default)
          mid_point = Geom::Point3d.new(p2.x, p1.y, p1.z)
          return [p1, mid_point, p2]
          
        when 1  # Vertical first, then horizontal
          mid_point = Geom::Point3d.new(p1.x, p2.y, p1.z)
          return [p1, mid_point, p2]
          
        when 2  # Deviation to right (3 segments)
          dx = (p2.x - p1.x).abs
          dy = (p2.y - p1.y).abs
          
          if dx > dy  # More horizontal movement
            mid_x = p1.x + (p2.x - p1.x) * 0.5
            mid_point1 = Geom::Point3d.new(mid_x, p1.y, p1.z)
            mid_point2 = Geom::Point3d.new(mid_x, p1.y + deviation, p1.z)
            mid_point3 = Geom::Point3d.new(mid_x, p2.y, p1.z)
            return [p1, mid_point1, mid_point2, mid_point3, p2]
          else  # More vertical movement
            mid_y = p1.y + (p2.y - p1.y) * 0.5
            mid_point1 = Geom::Point3d.new(p1.x, mid_y, p1.z)
            mid_point2 = Geom::Point3d.new(p1.x + deviation, mid_y, p1.z)
            mid_point3 = Geom::Point3d.new(p2.x, mid_y, p1.z)
            return [p1, mid_point1, mid_point2, mid_point3, p2]
          end
          
        when 3  # Deviation to left (3 segments)
          dx = (p2.x - p1.x).abs
          dy = (p2.y - p1.y).abs
          
          if dx > dy  # More horizontal movement
            mid_x = p1.x + (p2.x - p1.x) * 0.5
            mid_point1 = Geom::Point3d.new(mid_x, p1.y, p1.z)
            mid_point2 = Geom::Point3d.new(mid_x, p1.y - deviation, p1.z)
            mid_point3 = Geom::Point3d.new(mid_x, p2.y, p1.z)
            return [p1, mid_point1, mid_point2, mid_point3, p2]
          else  # More vertical movement
            mid_y = p1.y + (p2.y - p1.y) * 0.5
            mid_point1 = Geom::Point3d.new(p1.x, mid_y, p1.z)
            mid_point2 = Geom::Point3d.new(p1.x - deviation, mid_y, p1.z)
            mid_point3 = Geom::Point3d.new(p2.x, mid_y, p1.z)
            return [p1, mid_point1, mid_point2, mid_point3, p2]
          end
        end
      end

      # Calculate curved line points
      def self.calculate_curve(p1, p2, curve_type, arc_height, segments)
        curve_points = []
        
        (0..segments).each do |j|
          t = j.to_f / segments
          x = p1.x + (p2.x - p1.x) * t
          y = p1.y + (p2.y - p1.y) * t
          z = p1.z
          
          # Curvature factor (parabola: maximum in the middle)
          curve_factor = 2 * t * (1 - t)
          
          case curve_type
          when 0  # Curve upward (positive Y)
            y += arc_height * curve_factor
          when 1  # Curve downward (negative Y)
            y -= arc_height * curve_factor
          when 2  # Curve to right (positive X)
            x += arc_height * curve_factor
          when 3  # Curve to left (negative X)
            x -= arc_height * curve_factor
          end
          
          curve_points << Geom::Point3d.new(x, y, z)
        end
        
        curve_points
      end

      # Interactive tool for circuit connection
      class InteractiveCircuitConnectionTool
        def initialize
          @first_object = nil
          @second_object = nil
          @preview_points = []
          @curve_type = 0  # 0=up, 1=down, 2=right, 3=left
          @intensities = DEFAULT_INTENSITIES
          @current_intensity = 1  # Start with medium intensity
          @segments = DEFAULT_SEGMENTS
          @esc_count = 0  # ESC counter
          @straight_line = false  # false=curve, true=straight line
          @hover_object = nil
        end

        def activate
          Sketchup.set_status_text(ProjetaPlus::Localization.t("messages.circuit_connection_prompt"), SB_PROMPT)
        end

        def onMouseMove(flags, x, y, view)
          ph = view.pick_helper
          ph.do_pick(x, y)
          @hover_object = ph.best_picked
          
          # If we already have the first object and are hovering over another, create preview
          if @first_object && @hover_object && @hover_object != @first_object && 
             (@hover_object.is_a?(Sketchup::Group) || @hover_object.is_a?(Sketchup::ComponentInstance))
            
            @second_object = @hover_object
            calculate_preview
          else
            @preview_points = []
          end
          
          view.invalidate
        end

        def calculate_preview
          return unless @first_object && @second_object
          
          p1 = @first_object.bounds.center
          p2 = @second_object.bounds.center
          
          if @straight_line
            # Straight line style (orthogonal)
            @preview_points = ProjetaPlus::Modules::ProCircuitConnection.calculate_whimsical_line(p1, p2, @curve_type, @current_intensity)
          else
            # Curved line
            arc_height = @intensities[@current_intensity]
            @preview_points = ProjetaPlus::Modules::ProCircuitConnection.calculate_curve(p1, p2, @curve_type, arc_height, @segments)
          end
        end

        def draw(view)
          # Highlight object under cursor
          if @hover_object && (@hover_object.is_a?(Sketchup::Group) || @hover_object.is_a?(Sketchup::ComponentInstance))
            view.drawing_color = HOVER_COLOR
            view.line_stipple = ""
            view.line_width = 3
            
            bb = @hover_object.bounds
            corners = [
              [bb.min.x, bb.min.y, bb.min.z], [bb.max.x, bb.min.y, bb.min.z],
              [bb.max.x, bb.max.y, bb.min.z], [bb.min.x, bb.max.y, bb.min.z],
              [bb.min.x, bb.min.y, bb.max.z], [bb.max.x, bb.min.y, bb.max.z],
              [bb.max.x, bb.max.y, bb.max.z], [bb.min.x, bb.max.y, bb.max.z]
            ]
            
            edges = [[0,1], [1,2], [2,3], [3,0], [4,5], [5,6], [6,7], [7,4], [0,4], [1,5], [2,6], [3,7]]
            edges.each { |i, j| view.draw_line(corners[i], corners[j]) }
          end

          # Highlight first selected object
          if @first_object
            view.drawing_color = Sketchup::Color.new(SELECTED_COLOR)
            view.line_width = 4
            
            bb = @first_object.bounds
            corners = [
              [bb.min.x, bb.min.y, bb.min.z], [bb.max.x, bb.min.y, bb.min.z],
              [bb.max.x, bb.max.y, bb.min.z], [bb.min.x, bb.max.y, bb.min.z]
            ]
            
            edges = [[0,1], [1,2], [2,3], [3,0]]
            edges.each { |i, j| view.draw_line(corners[i], corners[j]) }
          end

          # Draw line preview
          if @preview_points.length > 1
            view.drawing_color = Sketchup::Color.new(PREVIEW_COLOR)
            view.line_stipple = "-"
            view.line_width = 2
            
            (0...@preview_points.length-1).each do |i|
              view.draw_line(@preview_points[i], @preview_points[i+1])
            end
          end
        end

        def onLButtonDown(flags, x, y, view)
          ph = view.pick_helper
          ph.do_pick(x, y)
          object = ph.best_picked
          
          return unless object && (object.is_a?(Sketchup::Group) || object.is_a?(Sketchup::ComponentInstance))
          
          if @first_object.nil?
            # First click - select first object
            @first_object = object
            Sketchup.set_status_text("Now click on the second object. Use arrows to change direction/intensity.", SB_PROMPT)
          elsif @second_object && object == @second_object
            # Click on same second object - confirm connection
            create_line
            @first_object = @second_object  # Second becomes first to continue
            @second_object = nil
            @preview_points = []
            Sketchup.set_status_text("Line created! Click on the next object or Esc to exit.", SB_PROMPT)
          elsif object != @first_object
            # Click on different object - change second object
            @second_object = object
            calculate_preview
            Sketchup.set_status_text("Use arrows to change direction/intensity. Click again to confirm.", SB_PROMPT)
          end
          
          view.invalidate
        end

        def onKeyDown(key, repeat, flags, view)
          case key
          when 27  # ESC
            @esc_count += 1
            
            if @esc_count == 1
              # First ESC - start new circuit
              @first_object = nil
              @second_object = nil
              @preview_points = []
              Sketchup.set_status_text("New circuit! Click on the first object. 1 ESC = new circuit, 2 ESC = exit.", SB_PROMPT)
              view.invalidate
              
              # Reset counter after 2 seconds if ESC not pressed again
              UI.start_timer(2.0, false) { @esc_count = 0 }
            else
              # Second ESC - exit tool
              Sketchup.active_model.select_tool(nil)
            end
          when VK_UP  # Arrow up - line style
            if @second_object
              @curve_type = 0
              calculate_preview
              if @straight_line
                Sketchup.set_status_text("WHIMSICAL: Horizontal → Vertical - Deviation: #{@current_intensity}/3", SB_PROMPT)
              else
                Sketchup.set_status_text("Curve UPWARD - Intensity: #{@current_intensity + 1}/4", SB_PROMPT)
              end
              view.invalidate
            end
          when VK_DOWN  # Arrow down - line style
            if @second_object
              @curve_type = 1
              calculate_preview
              if @straight_line
                Sketchup.set_status_text("WHIMSICAL: Vertical → Horizontal - Deviation: #{@current_intensity}/3", SB_PROMPT)
              else
                Sketchup.set_status_text("Curve DOWNWARD - Intensity: #{@current_intensity + 1}/4", SB_PROMPT)
              end
              view.invalidate
            end
          when VK_RIGHT  # Arrow right - line style
            if @second_object
              @curve_type = 2
              calculate_preview
              if @straight_line
                Sketchup.set_status_text("WHIMSICAL: Deviation to RIGHT - Deviation: #{@current_intensity}/3", SB_PROMPT)
              else
                Sketchup.set_status_text("Curve to RIGHT - Intensity: #{@current_intensity + 1}/4", SB_PROMPT)
              end
              view.invalidate
            end
          when VK_LEFT  # Arrow left - line style
            if @second_object
              @curve_type = 3
              calculate_preview
              if @straight_line
                Sketchup.set_status_text("WHIMSICAL: Deviation to LEFT - Deviation: #{@current_intensity}/3", SB_PROMPT)
              else
                Sketchup.set_status_text("Curve to LEFT - Intensity: #{@current_intensity + 1}/4", SB_PROMPT)
              end
              view.invalidate
            end
          when VK_CONTROL, 17  # Ctrl - change intensity/deviation
            if @second_object
              @current_intensity = (@current_intensity + 1) % @intensities.length
              calculate_preview
              if @straight_line
                styles = ["Horizontal → Vertical", "Vertical → Horizontal", "Deviation to RIGHT", "Deviation to LEFT"]
                Sketchup.set_status_text("WHIMSICAL: #{styles[@curve_type]} - Deviation: #{@current_intensity}/3", SB_PROMPT)
              else
                directions = ["UP", "DOWN", "RIGHT", "LEFT"]
                Sketchup.set_status_text("#{directions[@curve_type]} - Intensity: #{@current_intensity + 1}/4", SB_PROMPT)
              end
              view.invalidate
            end
          when VK_SHIFT, 16  # Shift - toggle between curve and whimsical line
            if @second_object
              @straight_line = !@straight_line
              calculate_preview
              if @straight_line
                styles = ["Horizontal → Vertical", "Vertical → Horizontal", "Deviation to RIGHT", "Deviation to LEFT"]
                Sketchup.set_status_text("WHIMSICAL: #{styles[@curve_type]} - Deviation: #{@current_intensity}/3", SB_PROMPT)
              else
                directions = ["UP", "DOWN", "RIGHT", "LEFT"]
                Sketchup.set_status_text("#{directions[@curve_type]} - Intensity: #{@current_intensity + 1}/4", SB_PROMPT)
              end
              view.invalidate
            end
          end
        end

        def create_line
          return unless @first_object && @second_object && @preview_points.length >= 2
          
          model = Sketchup.active_model
          model.start_operation(ProjetaPlus::Localization.t("commands.circuit_connection_operation_name"), true)
          
          connection_args = {
            'curve_type' => @curve_type,
            'intensity' => @current_intensity,
            'straight_line' => @straight_line,
            'segments' => @segments
          }
          
          result = ProjetaPlus::Modules::ProCircuitConnection.process_circuit_connection(@first_object, @second_object, connection_args)
          
          if result[:success]
            model.commit_operation
            ::UI.messagebox(ProjetaPlus::Localization.t("messages.circuit_connection_success"), MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          else
            model.abort_operation
            ::UI.messagebox(result[:message], MB_OK, ProjetaPlus::Localization.t("plugin_name"))
          end
        rescue StandardError => e
          model.abort_operation
          ::UI.messagebox("#{ProjetaPlus::Localization.t("messages.unexpected_error")}: #{e.message}", MB_OK, ProjetaPlus::Localization.t("plugin_name"))
        end
      end

      def self.start_interactive_connection
        if Sketchup.active_model.nil?
          return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") }
        end
        Sketchup.active_model.select_tool(InteractiveCircuitConnectionTool.new)
        { success: true, message: ProjetaPlus::Localization.t("messages.circuit_connection_tool_activated") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_activating_tool") + ": #{e.message}" }
      end

    end # module ProCircuitConnection
  end # module Modules
end # module ProjetaPlus

