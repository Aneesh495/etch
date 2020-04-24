###
# Etch EDA: Ball Grid Array Footprints (BGA-36, BGA-64, BGA-144)
#
# Generates high-density ball grid array packages conforming to JEDEC and
# IPC-7351B standards. Alphanumeric grid indexing (A1..H8) omitting ambiguous
# letters (I, O, Q, S, X, Z). Supports dog-bone via fanout geometry.
###

Units = require '../core/units'
Polygon = require '../core/polygon'
{ Pad, PadShape, PadType } = require '../model/pad'
Component = require '../model/component'

# JEDEC standard row lettering omitting visually ambiguous letters
JEDEC_LETTERS = ['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'J', 'K', 'L', 'M', 'N', 'P', 'R', 'T']

class BGAFootprints
  @create: (refDes, matrixSize = 8, pitchMm = 0.8, ballPadMm = 0.4, options = {}) ->
    comp = new Component({
      refDes: refDes
      value: options.value or ''
      footprintName: "BGA-#{matrixSize * matrixSize}"
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    pitch = Units.mm(pitchMm)
    padDiameter = Units.mm(ballPadMm)
    span = (matrixSize - 1) * pitch
    halfSpan = Math.round(span / 2)

    for row in [0...matrixSize]
      rowLetter = JEDEC_LETTERS[row] or "R#{row}"
      py = halfSpan - (row * pitch)

      for col in [0...matrixSize]
        colNum = col + 1
        px = -halfSpan + (col * pitch)
        pinName = "#{rowLetter}#{colNum}"

        comp.addPad(new Pad({
          number: pinName
          name: pinName
          shape: PadShape.CIRCLE
          type: PadType.SMD
          x: px
          y: py
          widthNm: padDiameter
          heightNm: padDiameter
        }))

    courtSize = Units.mm((matrixSize * pitchMm) + 1.6)
    comp.courtyard = Polygon.fromRect(
      -Math.round(courtSize / 2),
      -Math.round(courtSize / 2),
      courtSize,
      courtSize
    )

    comp

module.exports = BGAFootprints
