###
# Etch EDA: Embedded HTTP Server and Interactive Web CAD GUI Daemon
#
# Serves the dark-mode interactive Web CAD visualizer over HTTP. Provides
# REST API endpoints for board geometry, layer toggles, netlist queries,
# DRC validation diagnostics, and SVG vector exports.
###

http = require 'http'
fs = require 'fs'
path = require 'path'
Units = require '../core/units'
SVGRenderer = require './svg_renderer'
{ DesignRuleChecker } = require '../drc/checker'

class WebServer
  constructor: (@board, @port = 8080) ->
    @webDir = path.resolve(__dirname, '../../web')
    @server = null

  start: (callback) ->
    @server = http.createServer (req, res) =>
      @_handleRequest(req, res)

    @server.listen @port, =>
      console.log "Etch Web CAD Visualizer running at http://localhost:#{@port}/"
      callback?(@port)

  stop: (callback) ->
    if @server?
      @server.close(callback)
    else
      callback?()

  _handleRequest: (req, res) ->
    url = req.url.split('?')[0]

    switch url
      when '/', '/index.html'
        @_serveStatic(res, 'index.html', 'text/html')
      when '/style.css'
        @_serveStatic(res, 'style.css', 'text/css')
      when '/app.js'
        @_serveStatic(res, 'app.js', 'application/javascript')
      when '/api/board'
        @_serveBoardJSON(res)
      when '/api/drc'
        @_serveDRCJSON(res)
      when '/api/svg'
        @_serveSVG(res)
      else
        res.writeHead(404, { 'Content-Type': 'text/plain' })
        res.end('Not Found')

  _serveStatic: (res, filename, contentType) ->
    filePath = path.join(@webDir, filename)
    if fs.existsSync(filePath)
      content = fs.readFileSync(filePath, 'utf-8')
      res.writeHead(200, { 'Content-Type': contentType })
      res.end(content)
    else
      res.writeHead(404, { 'Content-Type': 'text/plain' })
      res.end("File not found: #{filename}")

  _serveBoardJSON: (res) ->
    stats = @board.statistics()

    # Collect layers
    layers = []
    for l in @board.stackup.copperLayers()
      layers.push({
        id: l.id
        name: l.name
        colorHex: l.colorHex
      })

    # Collect nets
    nets = []
    for net in @board.netlist.allNets()
      nets.push({
        id: net.id
        name: net.name
        pinCount: net.pins.length
      })

    # Collect pads
    pads = []
    for pad in @board.allPads()
      pos = pad.absolutePosition()
      pads.push({
        refDes: pad.parentComponent?.refDes or ''
        number: pad.number
        netId: pad.netId
        layerId: pad.layerId
        x: Units.fromNm(pos.x, 'mm')
        y: Units.fromNm(pos.y, 'mm')
        widthMm: Units.fromNm(pad.widthNm, 'mm')
        heightMm: Units.fromNm(pad.heightNm, 'mm')
        drillDiameterMm: Units.fromNm(pad.drillDiameterNm, 'mm')
      })

    # Collect traces
    traces = []
    for seg in @board.allTraceSegments()
      traces.push({
        netId: seg.netId
        layerId: seg.layerId
        x1: Units.fromNm(seg.p1.x, 'mm')
        y1: Units.fromNm(seg.p1.y, 'mm')
        x2: Units.fromNm(seg.p2.x, 'mm')
        y2: Units.fromNm(seg.p2.y, 'mm')
        widthMm: Units.fromNm(seg.widthNm, 'mm')
      })

    # Collect vias
    vias = []
    for via in @board.allVias()
      vias.push({
        netId: via.netId
        x: Units.fromNm(via.x, 'mm')
        y: Units.fromNm(via.y, 'mm')
        diameterMm: Units.fromNm(via.diameterNm, 'mm')
        drillDiameterMm: Units.fromNm(via.drillDiameterNm, 'mm')
      })

    # Collect components
    components = []
    for comp in @board.allComponents()
      components.push({
        refDes: comp.refDes
        value: comp.value
        footprint: comp.footprintName
        x: Units.fromNm(comp.x, 'mm')
        y: Units.fromNm(comp.y, 'mm')
        rotation: comp.rotationDeg
        side: comp.side
      })

    payload = {
      name: @board.name
      stats: stats
      layers: layers
      nets: nets
      pads: pads
      traces: traces
      vias: vias
      components: components
    }

    res.writeHead(200, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify(payload))

  _serveDRCJSON: (res) ->
    drc = DesignRuleChecker.run(@board)
    payload = {
      passed: drc.passed
      errorCount: drc.errorCount
      warningCount: drc.warningCount
      violations: drc.violations.map (v) ->
        {
          rule: v.rule
          severity: v.severity
          message: v.message
          layerId: v.layerId
        }
    }
    res.writeHead(200, { 'Content-Type': 'application/json' })
    res.end(JSON.stringify(payload))

  _serveSVG: (res) ->
    svg = SVGRenderer.render(@board)
    res.writeHead(200, { 'Content-Type': 'image/svg+xml' })
    res.end(svg)

module.exports = WebServer
