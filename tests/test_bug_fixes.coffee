###
# Etch EDA: Regression Test Suite & Bug Resolution Matrix
#
# Contains test cases that reproduce bugs encountered during development,
# verifying the fix and preventing regressions across future refactorings.
###

assert = require 'assert'
Polygon = require '../src/core/polygon'
{ Point } = require '../src/core/geometry'
Board = require '../src/model/board'
Component = require '../src/model/component'
{ Pad } = require '../src/model/pad'
Units = require '../src/core/units'

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

  # Bug 002: In CoffeeScript, iterating over ES6 Map.values() with `for ... in`
  # compiles to array length indexing (i < values.length) which terminates
  # immediately because MapIterator has no length property.
  # Resolution: Used CoffeeScript 2 `for ... from` to consume ES6 iterables.
  it 'Bug 002: correctly retrieves all pads across components from Map values using ES6 iterator', ->
    board = new Board({ name: 'map_iter_test' })
    c1 = new Component({ refDes: 'U1' })
    c1.addPad(new Pad({ number: '1' }))
    c1.addPad(new Pad({ number: '2' }))
    c2 = new Component({ refDes: 'U2' })
    c2.addPad(new Pad({ number: '1' }))
    board.addComponent(c1)
    board.addComponent(c2)

    pads = board.allPads()
    assert.strictEqual pads.length, 3

console.log 'All Bug Fix regression tests passed.'
