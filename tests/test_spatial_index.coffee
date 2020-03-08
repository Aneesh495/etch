assert = require 'assert'
SpatialIndex = require '../src/core/spatial_index'
{ Point, BoundingBox } = require '../src/core/geometry'

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

describe 'SpatialIndex (2D R-Tree) Range Queries', ->
  it 'handles empty spatial index searches safely', ->
    idx = new SpatialIndex()
    assert.strictEqual idx.size(), 0
    res = idx.search(new BoundingBox(0, 0, 100, 100))
    assert.strictEqual res.length, 0

  it 'inserts items and queries overlapping windows', ->
    idx = new SpatialIndex()
    idx.insert('ItemA', new BoundingBox(10, 10, 30, 30))
    idx.insert('ItemB', new BoundingBox(40, 40, 60, 60))
    idx.insert('ItemC', new BoundingBox(100, 100, 150, 150))
    assert.strictEqual idx.size(), 3

    # Query covering ItemA and ItemB
    q1 = idx.search(new BoundingBox(0, 0, 50, 50))
    assert.strictEqual q1.length, 2
    assert.ok 'ItemA' in q1
    assert.ok 'ItemB' in q1
    assert.ok not ('ItemC' in q1)

    # Point query on ItemC
    qPt = idx.searchPoint(new Point(120, 120))
    assert.strictEqual qPt.length, 1
    assert.strictEqual qPt[0], 'ItemC'

  it 'indexes 200 items across multiple node splits without data loss', ->
    idx = new SpatialIndex(8, 2)
    # Insert a 10x20 grid of items
    for x in [0...10]
      for y in [0...20]
        bb = new BoundingBox(x * 100, y * 100, x * 100 + 40, y * 100 + 40)
        idx.insert({ x: x, y: y }, bb, "item_#{x}_#{y}")

    assert.strictEqual idx.size(), 200

    # Query sub-region covering x in [2..4], y in [5..7] -> 3 x 3 = 9 items
    qBox = new BoundingBox(200, 500, 450, 750)
    results = idx.search(qBox)
    assert.strictEqual results.length, 9
    for r in results
      assert.ok r.x >= 2 and r.x <= 4
      assert.ok r.y >= 5 and r.y <= 7

  it 'bulk loads arrays of items correctly', ->
    idx = new SpatialIndex()
    items = []
    for i in [0...50]
      bb = new BoundingBox(i * 10, 0, i * 10 + 5, 10)
      items.push({ item: "id_#{i}", bb: bb, id: i })

    idx.bulkLoad(items)
    assert.strictEqual idx.size(), 50
    # Query first 5 items
    res = idx.search(new BoundingBox(0, 0, 45, 10))
    assert.strictEqual res.length, 5

console.log 'All SpatialIndex tests passed.'
