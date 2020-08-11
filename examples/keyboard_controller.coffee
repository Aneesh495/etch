###
# Etch EDA Example: Mechanical Keyboard RP2040 Controller (2-Layer Reference Design)
#
# A compact 2-layer custom mechanical keyboard controller module featuring the
# Raspberry Pi RP2040 dual-core ARM Cortex-M0+, W25Q128 SPI NOR Flash (SOIC-8),
# ESD-protected USB Type-C connector, and matrix pin breakouts.
###

Etch = require '../src/etch'
{ defineBoard, Units } = Etch

board = defineBoard 'keyboard_controller', {
  title: 'RP2040 Mechanical Keyboard Matrix Controller'
  revision: 'v1.0'
  width: Units.mm(50)
  height: Units.mm(35)
  layers: 2
  rules: {
    minTraceWidthNm: Units.mm(0.18)
    minClearanceNm: Units.mm(0.18)
    minDrillDiameterNm: Units.mm(0.3)
    minAnnularRingNm: Units.mm(0.15)
  }
}, (b) ->
  # Microcontroller: RP2040 (QFN-56 with central ground pad)
  b.component 'U1', 'QFN-56', {
    value: 'RP2040'
    x: Units.mm(25.0)
    y: Units.mm(17.5)
  }

  # External SPI NOR Flash Memory: W25Q128 (SOIC-8)
  b.component 'U2', 'SOIC-8', {
    value: 'W25Q128JVS'
    x: Units.mm(40.0)
    y: Units.mm(17.5)
  }

  # 3.3V LDO Voltage Regulator: SOT-23
  b.component 'U3', 'SOT-23', {
    value: 'RT9193-3.3'
    x: Units.mm(12.0)
    y: Units.mm(28.0)
  }

  # Reversible USB-C Connector
  b.component 'J1', 'USB-C', {
    value: 'USB_C_16P'
    x: Units.mm(5.0)
    y: Units.mm(17.5)
    rotation: 90
  }

  # Left Matrix Breakout Header (1x8 2.54mm)
  b.component 'J2', 'HEADER_1X8', {
    value: 'COL_MATRIX'
    x: Units.mm(25.0)
    y: Units.mm(31.0)
  }

  # Right Matrix Breakout Header (1x8 2.54mm)
  b.component 'J3', 'HEADER_1X8', {
    value: 'ROW_MATRIX'
    x: Units.mm(25.0)
    y: Units.mm(4.0)
  }

  # Decoupling Passives (0402)
  b.component 'C1', '0402', { value: '100nF', x: Units.mm(18.0), y: Units.mm(17.5) }
  b.component 'C2', '0402', { value: '100nF', x: Units.mm(32.0), y: Units.mm(17.5) }
  b.component 'C3', '0805', { value: '10uF', x: Units.mm(12.0), y: Units.mm(22.0) }

  # USB 27-Ohm Termination Resistors (0402)
  b.component 'R1', '0402', { value: '27R', x: Units.mm(14.0), y: Units.mm(19.0) }
  b.component 'R2', '0402', { value: '27R', x: Units.mm(14.0), y: Units.mm(16.0) }

  # Nets
  b.net 'GND', [
    'U1.EP', 'U2.4', 'U3.1', 'J1.SH1', 'J1.SH2',
    'C1.2', 'C2.2', 'C3.2'
  ]

  b.net 'VBUS', ['J1.A4', 'U3.3', 'C3.1']
  b.net '3V3', ['U3.2', 'U1.1', 'U2.8', 'C1.1', 'C2.1']

  b.net 'USB_DP', ['J1.A6', 'R1.1']
  b.net 'USB_DM', ['J1.A7', 'R2.1']
  b.net 'RP_USB_DP', ['R1.2', 'U1.15']
  b.net 'RP_USB_DM', ['R2.2', 'U1.16']

  b.net 'FLASH_CS', ['U1.52', 'U2.1']
  b.net 'FLASH_DO', ['U1.53', 'U2.2']
  b.net 'FLASH_CLK', ['U1.54', 'U2.6']
  b.net 'FLASH_DI', ['U1.55', 'U2.5']

  # Bottom ground pour
  b.plane 'GND', { layer: 'B.Cu' }

  b.mountingHoles(Units.mm(3.5))

module.exports = board
