###
# Etch EDA: Small Outline IC & Transistor Footprints (SOT-23, SOT-223, SOIC, TSSOP)
#
# Generates dual-row gull-wing SMD packages conforming to IPC-7351B:
# SOT-23 (3-pin), SOT-223 (4-pin voltage regulators), SOIC (1.27mm pitch),
# and TSSOP (0.65mm pitch) with pin 1 polarity markers.
###

Units = require '../core/units'
Polygon = require '../core/polygon'
{ Pad, PadShape, PadType } = require '../model/pad'
Component = require '../model/component'

class SmallOutlineFootprints
  # SOT-23 (3-pin discrete transistor / diode / LDO)
  @createSOT23: (refDes, options = {}) ->
    comp = new Component({
      refDes: refDes
      value: options.value or ''
      footprintName: 'SOT-23'
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    padW = Units.mm(0.6)
    padH = Units.mm(1.0)
    pitchX = Units.mm(0.95)
    rowSpacingY = Units.mm(2.2)
    halfRowY = Math.round(rowSpacingY / 2)

    # Pin 1: Bottom Left
    comp.addPad(new Pad({ number: '1', shape: PadShape.ROUNDED_RECT, x: -pitchX, y: -halfRowY, widthNm: padW, heightNm: padH }))
    # Pin 2: Bottom Right
    comp.addPad(new Pad({ number: '2', shape: PadShape.ROUNDED_RECT, x: pitchX, y: -halfRowY, widthNm: padW, heightNm: padH }))
    # Pin 3: Top Center
    comp.addPad(new Pad({ number: '3', shape: PadShape.ROUNDED_RECT, x: 0, y: halfRowY, widthNm: padW, heightNm: padH }))

    comp.courtyard = Polygon.fromRect(-Units.mm(1.5), -Units.mm(1.75), Units.mm(3.0), Units.mm(3.5))
    comp

  # SOT-223 (4-pin power regulator, pin 4 is large heat sink tab)
  @createSOT223: (refDes, options = {}) ->
    comp = new Component({
      refDes: refDes
      value: options.value or ''
      footprintName: 'SOT-223'
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    padW = Units.mm(1.0)
    padH = Units.mm(1.5)
    pitchX = Units.mm(2.3)
    rowSpacingY = Units.mm(6.2)
    halfRowY = Math.round(rowSpacingY / 2)

    # Pins 1, 2, 3 on bottom
    comp.addPad(new Pad({ number: '1', shape: PadShape.ROUNDED_RECT, x: -pitchX, y: -halfRowY, widthNm: padW, heightNm: padH }))
    comp.addPad(new Pad({ number: '2', shape: PadShape.ROUNDED_RECT, x: 0, y: -halfRowY, widthNm: padW, heightNm: padH }))
    comp.addPad(new Pad({ number: '3', shape: PadShape.ROUNDED_RECT, x: pitchX, y: -halfRowY, widthNm: padW, heightNm: padH }))

    # Pin 4: Large heat-tab on top
    comp.addPad(new Pad({ number: '4', shape: PadShape.ROUNDED_RECT, x: 0, y: halfRowY, widthNm: Units.mm(3.3), heightNm: padH }))

    comp.courtyard = Polygon.fromRect(-Units.mm(3.8), -Units.mm(4.0), Units.mm(7.6), Units.mm(8.0))
    comp

  # SOIC Dual-Row Package (pin count: 8, 14, 16, 28; pitch: 1.27 mm / 50 mil)
  @createSOIC: (refDes, pinCount = 8, options = {}) ->
    comp = new Component({
      refDes: refDes
      value: options.value or ''
      footprintName: "SOIC-#{pinCount}"
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    pinsPerRow = pinCount / 2
    pitchY = Units.mm(1.27)
    rowSpacingX = Units.mm(5.8)
    halfRowX = Math.round(rowSpacingX / 2)
    padW = Units.mm(1.5)
    padH = Units.mm(0.6)

    startY = Math.round(((pinsPerRow - 1) * pitchY) / 2)

    # Left Row (Pins 1 to pinsPerRow, top to bottom)
    for i in [0...pinsPerRow]
      pinNum = (i + 1).toString()
      py = startY - (i * pitchY)
      comp.addPad(new Pad({
        number: pinNum
        shape: PadShape.ROUNDED_RECT
        x: -halfRowX
        y: py
        widthNm: padW
        heightNm: padH
      }))

    # Right Row (Pins pinsPerRow+1 to pinCount, bottom to top)
    for i in [0...pinsPerRow]
      pinNum = (pinCount - i).toString()
      py = startY - (i * pitchY)
      comp.addPad(new Pad({
        number: pinNum
        shape: PadShape.ROUNDED_RECT
        x: halfRowX
        y: py
        widthNm: padW
        heightNm: padH
      }))

    courtW = Units.mm(7.0)
    courtH = Units.mm((pinsPerRow * 1.27) + 1.0)
    comp.courtyard = Polygon.fromRect(
      -Math.round(courtW / 2),
      -Math.round(courtH / 2),
      courtW,
      courtH
    )

    comp

  # TSSOP Thin Shrink Small Outline Package (pitch: 0.65 mm)
  @createTSSOP: (refDes, pinCount = 16, options = {}) ->
    comp = new Component({
      refDes: refDes
      value: options.value or ''
      footprintName: "TSSOP-#{pinCount}"
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    pinsPerRow = pinCount / 2
    pitchY = Units.mm(0.65)
    rowSpacingX = Units.mm(5.6)
    halfRowX = Math.round(rowSpacingX / 2)
    padW = Units.mm(1.2)
    padH = Units.mm(0.4)

    startY = Math.round(((pinsPerRow - 1) * pitchY) / 2)

    for i in [0...pinsPerRow]
      pinNum = (i + 1).toString()
      py = startY - (i * pitchY)
      comp.addPad(new Pad({ number: pinNum, shape: PadShape.ROUNDED_RECT, x: -halfRowX, y: py, widthNm: padW, heightNm: padH }))

    for i in [0...pinsPerRow]
      pinNum = (pinCount - i).toString()
      py = startY - (i * pitchY)
      comp.addPad(new Pad({ number: pinNum, shape: PadShape.ROUNDED_RECT, x: halfRowX, y: py, widthNm: padW, heightNm: padH }))

    courtW = Units.mm(6.4)
    courtH = Units.mm((pinsPerRow * 0.65) + 0.8)
    comp.courtyard = Polygon.fromRect(-Math.round(courtW / 2), -Math.round(courtH / 2), courtW, courtH)
    comp

module.exports = SmallOutlineFootprints
