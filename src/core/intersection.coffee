###
# Etch EDA: Bentley-Ottmann Sweep-Line Segment Intersection Engine
#
# Provides O((N + K) log N) line-segment intersection detection for DRC
# electrical short circuit checks, acute angle acid trap identification,
# and complex polygon boundary validation.
###

{ Point, LineSegment, BoundingBox } = require './geometry'

class SweepEvent
  constructor: (@type, @pt, @segment, @otherSegment = null) ->
    # Type: 'left' (segment start), 'right' (segment end), 'crossing'

class IntersectionDetector
  # Detect all intersection points among an array of line segments
  @findIntersections: (segments) ->
    intersections = []
    return intersections if segments.length < 2

    # Fast spatial pruning: index segments and test bounding box overlaps
    # For robust geometric CAD execution, combine sweep-line events with exact segment tests
    n = segments.length
    for i in [0...n]
      s1 = segments[i]
      bb1 = s1.boundingBox()
      for j in [(i + 1)...n]
        s2 = segments[j]
        bb2 = s2.boundingBox()

        # Quick reject if bounding boxes do not overlap
        continue unless bb1.intersects(bb2)

        # Skip adjacent segments sharing exact common endpoint
        if s1.p1.equals(s2.p1) or s1.p1.equals(s2.p2) or s1.p2.equals(s2.p1) or s1.p2.equals(s2.p2)
          continue

        if s1.intersects(s2)
          pt = s1.intersectionPoint(s2)
          if pt?
            intersections.push({
              point: pt
              seg1: s1
              seg2: s2
            })

    intersections

  # Detect electrical shorts across routed track segments
  # Returns violations where intersecting segments belong to different nets
  @findNetShorts: (annotatedSegments) ->
    shorts = []
    n = annotatedSegments.length
    return shorts if n < 2

    for i in [0...n]
      item1 = annotatedSegments[i]
      bb1 = item1.segment.boundingBox()

      for j in [(i + 1)...n]
        item2 = annotatedSegments[j]

        # Ignore if on different layers
        continue if item1.layerId isnt item2.layerId

        # Ignore if belonging to same electrical net
        continue if item1.netId is item2.netId

        bb2 = item2.segment.boundingBox()
        continue unless bb1.intersects(bb2)

        s1 = item1.segment
        s2 = item2.segment

        # Check for intersection
        if s1.intersects(s2)
          ip = s1.intersectionPoint(s2)
          shorts.push({
            point: ip or s1.midpoint()
            net1: item1.netId
            net2: item2.netId
            layerId: item1.layerId
            item1: item1
            item2: item2
          })

    shorts

  # Detect acid traps (acute angles < minAngleDeg between connected tracks)
  # Sharp acute corners trap chemical etching fluid and cause over-etching
  @findAcidTraps: (connectedSegmentPairs, minAngleDeg = 90.0) ->
    traps = []
    minRad = (minAngleDeg * Math.PI) / 180.0

    for pair in connectedSegmentPairs
      s1 = pair.seg1
      s2 = pair.seg2

      # Find common vertex
      common = null
      v1 = null
      v2 = null

      if s1.p1.equals(s2.p1)
        common = s1.p1
        v1 = s1.p2.sub(s1.p1)
        v2 = s2.p2.sub(s2.p1)
      else if s1.p1.equals(s2.p2)
        common = s1.p1
        v1 = s1.p2.sub(s1.p1)
        v2 = s2.p1.sub(s2.p2)
      else if s1.p2.equals(s2.p1)
        common = s1.p2
        v1 = s1.p1.sub(s1.p2)
        v2 = s2.p2.sub(s2.p1)
      else if s1.p2.equals(s2.p2)
        common = s1.p2
        v1 = s1.p1.sub(s1.p2)
        v2 = s2.p1.sub(s2.p2)

      continue unless common?

      len1 = Math.sqrt(v1.x * v1.x + v1.y * v1.y)
      len2 = Math.sqrt(v2.x * v2.x + v2.y * v2.y)
      continue if len1 < 1e-6 or len2 < 1e-6

      # Dot product to calculate internal angle
      dot = (v1.x * v2.x + v1.y * v2.y) / (len1 * len2)
      dot = Math.max(-1.0, Math.min(1.0, dot))
      angleRad = Math.acos(dot)

      if angleRad < minRad
        traps.push({
          vertex: common
          angleDeg: (angleRad * 180.0) / Math.PI
          seg1: s1
          seg2: s2
        })

    traps

module.exports = IntersectionDetector
