assert = require 'assert'
LengthTuner = require '../src/router/length_tuner'
{ TraceSegment } = require '../src/model/trace'
{ Point } = require '../src/core/geometry'
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

describe 'LengthTuner High-Speed Differential Pair Tuning', ->
  it 'adds serpentine accordion meanders to equalize trace length', ->
    # Baseline straight trace of 10 mm length
    seg = new TraceSegment({
      p1: new Point(Units.mm(0), Units.mm(10))
      p2: new Point(Units.mm(10), Units.mm(10))
      widthNm: Units.mm(0.2)
      layerId: 'F.Cu'
      netId: 'USB_D_MINUS'
    })

    initialLen = seg.length()
    assert.strictEqual initialLen, Units.mm(10)

    # Target length: 13 mm (needs 3 mm of extra serpentine meanders)
    targetLen = Units.mm(13)
    tuned = LengthTuner.tuneToLength([seg], targetLen, Units.mm(0.6), Units.mm(0.5))

    # Length after serpentine insertion must be greater than original 10 mm
    tunedLen = 0
    for s in tuned
      tunedLen += s.length()

    assert.ok tuned.length > 1
    assert.ok tunedLen > initialLen
    # Tolerance within 1.0 mm of target
    assert.ok Math.abs(tunedLen - targetLen) < Units.mm(1.0)

console.log 'All LengthTuner tests passed.'
