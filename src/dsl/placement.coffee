###
# Etch EDA: Parametric Component Placement and Array Layout Helpers
#
# Provides algorithmic component placement utilities for linear arrays,
# matrices, polar circular arrangements (e.g. rotary dials, LED rings),
# and auto-spacing around IC perimeters.
###

Units = require '../core/units'

class Placement
  # Arrange components in a horizontal row with fixed pitch
  @alignRow: (components, startX, startY, pitchX) ->
    for i in [0...components.length]
      c = components[i]
      c.x = startX + (i * pitchX)
      c.y = startY
    components

  # Arrange components in a vertical column with fixed pitch
  @alignColumn: (components, startX, startY, pitchY) ->
    for i in [0...components.length]
      c = components[i]
      c.x = startX
      c.y = startY + (i * pitchY)
    components

  # Arrange components in a 2D rectangular grid
  @alignMatrix: (components, startX, startY, pitchX, pitchY, cols = 4) ->
    for i in [0...components.length]
      c = components[i]
      row = Math.floor(i / cols)
      col = i % cols
      c.x = startX + (col * pitchX)
      c.y = startY + (row * pitchY)
    components

  # Arrange components evenly along a circular polar ring
  @placePolar: (components, centerX, centerY, radiusNm, startAngleDeg = 0.0) ->
    n = components.length
    return components if n is 0

    angleStep = 360.0 / n
    for i in [0...n]
      c = components[i]
      deg = startAngleDeg + (i * angleStep)
      rad = Units.degToRad(deg)
      c.x = Math.round(centerX + radiusNm * Math.cos(rad))
      c.y = Math.round(centerY + radiusNm * Math.sin(rad))
      # Rotate component tangential to circle
      c.rotationDeg = Units.normalizeDeg(deg + 90.0)
    components

module.exports = Placement
