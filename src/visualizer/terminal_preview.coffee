###
# Etch EDA: Terminal ANSI ASCII-Art Board and Routing Previewer
#
# Generates compact, formatted text-based representations of board layouts
# directly in the terminal for headless CLI inspection, CI logs, and quick checks.
###

Units = require '../core/units'

class TerminalPreview
  # Generate ASCII canvas string representation of board
  @render: (board, widthChars = 70, heightChars = 24) ->
    wNm = board.widthNm()
    hNm = board.heightNm()

    # Initialize 2D character matrix with spaces
    grid = []
    for r in [0...heightChars]
      grid.push(new Array(widthChars).fill(' '))

    # Coordinate mapping: Board nm -> Terminal char column & row
    toCol = (xNm) ->
      c = Math.round((xNm / wNm) * (widthChars - 1))
      Math.max(0, Math.min(widthChars - 1, c))

    toRow = (yNm) ->
      # Invert Y for screen display (top is 0)
      r = Math.round(((hNm - yNm) / hNm) * (heightChars - 1))
      Math.max(0, Math.min(heightChars - 1, r))

    # 1. Draw Board Perimeter
    for c in [0...widthChars]
      grid[0][c] = '-'
      grid[heightChars - 1][c] = '-'
    for r in [0...heightChars]
      grid[r][0] = '|'
      grid[r][widthChars - 1] = '|'
    grid[0][0] = '+'
    grid[0][widthChars - 1] = '+'
    grid[heightChars - 1][0] = '+'
    grid[heightChars - 1][widthChars - 1] = '+'

    # 2. Draw Routed Traces
    for seg in board.allTraceSegments()
      c1 = toCol(seg.p1.x)
      r1 = toRow(seg.p1.y)
      c2 = toCol(seg.p2.x)
      r2 = toRow(seg.p2.y)

      # Bresenham-style line plotting
      dx = Math.abs(c2 - c1)
      dy = Math.abs(r2 - r1)
      sx = if c1 < c2 then 1 else -1
      sy = if r1 < r2 then 1 else -1
      err = dx - dy

      currC = c1
      currR = r1

      while true
        if currC > 0 and currC < widthChars - 1 and currR > 0 and currR < heightChars - 1
          ch = if seg.layerId is 'F.Cu' then '.' else '~'
          grid[currR][currC] = ch if grid[currR][currC] is ' '

        break if currC is c2 and currR is r2
        e2 = 2 * err
        if e2 > -dy
          err -= dy
          currC += sx
        if e2 < dx
          err += dx
          currR += sy

    # 3. Draw Vias
    for via in board.allVias()
      vc = toCol(via.x)
      vr = toRow(via.y)
      if vc > 0 and vc < widthChars - 1 and vr > 0 and vr < heightChars - 1
        grid[vr][vc] = 'O'

    # 4. Draw Mounting Holes
    for mh in board.mountingHoles
      mc = toCol(mh.x)
      mr = toRow(mh.y)
      if mc > 0 and mc < widthChars - 1 and mr > 0 and mr < heightChars - 1
        grid[mr][mc] = '@'

    # 5. Draw Components and Labels
    for comp in board.allComponents()
      cc = toCol(comp.x)
      cr = toRow(comp.y)
      label = "[#{comp.refDes}]"
      startC = Math.max(1, cc - Math.floor(label.length / 2))

      for i in [0...label.length]
        targetC = startC + i
        if targetC < widthChars - 1 and cr > 0 and cr < heightChars - 1
          grid[cr][targetC] = label[i]

    # Render lines
    lines = []
    lines.push "Board: #{board.name} (#{Units.formatMetric(wNm)} x #{Units.formatMetric(hNm)}, #{board.stackup.copperLayers().length} layers)"
    for r in [0...heightChars]
      lines.push grid[r].join('')
    lines.push "Legend: [RefDes]=Component  .=Top Trace  ~=Bottom Trace  O=Via  @=Hole"
    lines.join("\n") + "\n"

module.exports = TerminalPreview
