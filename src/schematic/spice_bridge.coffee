###
# Etch EDA: SPICE Circuit Simulation Netlist Bridge
#
# Translates physical board components and netlist connectivity into standard
# SPICE circuit netlists (.cir) for analog AC/DC and transient simulations.
# Maps GND net to global reference node 0.
###

class SPICEBridge
  # Export board netlist to SPICE format
  @exportSPICE: (board, title = board.name) ->
    lines = []
    lines.push "* SPICE netlist exported by Etch EDA v1.0.0"
    lines.push "* Title: #{title}"
    lines.push "* Date: 2026-11-09"
    lines.push ""

    # Generate node map: netName -> nodeString (GND -> '0')
    nodeMap = (netName) ->
      if not netName? or netName.toUpperCase() in ['GND', 'GROUND', '0']
        '0'
      else
        netName.replace(/[^a-zA-Z0-9_]/g, '_')

    for comp in board.allComponents()
      ref = comp.refDes.toUpperCase()
      typePrefix = ref.charAt(0)

      # Extract connected nets from pads
      pad1Net = nodeMap(comp.pads[0]?.netId)
      pad2Net = nodeMap(comp.pads[1]?.netId)

      switch typePrefix
        when 'R' # Resistor: R1 N1 N2 10k
          val = comp.value or '1k'
          lines.push "#{ref} #{pad1Net} #{pad2Net} #{val}"
        when 'C' # Capacitor: C1 N1 N2 100nF
          val = comp.value or '100nF'
          lines.push "#{ref} #{pad1Net} #{pad2Net} #{val}"
        when 'L' # Inductor: L1 N1 N2 10uH
          val = comp.value or '10uH'
          lines.push "#{ref} #{pad1Net} #{pad2Net} #{val}"
        when 'D' # Diode: D1 N1 N2 1N4148
          model = comp.value or '1N4148'
          lines.push "#{ref} #{pad1Net} #{pad2Net} #{model}"
        when 'Q' # BJT/MOSFET: Q1 Drain Gate Source / Collector Base Emitter
          pad3Net = nodeMap(comp.pads[2]?.netId)
          model = comp.value or '2N2222'
          lines.push "#{ref} #{pad1Net} #{pad2Net} #{pad3Net} #{model}"
        else
          # Generic subcircuit / IC
          padNodes = (nodeMap(p.netId) for p in comp.pads).join(' ')
          subckt = comp.value or comp.footprintName
          lines.push "X#{ref} #{padNodes} #{subckt}"

    lines.push ""
    lines.push ".END"
    lines.join("\n") + "\n"

module.exports = SPICEBridge
