###
# Etch EDA: Declarative CoffeeScript PCB Design Domain-Specific Language (DSL)
#
# Provides a clean, literate DSL for hardware engineers to specify multi-layer
# printed circuit boards, component placements, electrical nets, and copper
# plane zones directly in concise CoffeeScript code.
###

Units = require '../core/units'
Polygon = require '../core/polygon'
Board = require '../model/board'
{ Net, NetClass } = require '../model/net'
{ Zone, ZoneType } = require '../model/zone'
Footprints = require '../footprints/index'
Placement = require './placement'

class BoardBuilder
  constructor: (@boardName = 'untitled', options = {}) ->
    width = options.width or Units.mm(100)
    height = options.height or Units.mm(80)
    layers = options.layers or 2

    @board = new Board({
      name: @boardName
      title: options.title or @boardName
      revision: options.revision or 'v1.0'
      width: width
      height: height
      layers: layers
      rules: options.rules or {}
    })

    @pendingConnections = [] # Array of { netName, pinKeys }

  # Component definition helper
  component: (refDes, footprintName, options = {}) ->
    comp = Footprints.create(refDes, footprintName, options)
    @board.addComponent(comp)
    comp

  # Electrical net definition helper
  # Example: b.net 'SPI_SCK', ['U1.4', 'U2.12', 'R1.1']
  net: (name, pinKeys = [], netClass = NetClass.default()) ->
    existingNet = @board.netlist.getNet(name)
    targetNet = existingNet or new Net(name, name, netClass)
    @board.netlist.addNet(targetNet) unless existingNet?

    if pinKeys.length > 0
      @pendingConnections.push({ netName: name, pinKeys: pinKeys })
    targetNet

  # Direct connection helper between two or more pins
  connect: (netName, pinKeys...) ->
    keys = if Array.isArray(pinKeys[0]) then pinKeys[0] else pinKeys
    @net(netName, keys)

  # Full-board ground or power copper plane zone
  plane: (netName, options = {}) ->
    layerId = options.layer or 'In1.Cu'
    clearance = options.clearance or Units.mm(0.3)
    margin = options.margin or Units.mm(0.5)

    # Shrunk board outline for plane
    w = @board.widthNm()
    h = @board.heightNm()
    planePoly = Polygon.fromRect(margin, margin, w - 2 * margin, h - 2 * margin)

    zone = new Zone({
      netId: netName
      layerId: layerId
      polygon: planePoly
      type: ZoneType.COPPER_POUR
      priority: options.priority or 0
      clearanceNm: clearance
    })
    @board.addZone(zone)
    zone

  # Automatically add 4 corner mounting holes inset by margin
  mountingHoles: (marginNm = Units.mm(5.0), drillNm = Units.mm(3.2), padNm = Units.mm(6.0)) ->
    w = @board.widthNm()
    h = @board.heightNm()
    @board.addMountingHole(marginNm, marginNm, drillNm, padNm)
    @board.addMountingHole(w - marginNm, marginNm, drillNm, padNm)
    @board.addMountingHole(w - marginNm, h - marginNm, drillNm, padNm)
    @board.addMountingHole(marginNm, h - marginNm, drillNm, padNm)

  # Finalize and resolve all pending net connections to physical pads
  build: ->
    for conn in @pendingConnections
      net = @board.netlist.getNet(conn.netName)
      continue unless net?

      for pinKey in conn.pinKeys
        parts = pinKey.split('.')
        refDes = parts[0]
        pinNum = parts[1]

        comp = @board.getComponent(refDes)
        if comp?
          pad = comp.getPad(pinNum)
          if pad?
            pad.netId = conn.netName
            net.addPin(refDes, pinNum, pad)

    @board.rebuildSpatialIndex()
    @board

# Top-level factory function
defineBoard = (name, options, dslBlock) ->
  if typeof options is 'function'
    dslBlock = options
    options = {}
  builder = new BoardBuilder(name, options)
  dslBlock?(builder)
  builder.build()

module.exports = {
  BoardBuilder
  defineBoard
  Placement
}
