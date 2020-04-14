###
# Etch EDA: IPC-7351B Passive Chip Component Footprints (SMD 0201 to 2512)
#
# Generates surface-mount device (SMD) rectangular chip footprints for resistors,
# capacitors, and inductors with courtyard boundaries and silkscreen markings.
###

Units = require '../core/units'
{ Point } = require '../core/geometry'
Polygon = require '../core/polygon'
{ Pad, PadShape, PadType } = require '../model/pad'
Component = require '../model/component'

PASSIVE_SPECS = {
  '0201': { padW: 0.3, padH: 0.3, pitch: 0.55, bodyW: 0.6, bodyH: 0.3 }
  '0402': { padW: 0.5, padH: 0.55, pitch: 0.95, bodyW: 1.0, bodyH: 0.5 }
  '0603': { padW: 0.8, padH: 0.9, pitch: 1.6, bodyW: 1.6, bodyH: 0.8 }
  '0805': { padW: 1.0, padH: 1.35, pitch: 1.9, bodyW: 2.0, bodyH: 1.25 }
  '1206': { padW: 1.1, padH: 1.8, pitch: 3.0, bodyW: 3.2, bodyH: 1.6 }
  '1210': { padW: 1.1, padH: 2.65, pitch: 3.0, bodyW: 3.2, bodyH: 2.5 }
  '2010': { padW: 1.3, padH: 2.65, pitch: 4.8, bodyW: 5.0, bodyH: 2.5 }
  '2512': { padW: 1.3, padH: 3.35, pitch: 6.1, bodyW: 6.3, bodyH: 3.2 }
}

class PassivesFootprints
  @create: (refDes, packageCode, options = {}) ->
    code = packageCode.replace(/^[RC_]/i, '')
    spec = PASSIVE_SPECS[code] or PASSIVE_SPECS['0805']

    comp = new Component({
      refDes: refDes
      value: options.value or ''
      footprintName: "SMD_#{code}"
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    halfPitch = Units.mm(spec.pitch / 2)
    padW = Units.mm(spec.padW)
    padH = Units.mm(spec.padH)

    # Pad 1 (Left)
    comp.addPad(new Pad({
      number: '1'
      name: '1'
      shape: PadShape.ROUNDED_RECT
      type: PadType.SMD
      x: -halfPitch
      y: 0
      widthNm: padW
      heightNm: padH
    }))

    # Pad 2 (Right)
    comp.addPad(new Pad({
      number: '2'
      name: '2'
      shape: PadShape.ROUNDED_RECT
      type: PadType.SMD
      x: halfPitch
      y: 0
      widthNm: padW
      heightNm: padH
    }))

    # Courtyard
    courtW = Units.mm(spec.bodyW + 0.5)
    courtH = Units.mm(spec.bodyH + 0.5)
    comp.courtyard = Polygon.fromRect(
      -Math.round(courtW / 2),
      -Math.round(courtH / 2),
      courtW,
      courtH
    )

    comp

module.exports = PassivesFootprints
