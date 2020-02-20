###
# Etch EDA: 2D Geometric Primitives for Board Layout and Photoplotting
#
# Provides robust 2D geometry classes built on fixed-point nanometer
# coordinates. Supports point vector operations, line segment distances,
# bounding box spatial tests, arcs, and polylines.
###

Units = require './units'

class Point
  constructor: (@x = 0, @y = 0) ->
    @x = Math.round(@x)
    @y = Math.round(@y)

  clone: -> new Point(@x, @y)

  equals: (other, tolerance = 0) ->
    return false unless other?
    if tolerance is 0
      @x is other.x and @y is other.y
    else
      Math.abs(@x - other.x) <= tolerance and Math.abs(@y - other.y) <= tolerance

  add: (other) -> new Point(@x + other.x, @y + other.y)
  sub: (other) -> new Point(@x - other.x, @y - other.y)
  scale: (factor) -> new Point(Math.round(@x * factor), Math.round(@y * factor))

  distSq: (other) ->
    dx = @x - other.x
    dy = @y - other.y
    dx * dx + dy * dy

  dist: (other) -> Math.sqrt(@distSq(other))

  manhattanDist: (other) ->
    Math.abs(@x - other.x) + Math.abs(@y - other.y)

  midpoint: (other) ->
    new Point(Math.round((@x + other.x) / 2), Math.round((@y + other.y) / 2))

  # Rotate point around pivot by angle in radians
  rotate: (angleRad, pivot = new Point(0, 0)) ->
    cosA = Math.cos(angleRad)
    sinA = Math.sin(angleRad)
    dx = @x - pivot.x
    dy = @y - pivot.y
    new Point(
      Math.round(pivot.x + (dx * cosA - dy * sinA)),
      Math.round(pivot.y + (dx * sinA + dy * cosA))
    )

  # Rotate point by angle in degrees
  rotateDeg: (angleDeg, pivot = new Point(0, 0)) ->
    @rotate(Units.degToRad(angleDeg), pivot)

  translate: (dx, dy) ->
    new Point(@x + dx, @y + dy)

  # Dot product treating point as vector from origin
  dot: (other) -> (@x * other.x) + (@y * other.y)

  # 2D cross product (determinant)
  cross: (other) -> (@x * other.y) - (@y * other.x)

  toString: -> "(#{@x}, #{@y})"


class Vector2D
  constructor: (@dx = 0, @dy = 0) ->

  @fromPoints: (p1, p2) ->
    new Vector2D(p2.x - p1.x, p2.y - p1.y)

  lengthSq: -> @dx * @dx + @dy * @dy
  length: -> Math.sqrt(@lengthSq())

  normalize: ->
    len = @length()
    if len < 1e-9
      new Vector2D(0, 0)
    else
      new Vector2D(@dx / len, @dy / len)

  scale: (s) -> new Vector2D(@dx * s, @dy * s)

  # Normal perpendicular vector (rotated 90 degrees counter-clockwise)
  perpendicular: -> new Vector2D(-@dy, @dx)

  dot: (other) -> @dx * other.dx + @dy * other.dy
  cross: (other) -> @dx * other.dy - @dy * other.dx

  angle: ->
    rad = Math.atan2(@dy, @dx)
    Units.normalizeRad(rad)


class BoundingBox
  constructor: (@minX = Infinity, @minY = Infinity, @maxX = -Infinity, @maxY = -Infinity) ->

  @fromPoints: (points) ->
    bb = new BoundingBox()
    for pt in points
      bb.expandToPoint(pt)
    bb

  clone: -> new BoundingBox(@minX, @minY, @maxX, @maxY)

  isValid: -> @minX <= @maxX and @minY <= @maxY

  width: -> if @isValid() then @maxX - @minX else 0
  height: -> if @isValid() then @maxY - @minY else 0
  area: -> @width() * @height()

  center: ->
    new Point(
      Math.round((@minX + @maxX) / 2),
      Math.round((@minY + @maxY) / 2)
    )

  expandToPoint: (pt) ->
    @minX = Math.min(@minX, pt.x)
    @minY = Math.min(@minY, pt.y)
    @maxX = Math.max(@maxX, pt.x)
    @maxY = Math.max(@maxY, pt.y)
    this

  expandByMargin: (margin) ->
    new BoundingBox(
      @minX - margin,
      @minY - margin,
      @maxX + margin,
      @maxY + margin
    )

  containsPoint: (pt) ->
    pt.x >= @minX and pt.x <= @maxX and pt.y >= @minY and pt.y <= @maxY

  intersects: (other) ->
    not (@maxX < other.minX or @minX > other.maxX or @maxY < other.minY or @minY > other.maxY)

  union: (other) ->
    return @clone() unless other?.isValid()
    return other.clone() unless @isValid()
    new BoundingBox(
      Math.min(@minX, other.minX),
      Math.min(@minY, other.minY),
      Math.max(@maxX, other.maxX),
      Math.max(@maxY, other.maxY)
    )

  intersection: (other) ->
    return new BoundingBox() unless @intersects(other)
    new BoundingBox(
      Math.max(@minX, other.minX),
      Math.max(@minY, other.minY),
      Math.min(@maxX, other.maxX),
      Math.min(@maxY, other.maxY)
    )


