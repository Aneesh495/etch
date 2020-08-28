# Etch EDA: Declarative CoffeeScript PCB Layout DSL Guide

## 1. Introduction

Etch provides a literate, declarative domain-specific language (DSL) for designing printed circuit boards directly in CoffeeScript. By eliminating boilerplate syntax (parentheses, braces, semicolons), layouts read like clean engineering specifications.

## 2. Defining a Board

A board layout is declared using the `defineBoard` factory:

```coffeescript
Etch = require 'etch'
{ defineBoard, Units } = Etch

board = defineBoard 'sensor_node', {
  title: 'Environmental Telemetry Node'
  revision: 'v1.0'
  width: Units.mm(80)
  height: Units.mm(50)
  layers: 4
  rules: {
    minTraceWidthNm: Units.mm(0.15) # 6 mil minimum
    minClearanceNm: Units.mm(0.15)   # 6 mil minimum
    minDrillDiameterNm: Units.mm(0.3)
  }
}, (b) ->
  # Board definitions follow here
```

## 3. Component Instantiation

Components are instantiated using `b.component` with a reference designator and footprint identifier:

```coffeescript
# Microcontroller in QFN-32 package
b.component 'U1', 'QFN-32', {
  value: 'STM32F401'
  x: Units.mm(40.0)
  y: Units.mm(25.0)
  rotationDeg: 0
}

# Passive decoupling capacitor in 0402 package
b.component 'C1', '0402', {
  value: '100nF'
  x: Units.mm(34.0)
  y: Units.mm(25.0)
}

# Reversible USB Type-C connector rotated 90 degrees
b.component 'J1', 'USB-C', {
  value: 'TYPE-C-16P'
  x: Units.mm(6.0)
  y: Units.mm(25.0)
  rotationDeg: 90
}
```

### Supported Footprint Families
* **Passives**: `'0201'`, `'0402'`, `'0603'`, `'0805'`, `'1206'`, `'1210'`, `'2010'`, `'2512'`
* **Small Outline**: `'SOT-23'`, `'SOT-223'`, `'SOIC-8'`, `'SOIC-16'`, `'TSSOP-16'`, `'TSSOP-20'`
* **Quad Flat**: `'QFP-32'`, `'QFP-48'`, `'QFP-64'`, `'QFP-100'`, `'LQFP-48'`
* **Quad Flat No-leads**: `'QFN-16'`, `'QFN-24'`, `'QFN-32'`, `'QFN-48'`, `'QFN-64'` (with center thermal pad `EP`)
* **Ball Grid Array**: `'BGA-36'`, `'BGA-64'`, `'BGA-144'`
* **Through-Hole**: `'DIP-8'`, `'DIP-14'`, `'DIP-16'`, `'HEADER_1X4'`, `'HEADER_2X5'`
* **Connectors**: `'USB-C'`, `'SMA'`

## 4. Electrical Nets & Connectivity

Nets declare electrical connectivity across component pins using dot notation (`RefDes.PinNumber`):

```coffeescript
# Ground net connecting central thermal pads and bypass caps
b.net 'GND', [
  'U1.EP'
  'C1.2'
  'J1.SH1'
  'J1.SH2'
]

# Regulated 3.3V power bus
b.net '3V3', [
  'U1.1'
  'C1.1'
]

# High-speed SPI clock line
b.net 'SPI_CLK', ['U1.20', 'U2.6']
```

### NetClasses
Physical routing rules can be customized per net using NetClasses:

```coffeescript
pwrRules = Etch.NetClass.power() # 20 mil traces, 0.4mm vias
b.net 'VBUS', ['J1.A4', 'U2.3'], pwrRules

diffRules = Etch.NetClass.differential() # 90 ohm matched impedance
b.net 'USB_D_POS', ['J1.A6', 'U1.15'], diffRules
```

## 5. Copper Pour Planes & Mounting Holes

### Solid Internal Planes
Internal power and ground planes are declared with `b.plane`:

```coffeescript
b.plane 'GND', { layer: 'In1.Cu', priority: 1 }
b.plane '3V3', { layer: 'In2.Cu', priority: 0 }
```

### Corner Mounting Holes
Four corner mounting holes can be automatically positioned with specified edge insets:

```coffeescript
# Adds 4 corner holes 4.5 mm from edges with 3.2 mm drill (M3 screw)
b.mountingHoles(Units.mm(4.5), Units.mm(3.2), Units.mm(6.0))
```

## 6. Algorithmic Placement Arrays

For regular layouts (LED matrices, button arrays, rotary rings):

```coffeescript
{ Placement } = Etch

# Place 8 LEDs in a horizontal row
Placement.alignRow(ledArray, startX, startY, pitchX)

# Place 12 LEDs in a circular polar ring
Placement.placePolar(ledArray, centerX, centerY, radiusNm)
```
