# encoding: UTF-8
require 'sketchup.rb'

module ProjetaPlus
  module Modules 
    module ProHoverFaceUtil 
      COLOR_FILL = Sketchup::Color.new("#a7af8b")
      COLOR_EDGE = Sketchup::Color.new("#803965")
      IDENTITY   = Geom::Transformation.new

      def update_hover(view, x, y)
        ph = view.pick_helper; ph.do_pick(x, y)
        @path = ph.path_at(0)
        @hover_face = @path && @path.find { |e| e.is_a?(Sketchup::Face) }
        @tr_world   = @hover_face ? (ph.respond_to?(:transformation_at) ? ph.transformation_at(0) : IDENTITY) : IDENTITY
        rebuild_hover_geometry
      end

      def rebuild_hover_geometry
        @tris = []; @loops = []; @bb = nil
        return unless @hover_face
        @bb = Geom::BoundingBox.new

        mesh = @hover_face.mesh 0
        pts  = mesh.points.map { |p| p.transform(@tr_world) }
        mesh.polygons.each do |poly|
          idx = poly.map { |i| i.abs - 1 }
          next if idx.length < 3
          p0 = pts[idx[0]]
          (1...(idx.length-1)).each { |k| @tris << p0 << pts[idx[k]] << pts[idx[k+1]] }
        end
        @tris.each { |p| @bb.add(p) }

        loops = [@hover_face.outer_loop] + @hover_face.loops.reject(&:outer?)
        @loops = loops.map do |lp|
          arr = lp.vertices.map { |v| v.position.transform(@tr_world) }
          arr.each { |p| @bb.add(p) }
          arr
        end
      end

      def draw_hover(view)
        return if @tris.nil? || (@tris.empty? && @loops.empty?)
        view.drawing_color = COLOR_FILL
        view.draw(GL_TRIANGLES, @tris) unless @tris.empty?
        view.drawing_color = COLOR_EDGE
        view.line_stipple  = ""
        view.line_width    = 3
        @loops.each { |pts| view.draw(GL_LINE_LOOP, pts) }
      end

      def hover_extents
        @bb || Geom::BoundingBox.new
      end
    end # module ProHoverFaceUtil
  end # module Modules
end # module ProjetaPlus