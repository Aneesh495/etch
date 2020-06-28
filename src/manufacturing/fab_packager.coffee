###
# Etch EDA: Fabrication Package Exporter and File Bundler
#
# Emits complete manufacturing archives containing RS-274X Gerbers, Excellon NC
# drill files, IPC-D-356 netlists, pick-and-place CPL, and structured BOMs.
###

fs = require 'fs'
path = require 'path'
{ GerberExporter } = require './gerber_rs274x'
ExcellonExporter = require './excellon'
IPCD356Exporter = require './ipc_d_356'
PickAndPlaceExporter = require './pick_and_place'
BOMExporter = require './bom'

class FabPackager
  @exportAll: (board, outputDir = 'fab_output') ->
    fs.mkdirSync(outputDir, { recursive: true }) unless fs.existsSync(outputDir)
    generatedFiles = []

    prefix = board.name.replace(/[^a-zA-Z0-9_-]/g, '_')

    # 1. Copper Layers
    for layer in board.stackup.copperLayers()
      gerberContent = GerberExporter.exportCopperLayer(board, layer.id)
      filename = "#{prefix}_#{layer.id.replace('.', '_')}.gbr"
      filePath = path.join(outputDir, filename)
      fs.writeFileSync(filePath, gerberContent, 'utf-8')
      generatedFiles.push(filePath)

    # 2. Solder Mask Layers
    fMaskContent = GerberExporter.exportSolderMask(board, 'F.Mask')
    fMaskPath = path.join(outputDir, "#{prefix}_F_Mask.gbr")
    fs.writeFileSync(fMaskPath, fMaskContent, 'utf-8')
    generatedFiles.push(fMaskPath)

    bMaskContent = GerberExporter.exportSolderMask(board, 'B.Mask')
    bMaskPath = path.join(outputDir, "#{prefix}_B_Mask.gbr")
    fs.writeFileSync(bMaskPath, bMaskContent, 'utf-8')
    generatedFiles.push(bMaskPath)

    # 3. Edge Cuts
    edgeContent = GerberExporter.exportEdgeCuts(board)
    edgePath = path.join(outputDir, "#{prefix}_Edge_Cuts.gbr")
    fs.writeFileSync(edgePath, edgeContent, 'utf-8')
    generatedFiles.push(edgePath)

    # 4. Excellon Drill File
    drillContent = ExcellonExporter.exportDrill(board)
    drillPath = path.join(outputDir, "#{prefix}.drl")
    fs.writeFileSync(drillPath, drillContent, 'utf-8')
    generatedFiles.push(drillPath)

    # 5. IPC-D-356 Test Netlist
    ipcContent = IPCD356Exporter.exportNetlist(board)
    ipcPath = path.join(outputDir, "#{prefix}.ipc")
    fs.writeFileSync(ipcPath, ipcContent, 'utf-8')
    generatedFiles.push(ipcPath)

    # 6. Pick-and-Place Centroid CSV
    cplContent = PickAndPlaceExporter.exportCSV(board)
    cplPath = path.join(outputDir, "#{prefix}_cpl.csv")
    fs.writeFileSync(cplPath, cplContent, 'utf-8')
    generatedFiles.push(cplPath)

    # 7. Bill of Materials (BOM)
    bomCsvContent = BOMExporter.exportCSV(board)
    bomCsvPath = path.join(outputDir, "#{prefix}_bom.csv")
    fs.writeFileSync(bomCsvPath, bomCsvContent, 'utf-8')
    generatedFiles.push(bomCsvPath)

    bomMdContent = BOMExporter.exportMarkdown(board)
    bomMdPath = path.join(outputDir, "#{prefix}_bom.md")
    fs.writeFileSync(bomMdPath, bomMdContent, 'utf-8')
    generatedFiles.push(bomMdPath)

    # 8. Fabrication Readme
    readmeContent = @_generateReadme(board)
    readmePath = path.join(outputDir, "README_FABRICATION.txt")
    fs.writeFileSync(readmePath, readmeContent, 'utf-8')
    generatedFiles.push(readmePath)

    {
      outputDir: outputDir
      fileCount: generatedFiles.length
      files: generatedFiles
    }

  @_generateReadme: (board) ->
    stats = board.statistics()
    lines = []
    lines.push "=================================================================="
    lines.push "             ETCH EDA: FABRICATION ARCHIVE SPECIFICATION          "
    lines.push "=================================================================="
    lines.push "Project Name: #{board.name}"
    lines.push "Revision: #{board.revision}"
    lines.push "Date: 2026-11-09"
    lines.push "Copper Layers: #{stats.layerCount}"
    lines.push "Board Dimensions: #{stats.widthMm} mm x #{stats.heightMm} mm"
    lines.push "Surface Finish: ENIG (Electroless Nickel Immersion Gold)"
    lines.push "Solder Mask: Matte Black / Classic Green"
    lines.push "Silkscreen: White"
    lines.push "Copper Weight: 1 oz (35 um) Outer / 1 oz Inner"
    lines.push "Minimum Trace Width: 0.15 mm (6 mil)"
    lines.push "Minimum Clearance: 0.15 mm (6 mil)"
    lines.push "Minimum Drill Hole: 0.30 mm (12 mil)"
    lines.push "=================================================================="
    lines.join("\n") + "\n"

module.exports = FabPackager
