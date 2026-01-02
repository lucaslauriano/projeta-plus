# encoding: UTF-8
require 'sketchup.rb'
require_relative '../settings/pro_settings.rb'
require_relative '../settings/pro_settings_utils.rb'
require_relative '../../localization.rb'

module ProjetaPlus
  module Modules
    module ProCircuitConnection

      HOVER_COLOR = Sketchup::Color.new(167, 175, 139)
      SELECTED_COLOR = "#803965"
      PREVIEW_COLOR = "#803965"
      DEFAULT_INTENSITY = 30.cm
      DEFAULT_SEGMENTS = 12

      def self.process_circuit_connection(first_object, second_object, connection_args)
        model = Sketchup.active_model
        curve_type = connection_args['curve_type'].to_i
        current_intensity = connection_args['intensity'].to_i
        straight_line = connection_args['straight_line'] == true
        segments = connection_args['segments'].to_i
        intensity = DEFAULT_INTENSITY
        
        p1 = first_object.bounds.center
        p2 = second_object.bounds.center
        preview_points = []
        
        if straight_line
          preview_points = calculate_whimsical_line(p1, p2, curve_type, current_intensity)
        else
          arc_height = current_intensity.is_a?(Numeric) ? current_intensity : intensity
          preview_points = calculate_curve(p1, p2, curve_type, arc_height, segments)
        end
        
        return { success: false, message: "Invalid connection points" } if preview_points.length < 2
        
        layer_name = "-ANOTACAO-ILUMINACAO LINHAS"
        layer = model.layers[layer_name] || model.layers.add(layer_name)
        
        line_group = model.entities.add_group
        line_group.name = straight_line ? "Circuit Connection - Whimsical" : "Circuit Connection - Curve"
        line_group.layer = layer
        
        if straight_line
          (0...preview_points.length-1).each do |i|
            line_group.entities.add_line(preview_points[i], preview_points[i+1])
          end
        else
          line_group.entities.add_curve(preview_points)
        end
        
        model.selection.clear
        model.selection.add(line_group)
        
        { success: true, message: ProjetaPlus::Localization.t("messages.circuit_connection_success") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_adding_circuit_connection") + ": #{e.message}" }
      end

      def self.calculate_whimsical_line(p1, p2, curve_type, current_intensity)
        if current_intensity == 0
          return [p1, p2]
        end
        
        deviation = current_intensity * 20.cm
        
        case curve_type
        when 0
          mid_point = Geom::Point3d.new(p2.x, p1.y, p1.z)
          return [p1, mid_point, p2]
        when 1
          mid_point = Geom::Point3d.new(p1.x, p2.y, p1.z)
          return [p1, mid_point, p2]
        when 2
          dx = (p2.x - p1.x).abs
          dy = (p2.y - p1.y).abs
          if dx > dy
            mid_x = p1.x + (p2.x - p1.x) * 0.5
            mid_point1 = Geom::Point3d.new(mid_x, p1.y, p1.z)
            mid_point2 = Geom::Point3d.new(mid_x, p1.y + deviation, p1.z)
            mid_point3 = Geom::Point3d.new(mid_x, p2.y, p1.z)
            return [p1, mid_point1, mid_point2, mid_point3, p2]
          else
            mid_y = p1.y + (p2.y - p1.y) * 0.5
            mid_point1 = Geom::Point3d.new(p1.x, mid_y, p1.z)
            mid_point2 = Geom::Point3d.new(p1.x + deviation, mid_y, p1.z)
            mid_point3 = Geom::Point3d.new(p2.x, mid_y, p1.z)
            return [p1, mid_point1, mid_point2, mid_point3, p2]
          end
        when 3
          dx = (p2.x - p1.x).abs
          dy = (p2.y - p1.y).abs
          if dx > dy
            mid_x = p1.x + (p2.x - p1.x) * 0.5
            mid_point1 = Geom::Point3d.new(mid_x, p1.y, p1.z)
            mid_point2 = Geom::Point3d.new(mid_x, p1.y - deviation, p1.z)
            mid_point3 = Geom::Point3d.new(mid_x, p2.y, p1.z)
            return [p1, mid_point1, mid_point2, mid_point3, p2]
          else
            mid_y = p1.y + (p2.y - p1.y) * 0.5
            mid_point1 = Geom::Point3d.new(p1.x, mid_y, p1.z)
            mid_point2 = Geom::Point3d.new(p1.x - deviation, mid_y, p1.z)
            mid_point3 = Geom::Point3d.new(p2.x, mid_y, p1.z)
            return [p1, mid_point1, mid_point2, mid_point3, p2]
          end
        end
      end

      def self.calculate_curve(p1, p2, curve_type, arc_height, segments)
        curve_points = []
        (0..segments).each do |j|
          t = j.to_f / segments
          x = p1.x + (p2.x - p1.x) * t
          y = p1.y + (p2.y - p1.y) * t
          z = p1.z
          
          curve_factor = 2 * t * (1 - t)
          
          case curve_type
          when 0
            y += arc_height * curve_factor
          when 1
            y -= arc_height * curve_factor
          when 2
            x += arc_height * curve_factor
          when 3
            x -= arc_height * curve_factor
          end
          
          curve_points << Geom::Point3d.new(x, y, z)
        end
        curve_points
      end

      class InteractiveCircuitConnectionTool
        
        def handle_escape(view)
          now = Time.now
          @last_esc_at ||= Time.at(0)
          
          if (now - @last_esc_at) <= 0.7
            # Double ESC: exit tool
            Sketchup.active_model.select_tool(nil)
          else
            # Single ESC: start new circuit
            @first_object = nil
            @second_object = nil
            @preview_points = []
            Sketchup.set_status_text("New circuit! Click on the first object. ESC x2 quickly = exit.", SB_PROMPT)
            view.invalidate
          end
          
          @last_esc_at = now
        end
        
        def onCancel(reason, view)
          handle_escape(view)
        end
        
        def initialize(dialog = nil)
          @dialog = dialog
          @last_esc_at = Time.at(0)
          @first_object = nil
          @second_object = nil
          @preview_points = []
          @curve_type = 0
          @current_intensity = 30.cm # default initial value
          @segments = DEFAULT_SEGMENTS
          @esc_count = 0
          @straight_line = false
          @hover_object = nil
        end
        
        def activate
          Sketchup.set_status_text(ProjetaPlus::Localization.t("messages.circuit_connection_prompt"), SB_PROMPT)
        end
        
        def onMouseMove(flags, x, y, view)
          ph = view.pick_helper
          ph.do_pick(x, y)
          @hover_object = ph.best_picked
          
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
            @preview_points = ProjetaPlus::Modules::ProCircuitConnection.calculate_whimsical_line(p1, p2, @curve_type, @current_intensity)
          else
            arc_height = @current_intensity
            @preview_points = ProjetaPlus::Modules::ProCircuitConnection.calculate_curve(p1, p2, @curve_type, arc_height, @segments)
          end
        end
        
        def draw(view)
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
            @first_object = object
            Sketchup.set_status_text("Now click on the second object. Use arrows to change direction/intensity.", SB_PROMPT)
          elsif @second_object && object == @second_object
            create_line
            @first_object = @second_object
            @second_object = nil
            @preview_points = []
            Sketchup.set_status_text("Line created! Click on the next object or Esc to exit.", SB_PROMPT)
          elsif object != @first_object
            @second_object = object
            calculate_preview
            Sketchup.set_status_text("Use arrows to change direction/intensity. Click again to confirm.", SB_PROMPT)
          end
          
          view.invalidate
        end
        
        def onKeyDown(key, repeat, flags, view)
          case key
          when 27
            handle_escape(view)
            return
            
          when 38  # VK_UP
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
            
          when 40  # VK_DOWN
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
            
          when 39  # VK_RIGHT
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
            
          when 37  # VK_LEFT
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
            
          # -------- INTENSITY NOW ON + AND - --------
          
          # + (increase 10 cm)
          when 187
            if @second_object
              @current_intensity += 10.cm
              calculate_preview
              directions = ["UP", "DOWN", "RIGHT", "LEFT"]
              msg = @straight_line ?
                "WHIMSICAL deviation: #{@current_intensity.to_l}" :
                "Curve #{directions[@curve_type]} - Height: #{@current_intensity.to_l}"
              Sketchup.set_status_text(msg, SB_PROMPT)
              view.invalidate
            end
            
          # - (decrease 10 cm)
          when 189
            if @second_object
              @current_intensity -= 10.cm
              @current_intensity = 0.cm if @current_intensity < 0.cm # prevent negative
              calculate_preview
              directions = ["UP", "DOWN", "RIGHT", "LEFT"]
              msg = @straight_line ?
                "WHIMSICAL deviation: #{@current_intensity.to_l}" :
                "Curve #{directions[@curve_type]} - Height: #{@current_intensity.to_l}"
              Sketchup.set_status_text(msg, SB_PROMPT)
              view.invalidate
            end
            
          # -------------------------------------------
          
          when 16  # VK_SHIFT
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
            if @dialog
              @dialog.execute_script("showMessage('#{result[:message]}', 'success');")
            end
          else
            model.abort_operation
            if @dialog
              escaped_message = result[:message].gsub("'", "\\\\'")
              @dialog.execute_script("showMessage('#{escaped_message}', 'error');")
            end
          end
        rescue StandardError => e
          model.abort_operation
          if @dialog
            error_msg = "#{ProjetaPlus::Localization.t("messages.unexpected_error")}: #{e.message}".gsub("'", "\\\\'")
            @dialog.execute_script("showMessage('#{error_msg}', 'error');")
          end
        end
      end

      def self.start_interactive_connection(dialog = nil)
        if Sketchup.active_model.nil?
          return { success: false, message: ProjetaPlus::Localization.t("messages.no_model_open") }
        end
        Sketchup.active_model.select_tool(InteractiveCircuitConnectionTool.new(dialog))
        { success: true, message: ProjetaPlus::Localization.t("messages.circuit_connection_tool_activated") }
      rescue StandardError => e
        { success: false, message: ProjetaPlus::Localization.t("messages.error_activating_tool") + ": #{e.message}" }
      end
    end
  end
end
