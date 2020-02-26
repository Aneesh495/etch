assert = require 'assert'
Polygon = require '../src/core/polygon'
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

describe 'Polygon Geometric Analysis & Operations', ->
  it 'constructs rectangular polygons from origin and dimensions', ->
    rect = Polygon.fromRect(100, 200, 400, 300)
    assert.strictEqual rect.vertexCount(), 4
    bb = rect.boundingBox()
    assert.strictEqual bb.width(), 400
    assert.strictEqual bb.height(), 300

  it 'computes signed area and evaluates winding order accurately', ->
    # CCW unit square: (0,0) -> (10,0) -> (10,10) -> (0,10)
    ccwSquare = new Polygon([
      new Point(0, 0)
      new Point(10, 0)
      new Point(10, 10)
      new Point(0, 10)
    ])
    assert.strictEqual ccwSquare.area(), 100
    assert.strictEqual ccwSquare.isCounterClockwise(), true
    assert.strictEqual ccwSquare.isClockwise(), false

    # CW square (reversed order)
    cwSquare = new Polygon([
      new Point(0, 0)
      new Point(0, 10)
      new Point(10, 10)
      new Point(10, 0)
    ])
    assert.strictEqual cwSquare.area(), 100
    assert.strictEqual cwSquare.isClockwise(), true

  it 'determines polygon centroid coordinates', ->
    rect = Polygon.fromRect(0, 0, 100, 100)
    c = rect.centroid()
    assert.strictEqual c.x, 50
    assert.strictEqual c.y, 50

  it 'tests point enclosure using generalized winding numbers', ->
    poly = new Polygon([
      new Point(0, 0)
      new Point(100, 0)
      new Point(100, 100)
      new Point(0, 100)
    ])
    assert.strictEqual poly.containsPoint(new Point(50, 50)), true
    assert.strictEqual poly.containsPoint(new Point(150, 50)), false
    assert.strictEqual poly.containsPoint(new Point(-10, 50)), false

  it 'respects interior cutout holes in containment tests', ->
    outer = Polygon.fromRect(0, 0, 200, 200)
    hole = Polygon.fromRect(50, 50, 100, 100)
    outer.addHole(hole)

    # Point in solid meat of polygon
    assert.strictEqual outer.containsPoint(new Point(20, 20)), true
    # Point inside the cutout hole should return false
    assert.strictEqual outer.containsPoint(new Point(100, 100)), false

  it 'filters collinear redundant vertices', ->
    poly = new Polygon([
      new Point(0, 0)
      new Point(50, 0) # Collinear midpoint along bottom edge
      new Point(100, 0)
      new Point(100, 100)
      new Point(0, 100)
    ])
    assert.strictEqual poly.vertexCount(), 5
    poly.cleanCollinear()
    assert.strictEqual poly.vertexCount(), 4

  it 'inflates polygon boundaries outward by a specified margin', ->
    square = Polygon.fromRect(0, 0, 100, 100)
    inflated = square.inflate(10)
    bb = inflated.boundingBox()
    # Expect width and height expanded by approx 20 (10 on each side)
    assert.ok Math.abs(bb.width() - 120) <= 2
    assert.ok Math.abs(bb.height() - 120) <= 2

console.log 'All Polygon tests passed.'
