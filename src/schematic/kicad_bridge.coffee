###
# Etch EDA: KiCad S-Expression Netlist Parser and Exporter Bridge
#
# Provides bidirectional interoperability with KiCad EDA. Imports and exports
# KiCad S-expression netlist files (.net) mapping schematic symbols, component
# values, footprint associations, and hierarchical net graphs.
###

Component = require '../model/component'
{ Net } = require '../model/net'
Footprints = require '../footprints/index'

class KiCadNetlistBridge
  # Export Board netlist to KiCad S-expression format (.net)
  @exportSExpr: (board) ->
    lines = []
    lines.push "(export (version \"E\")"
    lines.push "  (design"
    lines.push "    (source \"#{board.name}.kicad_sch\")"
    lines.push "    (date \"2026-11-09\")"
    lines.push "    (tool \"Etch EDA v1.0.0\"))"

    # Components block
    lines.push "  (components"
    for comp in board.allComponents()
      lines.push "    (comp (ref \"#{comp.refDes}\")"
      lines.push "      (value \"#{comp.value}\")"
      lines.push "      (footprint \"#{comp.footprintName}\"))"
    lines.push "  )"

    # Nets block
    lines.push "  (nets"
    netCode = 1
    for net in board.netlist.allNets()
      lines.push "    (net (code \"#{netCode++}\") (name \"#{net.name}\")"
      for pinRef in net.pins
        lines.push "      (node (ref \"#{pinRef.componentRefDes}\") (pin \"#{pinRef.pinNumber}\"))"
      lines.push "    )"
    lines.push "  )"

    lines.push ")"
    lines.join("\n") + "\n"

  # Parse simple KiCad S-expression netlist text
  @importSExpr: (sExprText, board) ->
    # Simple regex-based S-expression parser
    compRegex = /\(comp\s+\(ref\s+"([^"]+)"\)\s+\(value\s+"([^"]*)"\)\s+\(footprint\s+"([^"]*)"\)\)/g
    m = null
    while (m = compRegex.exec(sExprText)) isnt null
      refDes = m[1]
      value = m[2]
      footprint = m[3]
      comp = Footprints.create(refDes, footprint, { value: value })
      board.addComponent(comp)

    # Parse nets
    netRegex = /\(net\s+\(code\s+"[^"]+"\)\s+\(name\s+"([^"]+)"\)([\s\S]*?)\n\s*\)/g
    nodeRegex = /\(node\s+\(ref\s+"([^"]+)"\)\s+\(pin\s+"([^"]+)"\)\)/g

    while (mNet = netRegex.exec(sExprText)) isnt null
      netName = mNet[1]
      netBody = mNet[2]
      targetNet = board.netlist.getNet(netName) or new Net(netName, netName)
      board.netlist.addNet(targetNet) unless board.netlist.hasNet(netName)

      while (mNode = nodeRegex.exec(netBody)) isnt null
        ref = mNode[1]
        pin = mNode[2]
        comp = board.getComponent(ref)
        pad = comp?.getPad(pin)
        targetNet.addPin(ref, pin, pad)

    board

module.exports = KiCadNetlistBridge
