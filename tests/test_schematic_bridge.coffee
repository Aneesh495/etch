assert = require 'assert'
Board = require '../src/model/board'
Component = require '../src/model/component'
{ Pad } = require '../src/model/pad'
{ Net } = require '../src/model/net'
KiCadNetlistBridge = require '../src/schematic/kicad_bridge'
SPICEBridge = require '../src/schematic/spice_bridge'
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

createTestBoard = ->
  b = new Board({ name: 'schematic_test' })
  r1 = new Component({ refDes: 'R1', value: '10k', footprintName: '0805' })
  p1 = r1.addPad(new Pad({ number: '1', netId: 'VIN' }))
  p2 = r1.addPad(new Pad({ number: '2', netId: 'VOUT' }))
  b.addComponent(r1)

  c1 = new Component({ refDes: 'C1', value: '100nF', footprintName: '0603' })
  c1.addPad(new Pad({ number: '1', netId: 'VOUT' }))
  c1.addPad(new Pad({ number: '2', netId: 'GND' }))
  b.addComponent(c1)

  netVin = new Net('VIN', 'VIN')
  netVin.addPin('R1', '1', p1)
  b.netlist.addNet(netVin)

  netVout = new Net('VOUT', 'VOUT')
  netVout.addPin('R1', '2', p2)
  b.netlist.addNet(netVout)

  b

describe 'Schematic Netlist Bridges', ->
  it 'exports valid KiCad S-expression netlists (.net)', ->
    b = createTestBoard()
    sExpr = KiCadNetlistBridge.exportSExpr(b)

    assert.ok sExpr.indexOf('(export (version "E")') isnt -1
    assert.ok sExpr.indexOf('(comp (ref "R1")') isnt -1
    assert.ok sExpr.indexOf('(net (code') isnt -1
    assert.ok sExpr.indexOf('(name "VIN")') isnt -1

  it 'roundtrips KiCad netlist text back into a Board model', ->
    bOrig = createTestBoard()
    sExpr = KiCadNetlistBridge.exportSExpr(bOrig)

    bNew = new Board({ name: 'imported_board' })
    KiCadNetlistBridge.importSExpr(sExpr, bNew)

    assert.strictEqual bNew.allComponents().length, 2
    assert.ok bNew.getComponent('R1')?
    assert.ok bNew.getComponent('C1')?
    assert.ok bNew.netlist.getNet('VIN')?

  it 'exports SPICE simulation netlists with GND mapped to node 0', ->
    b = createTestBoard()
    spice = SPICEBridge.exportSPICE(b)

    assert.ok spice.indexOf('R1 VIN VOUT 10k') isnt -1
    # C1 connected between VOUT and GND -> GND mapped to 0
    assert.ok spice.indexOf('C1 VOUT 0 100nF') isnt -1
    assert.ok spice.indexOf('.END') isnt -1

console.log 'All Schematic Bridge tests passed.'
