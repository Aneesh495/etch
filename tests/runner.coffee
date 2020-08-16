###
# Etch EDA: Unified Test Runner and Suite Orchestrator
#
# Discovers and runs all 21 modular unit, structure, regression, and
# integration test suites. Reports aggregate assertions, durations, and pass/fail.
###

path = require 'path'

TEST_SUITES = [
  './test_units.coffee'
  './test_geometry.coffee'
  './test_matrix.coffee'
  './test_polygon.coffee'
  './test_polygon_ops.coffee'
  './test_spatial_index.coffee'
  './test_intersection.coffee'
  './test_board_model.coffee'
  './test_footprints.coffee'
  './test_dsl.coffee'
  './test_router_grid.coffee'
  './test_astar_router.coffee'
  './test_length_tuner.coffee'
  './test_drc_clearance.coffee'
  './test_drc_rules.coffee'
  './test_manufacturing.coffee'
  './test_visualizer.coffee'
  './test_schematic_bridge.coffee'
  './test_native_fastpath.coffee'
  './test_integration.coffee'
  './test_bug_fixes.coffee'
]

console.log "=================================================================="
console.log "                    ETCH EDA: MASTER TEST SUITE                   "
console.log "=================================================================="

startTime = Date.now()
passedCount = 0
failedCount = 0

for suitePath in TEST_SUITES
  suiteName = path.basename(suitePath)
  console.log "\nRunning #{suiteName}..."
  try
    require(suitePath)
    passedCount++
  catch err
    console.error "FAILED: #{suiteName} -> #{err.message}"
    failedCount++

elapsedMs = Date.now() - startTime
console.log "\n=================================================================="
console.log "SUMMARY: #{passedCount} of #{TEST_SUITES.length} test suites passed in #{elapsedMs} ms."
if failedCount is 0
  console.log "RESULT: ALL TESTS PASSED."
  process.exit(0)
else
  console.error "RESULT: #{failedCount} SUITES FAILED."
  process.exit(1)
