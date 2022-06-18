# frozen_string_literal: true

DEGREES_TO_RADIANS = Math::PI / 180

$gtk.reset

def tick(args)
  mouse_x = args.inputs.mouse.x
  mouse_y = args.inputs.mouse.y

  block = { x: 100, y: 100, w: 100, h: 100 }
  screen = { x: args.grid.left, y: args.grid.bottom, w: args.grid.w, h: args.grid.h }

  lines = []

  lines.concat deconstruct_rect_lines(block)
  lines.concat deconstruct_rect_lines(screen)

  rays = []

  degree = 0
  num_rays = 360
  ray_length = 200

  num_rays.times do
    ray_end = point_at_angle_distance({ x: mouse_x, y: mouse_y }, ray_length, degree)
    rays << { x: mouse_x, y: mouse_y, x2: ray_end.x, y2: ray_end.y, g: 255 }
    degree -= 360 / num_rays
  end

  args.outputs.lines << lines
  args.outputs.lines << rays

  intersections = []

  rays.each do |ray|
    lines.each do |line|
      new_intersection = line_intersection(line, ray)
      next unless new_intersection && !new_intersection.nil?
      new_intersection = new_intersection.merge(w: 10, h: 10, b: 255)
      new_intersection.x = new_intersection.x - 5
      new_intersection.y = new_intersection.y - 5
      intersections << new_intersection
    end
  end

  args.outputs.solids << intersections
  args.outputs.solids << block

  args.outputs.labels << { x: 0, y: args.grid.center_y, text: intersections.length.to_s }

  args.outputs.labels << [10, 710, "framerate: #{args.gtk.current_framerate.round}"]
  args.outputs.labels << [10, 690, "rays: #{num_rays}"]
end

def deconstruct_rect_lines(rect)
  [
    { x: rect.x, y: rect.y, x2: rect.x + rect.w, y2: rect.y, r: 255 },
    { x: rect.x, y: rect.y, x2: rect.x, y2: rect.y + rect.h, r: 255 },
    { x: rect.x + rect.w, y: rect.y, x2: rect.x + rect.w, y2: rect.y + rect.h, r: 255 },
    { x: rect.x, y: rect.y + rect.h, x2: rect.x + rect.w, y2: rect.y + rect.h, r: 255 }
  ]
end

def line_slope(line)
  return nil if line.x == line.x2
  (line.y2 - line.y) / (line.x2 - line.x)
end

def point_at_angle_distance(point, distance, angle)
  {
    x: point.x + (distance * Math.cos(angle * DEGREES_TO_RADIANS)),
    y: point.y + (distance * Math.sin(angle * DEGREES_TO_RADIANS))
  }
end

def line_intersection(line_a, line_b)
  point1 = { x: line_a.x, y: line_a.y }
  point2 = { x: line_a.x2, y: line_a.y2 }
  point3 = { x: line_b.x, y: line_b.y }
  point4 = { x: line_b.x2, y: line_b.y2 }

  a1 = point2.y - point1.y
  b1 = point1.x - point2.x
  c1 = a1 * point1.x + b1 * point1.y

  a2 = point4.y - point3.y
  b2 = point3.x - point4.x
  c2 = a2 * point3.x + b2 * point3.y

  determinant = a1 * b2 - a2 * b1

  return nil if determinant.zero?

  x = (b2 * c1 - b1 * c2) / determinant
  y = (a1 * c2 - a2 * c1) / determinant
  intersection = { x: x.round(0), y: y.round(0) }

  return nil unless in_range(line_a.x, line_a.x2, intersection.x) && in_range(line_b.x, line_b.x2, intersection.x)
  return nil unless in_range(line_a.y, line_a.y2, intersection.y) && in_range(line_b.y, line_b.y2, intersection.y)

  intersection
end

def in_range(first_number, second_number, test_number)
  range = [first_number, second_number]
  (range.min..range.max).cover?(test_number)
end
