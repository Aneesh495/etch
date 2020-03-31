###
# Etch EDA: Automated Thermal Relief Spoke Generator
#
# Generates thermal isolation gaps and narrow copper connection spokes
# between pads/vias and continuous ground/power planes. Prevents heat
# sinking during reflow soldering while maintaining electrical connectivity.
###

Units = require '../core/units'
{ Point, LineSegment } = require '../core/geometry'
Polygon = require '../core/polygon'

class ThermalRelief
  # Generate thermal connection spokes for a pad inside a copper zone
  # Returns array of LineSegment representing spoke centerlines
  @generateSpokes: (pad, spokeWidthNm = Units.mm(0.3), clearanceGapNm = Units.mm(0.25), pattern = '4-spoke-90') ->
    center = pad.absolutePosition()
    radius = Math.round(Math.max(pad.widthNm, pad.heightNm) / 2)
    outerRadius = radius + clearanceGapNm

    spokes = []
    anglesDeg = switch pattern
      when '4-spoke-90'
        [0, 90, 180, 270]
      when '4-spoke-45'
        [45, 135, 225, 315]
      when '2-spoke-horizontal'
        [0, 180]
      when '2-spoke-vertical'
        [90, 270]
      else
        [0, 90, 180, 270]

    for deg in anglesDeg
      rad = Units.degToRad(deg)
      cosA = Math.cos(rad)
      sinA = Math.sin(rad)

      innerPt = new Point(
        Math.round(center.x + radius * cosA),
        Math.round(center.y + radius * sinA)
      )
      outerPt = new Point(
        Math.round(center.x + outerRadius * cosA),
        Math.round(center.y + outerRadius * sinA)
      )
      spokes.push(new LineSegment(innerPt, outerPt))

    spokes

module.exports = ThermalRelief
