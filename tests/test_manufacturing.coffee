assert = require 'assert'
Board = require '../src/model/board'
Component = require '../src/model/component'
{ Pad, PadShape, PadType } = require '../src/model/pad'
{ Via } = require '../src/model/via'
{ Trace } = require '../src/model/trace'
{ Net } = require '../src/model/net'
Units = require '../src/core/units'
{ Point } = require '../src/core/geometry'
{ GerberExporter } = require '../src/manufacturing/gerber_rs274x'
ExcellonExporter = require '../src/manufacturing/excellon'
IPCD356Exporter = require '../src/manufacturing/ipc_d_356'
PickAndPlaceExporter = require '../src/manufacturing/pick_and_place'
BOMExporter = require '../src/manufacturing/bom'

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

createSampleBoard = ->
  b = new Board({ name: 'mfg_sample', width: Units.mm(50), height: Units.mm(40), layers: 2 })

  # Add components
  u1 = new Component({ refDes: 'U1', value: 'ATmega328P', footprintName: 'QFN-32', x: Units.mm(25), y: Units.mm(20) })
  p1 = u1.addPad(new Pad({ number: '1', name: 'PD3', x: -Units.mm(2), y: 0, widthNm: Units.mm(0.3), heightNm: Units.mm(0.8) }))
  p2 = u1.addPad(new Pad({ number: '2', name: 'GND', x: -Units.mm(2), y: -Units.mm(0.5), widthNm: Units.mm(0.3), heightNm: Units.mm(0.8) }))
  b.addComponent(u1)

  c1 = new Component({ refDes: 'C1', value: '100nF', footprintName: '0603', x: Units.mm(15), y: Units.mm(20) })
  c1.addPad(new Pad({ number: '1', name: '1', x: -Units.mm(0.8), y: 0, widthNm: Units.mm(0.8), heightNm: Units.mm(0.9) }))
  c1.addPad(new Pad({ number: '2', name: '2', x: Units.mm(0.8), y: 0, widthNm: Units.mm(0.8), heightNm: Units.mm(0.9) }))
  b.addComponent(c1)

  # Add through-hole connector
  j1 = new Component({ refDes: 'J1', value: 'Header_1x2', footprintName: 'HEADER_1X2', x: Units.mm(5), y: Units.mm(20) })
  j1.addPad(new Pad({
    number: '1', type: PadType.THROUGH_HOLE, x: 0, y: -Units.mm(1.27),
    widthNm: Units.mm(1.6), heightNm: Units.mm(1.6), drillDiameterNm: Units.mm(0.8)
  }))
  j1.addPad(new Pad({
    number: '2', type: PadType.THROUGH_HOLE, x: 0, y: Units.mm(1.27),
    widthNm: Units.mm(1.6), heightNm: Units.mm(1.6), drillDiameterNm: Units.mm(0.8)
  }))
  b.addComponent(j1)

  # Add net and traces
  netGND = new Net('GND', 'GND')
  netGND.addPin('U1', '2', p2)
  b.netlist.addNet(netGND)

  trace = new Trace({ netId: 'GND', layerId: 'F.Cu' })
  trace.addSegment(new Point(Units.mm(10), Units.mm(20)), new Point(Units.mm(20), Units.mm(20)), Units.mm(0.25))
  b.addTrace(trace)

  # Add via and mounting hole
  b.addVia(new Via({ x: Units.mm(20), y: Units.mm(20), drillDiameterNm: Units.mm(0.3) }))
  b.addMountingHole(Units.mm(4), Units.mm(4), Units.mm(3.2))

  b

describe 'Manufacturing Outputs Verification', ->
  it 'generates valid RS-274X Gerber photoplotter syntax', ->
    b = createSampleBoard()
    gbr = GerberExporter.exportCopperLayer(b, 'F.Cu')

    assert.ok gbr.indexOf('%FSLAX46Y46*%') isnt -1
    assert.ok gbr.indexOf('%MOMM*%') isnt -1
    assert.ok gbr.indexOf('%LPD*%') isnt -1
    assert.ok gbr.indexOf('%ADD10') isnt -1 # Aperture table entry
    assert.ok gbr.indexOf('M02*') isnt -1   # End of file

  it 'generates Excellon NC drill file with tool table', ->
    b = createSampleBoard()
    drl = ExcellonExporter.exportDrill(b)

    assert.ok drl.indexOf('M48') isnt -1
    assert.ok drl.indexOf('METRIC,TZ') isnt -1
    assert.ok drl.indexOf('T01C') isnt -1 # Tool table definition
    assert.ok drl.indexOf('M30') isnt -1  # End of program

  it 'generates IPC-D-356 electrical test netlist', ->
    b = createSampleBoard()
    ipc = IPCD356Exporter.exportNetlist(b)

    assert.ok ipc.indexOf('IPC-D-356') isnt -1
    assert.ok ipc.indexOf('P  JOB') isnt -1
    assert.ok ipc.indexOf('327') isnt -1 or ipc.indexOf('317') isnt -1
    assert.ok ipc.indexOf('999') isnt -1 # End of file

  it 'generates Pick-and-Place Centroid CSV', ->
    b = createSampleBoard()
    cpl = PickAndPlaceExporter.exportCSV(b)

    lines = cpl.trim().split("\n")
    assert.strictEqual lines[0], "Designator,Val,Package,Mid X,Mid Y,Rotation,Layer"
    assert.ok cpl.indexOf('U1') isnt -1
    assert.ok cpl.indexOf('C1') isnt -1

  it 'groups components and outputs Bill of Materials (BOM)', ->
    b = createSampleBoard()
    bom = BOMExporter.exportCSV(b)

    assert.ok bom.indexOf('Item,Qty,Designator,Value,Footprint') isnt -1
    assert.ok bom.indexOf('ATmega328P') isnt -1
    assert.ok bom.indexOf('100nF') isnt -1

console.log 'All Manufacturing tests passed.'
