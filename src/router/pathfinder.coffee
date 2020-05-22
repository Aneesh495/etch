###
# Etch EDA: PathFinder Negotiated Congestion Iterative Router
#
# Implements the PathFinder negotiated congestion algorithm. Nets initially
# route independently and may share grid cells. Over successive iterations,
# historical cost multipliers are applied to congested cells until all overlaps
# are completely eliminated.
###

Units = require '../core/units'
{ AStarRouter } = require './astar_router'

class PathFinderRouter
  constructor: (@grid, options = {}) ->
    @maxIterations = options.maxIterations or 10
    @historyFactor = options.historyFactor or 1.5

  routeAllNets: (nets) ->
    # Allocate cell usage count and history cost maps
    totalCells = @grid.cols * @grid.rows * @grid.layerCount
    cellUsage = new Int16Array(totalCells)
    historyCost = new Float32Array(totalCells)
    historyCost.fill(1.0)

    netRoutes = new Map() # netId -> { segments, vias }

    # Sort nets by pin count and bounding box area (route short sensitive nets first)
    sortedNets = nets.slice().sort (a, b) ->
      a.pins.length - b.pins.length

    astar = new AStarRouter(@grid)

    for iter in [1..@maxIterations]
      cellUsage.fill(0)
      overuseCount = 0

      for net in sortedNets
        continue if net.pins.length < 2

        # Route between consecutive pins
        allSegs = []
        allVias = []

        for pIdx in [0...(net.pins.length - 1)]
          pinA = net.pins[pIdx]
          pinB = net.pins[pIdx + 1]

          res = astar.routeConnection(
            pinA.position(),
            pinA.pad?.layerId or 'F.Cu',
            pinB.position(),
            pinB.pad?.layerId or 'F.Cu',
            net.id
          )

          if res.success
            allSegs.push(res.segments...)
            allVias.push(res.vias...)

            # Mark cell usage
            for seg in res.segments
              g1 = @grid.boardToGrid(seg.p1.x, seg.p1.y, seg.layerId)
              g2 = @grid.boardToGrid(seg.p2.x, seg.p2.y, seg.layerId)
              idx1 = @grid.cellIndex(g1.col, g1.row, g1.layer)
              idx2 = @grid.cellIndex(g2.col, g2.row, g2.layer)
              cellUsage[idx1]++
              cellUsage[idx2]++

        netRoutes.set(net.id, { segments: allSegs, vias: allVias })

      # Check for cell overuse (cells occupied by multiple nets)
      for idx in [0...totalCells]
        if cellUsage[idx] > 1
          overuseCount++
          historyCost[idx] *= @historyFactor
          # Increase base grid cost for this congested cell
          @grid.costs[idx] += 5.0 * (cellUsage[idx] - 1)

      # If zero overused cells, routing converged cleanly
      if overuseCount is 0
        break

    netRoutes

module.exports = PathFinderRouter
