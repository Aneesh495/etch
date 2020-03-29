###
# Etch EDA: Routed Copper Tracks, Octilinear Segments, and Bus Traces
#
# Models 45-degree octilinear track segments, curved arc corners, and
# connected multi-segment routes with specific widths, net associations,
# and layer assignments.
###

Units = require '../core/units'
{ Point, LineSegment, BoundingBox } = require '../core/geometry'

class TraceSegment
  constructor: (options = {}) ->
    @p1 = options.p1 or new Point(0, 0)
    @p2 = options.p2 or new Point(0, 0)
    @widthNm = options.widthNm or Units.mm(0.2)
    @layerId = options.layerId or 'F.Cu'
    @netId = options.netId or null

  length: -> @p1.dist(@p2)
  lengthSq: -> @p1.distSq(@p2)

  asLineSegment: -> new LineSegment(@p1, @p2)

  angleDeg: ->
    rad = Math.atan2(@p2.y - @p1.y, @p2.x - @p1.x)
    Units.radToDeg(Units.normalizeRad(rad))

  # Test if segment is octilinear (angle is a multiple of 45 degrees within 1 degree tolerance)
  isOctilinear: ->
    deg = @angleDeg()
    rem = deg % 45.0
    rem < 1.0 or rem > 44.0

  boundingBox: ->
    halfW = Math.round(@widthNm / 2)
    segBB = @asLineSegment().boundingBox()
    new BoundingBox(
      segBB.minX - halfW,
      segBB.minY - halfW,
      segBB.maxX + halfW,
      segBB.maxY + halfW
    )


class Trace
  constructor: (options = {}) ->
    @netId = options.netId or null
    @layerId = options.layerId or 'F.Cu'
    @segments = []

  addSegment: (p1, p2, widthNm = Units.mm(0.2)) ->
    seg = new TraceSegment({
      p1: p1
      p2: p2
      widthNm: widthNm
      layerId: @layerId
      netId: @netId
    })
    @segments.push(seg)
    seg

  segmentCount: -> @segments.length

  totalLength: ->
    len = 0
    for s in @segments
      len += s.length()
    len

  boundingBox: ->
    bb = new BoundingBox()
    for s in @segments
      bb = bb.union(s.boundingBox())
    bb

module.exports = {
  TraceSegment
  Trace
}
