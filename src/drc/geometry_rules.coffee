###
# Etch EDA: Geometric Design Rule Checker (Trace Width, Annular Ring, Drill Spacing)
#
# Validates minimum trace widths, pad/via annular ring thicknesses, drill
# hole sizes, and hole-to-hole clearance distances against manufacturing limits.
###

Units = require '../core/units'

class GeometryRulesChecker
  @check: (board) ->
    violations = []
    rules = board.rules

    # 1. Minimum Trace Width
    for seg in board.allTraceSegments()
      if seg.widthNm < rules.minTraceWidthNm
        violations.push({
          rule: 'MIN_TRACE_WIDTH'
          severity: 'ERROR'
          message: "Trace width #{Units.formatMetric(seg.widthNm)} is below minimum allowed #{Units.formatMetric(rules.minTraceWidthNm)}"
          location: seg.p1
          layerId: seg.layerId
        })

    # 2. Minimum Annular Ring for Vias and Through-Hole Pads
    for via in board.allVias()
      ring = via.annularRingNm()
      if ring < rules.minAnnularRingNm
        violations.push({
          rule: 'MIN_ANNULAR_RING'
          severity: 'ERROR'
          message: "Via annular ring #{Units.formatMetric(ring)} is below minimum allowed #{Units.formatMetric(rules.minAnnularRingNm)}"
          location: via.position()
          layerId: via.startLayerId
        })

    for pad in board.allPads()
      continue unless pad.isThroughHole()
      ring = pad.annularRingNm()
      if ring < rules.minAnnularRingNm
        violations.push({
          rule: 'MIN_ANNULAR_RING'
          severity: 'ERROR'
          message: "Pad #{pad.parentComponent?.refDes}.#{pad.number} annular ring #{Units.formatMetric(ring)} is below minimum allowed #{Units.formatMetric(rules.minAnnularRingNm)}"
          location: pad.absolutePosition()
          layerId: pad.layerId
        })

    # 3. Minimum Drill Diameter
    for via in board.allVias()
      if via.drillDiameterNm < rules.minDrillDiameterNm
        violations.push({
          rule: 'MIN_DRILL_DIAMETER'
          severity: 'ERROR'
          message: "Via drill diameter #{Units.formatMetric(via.drillDiameterNm)} is below minimum allowed #{Units.formatMetric(rules.minDrillDiameterNm)}"
          location: via.position()
          layerId: 'All.Cu'
        })

    for pad in board.allPads()
      continue unless pad.isThroughHole()
      if pad.drillDiameterNm < rules.minDrillDiameterNm
        violations.push({
          rule: 'MIN_DRILL_DIAMETER'
          severity: 'ERROR'
          message: "Pad drill diameter #{Units.formatMetric(pad.drillDiameterNm)} is below minimum allowed #{Units.formatMetric(rules.minDrillDiameterNm)}"
          location: pad.absolutePosition()
          layerId: 'All.Cu'
        })

    # 4. Drill-to-Drill Spacing (Hole-to-Hole Distance)
    holes = []
    for pad in board.allPads()
      if pad.isThroughHole()
        holes.push({ pos: pad.absolutePosition(), drill: pad.drillDiameterNm, id: "#{pad.parentComponent?.refDes}.#{pad.number}" })
    for via in board.allVias()
      holes.push({ pos: via.position(), drill: via.drillDiameterNm, id: "via_#{via.netId}" })
    for mh in board.mountingHoles
      holes.push({ pos: new Point(mh.x, mh.y), drill: mh.drillDiameterNm, id: 'mounting_hole' })

    for i in [0...holes.length]
      h1 = holes[i]
      for j in [(i + 1)...holes.length]
        h2 = holes[j]
        centerDist = h1.pos.dist(h2.pos)
        edgeDist = centerDist - (h1.drill / 2 + h2.drill / 2)
        if edgeDist < rules.minHoleToHoleClearanceNm
          violations.push({
            rule: 'DRILL_TO_DRILL_CLEARANCE'
            severity: 'ERROR'
            message: "Hole-to-hole clearance between #{h1.id} and #{h2.id} is #{Units.formatMetric(edgeDist)} < #{Units.formatMetric(rules.minHoleToHoleClearanceNm)}"
            location: h1.pos.midpoint(h2.pos)
            layerId: 'All.Cu'
          })

    violations

module.exports = GeometryRulesChecker
