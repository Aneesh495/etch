assert = require 'assert'
Board = require '../src/model/board'
Component = require '../src/model/component'
{ Pad, PadShape, PadType } = require '../src/model/pad'
{ Trace, TraceSegment } = require '../src/model/trace'
ClearanceChecker = require '../src/drc/clearance'
Units = require '../src/core/units'
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

describe 'DRC Spatial Clearance Verification', ->
  it 'detects track-to-track clearance violations on the same layer', ->
    b = new Board({
      width: Units.mm(50)
      height: Units.mm(50)
      rules: { minClearanceNm: Units.mm(0.2) } # 0.2 mm clearance required
    })

    # Two parallel tracks of different nets separated by only 0.1 mm (< 0.2 mm)
    t1 = new Trace({ netId: 'NET_A', layerId: 'F.Cu' })
    t1.addSegment(new Point(Units.mm(10), Units.mm(10)), new Point(Units.mm(20), Units.mm(10)), Units.mm(0.2))

    t2 = new Trace({ netId: 'NET_B', layerId: 'F.Cu' })
    # Centerline at Y = 10.3 mm. Distance between edges = 0.3 - (0.1 + 0.1) = 0.1 mm (< 0.2 mm!)
    t2.addSegment(new Point(Units.mm(10), Units.mm(10.3)), new Point(Units.mm(20), Units.mm(10.3)), Units.mm(0.2))

    b.addTrace(t1)
    b.addTrace(t2)

    violations = ClearanceChecker.check(b)
    trackViolations = (v for v in violations when v.rule is 'CLEARANCE_TRACK_TO_TRACK')
    assert.strictEqual trackViolations.length, 1
    assert.strictEqual trackViolations[0].severity, 'ERROR'

  it 'ignores parallel tracks that belong to the exact same net', ->
    b = new Board({
      width: Units.mm(50)
      height: Units.mm(50)
      rules: { minClearanceNm: Units.mm(0.2) }
    })

    # Both tracks belong to NET_GND
    t1 = new Trace({ netId: 'NET_GND', layerId: 'F.Cu' })
    t1.addSegment(new Point(Units.mm(10), Units.mm(10)), new Point(Units.mm(20), Units.mm(10)), Units.mm(0.2))

    t2 = new Trace({ netId: 'NET_GND', layerId: 'F.Cu' })
    t2.addSegment(new Point(Units.mm(10), Units.mm(10.2)), new Point(Units.mm(20), Units.mm(10.2)), Units.mm(0.2))

    b.addTrace(t1)
    b.addTrace(t2)

    violations = ClearanceChecker.check(b)
    trackViolations = (v for v in violations when v.rule is 'CLEARANCE_TRACK_TO_TRACK')
    assert.strictEqual trackViolations.length, 0

console.log 'All DRC Clearance tests passed.'
