###
# Etch EDA: Standard Hardware Connectors (USB-C 16-Pin, Micro-USB, SMA, JST)
#
# Generates realistic hybrid SMT/THT footprints for modern board interfaces:
# reversible USB Type-C receptacles, coaxial RF connectors, and DC power jacks.
###

Units = require '../core/units'
Polygon = require '../core/polygon'
{ Pad, PadShape, PadType } = require '../model/pad'
Component = require '../model/component'

class ConnectorFootprints
  # USB Type-C 16-Pin Receptacle (Standard USB 2.0 compliant Type-C)
  # 12 SMT signal pins + 4 through-hole shield retention tabs
  @createUSBC: (refDes, options = {}) ->
    comp = new Component({
      refDes: refDes
      value: options.value or 'USB-C-16P'
      footprintName: 'USB_C_Receptacle_16P'
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    # SMT Signal Pins (Top/Bottom paired: GND, VBUS, CC1, D+, D-, SBU1, VBUS, GND, etc.)
    # 0.5 mm pitch SMT pins
    pinNames = ['A1', 'A4', 'B5', 'A5', 'A6', 'A7', 'A8', 'B8', 'B7', 'B6', 'A9', 'B9']
    pitch = Units.mm(0.5)
    padW = Units.mm(0.3)
    padH = Units.mm(1.2)
    startPinX = -Math.round(((pinNames.length - 1) * pitch) / 2)

    for i in [0...pinNames.length]
      pName = pinNames[i]
      px = startPinX + (i * pitch)
      comp.addPad(new Pad({
        number: pName
        name: pName
        shape: PadShape.ROUNDED_RECT
        type: PadType.SMD
        x: px
        y: Units.mm(1.5)
        widthNm: padW
        heightNm: padH
      }))

    # 4 Through-Hole Shield Mounting Tabs (Front left/right, Rear left/right)
    shieldTabPadW = Units.mm(1.8)
    shieldTabPadH = Units.mm(1.2)
    shieldDrill = Units.mm(0.8)

    shieldCoords = [
      { num: 'SH1', x: -Units.mm(4.3), y: Units.mm(0.5) }
      { num: 'SH2', x: Units.mm(4.3), y: Units.mm(0.5) }
      { num: 'SH3', x: -Units.mm(4.3), y: -Units.mm(2.5) }
      { num: 'SH4', x: Units.mm(4.3), y: -Units.mm(2.5) }
    ]

    for sh in shieldCoords
      comp.addPad(new Pad({
        number: sh.num
        name: 'GND'
        shape: PadShape.OVAL
        type: PadType.THROUGH_HOLE
        x: sh.x
        y: sh.y
        widthNm: shieldTabPadW
        heightNm: shieldTabPadH
        drillDiameterNm: shieldDrill
        layerId: 'All.Cu'
        netId: 'GND'
      }))

    comp.courtyard = Polygon.fromRect(-Units.mm(5.0), -Units.mm(3.5), Units.mm(10.0), Units.mm(6.5))
    comp

  # SMA Edge-Launch RF Coaxial Connector
  @createSMA: (refDes, options = {}) ->
    comp = new Component({
      refDes: refDes
      value: options.value or 'SMA_Edge_Launch'
      footprintName: 'SMA_EdgeLaunch_RF'
      x: options.x or 0
      y: options.y or 0
      rotationDeg: options.rotationDeg or 0
      side: options.side or 'top'
    })

    # Center RF Signal pin (Pin 1)
    comp.addPad(new Pad({
      number: '1'
      name: 'RF_IN'
      shape: PadShape.RECTANGLE
      type: PadType.SMD
      x: 0
      y: Units.mm(1.5)
      widthNm: Units.mm(0.8)
      heightNm: Units.mm(3.0)
    }))

    # Ground Tabs Left & Right (Pin 2 and 3)
    comp.addPad(new Pad({
      number: '2'
      name: 'GND'
      shape: PadShape.RECTANGLE
      type: PadType.SMD
      x: -Units.mm(2.5)
      y: Units.mm(1.5)
      widthNm: Units.mm(1.5)
      heightNm: Units.mm(3.0)
      netId: 'GND'
    }))
    comp.addPad(new Pad({
      number: '3'
      name: 'GND'
      shape: PadShape.RECTANGLE
      type: PadType.SMD
      x: Units.mm(2.5)
      y: Units.mm(1.5)
      widthNm: Units.mm(1.5)
      heightNm: Units.mm(3.0)
      netId: 'GND'
    }))

    comp.courtyard = Polygon.fromRect(-Units.mm(3.5), 0, Units.mm(7.0), Units.mm(5.0))
    comp

module.exports = ConnectorFootprints
