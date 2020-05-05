assert = require 'assert'
Footprints = require '../src/footprints/index'
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

describe 'Footprints IPC-7351B Standard Library', ->
  it 'generates SMD passive chip footprints (0402, 0805, 1206)', ->
    r1 = Footprints.create('R1', '0805', { value: '10k' })
    assert.strictEqual r1.padCount(), 2
    assert.ok r1.courtyard?
    p1 = r1.getPad('1')
    p2 = r1.getPad('2')
    assert.ok p1? and p2?
    assert.ok p1.x < 0 and p2.x > 0

  it 'generates SOT-23 and SOT-223 transistor footprints', ->
    q1 = Footprints.create('Q1', 'SOT-23')
    assert.strictEqual q1.padCount(), 3

    uReg = Footprints.create('U2', 'SOT-223', { value: 'AMS1117' })
    assert.strictEqual uReg.padCount(), 4
    tab = uReg.getPad('4')
    assert.ok tab?
    # Tab pad should be much wider than signal pin 1
    assert.ok tab.widthNm > uReg.getPad('1').widthNm

  it 'generates SOIC dual-row IC packages (SOIC-8, SOIC-16)', ->
    soic8 = Footprints.create('U1', 'SOIC-8', { value: 'NE555' })
    assert.strictEqual soic8.padCount(), 8
    p1 = soic8.getPad('1')
    p8 = soic8.getPad('8')
    assert.ok p1? and p8?
    assert.ok p1.x < 0 and p8.x > 0

  it 'generates QFP 4-sided gull-wing packages (QFP-48)', ->
    qfp48 = Footprints.create('U3', 'QFP-48')
    assert.strictEqual qfp48.padCount(), 48
    # Verify presence of pin 1, 12, 24, 36, 48
    assert.ok qfp48.getPad('1')?
    assert.ok qfp48.getPad('12')?
    assert.ok qfp48.getPad('24')?
    assert.ok qfp48.getPad('36')?
    assert.ok qfp48.getPad('48')?

  it 'generates QFN leadless packages with exposed thermal pad (QFN-32)', ->
    qfn32 = Footprints.create('U4', 'QFN-32', { value: 'STM32F401' })
    # 32 perimeter pads + 1 central exposed pad (EP) = 33 pads
    assert.strictEqual qfn32.padCount(), 33
    ep = qfn32.getPad('EP')
    assert.ok ep?
    assert.strictEqual ep.x, 0
    assert.strictEqual ep.y, 0

  it 'generates BGA ball grid arrays with JEDEC naming (BGA-64)', ->
    bga64 = Footprints.create('U5', 'BGA-64')
    assert.strictEqual bga64.padCount(), 64
    assert.ok bga64.getPad('A1')?
    assert.ok bga64.getPad('H8')?

  it 'generates through-hole DIP packages and pin headers', ->
    dip8 = Footprints.create('U6', 'DIP-8')
    assert.strictEqual dip8.padCount(), 8
    p1 = dip8.getPad('1')
    assert.ok p1.isThroughHole()
    assert.ok p1.drillDiameterNm > 0

    header = Footprints.create('J1', 'HEADER_2X5')
    assert.strictEqual header.padCount(), 10

  it 'generates USB-C hybrid SMT/THT connector', ->
    usbc = Footprints.create('J2', 'USB-C')
    # 12 SMT signal pins + 4 through-hole shield tabs = 16 pads
    assert.strictEqual usbc.padCount(), 16
    assert.ok usbc.getPad('A1')?
    assert.ok usbc.getPad('SH1')?
    assert.ok usbc.getPad('SH1').isThroughHole()

console.log 'All Footprints tests passed.'
