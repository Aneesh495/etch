assert = require 'assert'
Board = require '../src/model/board'
RoutingGrid = require '../src/router/grid'
Units = require '../src/core/units'
{ Point, BoundingBox } = require '../src/core/geometry'

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

describe 'RoutingGrid 3D Lattice & Obstacle Rasterizer', ->
  it 'converts between board coordinates and grid lattice indices', ->
    b = new Board({ width: Units.mm(20), height: Units.mm(20), layers: 2 })
    grid = new RoutingGrid(b, { resolutionNm: Units.mm(1.0) })

    # Board (10mm, 10mm) on Top layer F.Cu
    g = grid.boardToGrid(Units.mm(10), Units.mm(10), 'F.Cu')
    assert.strictEqual g.col, 10
    assert.strictEqual g.row, 10
    assert.strictEqual g.layer, 0

    # Back to board coordinates
    pt = grid.gridToBoard(10, 10, 0)
    assert.strictEqual pt.x, Units.mm(10)
    assert.strictEqual pt.y, Units.mm(10)
    assert.strictEqual pt.layerId, 'F.Cu'

  it 'blocks rectangular zones and detects blocked status', ->
    b = new Board({ width: Units.mm(20), height: Units.mm(20), layers: 2 })
    grid = new RoutingGrid(b, { resolutionNm: Units.mm(1.0) })

    bb = new BoundingBox(Units.mm(4), Units.mm(4), Units.mm(6), Units.mm(6))
    grid.blockBox(bb, 0)

    # Center cell (5, 5, 0) should be blocked
    assert.strictEqual grid.isBlocked(5, 5, 0), true
    # Corner cell (0, 0, 0) should be free
    assert.strictEqual grid.isBlocked(0, 0, 0), false
    # Same cell on layer 1 (B.Cu) should be free
    assert.strictEqual grid.isBlocked(5, 5, 1), false

console.log 'All Router Grid tests passed.'
