###
# Etch EDA: Automated Pick-and-Place (CPL / Centroid) CSV Exporter
#
# Generates component placement list (CPL) centroid CSV files for automated
# surface-mount (SMT) pick-and-place assembly machines (e.g. JLC SMT, PCBWay SMT).
###

Units = require '../core/units'

class PickAndPlaceExporter
  # Generate Centroid CSV string
  @exportCSV: (board) ->
    lines = []
    lines.push "Designator,Val,Package,Mid X,Mid Y,Rotation,Layer"

    comps = board.allComponents()
    # Sort by RefDes (e.g. C1, C2, R1, U1)
    comps.sort (a, b) -> a.refDes.localeCompare(b.refDes, undefined, { numeric: true })

    for comp in comps
      midXMm = (comp.x / Units.NM_PER_MM).toFixed(3)
      midYMm = (comp.y / Units.NM_PER_MM).toFixed(3)
      layer = if comp.side is 'bottom' then 'Bottom' else 'Top'
      rot = comp.rotationDeg.toFixed(1)

      valEscaped = "\"#{comp.value}\""
      pkgEscaped = "\"#{comp.footprintName}\""

      lines.push "#{comp.refDes},#{valEscaped},#{pkgEscaped},#{midXMm},#{midYMm},#{rot},#{layer}"

    lines.join("\n") + "\n"

module.exports = PickAndPlaceExporter
