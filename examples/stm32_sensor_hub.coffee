###
# Etch EDA Example: STM32 IoT Multi-Sensor Node (4-Layer Reference Design)
#
# A production-ready 4-layer environmental telemetry board featuring an
# STM32F401 ARM Cortex-M4 microcontroller, BME280 barometric pressure sensor,
# MPU-6050 6-axis IMU, AMS1117 3.3V LDO regulator, and USB-C power/debug interface.
###

Etch = require '../src/etch'
{ defineBoard, Units } = Etch

board = defineBoard 'stm32_sensor_hub', {
  title: 'STM32 Environmental Telemetry & Motion Node'
  revision: 'v2.1'
  width: Units.mm(75)
  height: Units.mm(50)
  layers: 4
  rules: {
    minTraceWidthNm: Units.mm(0.15)
    minClearanceNm: Units.mm(0.15)
    minDrillDiameterNm: Units.mm(0.3)
    minAnnularRingNm: Units.mm(0.15)
  }
}, (b) ->
  # Microcontroller: STM32F401 (QFN-32)
  b.component 'U1', 'QFN-32', {
    value: 'STM32F401CCU6'
    x: Units.mm(37.5)
    y: Units.mm(25.0)
  }

  # Voltage Regulator: 3.3V LDO (SOT-223)
  b.component 'U2', 'SOT-223', {
    value: 'AMS1117-3.3'
    x: Units.mm(18.0)
    y: Units.mm(38.0)
  }

  # Environmental Sensor: BME280 (QFN-16)
  b.component 'U3', 'QFN-16', {
    value: 'BME280'
    x: Units.mm(58.0)
    y: Units.mm(35.0)
  }

  # 6-Axis Motion Sensor: MPU-6050 (QFN-24)
  b.component 'U4', 'QFN-24', {
    value: 'MPU-6050'
    x: Units.mm(58.0)
    y: Units.mm(15.0)
  }

  # USB-C Receptacle
  b.component 'J1', 'USB-C', {
    value: 'TYPE-C-16P'
    x: Units.mm(6.0)
    y: Units.mm(25.0)
    rotation: 90
  }

  # SWD Debug Header (1x4 2.54mm pin header)
  b.component 'J2', 'HEADER_1X4', {
    value: 'SWD_DEBUG'
    x: Units.mm(37.5)
    y: Units.mm(6.0)
  }

  # Decoupling Capacitors (0402)
  b.component 'C1', '0402', { value: '100nF', x: Units.mm(30.0), y: Units.mm(25.0) }
  b.component 'C2', '0402', { value: '100nF', x: Units.mm(45.0), y: Units.mm(25.0) }
  b.component 'C3', '0402', { value: '4.7uF', x: Units.mm(37.5), y: Units.mm(32.0) }
  b.component 'C4', '0805', { value: '10uF', x: Units.mm(12.0), y: Units.mm(38.0) }
  b.component 'C5', '0805', { value: '22uF', x: Units.mm(24.0), y: Units.mm(38.0) }

  # I2C Pull-Up Resistors (0603)
  b.component 'R1', '0603', { value: '4.7k', x: Units.mm(48.0), y: Units.mm(28.0) }
  b.component 'R2', '0603', { value: '4.7k', x: Units.mm(48.0), y: Units.mm(22.0) }

  # Electrical Net Connectivity
  b.net 'GND', [
    'U1.EP', 'U2.1', 'U3.EP', 'U4.EP',
    'J1.SH1', 'J1.SH2', 'J2.4',
    'C1.2', 'C2.2', 'C3.2', 'C4.2', 'C5.2'
  ]

  b.net 'VBUS', ['J1.A4', 'U2.3', 'C4.1']
  b.net '3V3', [
    'U2.2', 'C5.1', 'U1.1', 'U3.1', 'U4.1',
    'C1.1', 'C2.1', 'C3.1', 'R1.1', 'R2.1', 'J2.1'
  ]

  b.net 'I2C_SCL', ['U1.18', 'U3.2', 'U4.2', 'R1.2']
  b.net 'I2C_SDA', ['U1.19', 'U3.3', 'U4.3', 'R2.2']

  b.net 'SWDIO', ['U1.23', 'J2.2']
  b.net 'SWCLK', ['U1.24', 'J2.3']

  # Solid Internal Copper Planes
  b.plane 'GND', { layer: 'In1.Cu', priority: 1 }
  b.plane '3V3', { layer: 'In2.Cu', priority: 0 }

  # Four Corner M3 Mounting Holes
  b.mountingHoles(Units.mm(4.5), Units.mm(3.2), Units.mm(6.0))

module.exports = board
