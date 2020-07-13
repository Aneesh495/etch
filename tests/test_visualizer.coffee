assert = require 'assert'
Board = require '../src/model/board'
Component = require '../src/model/component'
{ Pad, PadShape, PadType } = require '../src/model/pad'
{ Via } = require '../src/model/via'
{ Trace } = require '../src/model/trace'
Units = require '../src/core/units'
{ Point } = require '../src/core/geometry'
SVGRenderer = require '../src/visualizer/svg_renderer'
TerminalPreview = require '../src/visualizer/terminal_preview'
WebServer = require '../src/visualizer/web_server'

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
  b = new Board({ name: 'vis_test', width: Units.mm(40), height: Units.mm(30), layers: 2 })
  u1 = new Component({ refDes: 'U1', value: 'MCU', x: Units.mm(20), y: Units.mm(15) })
  u1.addPad(new Pad({ number: '1', x: -Units.mm(1), y: 0 }))
  u1.addPad(new Pad({ number: '2', x: Units.mm(1), y: 0 }))
  b.addComponent(u1)

  t = new Trace({ netId: 'NET1', layerId: 'F.Cu' })
  t.addSegment(new Point(Units.mm(5), Units.mm(5)), new Point(Units.mm(15), Units.mm(5)))
  b.addTrace(t)
  b.addVia(new Via({ x: Units.mm(15), y: Units.mm(5) }))
  b.addMountingHole(Units.mm(3), Units.mm(3))
  b

describe 'Visualizer Rendering Engines', ->
  it 'renders scalable vector graphics (SVG) with all physical board layers', ->
    b = createTestBoard()
    svg = SVGRenderer.render(b, { theme: 'matte_black' })

    assert.ok svg.startsWith('<svg')
    assert.ok svg.indexOf('viewBox=') isnt -1
    assert.ok svg.indexOf('Substrate') isnt -1
    assert.ok svg.indexOf('Top Copper') isnt -1
    assert.ok svg.indexOf('Vias') isnt -1
    assert.ok svg.indexOf('Component Pads') isnt -1
    assert.ok svg.endsWith("</svg>\n")

  it 'renders terminal ASCII-art board inspector directly to string', ->
    b = createTestBoard()
    ascii = TerminalPreview.render(b, 60, 20)

    assert.ok ascii.indexOf('Board: vis_test') isnt -1
    assert.ok ascii.indexOf('+') isnt -1 # Corners
    assert.ok ascii.indexOf('[U1]') isnt -1 # Component label
    assert.ok ascii.indexOf('Legend:') isnt -1

  it 'initializes WebServer daemon and sets up HTTP router', ->
    b = createTestBoard()
    server = new WebServer(b, 0) # Port 0 for random free test port
    assert.ok server?
    assert.strictEqual typeof server.start, 'function'
    assert.strictEqual typeof server.stop, 'function'

console.log 'All Visualizer tests passed.'
