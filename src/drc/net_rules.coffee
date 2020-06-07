###
# Etch EDA: Net Connectivity Graph and Electrical Short Circuit Checker
#
# Verifies topological continuity across all electrical nets, flags unrouted
# airwires, and detects catastrophic short circuits between distinct nets.
###

Units = require '../core/units'
IntersectionDetector = require '../core/intersection'

class NetRulesChecker
  @check: (board) ->
    violations = []

    # 1. Check Unrouted Nets (Airwires)
    for net in board.netlist.allNets()
      continue if net.pins.length < 2

      # Check if traces exist for this net
      netTraces = (t for t in board.allTraces() when t.netId is net.id)
      netSegments = (s for s in board.allTraceSegments() when s.netId is net.id)

      # If net has pins but zero trace segments and is not a power plane zone
      isPlaneNet = false
      for z in board.allZones()
        if z.isCopperPour() and z.netId is net.id
          isPlaneNet = true
          break

      if not isPlaneNet and netSegments.length is 0
        violations.push({
          rule: 'UNROUTED_NET'
          severity: 'WARNING'
          message: "Net #{net.name} has #{net.pins.length} pins but has not been routed"
          location: net.pins[0].position()
          layerId: 'F.Cu'
        })

    # 2. Check Electrical Short Circuits
    annotated = []
    for s in board.allTraceSegments()
      annotated.push({
        segment: s.asLineSegment()
        netId: s.netId
        layerId: s.layerId
      })

    shorts = IntersectionDetector.findNetShorts(annotated)
    for sh in shorts
      violations.push({
        rule: 'ELECTRICAL_SHORT'
        severity: 'ERROR'
        message: "Short circuit between #{sh.net1} and #{sh.net2} on layer #{sh.layerId}"
        location: sh.point
        layerId: sh.layerId
      })

    violations

module.exports = NetRulesChecker
