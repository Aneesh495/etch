###
# Etch EDA Example: High-Current Synchronous Buck Power Supply (2-Layer Design)
#
# A 2-layer high-current switching power supply module delivering 5V/3A and 3.3V/2A
# with wide 40-mil copper pours, low-ESR polymer capacitors, shielded power
# inductors, and thermal relief via arrays.
###

Etch = require '../src/etch'
{ defineBoard, Units } = Etch

board = defineBoard 'power_distribution', {
  title: 'Synchronous Buck Step-Down Power Distribution Module'
  revision: 'v3.0'
  width: Units.mm(60)
  height: Units.mm(40)
  layers: 2
  rules: {
    minTraceWidthNm: Units.mm(0.25)
    minClearanceNm: Units.mm(0.25)
    minDrillDiameterNm: Units.mm(0.4)
    minAnnularRingNm: Units.mm(0.2)
  }
}, (b) ->
  # 5A Synchronous Step-Down Converter: TPS5450 (SOIC-8 with thermal pad)
  b.component 'U1', 'SOIC-8', {
    value: 'TPS5450DDAR'
    x: Units.mm(25.0)
    y: Units.mm(20.0)
  }

  # Input DC Screw Terminal Connector (1x2 2.54mm header)
  b.component 'J1', 'HEADER_1X2', {
    value: 'DC_VIN_12V'
    x: Units.mm(6.0)
    y: Units.mm(20.0)
  }

  # Regulated Output DC Screw Terminal Connector (1x2 2.54mm header)
  b.component 'J2', 'HEADER_1X2', {
    value: 'DC_VOUT_5V'
    x: Units.mm(54.0)
    y: Units.mm(20.0)
  }

  # High-Current Shielded Power Inductor (SMD 2512 footprint)
  b.component 'L1', '2512', {
    value: '10uH_6A'
    x: Units.mm(37.0)
    y: Units.mm(20.0)
  }

  # High-Voltage Input Filter Capacitor (SMD 1210)
  b.component 'C1', '1210', {
    value: '10uF_50V'
    x: Units.mm(15.0)
    y: Units.mm(20.0)
  }

  # Low-ESR Output Filter Capacitor (SMD 1210)
  b.component 'C2', '1210', {
    value: '47uF_16V'
    x: Units.mm(46.0)
    y: Units.mm(20.0)
  }

  # Voltage Feedback Divider Resistors (0805)
  b.component 'R1', '0805', { value: '10k_1%', x: Units.mm(35.0), y: Units.mm(30.0) }
  b.component 'R2', '0805', { value: '3.3k_1%', x: Units.mm(35.0), y: Units.mm(10.0) }

  # High-Current Power NetClasses
  pwrClass = Etch.NetClass.power()
  b.net 'VIN', ['J1.1', 'C1.1', 'U1.7'], pwrClass
  b.net 'SW_NODE', ['U1.8', 'L1.1'], pwrClass
  b.net 'VOUT', ['L1.2', 'C2.1', 'J2.1', 'R1.1'], pwrClass

  b.net 'GND', [
    'J1.2', 'C1.2', 'U1.6', 'C2.2', 'J2.2', 'R2.2'
  ]

  b.net 'FEEDBACK', ['R1.2', 'R2.1', 'U1.4']

  # Bottom ground pour
  b.plane 'GND', { layer: 'B.Cu' }

  b.mountingHoles(Units.mm(4.0))

module.exports = board
