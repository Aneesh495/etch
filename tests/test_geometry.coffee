assert = require 'assert'
{ Point, Vector2D, BoundingBox, LineSegment, Arc } = require '../src/core/geometry'
Units = require '../src/core/units'

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

describe 'Point Primitives & Operations', ->
  it 'instantiates with rounded integer nanometers', ->
    p = new Point(10.4, 20.6)
    assert.strictEqual p.x, 10
    assert.strictEqual p.y, 21

  it 'performs vector addition, subtraction and scaling', ->
    p1 = new Point(100, 200)
    p2 = new Point(50, 75)
    sum = p1.add(p2)
    assert.strictEqual sum.x, 150
    assert.strictEqual sum.y, 275

    diff = p1.sub(p2)
    assert.strictEqual diff.x, 50
    assert.strictEqual diff.y, 125

    scaled = p1.scale(2.5)
    assert.strictEqual scaled.x, 250
    assert.strictEqual scaled.y, 500

  it 'calculates Euclidean and Manhattan distances', ->
    p1 = new Point(0, 0)
    p2 = new Point(300, 400)
    assert.strictEqual p1.distSq(p2), 250000
    assert.strictEqual p1.dist(p2), 500
    assert.strictEqual p1.manhattanDist(p2), 700

  it 'rotates points around origin and arbitrary pivots', ->
    p = new Point(100, 0)
    rot90 = p.rotateDeg(90)
    assert.strictEqual rot90.x, 0
    assert.strictEqual rot90.y, 100

    pivot = new Point(50, 50)
    pPivot = new Point(150, 50)
    rotAround = pPivot.rotateDeg(90, pivot)
    assert.strictEqual rotAround.x, 50
    assert.strictEqual rotAround.y, 150

describe 'Vector2D Operations', ->
  it 'normalizes and computes lengths and perpendicular normals', ->
    v = new Vector2D(30, 40)
    assert.strictEqual v.length(), 50
    norm = v.normalize()
    assert.strictEqual Math.round(norm.dx * 100), 60
    assert.strictEqual Math.round(norm.dy * 100), 80

    perp = v.perpendicular()
    assert.strictEqual perp.dx, -40
    assert.strictEqual perp.dy, 30
    assert.strictEqual v.dot(perp), 0

describe 'LineSegment & Geometric Distance', ->
  it 'computes line segment lengths and angles', ->
    seg = new LineSegment(new Point(0, 0), new Point(100, 0))
    assert.strictEqual seg.length(), 100
    assert.strictEqual seg.angle(), 0

  it 'projects points onto segment to find closest point and distance', ->
    seg = new LineSegment(new Point(0, 0), new Point(100, 0))
    # Query point directly above segment
    ptAbove = new Point(50, 30)
    closest = seg.closestPointTo(ptAbove)
    assert.strictEqual closest.x, 50
    assert.strictEqual closest.y, 0
    assert.strictEqual seg.distanceToPoint(ptAbove), 30

    # Query point beyond p2
    ptBeyond = new Point(150, 40)
    closestBeyond = seg.closestPointTo(ptBeyond)
    assert.strictEqual closestBeyond.x, 100
    assert.strictEqual closestBeyond.y, 0

  it 'detects line segment intersections and calculates crossing points', ->
    s1 = new LineSegment(new Point(0, 50), new Point(100, 50))
    s2 = new LineSegment(new Point(50, 0), new Point(50, 100))
    assert.strictEqual s1.intersects(s2), true
    pt = s1.intersectionPoint(s2)
    assert.ok pt?
    assert.strictEqual pt.x, 50
    assert.strictEqual pt.y, 50

    s3 = new LineSegment(new Point(0, 0), new Point(10, 0))
    s4 = new LineSegment(new Point(0, 10), new Point(10, 10))
    assert.strictEqual s3.intersects(s4), false

describe 'BoundingBox Operations', ->
  it 'encloses points and expands correctly', ->
    bb = new BoundingBox()
    bb.expandToPoint(new Point(10, 20))
    bb.expandToPoint(new Point(100, 200))
    assert.strictEqual bb.width(), 90
    assert.strictEqual bb.height(), 180
    assert.strictEqual bb.containsPoint(new Point(50, 50)), true
    assert.strictEqual bb.containsPoint(new Point(5, 5)), false

  it 'computes unions and intersections between boxes', ->
    b1 = new BoundingBox(0, 0, 50, 50)
    b2 = new BoundingBox(30, 30, 80, 80)
    assert.strictEqual b1.intersects(b2), true
    inter = b1.intersection(b2)
    assert.strictEqual inter.minX, 30
    assert.strictEqual inter.minY, 30
    assert.strictEqual inter.maxX, 50
    assert.strictEqual inter.maxY, 50

console.log 'All Geometry tests passed.'
