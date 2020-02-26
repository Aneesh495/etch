###
# Etch EDA: Regression Test Suite & Bug Resolution Matrix
#
# Contains test cases that reproduce bugs encountered during development,
# verifying the fix and preventing regressions across future refactorings.
###

assert = require 'assert'
Polygon = require '../src/core/polygon'
{ Point } = require '../src/core/geometry'

describe = (name, fn) ->
  console.log "  Suite: #{name}"
  fn()

it = (name, fn) ->
  try
    fn()
    console.log "    [OK] #{name}"
  catch err
    console.error "    [FAIL] #{name}: #{err.message}"
    throw err

describe 'Regression Bug Fixes', ->
  # Bug 001: cleanCollinear fixed-distance threshold caused right-angle corners
  # on small polygons to be incorrectly flagged as collinear diagonals.
  # Resolution: Replaced fixed distance metric with normalized vector cross-product
  # sin(theta) and forward dot-product direction check.
  it 'Bug 001: preserves 90-degree corners on nanometer-scale polygons during cleanCollinear', ->
    poly = new Polygon([
      new Point(0, 0)
      new Point(50, 0) # Redundant midpoint along edge (0,0)->(100,0)
      new Point(100, 0)
      new Point(100, 100)
      new Point(0, 100)
    ])
    assert.strictEqual poly.vertexCount(), 5
    poly.cleanCollinear()
    # Exactly the redundant collinear point (50, 0) is pruned; corners must remain
    assert.strictEqual poly.vertexCount(), 4
    pts = poly.vertices
    assert.strictEqual pts[0].x, 0
    assert.strictEqual pts[0].y, 0
    assert.strictEqual pts[1].x, 100
    assert.strictEqual pts[1].y, 0
    assert.strictEqual pts[2].x, 100
    assert.strictEqual pts[2].y, 100
    assert.strictEqual pts[3].x, 0
    assert.strictEqual pts[3].y, 100

console.log 'All Bug Fix regression tests passed.'
