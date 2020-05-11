###
# Etch EDA: 3D Multi-Layer Routing Grid and Obstacle Rasterization
#
# Maps physical board space into a 3D discretized occupancy and cost lattice
# for maze routing. Enforces layer directional cost biasing (X-preference on
# top copper, Y-preference on bottom copper), clearance obstacle inflation,
# and via transition penalties.
###

Units = require '../core/units'
{ Point, BoundingBox } = require '../core/geometry'

class RoutingGrid
  constructor: (@board, options = {}) ->
    @resolutionNm = options.resolutionNm or Units.mm(0.2) # Default 0.2 mm grid cell
    @viaCost = options.viaCost or 50 # Penalty for inserting a via
    @xLayerBias = options.xLayerBias or 2.0 # Penalty for non-preferred axis
    @yLayerBias = options.yLayerBias or 2.0

    bb = @board.outline.boundingBox()
    @originX = bb.minX
    @originY = bb.minY
    @widthNm = bb.width()
    @heightNm = bb.height()

    @cols = Math.ceil(@widthNm / @resolutionNm) + 1
    @rows = Math.ceil(@heightNm / @resolutionNm) + 1
    @layerCount = @board.stackup.copperLayers().length

    # Flat 1D typed arrays for fast cache-friendly cell costs and net occupancy
    # Cost array: 0 = free, Infinity = hard obstacle, >0 = penalty
    totalCells = @cols * @rows * @layerCount
    @costs = new Float32Array(totalCells)
    @netOccupancy = new Int32Array(totalCells) # -1 = empty, >=0 = net ID integer hash

    # Initialize all cells to free
    @netOccupancy.fill(-1)

  # Indexing helper: 3D (col, row, layer) -> 1D index
  cellIndex: (col, row, layer) ->
    (layer * @rows + row) * @cols + col

  isValidCell: (col, row, layer) ->
    col >= 0 and col < @cols and row >= 0 and row < @rows and layer >= 0 and layer < @layerCount

  # Convert board coordinates (nm) to grid indices
  boardToGrid: (xNm, yNm, layerId = 'F.Cu') ->
    col = Math.round((xNm - @originX) / @resolutionNm)
    row = Math.round((yNm - @originY) / @resolutionNm)
    layer = @board.stackup.idToCopperIndex(layerId)
    layer = 0 if layer < 0
    { col: col, row: row, layer: layer }

  # Convert grid indices back to board coordinates (nm)
  gridToBoard: (col, row, layer) ->
    x = @originX + col * @resolutionNm
    y = @originY + row * @resolutionNm
    layerId = @board.stackup.copperIndexToId(layer) or 'F.Cu'
    { x: x, y: y, layerId: layerId, point: new Point(x, y) }

  # Set cell blockage
  setBlocked: (col, row, layer, isBlocked = true, netHash = -1) ->
    return unless @isValidCell(col, row, layer)
    idx = @cellIndex(col, row, layer)
    @costs[idx] = if isBlocked then Infinity else 0.0
    @netOccupancy[idx] = if isBlocked then netHash else -1

  isBlocked: (col, row, layer, currentNetHash = -1) ->
    return true unless @isValidCell(col, row, layer)
    idx = @cellIndex(col, row, layer)
    cost = @costs[idx]
    return true if cost is Infinity

    occ = @netOccupancy[idx]
    if occ isnt -1 and occ isnt currentNetHash
      return true # Cell occupied by a different net
    false

  # Block a rectangular region with clearance inflation
  blockBox: (bb, layer, clearanceNm = 0, netHash = -1) ->
    minCol = Math.max(0, Math.floor((bb.minX - @originX - clearanceNm) / @resolutionNm))
    maxCol = Math.min(@cols - 1, Math.ceil((bb.maxX - @originX + clearanceNm) / @resolutionNm))
    minRow = Math.max(0, Math.floor((bb.minY - @originY - clearanceNm) / @resolutionNm))
    maxRow = Math.min(@rows - 1, Math.ceil((bb.maxY - @originY + clearanceNm) / @resolutionNm))

    for c in [minCol..maxCol]
      for r in [minRow..maxRow]
        @setBlocked(c, r, layer, true, netHash)

  # Rasterize board obstacles (pads, keepouts, existing traces) into grid
  rasterizeObstacles: (targetNetId = null) ->
    defaultClearance = @board.rules.minClearanceNm

    # 1. Rasterize Pads
    for pad in @board.allPads()
      # If pad belongs to current net, do not block its center pins
      isTargetPad = (targetNetId? and pad.netId is targetNetId)
      netHash = if pad.netId? then @_hashString(pad.netId) else -2

      bb = pad.boundingBox()
      if pad.isThroughHole()
        # Through-hole blocks all copper layers
        for l in [0...@layerCount]
          clr = if isTargetPad then 0 else defaultClearance
          @blockBox(bb, l, clr, netHash)
      else
        layerIdx = @board.stackup.idToCopperIndex(pad.layerId)
        clr = if isTargetPad then 0 else defaultClearance
        @blockBox(bb, layerIdx, clr, netHash)

    # 2. Rasterize existing traces
    for seg in @board.allTraceSegments()
      isTargetSeg = (targetNetId? and seg.netId is targetNetId)
      continue if isTargetSeg

      netHash = if seg.netId? then @_hashString(seg.netId) else -2
      layerIdx = @board.stackup.idToCopperIndex(seg.layerId)
      bb = seg.boundingBox()
      @blockBox(bb, layerIdx, defaultClearance, netHash)

    # 3. Rasterize existing vias
    for via in @board.allVias()
      isTargetVia = (targetNetId? and via.netId is targetNetId)
      continue if isTargetVia

      netHash = if via.netId? then @_hashString(via.netId) else -2
      bb = via.boundingBox()
      for l in [0...@layerCount]
        @blockBox(bb, l, defaultClearance, netHash)

  # Clear target net pins from obstacle grid so router can connect into them
  unblockNetTerminals: (net) ->
    netHash = @_hashString(net.id)
    for ref in net.pins
      pos = ref.position()
      g = @boardToGrid(pos.x, pos.y)
      # Clear a 1-cell radius at the terminal pad center
      for dc in [-1..1]
        for dr in [-1..1]
          col = g.col + dc
          row = g.row + dr
          for l in [0...@layerCount]
            if @isValidCell(col, row, l)
              idx = @cellIndex(col, row, l)
              if @netOccupancy[idx] is netHash
                @costs[idx] = 0.0

  _hashString: (str) ->
    hash = 0
    return hash if str.length is 0
    for i in [0...str.length]
      chr = str.charCodeAt(i)
      hash = ((hash << 5) - hash) + chr
      hash |= 0
    Math.abs(hash)

module.exports = RoutingGrid
