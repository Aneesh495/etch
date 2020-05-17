###
# Etch EDA: 3D Multi-Layer A-Star Heuristic Maze Router
#
# Implements an optimal 3D heuristic pathfinder over the discretized routing
# lattice with min-heap priority queues, directional layer biasing, via penalty
# minimization, and corner-cutting prevention.
###

Units = require '../core/units'
{ Point } = require '../core/geometry'
{ TraceSegment } = require '../model/trace'
{ Via, ViaType } = require '../model/via'

# Fast Binary Min-Heap Priority Queue
class BinaryHeap
  constructor: ->
    @content = []

  push: (element) ->
    @content.push(element)
    @_bubbleUp(@content.length - 1)

  pop: ->
    result = @content[0]
    end = @content.pop()
    if @content.length > 0
      @content[0] = end
      @_sinkDown(0)
    result

  size: -> @content.length
  isEmpty: -> @content.length is 0

  _bubbleUp: (n) ->
    element = @content[n]
    score = element.f
    while n > 0
      parentN = Math.floor((n + 1) / 2) - 1
      parent = @content[parentN]
      break if score >= parent.f
      @content[parentN] = element
      @content[n] = parent
      n = parentN

  _sinkDown: (n) ->
    length = @content.length
    element = @content[n]
    elemScore = element.f

    loop
      child2N = (n + 1) * 2
      child1N = child2N - 1
      swap = null
      child1Score = 0

      if child1N < length
        child1 = @content[child1N]
        child1Score = child1.f
        swap = child1N if child1Score < elemScore

      if child2N < length
        child2 = @content[child2N]
        if child2.f < (if swap is null then elemScore else child1Score)
          swap = child2N

      break if swap is null
      @content[n] = @content[swap]
      @content[swap] = element
      n = swap


