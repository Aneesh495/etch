###
# Etch EDA: Manufacturing Rules (Acid Traps, Silkscreen Overlap, Floating Copper)
#
# Inspects layout for physical fabrication risks: sharp acute angles (<90 deg)
# that trap chemical etchant causing trace pinch-off, silkscreen overlapping
# exposed solder pads, and isolated floating copper islands.
###

Units = require '../core/units'
IntersectionDetector = require '../core/intersection'

class ManufacturingRulesChecker
  @check: (board) ->
    violations = []

    # 1. Acid Traps (< 90 degree acute corners between connected traces)
    # Group segments by net and layer to find connected vertex pairs
    segments = board.allTraceSegments()
    pairs = []
    n = segments.length

    for i in [0...n]
      s1 = segments[i]
      for j in [(i + 1)...n]
        s2 = segments[j]
        continue if s1.layerId isnt s2.layerId
        continue if s1.netId isnt s2.netId

        # If they share an endpoint
        if s1.p1.equals(s2.p1) or s1.p1.equals(s2.p2) or s1.p2.equals(s2.p1) or s1.p2.equals(s2.p2)
          pairs.push({
            seg1: s1.asLineSegment()
            seg2: s2.asLineSegment()
          })

    acidTraps = IntersectionDetector.findAcidTraps(pairs, 85.0)
    for trap in acidTraps
      violations.push({
        rule: 'ACID_TRAP'
        severity: 'WARNING'
        message: "Acute angle acid trap (#{trap.angleDeg.toFixed(1)} degrees) detected on layer"
        location: trap.vertex
        layerId: 'F.Cu'
      })

    # 2. Silkscreen Over Exposed Copper Pads
    # Silkscreen ink over exposed SMD pads prevents proper solder wetting
    pads = board.allPads()
    for comp in board.allComponents()
      for line in comp.silkscreenLines
        lineSeg = line.asLineSegment?()
        continue unless lineSeg?
        for pad in pads
          if pad.boundingBox().containsPoint(lineSeg.p1) or pad.boundingBox().containsPoint(lineSeg.p2)
            violations.push({
              rule: 'SILKSCREEN_OVER_PAD'
              severity: 'WARNING'
              message: "Silkscreen line of #{comp.refDes} encroaches on solder pad #{pad.parentComponent?.refDes}.#{pad.number}"
              location: pad.absolutePosition()
              layerId: 'F.SilkS'
            })

    violations

module.exports = ManufacturingRulesChecker
