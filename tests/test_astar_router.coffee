assert = require 'assert'
Board = require '../src/model/board'
RoutingGrid = require '../src/router/grid'
{ AStarRouter, BinaryHeap } = require '../src/router/astar_router'
TraceSmoother = require '../src/router/smoother'
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

describe 'BinaryHeap Priority Queue', ->
  it 'maintains min-heap property under push and pop operations', ->
    heap = new BinaryHeap()
    heap.push({ f: 40, id: 'd' })
    heap.push({ f: 10, id: 'a' })
    heap.push({ f: 30, id: 'c' })
    heap.push({ f: 20, id: 'b' })

    assert.strictEqual heap.size(), 4
    assert.strictEqual heap.pop().id, 'a'
    assert.strictEqual heap.pop().id, 'b'
    assert.strictEqual heap.pop().id, 'c'
    assert.strictEqual heap.pop().id, 'd'
    assert.strictEqual heap.isEmpty(), true

describe 'AStarRouter 3D Multi-Layer Pathfinder', ->
  it 'routes a direct straight connection across open grid space', ->
    b = new Board({ width: Units.mm(20), height: Units.mm(20), layers: 2 })
    grid = new RoutingGrid(b, { resolutionNm: Units.mm(1.0) })
    router = new AStarRouter(grid)

    p1 = new Point(Units.mm(2), Units.mm(5))
    p2 = new Point(Units.mm(10), Units.mm(5))

    res = router.routeConnection(p1, 'F.Cu', p2, 'F.Cu', 'NET_TEST')
    assert.strictEqual res.success, true
    assert.ok res.segments.length > 0
    assert.strictEqual res.vias.length, 0

  it 'routes around a blocking obstacle on the same layer', ->
    b = new Board({ width: Units.mm(20), height: Units.mm(20), layers: 2 })
    grid = new RoutingGrid(b, { resolutionNm: Units.mm(1.0) })

    # Place an obstacle directly in the line of sight between (2,5) and (10,5) on layer 0 (F.Cu)
    obs = new BoundingBox(Units.mm(5), Units.mm(2), Units.mm(7), Units.mm(8))
    grid.blockBox(obs, 0)

    router = new AStarRouter(grid)
    p1 = new Point(Units.mm(2), Units.mm(5))
    p2 = new Point(Units.mm(10), Units.mm(5))

    res = router.routeConnection(p1, 'F.Cu', p2, 'F.Cu', 'NET_TEST')
    assert.strictEqual res.success, true

    # Check that none of the generated segments pass through the blocked obstacle center (6, 5)
    for seg in res.segments
      mid = seg.asLineSegment().midpoint()
      assert.ok not obs.containsPoint(mid)

  it 'smooths staircase grid segments into clean collinear lines', ->
    b = new Board({ width: Units.mm(20), height: Units.mm(20), layers: 2 })
    grid = new RoutingGrid(b, { resolutionNm: Units.mm(1.0) })
    router = new AStarRouter(grid)

    p1 = new Point(Units.mm(2), Units.mm(2))
    p2 = new Point(Units.mm(10), Units.mm(2))

    res = router.routeConnection(p1, 'F.Cu', p2, 'F.Cu', 'NET_TEST')
    assert.strictEqual res.success, true
    rawSegCount = res.segments.length

    # Smoothing should collapse multiple 1mm segments along the straight line into 1 segment
    smoothed = TraceSmoother.smooth(res.segments)
    assert.ok smoothed.length < rawSegCount
    assert.strictEqual smoothed[0].p1.x, Units.mm(2)
    assert.strictEqual smoothed[smoothed.length - 1].p2.x, Units.mm(10)

console.log 'All AStarRouter tests passed.'
