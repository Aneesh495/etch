###
# Etch EDA Example: High-Fidelity 32-Bit Audio DAC (4-Layer Reference Design)
#
# A high-end balanced stereo audio DAC board with ESS Sabre ES9038Q2M (QFP-48),
# dual OPA1612 low-noise operational amplifiers (SOIC-8), isolated analog and
# digital ground planes (AGND/DGND), and WIMA audio film capacitors.
###

Etch = require '../src/etch'
{ defineBoard, Units } = Etch

board = defineBoard 'hifi_audio_dac', {
  title: 'Audiophile 32-Bit 384kHz Balanced Stereo DAC'
  revision: 'v1.4'
  width: Units.mm(85)
  height: Units.mm(55)
  layers: 4
  rules: {
    minTraceWidthNm: Units.mm(0.15)
    minClearanceNm: Units.mm(0.18)
    minDrillDiameterNm: Units.mm(0.3)
    minAnnularRingNm: Units.mm(0.15)
  }
}, (b) ->
  # Digital to Analog Converter: ESS Sabre ES9038Q2M (QFP-48)
  b.component 'U1', 'QFP-48', {
    value: 'ES9038Q2M'
    x: Units.mm(35.0)
    y: Units.mm(27.5)
  }

  # Dual Low-Noise Audio Op-Amp: OPA1612 (SOIC-8) Left Channel
  b.component 'U2', 'SOIC-8', {
    value: 'OPA1612_L'
    x: Units.mm(62.0)
    y: Units.mm(40.0)
  }

  # Dual Low-Noise Audio Op-Amp: OPA1612 (SOIC-8) Right Channel
  b.component 'U3', 'SOIC-8', {
    value: 'OPA1612_R'
    x: Units.mm(62.0)
    y: Units.mm(15.0)
  }

  # Low-Noise LDO Voltage Regulator: Analog Rail 3.3V (SOT-223)
  b.component 'U4', 'SOT-223', {
    value: 'TPS7A4700'
    x: Units.mm(15.0)
    y: Units.mm(40.0)
  }

  # Low-Noise LDO Voltage Regulator: Digital Rail 3.3V (SOT-223)
  b.component 'U5', 'SOT-223', {
    value: 'TPS7A4701'
    x: Units.mm(15.0)
    y: Units.mm(15.0)
  }

  # Master Clock (MCLK) RF SMA Edge Connector
  b.component 'J1', 'SMA', {
    value: 'MCLK_IN'
    x: Units.mm(4.0)
    y: Units.mm(27.5)
    rotation: 90
  }

  # I2S Digital Audio Input Header (1x6 2.54mm)
  b.component 'J2', 'HEADER_1X6', {
    value: 'I2S_DIGITAL_IN'
    x: Units.mm(22.0)
    y: Units.mm(6.0)
  }

  # Balanced Analog Audio Output Header (1x6 2.54mm)
  b.component 'J3', 'HEADER_1X6', {
    value: 'ANALOG_BALANCED_OUT'
    x: Units.mm(78.0)
    y: Units.mm(27.5)
  }

  # Power Supply Filtering Capacitors (1206)
  b.component 'C1', '1206', { value: '47uF', x: Units.mm(22.0), y: Units.mm(40.0) }
  b.component 'C2', '1206', { value: '47uF', x: Units.mm(22.0), y: Units.mm(15.0) }

  # High-Precision Feedback Resistors (0805)
  b.component 'R1', '0805', { value: '1.0k_0.1%', x: Units.mm(52.0), y: Units.mm(42.0) }
  b.component 'R2', '0805', { value: '1.0k_0.1%', x: Units.mm(52.0), y: Units.mm(13.0) }

  # Ground Planes
  b.plane 'AGND', { layer: 'In1.Cu', priority: 1 }
  b.plane 'AVCC', { layer: 'In2.Cu', priority: 0 }

  # Nets
  b.net 'AGND', ['U1.1', 'U2.4', 'U3.4', 'U4.1', 'C1.2', 'J3.1', 'J3.6']
  b.net 'DGND', ['U1.25', 'U5.1', 'C2.2', 'J1.2', 'J1.3', 'J2.6']
  b.net 'AVCC', ['U4.2', 'C1.1', 'U1.12', 'U2.8', 'U3.8']
  b.net 'DVCC', ['U5.2', 'C2.1', 'U1.36']

  b.net 'I2S_DATA', ['J2.1', 'U1.14']
  b.net 'I2S_BCLK', ['J2.2', 'U1.15']
  b.net 'I2S_LRCK', ['J2.3', 'U1.16']
  b.net 'MCLK', ['J1.1', 'U1.17']

  b.net 'AOUT_L_POS', ['U1.40', 'R1.1', 'U2.3']
  b.net 'AOUT_R_POS', ['U1.44', 'R2.1', 'U3.3']

  b.mountingHoles(Units.mm(5.0))

module.exports = board
