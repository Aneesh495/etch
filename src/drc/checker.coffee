###
# Etch EDA: Master Design Rule Check (DRC) Orchestrator
#
# Aggregates clearance, geometry, netlist continuity, and manufacturing
# fabrication rules into a unified verification pass. Emits structured
# violation reports and summary pass/fail statuses.
###

ClearanceChecker = require './clearance'
GeometryRulesChecker = require './geometry_rules'
NetRulesChecker = require './net_rules'
ManufacturingRulesChecker = require './manufacturing_rules'

class DRCResult
  constructor: (@violations = []) ->
    @errorCount = (v for v in @violations when v.severity is 'ERROR').length
    @warningCount = (v for v in @violations when v.severity is 'WARNING').length
    @passed = (@errorCount is 0)

  formatReport: ->
    lines = []
    lines.push "=================================================================="
    lines.push "                      ETCH EDA: DRC REPORT                        "
    lines.push "=================================================================="
    status = if @passed then "PASS (0 ERRORS)" else "FAIL (#{@errorCount} ERRORS)"
    lines.push "Status: #{status} | Warnings: #{@warningCount}"
    lines.push "------------------------------------------------------------------"

    if @violations.length is 0
      lines.push "Zero design rule violations detected. Board is fabrication-ready."
    else
      for i in [0...@violations.length]
        v = @violations[i]
        posStr = if v.location? then "(#{v.location.x}, #{v.location.y})" else "N/A"
        lines.push "[#{v.severity}] #{v.rule} at #{posStr} on layer #{v.layerId or 'N/A'}"
        lines.push "    #{v.message}"

    lines.push "=================================================================="
    lines.join("\n")


class DesignRuleChecker
  @run: (board) ->
    violations = []

    # 1. Clearance matrix rules
    clearanceViolations = ClearanceChecker.check(board)
    violations.push(clearanceViolations...)

    # 2. Geometric rules (width, annular ring, drill)
    geomViolations = GeometryRulesChecker.check(board)
    violations.push(geomViolations...)

    # 3. Netlist rules (shorts, airwires)
    netViolations = NetRulesChecker.check(board)
    violations.push(netViolations...)

    # 4. Manufacturing fabrication rules (acid traps, silkscreen)
    mfgViolations = ManufacturingRulesChecker.check(board)
    violations.push(mfgViolations...)

    new DRCResult(violations)

module.exports = {
  DesignRuleChecker
  DRCResult
}
