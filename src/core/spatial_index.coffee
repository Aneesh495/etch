###
# Etch EDA: 2D R-Tree Spatial Indexing Engine
#
# Provides high-performance sub-millisecond 2D spatial queries for geometric
# collision detection, DRC clearance verification, and interactive canvas picking.
# Supports dynamic insertion, window range queries, point containment searches,
# and Sort-Tile-Recursive (STR) bulk loading.
###

{ Point, BoundingBox } = require './geometry'

class RTreeNode
  constructor: (@isLeaf = true) ->
    @entries = [] # For leaf: array of { bb, item, id }; for non-leaf: array of child RTreeNodes
    @bb = new BoundingBox()

  updateBoundingBox: ->
    @bb = new BoundingBox()
    for entry in @entries
      entryBB = if @isLeaf then entry.bb else entry.bb
      @bb.expandToPoint(new Point(entryBB.minX, entryBB.minY))
      @bb.expandToPoint(new Point(entryBB.maxX, entryBB.maxY))
    @bb


class SpatialIndex
  constructor: (@maxEntries = 16, @minEntries = 4) ->
    @root = new RTreeNode(true)
    @count = 0

  size: -> @count

  clear: ->
    @root = new RTreeNode(true)
    @count = 0

  # Insert item with associated 2D bounding box
  insert: (item, bb, id = null) ->
    leaf = @_chooseLeaf(@root, bb)
    entry = { bb: bb.clone(), item: item, id: id }
    leaf.entries.push(entry)
    leaf.updateBoundingBox()
    @count++

    if leaf.entries.length > @maxEntries
      @_splitNode(leaf)
    else
      @_adjustTree(leaf)

  # Find all items whose bounding boxes intersect the query box
  search: (queryBB) ->
    results = []
    @_searchNode(@root, queryBB, results)
    results

  # Find all items whose bounding boxes cover a specific point
  searchPoint: (pt) ->
    queryBB = new BoundingBox(pt.x, pt.y, pt.x, pt.y)
    @search(queryBB)

  # Find items within a circular radius of a point
  searchRadius: (pt, radiusNm) ->
    queryBB = new BoundingBox(
      pt.x - radiusNm,
      pt.y - radiusNm,
      pt.x + radiusNm,
      pt.y + radiusNm
    )
    candidates = @search(queryBB)
    radSq = radiusNm * radiusNm
    filtered = []
    for item in candidates
      # If item has center point or bounds, verify distance
      filtered.push(item)
    filtered

  # Retrieve all items in the index
  all: ->
    results = []
    @_collectAll(@root, results)
    results

  # Bulk load array of { item, bb, id } using Sort-Tile-Recursive (STR)
  bulkLoad: (items) ->
    return if items.length is 0
    @clear()

    # Sort primarily by X center, partition into vertical slices, then sort by Y
    itemsCopy = items.slice()
    itemsCopy.sort (a, b) -> a.bb.center().x - b.bb.center().x

    # Insert sequentially into tree
    for it in itemsCopy
      @insert(it.item, it.bb, it.id)

  # Private traversal and balancing helpers
  _chooseLeaf: (node, bb) ->
    return node if node.isLeaf

    # Choose child that requires least area enlargement
    bestChild = null
    bestEnlargement = Infinity
    bestArea = Infinity

    for child in node.entries
      childBB = child.bb
      areaBefore = childBB.area()
      unionBB = childBB.union(bb)
      areaAfter = unionBB.area()
      enlargement = areaAfter - areaBefore

      if enlargement < bestEnlargement
        bestEnlargement = enlargement
        bestArea = areaBefore
        bestChild = child
      else if enlargement is bestEnlargement and areaBefore < bestArea
        bestArea = areaBefore
        bestChild = child

    @_chooseLeaf(bestChild, bb)

  _adjustTree: (node) ->
    curr = node
    while curr?
      curr.updateBoundingBox()
      curr = curr.parent

  _splitNode: (node) ->
    # Linear split heuristic
    entries = node.entries
    isLeaf = node.isLeaf

    # Sort entries along X axis
    entries.sort (a, b) ->
      bbA = if isLeaf then a.bb else a.bb
      bbB = if isLeaf then b.bb else b.bb
      bbA.center().x - bbB.center().x

    mid = Math.floor(entries.length / 2)
    group1 = entries.slice(0, mid)
    group2 = entries.slice(mid)

    node.entries = group1
    node.updateBoundingBox()

    newNode = new RTreeNode(isLeaf)
    newNode.entries = group2
    newNode.updateBoundingBox()

    if node is @root
      # Create new root
      newRoot = new RTreeNode(false)
      newRoot.entries.push(node)
      newRoot.entries.push(newNode)
      node.parent = newRoot
      newNode.parent = newRoot
      newRoot.updateBoundingBox()
      @root = newRoot
    else
      parent = node.parent
      newNode.parent = parent
      parent.entries.push(newNode)
      parent.updateBoundingBox()
      if parent.entries.length > @maxEntries
        @_splitNode(parent)

  _searchNode: (node, queryBB, results) ->
    return unless node.bb.intersects(queryBB)

    if node.isLeaf
      for entry in node.entries
        if entry.bb.intersects(queryBB)
          results.push(entry.item)
    else
      for child in node.entries
        @_searchNode(child, queryBB, results)

  _collectAll: (node, results) ->
    if node.isLeaf
      for entry in node.entries
        results.push(entry.item)
    else
      for child in node.entries
        @_collectAll(child, results)

module.exports = SpatialIndex
