assert = require 'assert'
Units = require '../src/core/units'
{ Point } = require '../src/core/geometry'
Polygon = require '../src/core/polygon'
{ LayerStackup, LayerType } = require '../src/model/layer'
{ NetClass, Net, Netlist } = require '../src/model/net'
{ Pad, PadShape, PadType } = require '../src/model/pad'
{ Via, ViaType } = require '../src/model/via'
{ Trace, TraceSegment } = require '../src/model/trace'
{ Zone, ZoneType } = require '../src/model/zone'
ThermalRelief = require '../src/model/thermal'
Component = require '../src/model/component'
Board = require '../src/model/board'

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

describe 'LayerStackup Architecture', ->
  it 'configures 2-layer and 4-layer stackups correctly', ->
    s2 = new LayerStackup(2)
    assert.strictEqual s2.copperLayers().length, 2
    assert.strictEqual s2.copperLayers()[0].id, 'F.Cu'
    assert.strictEqual s2.copperLayers()[1].id, 'B.Cu'

    s4 = new LayerStackup(4)
    assert.strictEqual s4.copperLayers().length, 4
    assert.strictEqual s4.copperLayers()[1].name, 'GND Plane'
    assert.strictEqual s4.copperLayers()[1].isPlane(), true

describe 'Net & Minimum Spanning Tree Ratsnest', ->
  it 'generates MST airwires across connected component pins', ->
    net = new Net('NET_SPI_CLK', 'SPI_CLK')
    # Create fake component and pads
    comp = new Component({ refDes: 'U1', x: Units.mm(10), y: Units.mm(10) })
    pad1 = comp.addPad(new Pad({ number: '1', x: 0, y: 0 }))
    pad2 = comp.addPad(new Pad({ number: '2', x: Units.mm(10), y: 0 }))
    pad3 = comp.addPad(new Pad({ number: '3', x: Units.mm(20), y: 0 }))

    net.addPin('U1', '1', pad1)
    net.addPin('U1', '2', pad2)
    net.addPin('U1', '3', pad3)
    assert.strictEqual net.pinCount(), 3

    airwires = net.generateRatsnest()
    # 3 pins in MST requires exactly 2 edges
    assert.strictEqual airwires.length, 2

describe 'Pad & Via Geometric Evaluation', ->
  it 'calculates through-hole annular rings accurately', ->
    thPad = new Pad({
      shape: PadShape.CIRCLE
      type: PadType.THROUGH_HOLE
      widthNm: Units.mm(1.6)
      heightNm: Units.mm(1.6)
      drillDiameterNm: Units.mm(0.8)
    })
    # Annular ring = (1.6 - 0.8) / 2 = 0.4 mm = 400000 nm
    assert.strictEqual thPad.annularRingNm(), Units.mm(0.4)

  it 'transforms local pad offsets to board space under component rotation', ->
    comp = new Component({
      refDes: 'R1'
      x: Units.mm(50)
      y: Units.mm(50)
      rotationDeg: 90
    })
    # Pad at local offset (1mm, 0) rotated 90 deg -> becomes (0, 1mm) relative to center
    pad = comp.addPad(new Pad({ number: '1', x: Units.mm(1.0), y: 0 }))
    pos = pad.absolutePosition()
    assert.strictEqual Math.round(pos.x), Units.mm(50)
    assert.strictEqual Math.round(pos.y), Units.mm(51)

describe 'Thermal Relief Spokes', ->
  it 'generates 4 orthogonal copper connection spokes', ->
    pad = new Pad({
      x: Units.mm(20)
      y: Units.mm(20)
      widthNm: Units.mm(1.2)
      heightNm: Units.mm(1.2)
    })
    spokes = ThermalRelief.generateSpokes(pad, Units.mm(0.3), Units.mm(0.25), '4-spoke-90')
    assert.strictEqual spokes.length, 4

describe 'Board Assembly & Statistics', ->
  it 'constructs board, adds traces and components, and computes metrics', ->
    board = new Board({
      name: 'stm32_core'
      width: Units.mm(60)
      height: Units.mm(40)
      layers: 4
    })
    assert.strictEqual board.widthNm(), Units.mm(60)
    assert.strictEqual board.heightNm(), Units.mm(40)

    # Add component
    u1 = new Component({ refDes: 'U1', footprintName: 'QFN-32', x: Units.mm(30), y: Units.mm(20) })
    u1.addPad(new Pad({ number: '1', x: -Units.mm(2), y: -Units.mm(2) }))
    u1.addPad(new Pad({ number: '2', x: Units.mm(2), y: Units.mm(2) }))
    board.addComponent(u1)

    # Add trace
    trace = new Trace({ netId: 'NET_VCC', layerId: 'F.Cu' })
    trace.addSegment(new Point(Units.mm(10), Units.mm(10)), new Point(Units.mm(20), Units.mm(10)))
    board.addTrace(trace)

    # Add via
    board.addVia(new Via({ x: Units.mm(20), y: Units.mm(10), netId: 'NET_VCC' }))

    # Add mounting hole
    board.addMountingHole(Units.mm(5), Units.mm(5))

    stats = board.statistics()
    assert.strictEqual stats.name, 'stm32_core'
    assert.strictEqual stats.layerCount, 4
    assert.strictEqual stats.componentCount, 1
    assert.strictEqual stats.padCount, 2
    assert.strictEqual stats.viaCount, 1
    assert.strictEqual stats.totalTraceLengthMm, 10
    assert.strictEqual stats.mountingHoleCount, 1

console.log 'All Board Model tests passed.'
