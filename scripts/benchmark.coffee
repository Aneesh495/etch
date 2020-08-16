###
# Etch EDA: Microbenchmarks for Geometric Routing & DRC Engine
#
# Profiles throughput of spatial indexing, polygon clipping, A* maze routing,
# and DRC clearance checks across varying board densities.
###

Etch = require '../src/etch'
{ defineBoard, Units, Point, BoundingBox } = require '../src/etch'

console.log "=================================================================="
console.log "                  ETCH EDA: PERFORMANCE BENCHMARKS                "
console.log "=================================================================="

# 1. Spatial Index Insertion & Query Benchmark
benchmarkSpatialIndex = ->
  idx = new Etch.SpatialIndex(16, 4)
  items = []
  count = 10000

  for i in [0...count]
    x = (i * 37) % 50000
    y = (i * 91) % 50000
    items.push({
      item: "pad_#{i}"
      bb: new BoundingBox(x, y, x + 100, y + 100)
      id: i
    })

  t0 = Date.now()
  idx.bulkLoad(items)
  loadMs = Date.now() - t0
  console.log "SpatialIndex Bulk Load: #{count} items in #{loadMs} ms (#{(count / (loadMs / 1000)).toFixed(0)} items/sec)"

  t1 = Date.now()
  queryCount = 1000
  hits = 0
  for q in [0...queryCount]
    qx = (q * 123) % 45000
    qy = (q * 77) % 45000
    res = idx.search(new BoundingBox(qx, qy, qx + 1000, qy + 1000))
    hits += res.length
  queryMs = Date.now() - t1
  console.log "SpatialIndex Range Queries: #{queryCount} window queries in #{queryMs} ms (#{(queryCount / (queryMs / 1000)).toFixed(0)} queries/sec)"

# 2. Polygon Containment & Winding Benchmark
benchmarkPolygon = ->
  poly = Etch.Polygon.fromRect(0, 0, 1000000, 1000000)
  testCount = 50000
  t0 = Date.now()
  inCount = 0
  for i in [0...testCount]
    pt = new Point((i * 41) % 1500000, (i * 73) % 1500000)
    inCount++ if poly.containsPoint(pt)
  polyMs = Date.now() - t0
  console.log "Polygon Winding Point-in-Poly: #{testCount} tests in #{polyMs} ms (#{(testCount / (polyMs / 1000)).toFixed(0)} tests/sec)"

# 3. Autorouter Pathfinding Benchmark
benchmarkRouter = ->
  b = new Etch.Board({ width: Units.mm(50), height: Units.mm(50), layers: 2 })
  grid = new Etch.RoutingGrid(b, { resolutionNm: Units.mm(0.5) })
  router = new Etch.AStarRouter(grid)

  routeCount = 20
  t0 = Date.now()
  successCount = 0
  for r in [0...routeCount]
    p1 = new Point(Units.mm(2), Units.mm(2 + r * 2))
    p2 = new Point(Units.mm(48), Units.mm(48 - r * 2))
    res = router.routeConnection(p1, 'F.Cu', p2, 'F.Cu', "NET_BENCH_#{r}")
    successCount++ if res.success
  routerMs = Date.now() - t0
  console.log "3D A* Maze Routing: #{routeCount} routes in #{routerMs} ms (#{(routerMs / routeCount).toFixed(1)} ms/route)"

benchmarkSpatialIndex()
benchmarkPolygon()
benchmarkRouter()
console.log "=================================================================="
console.log "Benchmarks completed."
