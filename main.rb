# frozen_string_literal: true

DEGREES_TO_RADIANS = Math::PI / 180
RAY_LENGTH = Math::sqrt((1280**2)+(720**2))

NUM_RAYS = 360
DEGREE = 360 / NUM_RAYS

BLOCK = { x: 100, y: 100, w: 100, h: 100 }
BLOCK2 = { x: 300, y: 300, w: 100, h: 100 }
BLOCK3 = { x: 600, y: 400, w: 100, h: 100 }

SCREEN = { x: 0, y: 0, w: 1280, h: 720 }

def rect_to_lines(rect)
  [
    { x: rect.x, y: rect.y, x2: rect.x + rect.w, y2: rect.y, r: 255 },
    { x: rect.x, y: rect.y, x2: rect.x, y2: rect.y + rect.h, r: 255 },
    { x: rect.x + rect.w, y: rect.y, x2: rect.x + rect.w, y2: rect.y + rect.h, r: 255 },
    { x: rect.x, y: rect.y + rect.h, x2: rect.x + rect.w, y2: rect.y + rect.h, r: 255 }
  ]
end

RECT_BLOCK = rect_to_lines(BLOCK)
RECT_BLOCK2 = rect_to_lines(BLOCK2)
RECT_BLOCK3 = rect_to_lines(BLOCK3)

RECT_SCREEN = rect_to_lines(SCREEN)

$gtk.reset

def tick(args)
  mouse_x = args.inputs.mouse.x
  mouse_y = args.inputs.mouse.y

  args.outputs[:output_target].solids << BLOCK
  args.outputs[:output_target].solids << BLOCK2
  args.outputs[:output_target].solids << BLOCK3

  lines = []

  lines.concat RECT_BLOCK
  lines.concat RECT_BLOCK2
  lines.concat RECT_BLOCK3
  lines.concat RECT_SCREEN

  rays = []
  degree = 0

  NUM_RAYS.times do
    ray_end = point_at_angle_distance({ x: mouse_x, y: mouse_y }, RAY_LENGTH, degree)
    rays << { x: mouse_x, y: mouse_y, x2: ray_end.x, y2: ray_end.y, g: 255 }
    degree -= DEGREE
  end

  intersections = []

  rays.each do |ray|
    this_ray_intersections = []
    lines.each do |line|
      new_intersection = line_intersection(line, ray)
      next unless new_intersection && !new_intersection.nil?
      new_intersection = new_intersection.merge(w: 10, h: 10, b: 255, distance: args.geometry.distance(new_intersection, x: mouse_x, y: mouse_y))
      this_ray_intersections << new_intersection
    end
    sorted_points = this_ray_intersections.sort_by { |hsh| hsh[:distance] }
    intersections << sorted_points[0]
  end

  final_rays = intersections.map do |point|
    { x: point.x, y: point.y, x2: mouse_x, y2: mouse_y } if point
  end

  args.outputs[:output_target].lines << final_rays

  args.outputs[:output_target].labels << [10, 710, "framerate: #{args.gtk.current_framerate.round}"]

  args.outputs.sprites << {x: 0, y: 0, w: args.grid.w, h: args.grid.h, path: :output_target}
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
  a1 = line_a.y2 - line_a.y
  b1 = line_a.x - line_a.x2
  c1 = a1 * line_a.x + b1 * line_a.y

  a2 = line_b.y2 - line_b.y
  b2 = line_b.x - line_b.x2
  c2 = a2 * line_b.x + b2 * line_b.y

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
