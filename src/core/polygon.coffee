###
# Etch EDA: 2D Polygonal Geometry, Winding Analysis, and Point Enclosure
#
# Provides 2D polygon representations with hole support, shoelace area
# calculations, winding order normalization, centroid evaluation, and
# generalized winding-number point-in-polygon containment tests.
###

{ Point, Vector2D, LineSegment, BoundingBox } = require './geometry'
Units = require './units'

class Polygon
  constructor: (@vertices = [], @holes = []) ->

  @fromRect: (x, y, width, height) ->
    p1 = new Point(x, y)
    p2 = new Point(x + width, y)
    p3 = new Point(x + width, y + height)
    p4 = new Point(x, y + height)
    new Polygon([p1, p2, p3, p4])

  @fromBoundingBox: (bb) ->
    @fromRect(bb.minX, bb.minY, bb.width(), bb.height())

  clone: ->
    clonedVertices = (v.clone() for v in @vertices)
    clonedHoles = (h.clone() for h in @holes)
    new Polygon(clonedVertices, clonedHoles)

  vertexCount: -> @vertices.length

  addVertex: (pt) ->
    @vertices.push(pt)
    this

  addHole: (holePolygon) ->
    @holes.push(holePolygon)
    this

  # Signed area using Gauss shoelace formula
  # Positive indicates counter-clockwise (CCW); negative indicates clockwise (CW)
  signedArea: ->
    n = @vertices.length
    return 0 if n < 3
    sum = 0
    for i in [0...n]
      j = (i + 1) % n
      sum += (@vertices[i].x * @vertices[j].y) - (@vertices[j].x * @vertices[i].y)
    sum / 2.0

  area: ->
    outerArea = Math.abs(@signedArea())
    holesArea = 0
    for h in @holes
      holesArea += Math.abs(h.signedArea())
    Math.max(0, outerArea - holesArea)

  isCounterClockwise: -> @signedArea() > 0
  isClockwise: -> @signedArea() < 0

  ensureWinding: (wantCCW = true) ->
    if @isCounterClockwise() isnt wantCCW
      @vertices.reverse()
    for h in @holes
      # Standard convention: holes have opposite winding from outer contour
      h.ensureWinding(not wantCCW)
    this

  centroid: ->
    n = @vertices.length
    return new Point(0, 0) if n is 0
    return @vertices[0].clone() if n is 1

    cx = 0
    cy = 0
    signedAreaSum = 0

    for i in [0...n]
      j = (i + 1) % n
      cross = (@vertices[i].x * @vertices[j].y) - (@vertices[j].x * @vertices[i].y)
      signedAreaSum += cross
      cx += (@vertices[i].x + @vertices[j].x) * cross
      cy += (@vertices[i].y + @vertices[j].y) * cross

    area6 = signedAreaSum * 3.0
    if Math.abs(area6) < 1e-9
      # Fallback to arithmetic mean for degenerate zero-area polygons
      meanX = 0
      meanY = 0
      for v in @vertices
        meanX += v.x
        meanY += v.y
      return new Point(Math.round(meanX / n), Math.round(meanY / n))

    new Point(Math.round(cx / area6), Math.round(cy / area6))

  boundingBox: ->
    bb = BoundingBox.fromPoints(@vertices)
    bb

  edges: ->
    n = @vertices.length
    return [] if n < 2
    for i in [0...n]
      j = (i + 1) % n
      new LineSegment(@vertices[i], @vertices[j])

  # Generalized winding number test for point containment
  # Handles non-convex polygons, self-intersections, and boundary tolerances
  containsPoint: (pt, includeBoundary = true) ->
    return false unless @boundingBox().expandByMargin(10).containsPoint(pt)

    # First verify point is inside outer boundary
    wn = @_windingNumber(@vertices, pt)
    insideOuter = (wn isnt 0)

    # Check if point lies exactly on an edge
    if includeBoundary and not insideOuter
      for edge in @edges()
        if edge.distanceToPoint(pt) <= 1
          return true

    return false unless insideOuter

    # Check if point falls inside any cutout holes
    for hole in @holes
      if hole.containsPoint(pt, not includeBoundary)
        return false

    true

  _windingNumber: (vertices, pt) ->
    wn = 0
    n = vertices.length
    return 0 if n < 3

    for i in [0...n]
      v1 = vertices[i]
      v2 = vertices[(i + 1) % n]

      if v1.y <= pt.y
        if v2.y > pt.y
          # Upward crossing: test if point is strictly to the left of edge
          cross = (v2.x - v1.x) * (pt.y - v1.y) - (pt.x - v1.x) * (v2.y - v1.y)
          wn++ if cross > 0
      else
        if v2.y <= pt.y
          # Downward crossing: test if point is strictly to the right of edge
          cross = (v2.x - v1.x) * (pt.y - v1.y) - (pt.x - v1.x) * (v2.y - v1.y)
          wn-- if cross < 0
    wn

  # Remove collinear redundant vertices along edges
  cleanCollinear: (maxAngleDeviationRad = 0.01) ->
    n = @vertices.length
    return this if n < 3

    filtered = []
    for i in [0...n]
      prev = @vertices[(i + n - 1) % n]
      curr = @vertices[i]
      next = @vertices[(i + 1) % n]

      # Vector from prev to curr and curr to next
      dx1 = curr.x - prev.x
      dy1 = curr.y - prev.y
      dx2 = next.x - curr.x
      dy2 = next.y - curr.y

      len1 = Math.sqrt(dx1 * dx1 + dy1 * dy1)
      len2 = Math.sqrt(dx2 * dx2 + dy2 * dy2)

      # If duplicate points, skip curr
      if len1 < 1 or len2 < 1
        continue

      # Cross product divided by lengths gives sin(theta) between edges
      cross = (dx1 * dy2) - (dy1 * dx2)
      sinTheta = Math.abs(cross / (len1 * len2))
      dot = (dx1 * dx2) + (dy1 * dy2)

      # If angle is near 0 and vectors point in same forward direction, curr is redundant
      isCollinear = (sinTheta < maxAngleDeviationRad) and (dot > 0)
      filtered.push(curr) unless isCollinear

    @vertices = filtered
    this

  translate: (dx, dy) ->
    @vertices = (v.translate(dx, dy) for v in @vertices)
    for h in @holes
      h.translate(dx, dy)
    this

  rotateDeg: (deg, pivot = new Point(0, 0)) ->
    @vertices = (v.rotateDeg(deg, pivot) for v in @vertices)
    for h in @holes
      h.rotateDeg(deg, pivot)
    this

  # Approximate normal dilation (expansion/offset)
  # Expands each vertex outwards along vertex normal bisector
  inflate: (distance) ->
    n = @vertices.length
    return @clone() if n < 3

    @ensureWinding(true) # Ensure outer contour is counter-clockwise
    newVertices = []

    for i in [0...n]
      prev = @vertices[(i + n - 1) % n]
      curr = @vertices[i]
      next = @vertices[(i + 1) % n]

      # Edge vectors
      v1 = Vector2D.fromPoints(prev, curr).normalize()
      v2 = Vector2D.fromPoints(curr, next).normalize()

      # Outward normals (perpendicular rotated 90 deg clockwise in screen space)
      n1 = new Vector2D(v1.dy, -v1.dx)
      n2 = new Vector2D(v2.dy, -v2.dx)

      # Bisector
      bisector = new Vector2D(n1.dx + n2.dx, n1.dy + n2.dy).normalize()
      cosHalfAngle = bisector.dot(n1)
      miterLen = if Math.abs(cosHalfAngle) > 0.1
        distance / cosHalfAngle
      else
        distance

      # Clamp extreme miter lengths at sharp corners to 2.5x distance
      miterLen = Math.min(distance * 2.5, Math.max(-distance * 2.5, miterLen))

      shiftedX = Math.round(curr.x + bisector.dx * miterLen)
      shiftedY = Math.round(curr.y + bisector.dy * miterLen)
      newVertices.push new Point(shiftedX, shiftedY)

    new Polygon(newVertices)

module.exports = Polygon
