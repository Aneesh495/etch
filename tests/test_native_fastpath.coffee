assert = require 'assert'
FastGridBridge = require '../src/native/fast_grid_bridge'

describe = (name, fn) ->
  console.log "  Suite: #{name}"
  fn()

it = (name, fn) ->
  try
    fn()
    console.log "    [OK] #{name}"
  catch err
    console.error "    [FAIL] #{name}: #{err.message}"
    throw err

describe 'Native & Fastpath Acceleration Engine', ->
  it 'allocates fast bitset lattice and toggles cell blockages', ->
    grid = new FastGridBridge(20, 20, 2)
    assert.strictEqual grid.isBlocked(0, 5, 5), false

    grid.blockCell(0, 5, 5)
    assert.strictEqual grid.isBlocked(0, 5, 5), true
    # Neighbor cell remains free
    assert.strictEqual grid.isBlocked(0, 5, 6), false
    # Same cell on layer 1 remains free
    assert.strictEqual grid.isBlocked(1, 5, 5), false

  it 'blocks rectangular bounding zones across lattice', ->
    grid = new FastGridBridge(30, 30, 2)
    grid.blockRect(0, 10, 10, 15, 15)

    assert.strictEqual grid.isBlocked(0, 12, 12), true
    assert.strictEqual grid.isBlocked(0, 10, 10), true
    assert.strictEqual grid.isBlocked(0, 15, 15), true
    assert.strictEqual grid.isBlocked(0, 9, 10), false
    assert.strictEqual grid.isBlocked(0, 16, 15), false

  it 'computes Euclidean distance transform field from obstacles', ->
    grid = new FastGridBridge(20, 20, 1)
    # Block a single point at (10, 10)
    grid.blockCell(0, 10, 10)
    grid.computeDistanceTransform(0)

    # Obstacle itself has distance 0
    assert.strictEqual grid.getDistance(0, 10, 10), 0.0

    # Point at (10, 14) is 4 cells away along Y axis
    dY = grid.getDistance(0, 10, 14)
    assert.strictEqual Math.round(dY), 4

    # Point at (13, 14) is 3-4-5 triangle away: sqrt(3^2 + 4^2) = 5
    dDiag = grid.getDistance(0, 13, 14)
    assert.strictEqual Math.round(dDiag), 5

console.log 'All Native Fastpath tests passed.'
