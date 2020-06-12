assert = require 'assert'
Board = require '../src/model/board'
Component = require '../src/model/component'
{ Pad, PadShape, PadType } = require '../src/model/pad'
{ Via, ViaType } = require '../src/model/via'
{ Trace, TraceSegment } = require '../src/model/trace'
{ Net } = require '../src/model/net'
{ DesignRuleChecker } = require '../src/drc/checker'
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

describe 'Master DesignRuleChecker Comprehensive Pass', ->
  it 'catches thin traces violating minimum trace width rules', ->
    b = new Board({
      width: Units.mm(30)
      height: Units.mm(30)
      rules: { minTraceWidthNm: Units.mm(0.15) } # 0.15 mm min
    })

    t = new Trace({ netId: 'NET_THIN', layerId: 'F.Cu' })
    # Trace with 0.1 mm width (< 0.15 mm allowed)
    t.addSegment(new Point(Units.mm(5), Units.mm(5)), new Point(Units.mm(15), Units.mm(5)), Units.mm(0.1))
    b.addTrace(t)

    result = DesignRuleChecker.run(b)
    assert.strictEqual result.passed, false
    violations = (v for v in result.violations when v.rule is 'MIN_TRACE_WIDTH')
    assert.strictEqual violations.length, 1

  it 'catches annular rings that are too narrow for reliable plated hole manufacturing', ->
    b = new Board({
      width: Units.mm(30)
      height: Units.mm(30)
      rules: { minAnnularRingNm: Units.mm(0.15) }
    })

    # Via with 0.5 mm diameter and 0.4 mm drill: ring = (0.5 - 0.4)/2 = 0.05 mm (< 0.15 mm!)
    b.addVia(new Via({
      x: Units.mm(10)
      y: Units.mm(10)
      diameterNm: Units.mm(0.5)
      drillDiameterNm: Units.mm(0.4)
    }))

    result = DesignRuleChecker.run(b)
    violations = (v for v in result.violations when v.rule is 'MIN_ANNULAR_RING')
    assert.strictEqual violations.length, 1

  it 'catches catastrophic electrical short circuits between different nets', ->
    b = new Board({ width: Units.mm(30), height: Units.mm(30) })

    t1 = new Trace({ netId: 'NET_VCC', layerId: 'F.Cu' })
    t1.addSegment(new Point(Units.mm(0), Units.mm(10)), new Point(Units.mm(20), Units.mm(10)))

    t2 = new Trace({ netId: 'NET_GND', layerId: 'F.Cu' })
    # Crossing perpendicularly at (10, 10)
    t2.addSegment(new Point(Units.mm(10), Units.mm(0)), new Point(Units.mm(10), Units.mm(20)))

    b.addTrace(t1)
    b.addTrace(t2)

    result = DesignRuleChecker.run(b)
    shorts = (v for v in result.violations when v.rule is 'ELECTRICAL_SHORT')
    assert.strictEqual shorts.length, 1
    assert.strictEqual result.passed, false

  it 'formats clean printable human-readable DRC reports', ->
    b = new Board({ width: Units.mm(30), height: Units.mm(30) })
    result = DesignRuleChecker.run(b)
    report = result.formatReport()
    assert.ok report.indexOf('ETCH EDA: DRC REPORT') isnt -1
    assert.ok report.indexOf('Status:') isnt -1

console.log 'All DRC Rules tests passed.'
