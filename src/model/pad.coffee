###
# Etch EDA: Pad Geometry, Solder Mask Expansions, and Annular Rings
#
# Represents surface-mount (SMD) and plated through-hole (THT) component
# pads conforming to IPC-7351B standards. Computes absolute board positions,
# solder mask openings, paste mask reductions, and annular rings.
###

Units = require '../core/units'
{ Point, BoundingBox } = require '../core/geometry'
Polygon = require '../core/polygon'

PadShape = {
  RECTANGLE: 'rect'
  ROUNDED_RECT: 'round_rect'
  CIRCLE: 'circle'
  OVAL: 'oval'
  CUSTOM: 'custom'
}

PadType = {
  SMD: 'smd'
  THROUGH_HOLE: 'through_hole'
  MOUNTING_HOLE: 'mounting_hole'
}

class Pad
  constructor: (options = {}) ->
    @number = options.number or '1'
    @name = options.name or @number
    @shape = options.shape or PadShape.RECTANGLE
    @type = options.type or PadType.SMD
    @x = options.x or 0 # Local X offset relative to component origin in nm
    @y = options.y or 0 # Local Y offset relative to component origin in nm
    @widthNm = options.widthNm or Units.mm(1.0)
    @heightNm = options.heightNm or Units.mm(1.0)
    @drillDiameterNm = options.drillDiameterNm or 0
    @layerId = options.layerId or 'F.Cu'
    @netId = options.netId or null
    @parentComponent = null # Set upon adding to Component
    @roundRadiusRatio = options.roundRadiusRatio or 0.25 # For rounded rects (IPC standard: 25%)

  isThroughHole: -> @type is PadType.THROUGH_HOLE
  isSMD: -> @type is PadType.SMD

  # Calculate absolute position on board accounting for component location and rotation
  absolutePosition: ->
    if @parentComponent?
      @parentComponent.localToBoard(new Point(@x, @y))
    else
      new Point(@x, @y)

  # Annular ring width for through-hole pads: (copper diameter - drill diameter) / 2
  annularRingNm: ->
    return 0 unless @isThroughHole()
    minDimension = Math.min(@widthNm, @heightNm)
    Math.max(0, Math.round((minDimension - @drillDiameterNm) / 2))

  # Bounding box in absolute board coordinates
  boundingBox: ->
    pos = @absolutePosition()
    hw = Math.round(@widthNm / 2)
    hh = Math.round(@heightNm / 2)
    new BoundingBox(pos.x - hw, pos.y - hh, pos.x + hw, pos.y + hh)

  # Polygonal boundary in absolute board coordinates
  polygon: ->
    pos = @absolutePosition()
    hw = Math.round(@widthNm / 2)
    hh = Math.round(@heightNm / 2)
    # Simple rectangular polygon approximation
    p1 = new Point(pos.x - hw, pos.y - hh)
    p2 = new Point(pos.x + hw, pos.y - hh)
    p3 = new Point(pos.x + hw, pos.y + hh)
    p4 = new Point(pos.x - hw, pos.y + hh)
    new Polygon([p1, p2, p3, p4])

  # Solder mask opening polygon (expanded by standard 50 um = 2 mil)
  solderMaskPolygon: (expansionNm = Units.um(50)) ->
    pos = @absolutePosition()
    hw = Math.round((@widthNm + 2 * expansionNm) / 2)
    hh = Math.round((@heightNm + 2 * expansionNm) / 2)
    p1 = new Point(pos.x - hw, pos.y - hh)
    p2 = new Point(pos.x + hw, pos.y - hh)
    p3 = new Point(pos.x + hw, pos.y + hh)
    p4 = new Point(pos.x - hw, pos.y + hh)
    new Polygon([p1, p2, p3, p4])

module.exports = {
  PadShape
  PadType
  Pad
}
