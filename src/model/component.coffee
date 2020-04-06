###
# Etch EDA: Component Instance, Reference Designator, and Spatial Placement
#
# Models placed schematic components (ICs, passives, connectors, transistors)
# on printed circuit boards. Handles footprint pad assignment, 2D rotation,
# layer flipping (top vs bottom), and courtyard boundary management.
###

Units = require '../core/units'
{ Point, BoundingBox } = require '../core/geometry'
Matrix2D = require '../core/matrix'
Polygon = require '../core/polygon'

class Component
  constructor: (options = {}) ->
    @refDes = options.refDes or 'U1'
    @value = options.value or ''
    @footprintName = options.footprintName or 'GENERIC'
    @x = options.x or 0
    @y = options.y or 0
    @rotationDeg = options.rotationDeg or 0.0
    @side = options.side or 'top' # 'top' (F.Cu) or 'bottom' (B.Cu)
    @pads = []
    @courtyard = options.courtyard or null
    @silkscreenLines = []

  position: -> new Point(@x, @y)

  addPad: (pad) ->
    pad.parentComponent = this
    if @side is 'bottom' and pad.layerId is 'F.Cu'
      pad.layerId = 'B.Cu'
    @pads.push(pad)
    pad

  getPad: (numberOrName) ->
    str = numberOrName.toString()
    for p in @pads
      return p if p.number is str or p.name is str
    null

  padCount: -> @pads.length

  # Compute transform matrix for this component instance
  transformMatrix: ->
    m = Matrix2D.translation(@x, @y)
    m.rotateDeg(@rotationDeg)
    if @side is 'bottom'
      m.multiply(Matrix2D.mirrorX())
    m

  # Convert local footprint coordinates to absolute board coordinates
  localToBoard: (localPt) ->
    @transformMatrix().transformPoint(localPt)

  # Convert absolute board coordinates to local footprint coordinates
  boardToLocal: (boardPt) ->
    @transformMatrix().inverse().transformPoint(boardPt)

  # Overall bounding box encompassing all pads and courtyard
  boundingBox: ->
    bb = new BoundingBox()
    for p in @pads
      bb = bb.union(p.boundingBox())
    if @courtyard?
      transCourtyard = @courtyard.clone()
      transCourtyard.rotateDeg(@rotationDeg)
      transCourtyard.translate(@x, @y)
      bb = bb.union(transCourtyard.boundingBox())
    bb

module.exports = Component
