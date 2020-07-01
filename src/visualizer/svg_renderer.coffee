###
# Etch EDA: Standalone Multi-Layer Vector SVG Generator
#
# Emits publication-quality, scalable vector graphics (SVG) representations
# of printed circuit boards with distinct layer styling, solder mask themes,
# component silkscreen text, and copper trace paths.
###

Units = require '../core/units'

class SVGRenderer
  # Render board to an SVG string
  @render: (board, options = {}) ->
    wNm = board.widthNm()
    hNm = board.heightNm()

    wMm = Units.fromNm(wNm, 'mm')
    hMm = Units.fromNm(hNm, 'mm')

    # ViewBox padding in mm
    padMm = 4.0
    viewBoxX = -padMm
    viewBoxY = -padMm
    viewBoxW = wMm + (2 * padMm)
    viewBoxH = hMm + (2 * padMm)

    theme = options.theme or 'matte_black'
    colors = @_getThemeColors(theme)

    svg = []
    svg.push """<svg xmlns="http://www.w3.org/2000/svg" viewBox="#{viewBoxX.toFixed(2)} #{viewBoxY.toFixed(2)} #{viewBoxW.toFixed(2)} #{viewBoxH.toFixed(2)}" width="#{viewBoxW * 15}" height="#{viewBoxH * 15}" style="background-color: #{colors.background}; font-family: monospace;">"""

    # Definitions for filters or patterns
    svg.push """<defs>
      <filter id="glow" x="-20%" y="-20%" width="140%" height="140%">
        <feGaussianBlur stdDeviation="0.4" result="blur" />
        <feComposite in="SourceGraphic" in2="blur" operator="over" />
      </filter>
    </defs>"""

    # 1. Substrate Body (FR4 Board Outline)
    outlinePts = (edge.p1 for edge in board.outline.edges())
    if outlinePts.length > 0
      ptsStr = ("#{Units.fromNm(p.x, 'mm').toFixed(3)},#{(hMm - Units.fromNm(p.y, 'mm')).toFixed(3)}" for p in outlinePts).join(' ')
      svg.push """  <!-- Substrate -->
  <polygon points="#{ptsStr}" fill="#{colors.mask}" stroke="#{colors.edge}" stroke-width="0.3" rx="1.0" />"""

    # 2. Bottom Copper Traces (faded behind)
    svg.push """  <!-- Bottom Copper (B.Cu) -->"""
    for seg in board.allTraceSegments()
      continue if seg.layerId isnt 'B.Cu'
      x1 = Units.fromNm(seg.p1.x, 'mm').toFixed(3)
      y1 = (hMm - Units.fromNm(seg.p1.y, 'mm')).toFixed(3)
      x2 = Units.fromNm(seg.p2.x, 'mm').toFixed(3)
      y2 = (hMm - Units.fromNm(seg.p2.y, 'mm')).toFixed(3)
      w = Units.fromNm(seg.widthNm, 'mm').toFixed(3)
      svg.push """  <line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" stroke="#{colors.copperBottom}" stroke-width="#{w}" stroke-linecap="round" opacity="0.6" />"""

    # 3. Top Copper Traces (F.Cu)
    svg.push """  <!-- Top Copper (F.Cu) -->"""
    for seg in board.allTraceSegments()
      continue if seg.layerId isnt 'F.Cu'
      x1 = Units.fromNm(seg.p1.x, 'mm').toFixed(3)
      y1 = (hMm - Units.fromNm(seg.p1.y, 'mm')).toFixed(3)
      x2 = Units.fromNm(seg.p2.x, 'mm').toFixed(3)
      y2 = (hMm - Units.fromNm(seg.p2.y, 'mm')).toFixed(3)
      w = Units.fromNm(seg.widthNm, 'mm').toFixed(3)
      svg.push """  <line x1="#{x1}" y1="#{y1}" x2="#{x2}" y2="#{y2}" stroke="#{colors.copperTop}" stroke-width="#{w}" stroke-linecap="round" />"""

    # 4. Vias
    svg.push """  <!-- Vias -->"""
    for via in board.allVias()
      vx = Units.fromNm(via.x, 'mm').toFixed(3)
      vy = (hMm - Units.fromNm(via.y, 'mm')).toFixed(3)
      r = (Units.fromNm(via.diameterNm, 'mm') / 2).toFixed(3)
      dr = (Units.fromNm(via.drillDiameterNm, 'mm') / 2).toFixed(3)
      svg.push """  <circle cx="#{vx}" cy="#{vy}" r="#{r}" fill="#{colors.copperTop}" />"""
      svg.push """  <circle cx="#{vx}" cy="#{vy}" r="#{dr}" fill="#{colors.drillHole}" />"""

    # 5. Component Pads
    svg.push """  <!-- Component Pads -->"""
    for pad in board.allPads()
      pos = pad.absolutePosition()
      px = Units.fromNm(pos.x, 'mm')
      py = hMm - Units.fromNm(pos.y, 'mm')
      pw = Units.fromNm(pad.widthNm, 'mm')
      ph = Units.fromNm(pad.heightNm, 'mm')

      if pad.isThroughHole()
        pr = (Math.max(pw, ph) / 2).toFixed(3)
        dr = (Units.fromNm(pad.drillDiameterNm, 'mm') / 2).toFixed(3)
        svg.push """  <circle cx="#{px.toFixed(3)}" cy="#{py.toFixed(3)}" r="#{pr}" fill="#{colors.goldPad}" stroke="#{colors.copperTop}" stroke-width="0.1" />"""
        svg.push """  <circle cx="#{px.toFixed(3)}" cy="#{py.toFixed(3)}" r="#{dr}" fill="#{colors.drillHole}" />"""
      else
        xMin = (px - pw / 2).toFixed(3)
        yMin = (py - ph / 2).toFixed(3)
        svg.push """  <rect x="#{xMin}" y="#{yMin}" width="#{pw.toFixed(3)}" height="#{ph.toFixed(3)}" rx="0.1" fill="#{colors.goldPad}" />"""

    # 6. Mounting Holes
    for mh in board.mountingHoles
      mx = Units.fromNm(mh.x, 'mm').toFixed(3)
      my = (hMm - Units.fromNm(mh.y, 'mm')).toFixed(3)
      pr = (Units.fromNm(mh.padDiameterNm, 'mm') / 2).toFixed(3)
      dr = (Units.fromNm(mh.drillDiameterNm, 'mm') / 2).toFixed(3)
      svg.push """  <!-- Mounting Hole -->
  <circle cx="#{mx}" cy="#{my}" r="#{pr}" fill="#{colors.goldPad}" />
  <circle cx="#{mx}" cy="#{my}" r="#{dr}" fill="#{colors.drillHole}" />"""

    # 7. Silkscreen Text & Courtyards
    svg.push """  <!-- Silkscreen -->"""
    for comp in board.allComponents()
      cx = Units.fromNm(comp.x, 'mm').toFixed(3)
      cy = (hMm - Units.fromNm(comp.y, 'mm')).toFixed(3)
      svg.push """  <text x="#{cx}" y="#{cy}" font-size="1.2" fill="#{colors.silkscreen}" text-anchor="middle" dominant-baseline="central">#{comp.refDes}</text>"""

    svg.push "</svg>\n"
    svg.join("\n")

  @_getThemeColors: (theme) ->
    switch theme
      when 'classic_green'
        { background: '#121212', mask: '#145228', edge: '#f1c40f', copperTop: '#e67e22', copperBottom: '#2980b9', goldPad: '#f39c12', drillHole: '#121212', silkscreen: '#ffffff' }
      when 'osh_park_purple'
        { background: '#101018', mask: '#38144c', edge: '#f1c40f', copperTop: '#d4af37', copperBottom: '#4a235a', goldPad: '#ffd700', drillHole: '#101018', silkscreen: '#ffffff' }
      else # matte_black
        { background: '#0a0a0c', mask: '#1a1a20', edge: '#555566', copperTop: '#cc3333', copperBottom: '#2266aa', goldPad: '#d4af37', drillHole: '#0a0a0c', silkscreen: '#e0e0e0' }

module.exports = SVGRenderer
