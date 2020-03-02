assert = require 'assert'
Polygon = require '../src/core/polygon'
PolygonOps = require '../src/core/polygon_ops'
{ Point } = require '../src/core/geometry'

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

describe 'PolygonOps Constructive Boolean Clipping', ->
  it 'handles disjoint non-overlapping polygons', ->
    p1 = Polygon.fromRect(0, 0, 50, 50)
    p2 = Polygon.fromRect(100, 100, 50, 50)

    # Intersection of disjoint is empty
    inter = PolygonOps.intersection(p1, p2)
    assert.strictEqual inter.length, 0

    # Difference of disjoint leaves subject unchanged
    diff = PolygonOps.difference(p1, p2)
    assert.strictEqual diff.length, 1
    assert.strictEqual diff[0].area(), 2500

    # Union of disjoint returns both
    un = PolygonOps.union(p1, p2)
    assert.strictEqual un.length, 2

  it 'handles nested contained polygons', ->
    outer = Polygon.fromRect(0, 0, 100, 100)
    inner = Polygon.fromRect(20, 20, 40, 40)

    # Intersection is the inner polygon
    inter = PolygonOps.intersection(outer, inner)
    assert.strictEqual inter.length, 1
    assert.strictEqual inter[0].area(), 1600

    # Union is the outer polygon
    un = PolygonOps.union(outer, inner)
    assert.strictEqual un.length, 1
    assert.strictEqual un[0].area(), 10000

    # Difference: inner subtracted from outer
    diff = PolygonOps.difference(outer, inner)
    assert.ok diff.length >= 1

  it 'clips overlapping intersecting polygons', ->
    p1 = Polygon.fromRect(0, 0, 100, 100)
    p2 = Polygon.fromRect(50, 0, 100, 100)

    inter = PolygonOps.intersection(p1, p2)
    assert.strictEqual inter.length, 1
    # Overlap area is 50 x 100 = 5000
    assert.ok Math.abs(inter[0].area() - 5000) <= 100

console.log 'All PolygonOps tests passed.'
