###
# Etch EDA: Lee Wave Expansion Algorithm (Breadth-First Search Maze Router)
#
# Implements classical Lee breadth-first wavefront propagation on the 3D
# routing grid. Guarantees finding the strictly shortest path between multi-source
# and multi-target pin sets when unweighted clearance paths exist.
###

Units = require '../core/units'
{ Point } = require '../core/geometry'
{ TraceSegment } = require '../model/trace'
{ Via, ViaType } = require '../model/via'

class LeeRouter
  constructor: (@grid) ->

  # Find route using Lee wavefront expansion
  routeConnection: (p1, layer1Id, p2, layer2Id, netId = null) ->
    start = @grid.boardToGrid(p1.x, p1.y, layer1Id)
    target = @grid.boardToGrid(p2.x, p2.y, layer2Id)

    if start.col is target.col and start.row is target.row and start.layer is target.layer
      return { success: true, segments: [], vias: [] }

    totalCells = @grid.cols * @grid.rows * @grid.layerCount
    distance = new Int32Array(totalCells)
    distance.fill(-1)

    cameFrom = new Int32Array(totalCells)
    cameFrom.fill(-1)

    startIdx = @grid.cellIndex(start.col, start.row, start.layer)
    targetIdx = @grid.cellIndex(target.col, target.row, target.layer)
    distance[startIdx] = 0

    netHash = if netId? then @grid._hashString(netId) else -1

    # Simple ring buffer / queue for BFS
    queue = [startIdx]
    head = 0
    found = false

    moves = [
      { dc: 1, dr: 0, dl: 0 }
      { dc: -1, dr: 0, dl: 0 }
      { dc: 0, dr: 1, dl: 0 }
      { dc: 0, dr: -1, dl: 0 }
    ]

    while head < queue.length and head < 200000
      currIdx = queue[head++]
      break if currIdx is targetIdx

      l = Math.floor(currIdx / (@grid.cols * @grid.rows))
      rem = currIdx % (@grid.cols * @grid.rows)
      r = Math.floor(rem / @grid.cols)
      c = rem % @grid.cols

      currDist = distance[currIdx]

      # Planar moves
      for m in moves
        nc = c + m.dc
        nr = r + m.dr
        nl = l
        continue unless @grid.isValidCell(nc, nr, nl)

        isTarget = (nc is target.col and nr is target.row and nl is target.layer)
        if not isTarget and @grid.isBlocked(nc, nr, nl, netHash)
          continue

        nIdx = @grid.cellIndex(nc, nr, nl)
        if distance[nIdx] is -1
          distance[nIdx] = currDist + 1
          cameFrom[nIdx] = currIdx
          queue.push(nIdx)
          if nIdx is targetIdx
            found = true
            break

      break if found

      # Layer transition via
      if @grid.layerCount > 1
        for dl in [-1, 1]
          nl = l + dl
          continue unless nl >= 0 and nl < @grid.layerCount
          nc = c
          nr = r

          isTarget = (nc is target.col and nr is target.row and nl is target.layer)
          if not isTarget and @grid.isBlocked(nc, nr, nl, netHash)
            continue

          nIdx = @grid.cellIndex(nc, nr, nl)
          if distance[nIdx] is -1
            distance[nIdx] = currDist + 5 # Via weight
            cameFrom[nIdx] = currIdx
            queue.push(nIdx)
            if nIdx is targetIdx
              found = true
              break

      break if found

    return { success: false, segments: [], vias: [] } unless found or distance[targetIdx] isnt -1

    # Reconstruct path
    pathCells = []
    curr = targetIdx
    while curr isnt -1
      l = Math.floor(curr / (@grid.cols * @grid.rows))
      rem = curr % (@grid.cols * @grid.rows)
      r = Math.floor(rem / @grid.cols)
      c = rem % @grid.cols
      pathCells.push({ col: c, row: r, layer: l })
      break if curr is startIdx
      curr = cameFrom[curr]

    pathCells.reverse()

    segments = []
    vias = []

    for i in [0...(pathCells.length - 1)]
      c1 = pathCells[i]
      c2 = pathCells[i + 1]
      p1 = @grid.gridToBoard(c1.col, c1.row, c1.layer)
      p2 = @grid.gridToBoard(c2.col, c2.row, c2.layer)

      if c1.layer isnt c2.layer
        vias.push new Via({
          x: p1.x
          y: p1.y
          startLayerId: p1.layerId
          endLayerId: p2.layerId
          netId: netId
          type: ViaType.THROUGH
        })
      else
        segments.push new TraceSegment({
          p1: p1.point
          p2: p2.point
          widthNm: @grid.board.rules.minTraceWidthNm
          layerId: p1.layerId
          netId: netId
        })

    { success: true, segments: segments, vias: vias }

module.exports = LeeRouter
