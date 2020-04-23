###
# Etch EDA: Quad Flat No-Leads Footprints (QFN-16, QFN-24, QFN-32, QFN-48, QFN-64)
#
# Generates leadless perimeter pads with central exposed thermal ground pad (EP)
# conforming to IPC-7351B standards for high-performance microcontrollers (e.g. STM32,
# ESP32, RP2040) and RF transceivers.
###

Units = require '../core/units'
Polygon = require '../core/polygon'
{ Pad, PadShape, PadType } = require '../model/pad'
Component = require '../model/component'

QFN_SPECS = {
  16: { pitch: 0.65, span: 4.0, padW: 0.35, padH: 0.8, epSize: 2.5, pinsPerSide: 4 }
  24: { pitch: 0.5, span: 4.0, padW: 0.25, padH: 0.7, epSize: 2.6, pinsPerSide: 6 }
  32: { pitch: 0.5, span: 5.0, padW: 0.25, padH: 0.8, epSize: 3.5, pinsPerSide: 8 }
  48: { pitch: 0.5, span: 7.0, padW: 0.25, padH: 0.8, epSize: 5.2, pinsPerSide: 12 }
  64: { pitch: 0.5, span: 9.0, padW: 0.25, padH: 0.8, epSize: 7.1, pinsPerSide: 16 }
}

class QFNFootprints
  @create: (refDes, pinCount = 32, options = {}) ->
    spec = QFN_SPECS[pinCount] or QFN_SPECS[32]
    nSide = spec.pinsPerSide

    comp = new Component({
      refDes: refDes
      value: options.value or ''
      footprintName: "QFN-#{pinCount}"
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

    # Side 1: Left (top to bottom) -> 1 to nSide
    for i in [0...nSide]
      py = offset - (i * pitch)
      comp.addPad(new Pad({
        number: (pinIdx++).toString()
        shape: PadShape.ROUNDED_RECT
        x: -halfSpan
        y: py
        widthNm: padH
        heightNm: padW
      }))

    # Side 2: Bottom (left to right) -> nSide+1 to 2*nSide
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

    # Side 3: Right (bottom to top) -> 2*nSide+1 to 3*nSide
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

    # Side 4: Top (right to left) -> 3*nSide+1 to 4*nSide
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

    # Central Exposed Thermal Pad (EP / Pin pinCount + 1)
    epDim = Units.mm(spec.epSize)
    comp.addPad(new Pad({
      number: (pinCount + 1).toString()
      name: 'EP'
      shape: PadShape.ROUNDED_RECT
      x: 0
      y: 0
      widthNm: epDim
      heightNm: epDim
      netId: options.epNetId or 'GND'
    }))

    courtSize = Units.mm(spec.span + 1.2)
    comp.courtyard = Polygon.fromRect(
      -Math.round(courtSize / 2),
      -Math.round(courtSize / 2),
      courtSize,
      courtSize
    )

    comp

module.exports = QFNFootprints
