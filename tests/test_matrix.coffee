assert = require 'assert'
Matrix2D = require '../src/core/matrix'
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

describe 'Matrix2D Affine Transformations', ->
  it 'preserves points with identity matrix', ->
    m = Matrix2D.identity()
    pt = new Point(1234, 5678)
    res = m.transformPoint(pt)
    assert.strictEqual res.x, 1234
    assert.strictEqual res.y, 5678

  it 'translates coordinates correctly', ->
    m = Matrix2D.translation(500, -300)
    pt = new Point(100, 200)
    res = m.transformPoint(pt)
    assert.strictEqual res.x, 600
    assert.strictEqual res.y, -100

  it 'rotates coordinates by 90 and 180 degrees', ->
    m90 = Matrix2D.rotationDeg(90)
    p1 = new Point(100, 0)
    res90 = m90.transformPoint(p1)
    assert.strictEqual res90.x, 0
    assert.strictEqual res90.y, 100

    m180 = Matrix2D.rotationDeg(180)
    res180 = m180.transformPoint(p1)
    assert.strictEqual res180.x, -100
    assert.strictEqual res180.y, 0

  it 'mirrors coordinates across axes for bottom-layer flip', ->
    mMirrorX = Matrix2D.mirrorX()
    pt = new Point(50, 100)
    res = mMirrorX.transformPoint(pt)
    assert.strictEqual res.x, -50
    assert.strictEqual res.y, 100

  it 'composes transformations in correct order (translate then rotate)', ->
    # Translate (10, 0), then rotate 90 degrees
    # P(0,0) -> translated to (10, 0) -> rotated 90 deg -> (0, 10)
    mT = Matrix2D.translation(10, 0)
    mR = Matrix2D.rotationDeg(90)
    combined = mR.multiply(mT)
    res = combined.transformPoint(new Point(0, 0))
    assert.strictEqual res.x, 0
    assert.strictEqual res.y, 10

  it 'inverts affine matrices accurately', ->
    m = Matrix2D.translation(250, 400).multiply(Matrix2D.rotationDeg(45))
    inv = m.inverse()
    orig = new Point(1000, 2000)
    transformed = m.transformPoint(orig)
    restored = inv.transformPoint(transformed)
    assert.ok Math.abs(restored.x - orig.x) <= 1
    assert.ok Math.abs(restored.y - orig.y) <= 1

  it 'transforms bounding boxes correctly', ->
    bb = new BoundingBox(0, 0, 100, 50)
    # Rotate 90 degrees: width becomes 50, height becomes 100
    m = Matrix2D.rotationDeg(90)
    tbb = m.transformBoundingBox(bb)
    assert.strictEqual tbb.width(), 50
    assert.strictEqual tbb.height(), 100

console.log 'All Matrix2D tests passed.'
