assert = require 'assert'
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

describe 'Units & Fixed-Point Nanometer Arithmetic', ->
  it 'converts millimeter values to exact integer nanometers', ->
    assert.strictEqual Units.toNm(1, 'mm'), 1000000
    assert.strictEqual Units.toNm(0.1, 'mm'), 100000
    assert.strictEqual Units.toNm(2.54, 'mm'), 2540000

  it 'converts mil (thou) values accurately to nanometers', ->
    # 1 mil = 25.4 um = 25400 nm
    assert.strictEqual Units.toNm(1, 'mil'), 25400
    assert.strictEqual Units.toNm(100, 'mil'), 2540000
    assert.strictEqual Units.toNm(6, 'mil'), 152400 # standard 6 mil trace

  it 'converts inches and microns to nanometers', ->
    assert.strictEqual Units.toNm(1, 'in'), 25400000
    assert.strictEqual Units.toNm(1, 'um'), 1000
    assert.strictEqual Units.toNm(10, 'nm'), 10

  it 'roundtrips from nanometers back to desired units', ->
    nm = Units.toNm(2.54, 'mm')
    assert.strictEqual Units.fromNm(nm, 'mm'), 2.54
    assert.strictEqual Units.fromNm(2540000, 'mil'), 100

  it 'provides direct shortcut methods', ->
    assert.strictEqual Units.mm(1.5), 1500000
    assert.strictEqual Units.mil(50), 1270000
    assert.strictEqual Units.um(250), 250000
    assert.strictEqual Units.inch(2), 50800000

  it 'formats metric and imperial strings cleanly without trailing zeroes', ->
    assert.strictEqual Units.formatMetric(1500000), '1.5 mm'
    assert.strictEqual Units.formatMetric(2540000), '2.54 mm'
    assert.strictEqual Units.formatImperial(25400), '1 mil'
    assert.strictEqual Units.formatImperial(152400), '6 mil'

  it 'converts angles and normalizes degrees correctly', ->
    assert.strictEqual Math.round(Units.radToDeg(Units.degToRad(90))), 90
    assert.strictEqual Units.normalizeDeg(450), 90
    assert.strictEqual Units.normalizeDeg(-90), 270

  it 'snaps angles to 45-degree increments for octilinear PCB tracks', ->
    assert.strictEqual Units.snapAngleDeg(42), 45
    assert.strictEqual Units.snapAngleDeg(88), 90
    assert.strictEqual Units.snapAngleDeg(134), 135
    assert.strictEqual Units.snapAngleDeg(181), 180
    assert.strictEqual Units.snapAngleDeg(358), 0

console.log 'All Units tests passed.'
