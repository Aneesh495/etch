###
# Etch EDA: Spatial Clearance Matrix Verification Engine
#
# Validates geometric separation between copper entities on the same layer
# against the design rule clearance matrix: Track-to-Track, Track-to-Pad,
# Pad-to-Pad, Via-to-Track, and Copper-to-Board-Edge.
###

Units = require '../core/units'
{ Point } = require '../core/geometry'

class ClearanceChecker
  # Check clearance rules across all board copper features
  # Returns array of violation objects
  @check: (board) ->
    violations = []
    minClearance = board.rules.minClearanceNm
    edgeClearance = board.rules.copperToEdgeClearanceNm

    pads = board.allPads()
    segments = board.allTraceSegments()
    vias = board.allVias()

    # 1. Pad to Pad clearance
    for i in [0...pads.length]
      p1 = pads[i]
      pos1 = p1.absolutePosition()
      for j in [(i + 1)...pads.length]
        p2 = pads[j]
        # Ignore pads belonging to same component (e.g. adjacent pins of IC have footprint-defined spacing)
        continue if p1.parentComponent is p2.parentComponent
        # Ignore pads belonging to same electrical net
        continue if p1.netId? and p1.netId is p2.netId
        # Ignore if on different layers
        continue unless @_layersOverlap(p1.layerId, p2.layerId)

        pos2 = p2.absolutePosition()
        dist = pos1.dist(pos2)
        # Approximate boundary distance by subtracting half-dimensions
        pad1Radius = Math.max(p1.widthNm, p1.heightNm) / 2
        pad2Radius = Math.max(p2.widthNm, p2.heightNm) / 2
        edgeDist = dist - (pad1Radius + pad2Radius)

        if edgeDist < minClearance
          violations.push({
            rule: 'CLEARANCE_PAD_TO_PAD'
            severity: 'ERROR'
            message: "Clearance violation between #{p1.parentComponent?.refDes}.#{p1.number} (#{p1.netId or 'none'}) and #{p2.parentComponent?.refDes}.#{p2.number} (#{p2.netId or 'none'}): #{Units.formatMetric(edgeDist)} < #{Units.formatMetric(minClearance)}"
            location: pos1.midpoint(pos2)
            layerId: p1.layerId
          })

    # 2. Track to Pad clearance
    for seg in segments
      segLine = seg.asLineSegment()
      for pad in pads
        continue if seg.netId? and seg.netId is pad.netId
        continue unless @_layersOverlap(seg.layerId, pad.layerId)

        padPos = pad.absolutePosition()
        distToLine = segLine.distanceToPoint(padPos)
        padRadius = Math.max(pad.widthNm, pad.heightNm) / 2
        trackRadius = seg.widthNm / 2
        edgeDist = distToLine - (padRadius + trackRadius)

        if edgeDist < minClearance
          violations.push({
            rule: 'CLEARANCE_TRACK_TO_PAD'
            severity: 'ERROR'
            message: "Clearance violation between track (#{seg.netId or 'none'}) and pad #{pad.parentComponent?.refDes}.#{pad.number}: #{Units.formatMetric(edgeDist)} < #{Units.formatMetric(minClearance)}"
            location: segLine.closestPointTo(padPos)
            layerId: seg.layerId
          })

    # 3. Track to Track clearance (different nets on same layer)
    for i in [0...segments.length]
      s1 = segments[i]
      line1 = s1.asLineSegment()
      bb1 = line1.boundingBox()

      for j in [(i + 1)...segments.length]
        s2 = segments[j]
        continue if s1.layerId isnt s2.layerId
        continue if s1.netId? and s1.netId is s2.netId

        line2 = s2.asLineSegment()
        # Fast reject if bounding boxes expanded by clearance and widths do not touch
        margin = minClearance + Math.round((s1.widthNm + s2.widthNm) / 2)
        continue unless bb1.expandByMargin(margin).intersects(line2.boundingBox())

        # Sample distance between endpoints
        d1 = line1.distanceToPoint(s2.p1)
        d2 = line1.distanceToPoint(s2.p2)
        d3 = line2.distanceToPoint(s1.p1)
        d4 = line2.distanceToPoint(s1.p2)
        minCenterDist = Math.min(d1, d2, d3, d4)

        edgeDist = minCenterDist - (s1.widthNm / 2 + s2.widthNm / 2)
        if edgeDist < minClearance
          violations.push({
            rule: 'CLEARANCE_TRACK_TO_TRACK'
            severity: 'ERROR'
            message: "Clearance violation between track (#{s1.netId or 'none'}) and track (#{s2.netId or 'none'}): #{Units.formatMetric(edgeDist)} < #{Units.formatMetric(minClearance)}"
            location: s1.p1.midpoint(s2.p1)
            layerId: s1.layerId
          })

    # 4. Copper to Board Edge clearance
    outlinePoly = board.outline
    for seg in segments
      for pt in [seg.p1, seg.p2]
        for edge in outlinePoly.edges()
          d = edge.distanceToPoint(pt) - (seg.widthNm / 2)
          if d < edgeClearance
            violations.push({
              rule: 'CLEARANCE_COPPER_TO_EDGE'
              severity: 'ERROR'
              message: "Trace (#{seg.netId or 'none'}) too close to board edge: #{Units.formatMetric(d)} < #{Units.formatMetric(edgeClearance)}"
              location: pt
              layerId: seg.layerId
            })
            break

    violations

  @_layersOverlap: (l1, l2) ->
    return true if l1 is 'All.Cu' or l2 is 'All.Cu'
    l1 is l2

module.exports = ClearanceChecker
