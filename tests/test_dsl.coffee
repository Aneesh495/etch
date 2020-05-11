assert = require 'assert'
{ defineBoard, BoardBuilder, Placement } = require '../src/dsl/builder'
Units = require '../src/core/units'
Component = require '../src/model/component'

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

describe 'Declarative CoffeeScript PCB DSL', ->
  it 'defines a complete board using literate declarative builder syntax', ->
    b = defineBoard 'sensor_node', { width: Units.mm(80), height: Units.mm(50), layers: 4 }, (board) ->
      board.component 'U1', 'QFN-32', { value: 'STM32F401', x: Units.mm(40), y: Units.mm(25) }
      board.component 'C1', '0402', { value: '100nF', x: Units.mm(35), y: Units.mm(25) }
      board.component 'R1', '0603', { value: '10k', x: Units.mm(45), y: Units.mm(25) }
      board.component 'J1', 'USB-C', { x: Units.mm(5), y: Units.mm(25) }

      board.net 'GND', ['U1.EP', 'C1.2', 'J1.SH1']
      board.net 'VCC3V3', ['U1.1', 'C1.1']
      board.net 'SWCLK', ['U1.20', 'R1.1']

      board.plane 'GND', { layer: 'In1.Cu' }
      board.plane 'VCC3V3', { layer: 'In2.Cu' }

      board.mountingHoles(Units.mm(4.0))

    assert.strictEqual b.name, 'sensor_node'
    assert.strictEqual b.allComponents().length, 4
    assert.strictEqual b.mountingHoles.length, 4
    assert.strictEqual b.zones.length, 2

    # Check net connectivity
    gnd = b.netlist.getNet('GND')
    assert.ok gnd?
    assert.strictEqual gnd.pinCount(), 3
    assert.strictEqual gnd.pins[0].key(), 'U1.EP'
    assert.strictEqual gnd.pins[0].pad.netId, 'GND'

describe 'Placement Array Helpers', ->
  it 'aligns components along rows, columns, and polar circular rings', ->
    c1 = new Component({ refDes: 'LED1' })
    c2 = new Component({ refDes: 'LED2' })
    c3 = new Component({ refDes: 'LED3' })

    # Align row
    Placement.alignRow([c1, c2, c3], 100, 200, 50)
    assert.strictEqual c1.x, 100
    assert.strictEqual c2.x, 150
    assert.strictEqual c3.x, 200
    assert.strictEqual c1.y, 200
    assert.strictEqual c2.y, 200

    # Place in polar circle
    Placement.placePolar([c1, c2, c3], 0, 0, 1000)
    assert.strictEqual Math.round(c1.x), 1000 # Angle 0 deg -> (1000, 0)
    assert.strictEqual Math.round(c1.y), 0

console.log 'All DSL tests passed.'
