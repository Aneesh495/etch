###
# Etch EDA: Structured Bill of Materials (BOM) Aggregator
#
# Collects and groups components by value and package footprint. Emits
# manufacturing bill of materials in standard CSV, Markdown table, and JSON.
###

class BOMExporter
  # Collect grouped BOM entries
  @getEntries: (board) ->
    groups = new Map() # "value|footprint" -> { value, footprint, designators: [] }

    for comp in board.allComponents()
      key = "#{comp.value}|#{comp.footprintName}"
      unless groups.has(key)
        groups.set(key, {
          value: comp.value or '-'
          footprint: comp.footprintName
          designators: []
        })
      groups.get(key).designators.push(comp.refDes)

    entries = []
    itemNum = 1
    for [key, data] from groups.entries()
      data.designators.sort (a, b) -> a.localeCompare(b, undefined, { numeric: true })
      entries.push({
        item: itemNum++
        quantity: data.designators.length
        designators: data.designators.join(', ')
        value: data.value
        footprint: data.footprint
      })

    entries

  # Generate BOM CSV string
  @exportCSV: (board) ->
    lines = []
    lines.push "Item,Qty,Designator,Value,Footprint"
    entries = @getEntries(board)

    for e in entries
      desStr = "\"#{e.designators}\""
      valStr = "\"#{e.value}\""
      pkgStr = "\"#{e.footprint}\""
      lines.push "#{e.item},#{e.quantity},#{desStr},#{valStr},#{pkgStr}"

    lines.join("\n") + "\n"

  # Generate BOM Markdown table
  @exportMarkdown: (board) ->
    lines = []
    lines.push "| Item | Qty | Designators | Value | Footprint |"
    lines.push "| :--- | :-- | :---------- | :---- | :-------- |"
    entries = @getEntries(board)

    for e in entries
      lines.push "| #{e.item} | #{e.quantity} | #{e.designators} | #{e.value} | #{e.footprint} |"

    lines.join("\n") + "\n"

module.exports = BOMExporter
