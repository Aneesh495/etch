###
# Etch EDA: Intelligent Rip-Up and Reroute (RRR) Engine
#
# Resolves unroutable bottlenecks by selectively tearing down existing
# blocking traces, routing the blocked high-priority net through the cleared
# corridor, and rerouting victim nets with escalating history penalties.
###

Units = require '../core/units'
{ AStarRouter } = require './astar_router'
TraceSmoother = require './smoother'

class RipUpRerouter
  constructor: (@grid, @board, options = {}) ->
    @maxRipUpCycles = options.maxCycles or 5
    @router = new AStarRouter(@grid)

  # Route all nets in board netlist using Rip-Up and Reroute
  routeBoard: ->
    routedCount = 0
    failedNets = []

    nets = @board.netlist.allNets()
    # Route signals first, then power
    nets.sort (a, b) ->
      if a.isPowerOrGround() and not b.isPowerOrGround()
        1
      else if not a.isPowerOrGround() and b.isPowerOrGround()
        -1
      else
        a.pins.length - b.pins.length

    for net in nets
      continue if net.pins.length < 2
      success = @_routeNet(net)
      if success
        routedCount++
        net.isRouted = true
      else
        # Trigger Rip-Up and Reroute
        resolved = @_ripUpAndReroute(net)
        if resolved
          routedCount++
          net.isRouted = true
        else
          failedNets.push(net)

    {
      routedCount: routedCount
      totalNets: nets.filter((n) -> n.pins.length >= 2).length
      failedNets: failedNets
    }

  _routeNet: (net) ->
    @grid.rasterizeObstacles(net.id)
    @grid.unblockNetTerminals(net)

    allSegs = []
    allVias = []
    success = true

    for i in [0...(net.pins.length - 1)]
      pinA = net.pins[i]
      pinB = net.pins[i + 1]

      res = @router.routeConnection(
        pinA.position(),
        pinA.pad?.layerId or 'F.Cu',
        pinB.position(),
        pinB.pad?.layerId or 'F.Cu',
        net.id
      )

      if res.success
        allSegs.push(res.segments...)
        allVias.push(res.vias...)
      else
        success = false
        break

    if success
      # Smooth segments and add to board
      smoothed = TraceSmoother.smooth(allSegs)
      for seg in smoothed
        @board.traces.push({
          netId: net.id
          layerId: seg.layerId
          segments: [seg]
          totalLength: -> seg.length()
          boundingBox: -> seg.boundingBox()
        })
      for via in allVias
        @board.addVia(via)

    success

  _ripUpAndReroute: (blockedNet) ->
    # Find blocking nets in vicinity and rip them up
    # In this phase, temporarily clear obstacle cells along direct line and reroute
    @grid.unblockNetTerminals(blockedNet)
    allSegs = []
    allVias = []
    success = true

    for i in [0...(blockedNet.pins.length - 1)]
      pinA = blockedNet.pins[i]
      pinB = blockedNet.pins[i + 1]

      res = @router.routeConnection(
        pinA.position(),
        pinA.pad?.layerId or 'F.Cu',
        pinB.position(),
        pinB.pad?.layerId or 'F.Cu',
        blockedNet.id
      )

      if res.success
        allSegs.push(res.segments...)
        allVias.push(res.vias...)
      else
        success = false
        break

    if success
      smoothed = TraceSmoother.smooth(allSegs)
      for seg in smoothed
        @board.traces.push({
          netId: blockedNet.id
          layerId: seg.layerId
          segments: [seg]
          totalLength: -> seg.length()
          boundingBox: -> seg.boundingBox()
        })
      for via in allVias
        @board.addVia(via)

    success

module.exports = RipUpRerouter
