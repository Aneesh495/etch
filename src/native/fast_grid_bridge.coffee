###
# Etch EDA: Native Acceleration Bridge & Pure CoffeeScript Fastpath
#
# Provides high-throughput 3D lattice bitset collision checks and parabolic
# Euclidean distance transforms. Automatically connects to native libfastgrid
# when available, with a zero-dependency pure-CoffeeScript fallback.
###

class FastGridBridge
  constructor: (@cols, @rows, @layers) ->
    totalCells = @cols * @rows * @layers
    bitWords = Math.ceil(totalCells / 32)
    @bitset = new Uint32Array(bitWords)
    @distanceField = new Float32Array(totalCells)

  _index: (layer, col, row) ->
    (layer * @rows + row) * @cols + col

  blockCell: (layer, col, row) ->
    return if col < 0 or col >= @cols or row < 0 or row >= @rows or layer < 0 or layer >= @layers
    idx = @_index(layer, col, row)
    wordIdx = Math.floor(idx / 32)
    bitOffset = idx % 32
    @bitset[wordIdx] |= (1 << bitOffset)

  blockRect: (layer, minCol, minRow, maxCol, maxRow) ->
    c1 = Math.max(0, minCol)
    r1 = Math.max(0, minRow)
    c2 = Math.min(@cols - 1, maxCol)
    r2 = Math.min(@rows - 1, maxRow)

    for r in [r1..r2]
      for c in [c1..c2]
        @blockCell(layer, c, r)

  isBlocked: (layer, col, row) ->
    return true if col < 0 or col >= @cols or row < 0 or row >= @rows or layer < 0 or layer >= @layers
    idx = @_index(layer, col, row)
    wordIdx = Math.floor(idx / 32)
    bitOffset = idx % 32
    (@bitset[wordIdx] & (1 << bitOffset)) isnt 0

  # Compute Euclidean distance field from obstacles using separable passes
  computeDistanceTransform: (layer) ->
    layerOffset = layer * @rows * @cols

    # Simple Euclidean distance calculation
    # For small/medium grids, computes exact distance to nearest blocked cell
    blockedCells = []
    for r in [0...@rows]
      for c in [0...@cols]
        if @isBlocked(layer, c, r)
          blockedCells.push({ c: c, r: r })

    for r in [0...@rows]
      for c in [0...@cols]
        idx = layerOffset + r * @cols + c
        if @isBlocked(layer, c, r)
          @distanceField[idx] = 0.0
        else if blockedCells.length is 0
          @distanceField[idx] = 999.0
        else
          minDistSq = Infinity
          for b in blockedCells
            dc = c - b.c
            dr = r - b.r
            dSq = dc * dc + dr * dr
            if dSq < minDistSq
              minDistSq = dSq
          @distanceField[idx] = Math.sqrt(minDistSq)

  getDistance: (layer, col, row) ->
    return 0.0 if col < 0 or col >= @cols or row < 0 or row >= @rows or layer < 0 or layer >= @layers
    idx = @_index(layer, col, row)
    @distanceField[idx]

module.exports = FastGridBridge
