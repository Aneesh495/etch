assert = require 'assert'
IntersectionDetector = require '../src/core/intersection'
{ Point, LineSegment } = require '../src/core/geometry'

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

describe 'IntersectionDetector & Geometric Short Verification', ->
  it 'detects crossing intersections and calculates exact collision points', ->
    s1 = new LineSegment(new Point(0, 100), new Point(200, 100))
    s2 = new LineSegment(new Point(100, 0), new Point(100, 200))
    s3 = new LineSegment(new Point(0, 300), new Point(200, 300)) # Disjoint

    intersections = IntersectionDetector.findIntersections([s1, s2, s3])
    assert.strictEqual intersections.length, 1
    assert.strictEqual intersections[0].point.x, 100
    assert.strictEqual intersections[0].point.y, 100

  it 'ignores contiguous connected trace segments sharing a common node', ->
    # Segments forming an L-bend
    s1 = new LineSegment(new Point(0, 0), new Point(50, 0))
    s2 = new LineSegment(new Point(50, 0), new Point(50, 50))

    intersections = IntersectionDetector.findIntersections([s1, s2])
    assert.strictEqual intersections.length, 0

  it 'flags electrical net shorts between different nets on the same layer', ->
    sA = new LineSegment(new Point(0, 50), new Point(100, 50))
    sB = new LineSegment(new Point(50, 0), new Point(50, 100))

    # Test 1: Different nets on same layer -> Short!
    annotated1 = [
      { segment: sA, netId: 'NET_VCC', layerId: 'F.Cu' }
      { segment: sB, netId: 'NET_GND', layerId: 'F.Cu' }
    ]
    shorts1 = IntersectionDetector.findNetShorts(annotated1)
    assert.strictEqual shorts1.length, 1
    assert.strictEqual shorts1[0].net1, 'NET_VCC'
    assert.strictEqual shorts1[0].net2, 'NET_GND'

    # Test 2: Different nets on different layers (F.Cu and B.Cu) -> No short!
    annotated2 = [
      { segment: sA, netId: 'NET_VCC', layerId: 'F.Cu' }
      { segment: sB, netId: 'NET_GND', layerId: 'B.Cu' }
    ]
    shorts2 = IntersectionDetector.findNetShorts(annotated2)
    assert.strictEqual shorts2.length, 0

    # Test 3: Same net on same layer -> No short (valid branch/T-junction)
    annotated3 = [
      { segment: sA, netId: 'NET_GND', layerId: 'F.Cu' }
      { segment: sB, netId: 'NET_GND', layerId: 'F.Cu' }
    ]
    shorts3 = IntersectionDetector.findNetShorts(annotated3)
    assert.strictEqual shorts3.length, 0

  it 'identifies acute-angle acid traps while permitting standard 135-degree and 90-degree corners', ->
    # 45-degree acute angle meeting at (50, 0) -> Acid trap!
    sAcute1 = new LineSegment(new Point(0, 0), new Point(50, 0))
    sAcute2 = new LineSegment(new Point(50, 0), new Point(10, 40))
    pairs1 = [{ seg1: sAcute1, seg2: sAcute2 }]
    traps1 = IntersectionDetector.findAcidTraps(pairs1, 90.0)
    assert.strictEqual traps1.length, 1
    assert.ok traps1[0].angleDeg < 90.0

    # 135-degree standard octilinear corner -> Clean!
    sOct1 = new LineSegment(new Point(0, 0), new Point(50, 0))
    sOct2 = new LineSegment(new Point(50, 0), new Point(85, 35))
    pairs2 = [{ seg1: sOct1, seg2: sOct2 }]
    traps2 = IntersectionDetector.findAcidTraps(pairs2, 90.0)
    assert.strictEqual traps2.length, 0

console.log 'All Intersection tests passed.'