class AStarRouter
  constructor: (@grid) ->
    @SQRT2 = Math.SQRT2

  # Route a connection between two board points on specific layers
  # Returns { success, segments: [...], vias: [...] }
  routeConnection: (p1, layer1Id, p2, layer2Id, netId = null) ->
    start = @grid.boardToGrid(p1.x, p1.y, layer1Id)
    target = @grid.boardToGrid(p2.x, p2.y, layer2Id)

    # If start and target are the exact same cell
    if start.col is target.col and start.row is target.row and start.layer is target.layer
      return { success: true, segments: [], vias: [] }

    netHash = if netId? then @grid._hashString(netId) else -1
    totalCells = @grid.cols * @grid.rows * @grid.layerCount

    gScore = new Float32Array(totalCells)
    gScore.fill(Infinity)

    # 1D index parent mapping for path reconstruction
    cameFrom = new Int32Array(totalCells)
    cameFrom.fill(-1)

    closedSet = new Uint8Array(totalCells)

    startIdx = @grid.cellIndex(start.col, start.row, start.layer)
    gScore[startIdx] = 0.0

    openHeap = new BinaryHeap()
    hStart = @_heuristic(start.col, start.row, start.layer, target.col, target.row, target.layer)
    openHeap.push({
      col: start.col
      row: start.row
      layer: start.layer
      idx: startIdx
      g: 0.0
      f: hStart
    })

    foundTarget = false
    targetIdx = @grid.cellIndex(target.col, target.row, target.layer)

    # 8 planar directions: (dCol, dRow, baseCost, isDiagonal, isHorizontal, isVertical)
    moves2D = [
      { dc: 1, dr: 0, cost: 1.0, isDiag: false, isH: true, isV: false }   # Right
      { dc: -1, dr: 0, cost: 1.0, isDiag: false, isH: true, isV: false }  # Left
      { dc: 0, dr: 1, cost: 1.0, isDiag: false, isH: false, isV: true }   # Up
      { dc: 0, dr: -1, cost: 1.0, isDiag: false, isH: false, isV: true }  # Down
      { dc: 1, dr: 1, cost: @SQRT2, isDiag: true, isH: false, isV: false }   # Top-Right
      { dc: -1, dr: 1, cost: @SQRT2, isDiag: true, isH: false, isV: false }  # Top-Left
      { dc: 1, dr: -1, cost: @SQRT2, isDiag: true, isH: false, isV: false }  # Bottom-Right
      { dc: -1, dr: -1, cost: @SQRT2, isDiag: true, isH: false, isV: false } # Bottom-Left
    ]

    maxExplorations = Math.min(totalCells * 2, 250000)
    iterations = 0

    while not openHeap.isEmpty() and iterations < maxExplorations
      iterations++
      curr = openHeap.pop()
      currIdx = curr.idx

      continue if closedSet[currIdx] is 1
      closedSet[currIdx] = 1

      if curr.col is target.col and curr.row is target.row and curr.layer is target.layer
        foundTarget = true
        break

      currG = curr.g

      # 1. Planar moves on current layer
      currLayer = curr.layer
      isTopLayer = (currLayer is 0) # Layer 0 prefers horizontal

      for m in moves2D
        nc = curr.col + m.dc
        nr = curr.row + m.dr
        nl = currLayer

        continue unless @grid.isValidCell(nc, nr, nl)

        # Check obstacle blockage (target cell is exempt)
        isTargetCell = (nc is target.col and nr is target.row and nl is target.layer)
        if not isTargetCell and @grid.isBlocked(nc, nr, nl, netHash)
          continue

        # Prevent corner cutting through diagonal obstacles
        if m.isDiag
          if @grid.isBlocked(curr.col + m.dc, curr.row, nl, netHash) or @grid.isBlocked(curr.col, curr.row + m.dr, nl, netHash)
            continue

        # Apply directional layer cost bias
        moveCost = m.cost
        if isTopLayer and m.isV
          moveCost *= @grid.yLayerBias # Top layer prefers horizontal
        else if not isTopLayer and m.isH
          moveCost *= @grid.xLayerBias # Inner/bottom layers prefer vertical

        nIdx = @grid.cellIndex(nc, nr, nl)
        continue if closedSet[nIdx] is 1

        tentativeG = currG + moveCost
        if tentativeG < gScore[nIdx]
          gScore[nIdx] = tentativeG
          cameFrom[nIdx] = currIdx
          h = @_heuristic(nc, nr, nl, target.col, target.row, target.layer)
          openHeap.push({
            col: nc
            row: nr
            layer: nl
            idx: nIdx
            g: tentativeG
            f: tentativeG + h
          })

      # 2. Layer transitions via Via (Z direction)
      if @grid.layerCount > 1
        for dl in [-1, 1]
          nl = currLayer + dl
          continue unless nl >= 0 and nl < @grid.layerCount

          nc = curr.col
          nr = curr.row

          # Check if destination layer cell is blocked
          isTargetCell = (nc is target.col and nr is target.row and nl is target.layer)
          if not isTargetCell and @grid.isBlocked(nc, nr, nl, netHash)
            continue

          viaMoveCost = @grid.viaCost
          nIdx = @grid.cellIndex(nc, nr, nl)
          continue if closedSet[nIdx] is 1

          tentativeG = currG + viaMoveCost
          if tentativeG < gScore[nIdx]
            gScore[nIdx] = tentativeG
            cameFrom[nIdx] = currIdx
            h = @_heuristic(nc, nr, nl, target.col, target.row, target.layer)
            openHeap.push({
              col: nc
              row: nr
              layer: nl
              idx: nIdx
              g: tentativeG
              f: tentativeG + h
            })

    return { success: false, segments: [], vias: [] } unless foundTarget

    # Reconstruct path
    @_reconstructPath(cameFrom, targetIdx, startIdx, netId)

  # Octilinear 3D distance heuristic
  _heuristic: (c1, r1, l1, c2, r2, l2) ->
    dc = Math.abs(c1 - c2)
    dr = Math.abs(r1 - r2)
    dl = Math.abs(l1 - l2)

    # 2D diagonal distance
    h2d = Math.max(dc, dr) + (@SQRT2 - 1.0) * Math.min(dc, dr)
    # Z-axis layer transition penalty
    h3d = h2d + dl * @grid.viaCost
    h3d

  _reconstructPath: (cameFrom, currIdx, startIdx, netId) ->
    pathCells = []
    curr = currIdx

    while curr isnt -1
      l = Math.floor(curr / (@grid.cols * @grid.rows))
      rem = curr % (@grid.cols * @grid.rows)
      r = Math.floor(rem / @grid.cols)
      c = rem % @grid.cols

      pathCells.push({ col: c, row: r, layer: l })
      break if curr is startIdx
      curr = cameFrom[curr]

    pathCells.reverse()

    # Convert consecutive grid points into line segments and vias
    segments = []
    vias = []

    return { success: true, segments: segments, vias: vias } if pathCells.length < 2

    for i in [0...(pathCells.length - 1)]
      c1 = pathCells[i]
      c2 = pathCells[i + 1]

      p1 = @grid.gridToBoard(c1.col, c1.row, c1.layer)
      p2 = @grid.gridToBoard(c2.col, c2.row, c2.layer)

      if c1.layer isnt c2.layer
        # Via inserted at this point
        via = new Via({
          x: p1.x
          y: p1.y
          startLayerId: p1.layerId
          endLayerId: p2.layerId
          netId: netId
          type: ViaType.THROUGH
        })
        vias.push(via)
      else
        seg = new TraceSegment({
          p1: p1.point
          p2: p2.point
          widthNm: @grid.board.rules.minTraceWidthNm
          layerId: p1.layerId
          netId: netId
        })
        segments.push(seg)

    { success: true, segments: segments, vias: vias }

module.exports = {
  BinaryHeap
  AStarRouter
}
