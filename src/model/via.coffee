###
# Etch EDA: Via Specifications, Multi-Layer Transitions, and Drill Geometry
#
# Represents plated through-vias, blind/buried vias, and micro-vias for
# layer transitions during multi-layer autorouting and power distribution.
###

Units = require '../core/units'
{ Point, BoundingBox } = require '../core/geometry'

ViaType = {
  THROUGH: 'through'
  BLIND: 'blind'
  BURIED: 'buried'
  MICROVIA: 'microvia'
  THERMAL: 'thermal'
}

class Via
  constructor: (options = {}) ->
    @x = options.x or 0
    @y = options.y or 0
    @diameterNm = options.diameterNm or Units.mm(0.6) # 0.6 mm (24 mil) standard pad
    @drillDiameterNm = options.drillDiameterNm or Units.mm(0.3) # 0.3 mm (12 mil) drill
    @startLayerId = options.startLayerId or 'F.Cu'
    @endLayerId = options.endLayerId or 'B.Cu'
    @netId = options.netId or null
    @type = options.type or ViaType.THROUGH

  position: -> new Point(@x, @y)

  annularRingNm: ->
    Math.max(0, Math.round((@diameterNm - @drillDiameterNm) / 2))

  boundingBox: ->
    radius = Math.round(@diameterNm / 2)
    new BoundingBox(@x - radius, @y - radius, @x + radius, @y + radius)

  drillBoundingBox: ->
    drillRadius = Math.round(@drillDiameterNm / 2)
    new BoundingBox(@x - drillRadius, @y - drillRadius, @x + drillRadius, @y + drillRadius)

  spansLayer: (layerId, stackup = null) ->
    return true if @type is ViaType.THROUGH
    if stackup?
      startIndex = stackup.idToCopperIndex(@startLayerId)
      endIndex = stackup.idToCopperIndex(@endLayerId)
      targetIndex = stackup.idToCopperIndex(layerId)
      minIdx = Math.min(startIndex, endIndex)
      maxIdx = Math.max(startIndex, endIndex)
      targetIndex >= minIdx and targetIndex <= maxIdx
    else
      layerId is @startLayerId or layerId is @endLayerId

module.exports = {
  ViaType
  Via
}
