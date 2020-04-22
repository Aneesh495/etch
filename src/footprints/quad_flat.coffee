###
# Etch EDA: Quad Flat Package Footprints (QFP-32, QFP-48, QFP-64, QFP-100)
#
# Generates 4-sided surface-mount packages with gull-wing leads conforming
# to IPC-7351B standards. Standard counter-clockwise pin numbering starting
# at top-left pin 1.
###

Units = require '../core/units'
Polygon = require '../core/polygon'
{ Pad, PadShape, PadType } = require '../model/pad'
Component = require '../model/component'

QFP_SPECS = {
  32: { pitch: 0.8, span: 9.0, padW: 0.5, padH: 1.5, pinsPerSide: 8 }
  48: { pitch: 0.5, span: 9.0, padW: 0.3, padH: 1.5, pinsPerSide: 12 }
  64: { pitch: 0.5, span: 12.0, padW: 0.3, padH: 1.5, pinsPerSide: 16 }
  100: { pitch: 0.5, span: 16.0, padW: 0.3, padH: 1.5, pinsPerSide: 25 }
}

class QuadFlatFootprints
  @create: (refDes, pinCount = 48, options = {}) ->
    spec = QFP_SPECS[pinCount] or QFP_SPECS[48]
    nSide = spec.pinsPerSide

    comp = new Component({
      refDes: refDes
      value: options.value or ''
      footprintName: "QFP-#{pinCount}"
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    pitch = Units.mm(spec.pitch)
    halfSpan = Math.round(Units.mm(spec.span) / 2)
    padW = Units.mm(spec.padW)
    padH = Units.mm(spec.padH)
    offset = Math.round(((nSide - 1) * pitch) / 2)

    pinIdx = 1

    # Side 1: Left edge (top to bottom) -> Pins 1 to nSide
    for i in [0...nSide]
      py = offset - (i * pitch)
      comp.addPad(new Pad({
        number: (pinIdx++).toString()
        shape: PadShape.ROUNDED_RECT
        x: -halfSpan
        y: py
        widthNm: padH # Rotated 90 deg relative to vertical
        heightNm: padW
      }))

    # Side 2: Bottom edge (left to right) -> Pins nSide+1 to 2*nSide
    for i in [0...nSide]
      px = -offset + (i * pitch)
      comp.addPad(new Pad({
        number: (pinIdx++).toString()
        shape: PadShape.ROUNDED_RECT
        x: px
        y: -halfSpan
        widthNm: padW
        heightNm: padH
      }))

    # Side 3: Right edge (bottom to top) -> Pins 2*nSide+1 to 3*nSide
    for i in [0...nSide]
      py = -offset + (i * pitch)
      comp.addPad(new Pad({
        number: (pinIdx++).toString()
        shape: PadShape.ROUNDED_RECT
        x: halfSpan
        y: py
        widthNm: padH
        heightNm: padW
      }))

    # Side 4: Top edge (right to left) -> Pins 3*nSide+1 to 4*nSide
    for i in [0...nSide]
      px = offset - (i * pitch)
      comp.addPad(new Pad({
        number: (pinIdx++).toString()
        shape: PadShape.ROUNDED_RECT
        x: px
        y: halfSpan
        widthNm: padW
        heightNm: padH
      }))

    courtSize = Units.mm(spec.span + 2.0)
    comp.courtyard = Polygon.fromRect(
      -Math.round(courtSize / 2),
      -Math.round(courtSize / 2),
      courtSize,
      courtSize
    )

    comp

module.exports = QuadFlatFootprints
