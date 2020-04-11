###
# Etch EDA: Master Printed Circuit Board (PCB) Model and Assembly State
#
# Top-level CAD database containing board outline geometry, layer stackup,
# placed components, logical netlist, routed copper traces, interlayer vias,
# polygonal copper pour zones, and manufacturing design rules.
###

Units = require '../core/units'
{ Point, BoundingBox } = require '../core/geometry'
Polygon = require '../core/polygon'
{ LayerStackup } = require './layer'
{ Netlist, Net } = require './net'
SpatialIndex = require '../core/spatial_index'

class Board
  constructor: (options = {}) ->
    @name = options.name or 'untitled_board'
    @title = options.title or @name
    @revision = options.revision or 'v1.0'
    @date = options.date or '2026-11-09'

    layerCount = options.layers or 2
    @stackup = options.stackup or new LayerStackup(layerCount)

    # Physical board outline polygon
    width = options.width or Units.mm(100)
    height = options.height or Units.mm(80)
    @outline = options.outline or Polygon.fromRect(0, 0, width, height)
    @cutouts = [] # Array of Polygon internal slots/cutouts

    # Assemblies and connectivity
    @components = new Map() # refDes -> Component
    @netlist = options.netlist or new Netlist()
    @traces = []            # Array of Trace
    @vias = []              # Array of Via
    @zones = []             # Array of Zone
    @mountingHoles = []     # Array of { x, y, drillDiameterNm, padDiameterNm }

    # Physical Design Rules
    rules = options.rules or {}
    @rules = {
      minTraceWidthNm: rules.minTraceWidthNm or Units.mm(0.15) # 6 mil
      minClearanceNm: rules.minClearanceNm or Units.mm(0.15)   # 6 mil
      minDrillDiameterNm: rules.minDrillDiameterNm or Units.mm(0.3) # 12 mil
      minAnnularRingNm: rules.minAnnularRingNm or Units.mm(0.15)
      copperToEdgeClearanceNm: rules.copperToEdgeClearanceNm or Units.mm(0.3)
      minHoleToHoleClearanceNm: rules.minHoleToHoleClearanceNm or Units.mm(0.5)
    }

    @spatialIndex = new SpatialIndex()

  # Dimension helpers
  widthNm: -> @outline.boundingBox().width()
  heightNm: -> @outline.boundingBox().height()

  # Component management
  addComponent: (comp) ->
    @components.set(comp.refDes, comp)
    comp

  getComponent: (refDes) ->
    @components.get(refDes) or null

  allComponents: -> Array.from(@components.values())

  # Pad accessors
  allPads: ->
    pads = []
    for comp from @components.values()
      for p in comp.pads
        pads.push(p)
    pads

  # Trace and via management
  addTrace: (trace) ->
    @traces.push(trace)
    trace

  allTraces: -> @traces

  allTraceSegments: ->
    segments = []
    for t in @traces
      for s in t.segments
        segments.push(s)
    segments

  addVia: (via) ->
    @vias.push(via)
    via

  allVias: -> @vias

  addZone: (zone) ->
    @zones.push(zone)
    zone

  allZones: -> @zones

  addMountingHole: (x, y, drillDiameterNm = Units.mm(3.2), padDiameterNm = Units.mm(6.0)) ->
    hole = { x: x, y: y, drillDiameterNm: drillDiameterNm, padDiameterNm: padDiameterNm }
    @mountingHoles.push(hole)
    hole

  # Spatial Index management
  rebuildSpatialIndex: ->
    @spatialIndex.clear()
    items = []

    # Index all pads
    for pad in @allPads()
      items.push({ item: { type: 'pad', entity: pad }, bb: pad.boundingBox(), id: "pad_#{pad.parentComponent.refDes}_#{pad.number}" })

    # Index all trace segments
    for seg in @allTraceSegments()
      items.push({ item: { type: 'trace_segment', entity: seg }, bb: seg.boundingBox(), id: "seg_#{seg.netId}_#{seg.p1.x}_#{seg.p1.y}" })

    # Index all vias
    for via in @vias
      items.push({ item: { type: 'via', entity: via }, bb: via.boundingBox(), id: "via_#{via.netId}_#{via.x}_#{via.y}" })

    @spatialIndex.bulkLoad(items)

  boundingBox: ->
    bb = @outline.boundingBox()
    for comp from @components.values()
      bb = bb.union(comp.boundingBox())
    bb

  # Calculate comprehensive board complexity statistics
  statistics: ->
    totalTraceLen = 0
    for t in @traces
      totalTraceLen += t.totalLength()

    compCount = @components.size
    padCount = @allPads().length
    netCount = @netlist.count()
    viaCount = @vias.length
    segmentCount = @allTraceSegments().length

    {
      name: @name
      layerCount: @stackup.copperLayers().length
      widthMm: Units.fromNm(@widthNm(), 'mm')
      heightMm: Units.fromNm(@heightNm(), 'mm')
      componentCount: compCount
      padCount: padCount
      netCount: netCount
      viaCount: viaCount
      traceSegmentCount: segmentCount
      totalTraceLengthMm: Units.fromNm(totalTraceLen, 'mm')
      zoneCount: @zones.length
      mountingHoleCount: @mountingHoles.length
    }

module.exports = Board
