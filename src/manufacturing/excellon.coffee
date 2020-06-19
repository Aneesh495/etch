###
# Etch EDA: Excellon NC Drill File Format Generator (Format 2)
#
# Generates CNC numeric control drill files conforming to the Excellon format.
# Organizes drill holes by tool diameter, defines the tool table (%T01C...),
# and outputs metric coordinate cycles for automated drill spindles.
###

Units = require '../core/units'

class ExcellonExporter
  # Generate Excellon NC Drill file string
  @exportDrill: (board) ->
    lines = []
    lines.push "M48"                                # Start of header
    lines.push "; DRILL file {Etch EDA} date 2026-11-09"
    lines.push "; FORMAT={-:-/ metric / decimal}"
    lines.push "METRIC,TZ"                          # Metric with trailing zero suppression

    # Collect and group all drill holes by diameter
    # Diameter in mm (3 decimals string, e.g. "0.300") -> Array of { x, y }
    toolMap = new Map()

    # 1. Through-hole pads
    for pad in board.allPads()
      continue unless pad.isThroughHole() and pad.drillDiameterNm > 0
      dMm = (pad.drillDiameterNm / Units.NM_PER_MM).toFixed(3)
      pos = pad.absolutePosition()
      unless toolMap.has(dMm)
        toolMap.set(dMm, [])
      toolMap.get(dMm).push(pos)

    # 2. Vias
    for via in board.allVias()
      continue unless via.drillDiameterNm > 0
      dMm = (via.drillDiameterNm / Units.NM_PER_MM).toFixed(3)
      pos = via.position()
      unless toolMap.has(dMm)
        toolMap.set(dMm, [])
      toolMap.get(dMm).push(pos)

    # 3. Mounting holes
    for mh in board.mountingHoles
      continue unless mh.drillDiameterNm > 0
      dMm = (mh.drillDiameterNm / Units.NM_PER_MM).toFixed(3)
      unless toolMap.has(dMm)
        toolMap.set(dMm, [])
      toolMap.get(dMm).push({ x: mh.x, y: mh.y })

    # Sort tools by diameter ascending
    sortedDiameters = Array.from(toolMap.keys()).sort (a, b) ->
      parseFloat(a) - parseFloat(b)

    # Assign tool codes (T01, T02, ...)
    toolCodes = new Map()
    tNum = 1
    for dMm in sortedDiameters
      tCode = "T#{tNum.toString().padStart(2, '0')}"
      toolCodes.set(dMm, tCode)
      lines.push "#{tCode}C#{dMm}"
      tNum++

    lines.push "%" # End of header

    # Generate drill coordinate cycles for each tool
    for dMm in sortedDiameters
      tCode = toolCodes.get(dMm)
      holes = toolMap.get(dMm)
      lines.push tCode # Select tool

      for h in holes
        # Metric coordinates formatted as e.g. X10.500Y20.250
        xMm = (h.x / Units.NM_PER_MM).toFixed(3)
        yMm = (h.y / Units.NM_PER_MM).toFixed(3)
        lines.push "X#{xMm}Y#{yMm}"

    lines.push "M30" # End of program
    lines.join("\n") + "\n"

module.exports = ExcellonExporter
