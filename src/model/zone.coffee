###
# Etch EDA: Polygonal Copper Pour Zones, Ground Planes, and Keepouts
#
# Models solid and hatched copper planes, split power planes, keepout zones,
# priority resolution between overlapping planes, and copper island removal.
###

Units = require '../core/units'
{ Point, BoundingBox } = require '../core/geometry'
Polygon = require '../core/polygon'

ZoneType = {
  COPPER_POUR: 'copper_pour'
  KEEPOUT: 'keepout'
  ROUTING_KEEPOUT: 'routing_keepout'
  COMPONENT_KEEPOUT: 'component_keepout'
}

ZoneFillMode = {
  SOLID: 'solid'
  HATCHED: 'hatched'
}

class Zone
  constructor: (options = {}) ->
    @netId = options.netId or 'GND'
    @layerId = options.layerId or 'In1.Cu'
    @polygon = options.polygon or new Polygon()
    @type = options.type or ZoneType.COPPER_POUR
    @fillMode = options.fillMode or ZoneFillMode.SOLID
    @priority = options.priority or 0 # Higher numbers fill first
    @clearanceNm = options.clearanceNm or Units.mm(0.3)
    @thermalSpokeWidthNm = options.thermalSpokeWidthNm or Units.mm(0.3)
    @minIslandAreaNm2 = options.minIslandAreaNm2 or (Units.mm(1.0) * Units.mm(1.0)) # 1 mm^2

  isCopperPour: -> @type is ZoneType.COPPER_POUR
  isKeepout: -> @type in [ZoneType.KEEPOUT, ZoneType.ROUTING_KEEPOUT, ZoneType.COMPONENT_KEEPOUT]

  containsPoint: (pt) -> @polygon.containsPoint(pt)

  boundingBox: -> @polygon.boundingBox()

  area: -> @polygon.area()

module.exports = {
  ZoneType
  ZoneFillMode
  Zone
}