class LineSegment
  constructor: (@p1, @p2) ->

  lengthSq: -> @p1.distSq(@p2)
  length: -> @p1.dist(@p2)

  dx: -> @p2.x - @p1.x
  dy: -> @p2.y - @p1.y

  angle: ->
    rad = Math.atan2(@dy(), @dx())
    Units.normalizeRad(rad)

  midpoint: -> @p1.midpoint(@p2)

  boundingBox: ->
    new BoundingBox(
      Math.min(@p1.x, @p2.x),
      Math.min(@p1.y, @p2.y),
      Math.max(@p1.x, @p2.x),
      Math.max(@p1.y, @p2.y)
    )

  # Closest point on this line segment to an external query point
  closestPointTo: (pt) ->
    segLenSq = @lengthSq()
    if segLenSq < 1e-9
      return @p1.clone()

    # Parametric projection t in [0, 1]
    t = ((pt.x - @p1.x) * @dx() + (pt.y - @p1.y) * @dy()) / segLenSq
    t = Math.max(0.0, Math.min(1.0, t))

    new Point(
      Math.round(@p1.x + t * @dx()),
      Math.round(@p1.y + t * @dy())
    )

  distanceToPoint: (pt) ->
    closest = @closestPointTo(pt)
    closest.dist(pt)

  # Check if two line segments intersect
  intersects: (other) ->
    ccw = (a, b, c) ->
      (c.y - a.y) * (b.x - a.x) > (b.y - a.y) * (c.x - a.x)

    a = @p1
    b = @p2
    c = other.p1
    d = other.p2

    (ccw(a, c, d) isnt ccw(b, c, d)) and (ccw(a, b, c) isnt ccw(a, b, d))

  # Calculate exact intersection point between two non-collinear segments
  intersectionPoint: (other) ->
    return null unless @intersects(other)

    x1 = @p1.x
    y1 = @p1.y
    x2 = @p2.x
    y2 = @p2.y
    x3 = other.p1.x
    y3 = other.p1.y
    x4 = other.p2.x
    y4 = other.p2.y

    denom = (x1 - x2) * (y3 - y4) - (y1 - y2) * (x3 - x4)
    return null if Math.abs(denom) < 1e-9

    t = ((x1 - x3) * (y3 - y4) - (y1 - y3) * (x3 - x4)) / denom
    new Point(
      Math.round(x1 + t * (x2 - x1)),
      Math.round(y1 + t * (y2 - y1))
    )

  # Compute parallel offset segment by signed distance
  offset: (distance) ->
    vec = Vector2D.fromPoints(@p1, @p2).normalize().perpendicular()
    shiftX = Math.round(vec.dx * distance)
    shiftY = Math.round(vec.dy * distance)
    new LineSegment(
      new Point(@p1.x + shiftX, @p1.y + shiftY),
      new Point(@p2.x + shiftX, @p2.y + shiftY)
    )


class Arc
  constructor: (@center, @radius, @startAngleRad, @endAngleRad, @clockwise = false) ->

  length: ->
    span = Math.abs(@endAngleRad - @startAngleRad)
    @radius * span

  pointAt: (t) -> # t in [0, 1]
    angle = @startAngleRad + t * (@endAngleRad - @startAngleRad)
    new Point(
      Math.round(@center.x + @radius * Math.cos(angle)),
      Math.round(@center.y + @radius * Math.sin(angle))
    )

  boundingBox: ->
    pts = [@pointAt(0), @pointAt(1)]
    # Check cardinal compass points falling within arc span
    twoPi = 2 * Math.PI
    for i in [0..3]
      cardinalAngle = (i * Math.PI) / 2
      # Check if cardinalAngle is inside span
      relStart = Units.normalizeRad(@startAngleRad)
      relEnd = Units.normalizeRad(@endAngleRad)
      inside = if relStart <= relEnd
        cardinalAngle >= relStart and cardinalAngle <= relEnd
      else
        cardinalAngle >= relStart or cardinalAngle <= relEnd

      if inside
        pts.push new Point(
          Math.round(@center.x + @radius * Math.cos(cardinalAngle)),
          Math.round(@center.y + @radius * Math.sin(cardinalAngle))
        )
    BoundingBox.fromPoints(pts)


module.exports = {
  Point
  Vector2D
  BoundingBox
  LineSegment
  Arc
}
