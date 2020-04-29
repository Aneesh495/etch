###
# Etch EDA: Through-Hole Component Footprints (DIP, Pin Headers, TO-220, TO-92)
#
# Generates plated through-hole (THT) footprints conforming to IPC-2221
# with circular and square pin 1 origin pads, drill holes, and annular rings.
###

Units = require '../core/units'
Polygon = require '../core/polygon'
{ Pad, PadShape, PadType } = require '../model/pad'
Component = require '../model/component'

class ThroughHoleFootprints
  # Dual In-line Package (pitch: 2.54 mm / 100 mil, row spacing: 7.62 mm / 300 mil)
  @createDIP: (refDes, pinCount = 8, options = {}) ->
    comp = new Component({
      refDes: refDes
      value: options.value or ''
      footprintName: "DIP-#{pinCount}"
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    pinsPerRow = pinCount / 2
    pitchY = Units.mm(2.54)
    rowSpacingX = Units.mm(7.62)
    halfRowX = Math.round(rowSpacingX / 2)
    padDiameter = Units.mm(1.6)
    drillDiameter = Units.mm(0.8)

    startY = Math.round(((pinsPerRow - 1) * pitchY) / 2)

    # Left Row (Pins 1 to pinsPerRow, top to bottom)
    for i in [0...pinsPerRow]
      pinNum = (i + 1).toString()
      py = startY - (i * pitchY)
      # Pin 1 gets rectangular pad for visual polarity alignment
      shape = if i is 0 then PadShape.RECTANGLE else PadShape.CIRCLE
      comp.addPad(new Pad({
        number: pinNum
        shape: shape
        type: PadType.THROUGH_HOLE
        x: -halfRowX
        y: py
        widthNm: padDiameter
        heightNm: padDiameter
        drillDiameterNm: drillDiameter
        layerId: 'All.Cu'
      }))

    # Right Row (Pins pinsPerRow+1 to pinCount, bottom to top)
    for i in [0...pinsPerRow]
      pinNum = (pinCount - i).toString()
      py = startY - (i * pitchY)
      comp.addPad(new Pad({
        number: pinNum
        shape: PadShape.CIRCLE
        type: PadType.THROUGH_HOLE
        x: halfRowX
        y: py
        widthNm: padDiameter
        heightNm: padDiameter
        drillDiameterNm: drillDiameter
        layerId: 'All.Cu'
      }))

    courtW = Units.mm(10.0)
    courtH = Units.mm((pinsPerRow * 2.54) + 2.0)
    comp.courtyard = Polygon.fromRect(
      -Math.round(courtW / 2),
      -Math.round(courtH / 2),
      courtW,
      courtH
    )

    comp

  # Standard 2.54mm (0.1 inch) Pin Header (Single or Dual Row)
  @createPinHeader: (refDes, rows = 1, cols = 4, options = {}) ->
    comp = new Component({
      refDes: refDes
      value: options.value or ''
      footprintName: "Header_#{rows}x#{cols}_P2.54mm"
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    pitch = Units.mm(2.54)
    padDiameter = Units.mm(1.7)
    drillDiameter = Units.mm(1.0)

    startColX = -Math.round(((cols - 1) * pitch) / 2)
    startRowY = Math.round(((rows - 1) * pitch) / 2)

    pinNum = 1
    for r in [0...rows]
      py = startRowY - (r * pitch)
      for c in [0...cols]
        px = startColX + (c * pitch)
        shape = if pinNum is 1 then PadShape.RECTANGLE else PadShape.CIRCLE
        comp.addPad(new Pad({
          number: pinNum.toString()
          shape: shape
          type: PadType.THROUGH_HOLE
          x: px
          y: py
          widthNm: padDiameter
          heightNm: padDiameter
          drillDiameterNm: drillDiameter
          layerId: 'All.Cu'
        }))
        pinNum++

    courtW = Units.mm((cols * 2.54) + 1.0)
    courtH = Units.mm((rows * 2.54) + 1.0)
    comp.courtyard = Polygon.fromRect(
      -Math.round(courtW / 2),
      -Math.round(courtH / 2),
      courtW,
      courtH
    )

    comp

module.exports = ThroughHoleFootprints
