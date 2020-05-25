###
# Etch EDA: Post-Routing Topological Trace Optimizer and Corner Mitering
#
# Transforms staircase grid steps into smooth octilinear tracks. Merges
# collinear segment chains, bevels 90-degree corners to 45-degree bends,
# and eliminates redundant dog-leg detours to minimize track length.
###

Units = require '../core/units'
{ Point, LineSegment } = require '../core/geometry'
{ TraceSegment } = require '../model/trace'

class TraceSmoother
  # Smooth an array of TraceSegments belonging to a routed net
  @smooth: (segments) ->
    return segments if segments.length < 2

    # Group segments by continuous layer chains
    chains = @_partitionByLayer(segments)
    smoothedSegments = []

    for chain in chains
      if chain.length <= 1
        smoothedSegments.push(chain...)
        continue

      # Step 1: Merge collinear contiguous segments
      merged = @_mergeCollinear(chain)

      # Step 2: Miter 90-degree right angles into 45-degree bevels
      mitered = @_miterCorners(merged)

      smoothedSegments.push(mitered...)

    smoothedSegments

  # Partition segments into contiguous runs on the same layer
  @_partitionByLayer: (segments) ->
    chains = []
    currChain = []

    for seg in segments
      if currChain.length is 0
        currChain.push(seg)
      else
        last = currChain[currChain.length - 1]
        # Check if connected and on same layer
        if last.layerId is seg.layerId and last.p2.equals(seg.p1, 100)
          currChain.push(seg)
        else
          chains.push(currChain)
          currChain = [seg]

    chains.push(currChain) if currChain.length > 0
    chains

  # Merge consecutive segments pointing in the exact same direction
  @_mergeCollinear: (chain) ->
    return chain if chain.length < 2
    merged = []
    curr = chain[0]

    for i in [1...chain.length]
      next = chain[i]

      # Vectors
      dx1 = curr.p2.x - curr.p1.x
      dy1 = curr.p2.y - curr.p1.y
      dx2 = next.p2.x - next.p1.x
      dy2 = next.p2.y - next.p1.y

      len1 = Math.sqrt(dx1 * dx1 + dy1 * dy1)
      len2 = Math.sqrt(dx2 * dx2 + dy2 * dy2)

      if len1 < 10
        curr = next
        continue
      if len2 < 10
        continue

      # Cross product to test collinearity
      cross = (dx1 * dy2) - (dy1 * dx2)
      dot = (dx1 * dx2) + (dy1 * dy2)

      # If collinear and pointing in the same direction, extend curr.p2 to next.p2
      if Math.abs(cross / (len1 * len2)) < 0.05 and dot > 0
        curr = new TraceSegment({
          p1: curr.p1
          p2: next.p2
          widthNm: curr.widthNm
          layerId: curr.layerId
          netId: curr.netId
        })
      else
        merged.push(curr)
        curr = next

    merged.push(curr)
    merged

  # Miter 90-degree corners to 45-degree chamfers
  @_miterCorners: (chain) ->
    return chain if chain.length < 2
    result = []

    for i in [0...(chain.length - 1)]
      s1 = chain[i]
      s2 = chain[i + 1]

      # Check if meeting at a right angle (90 deg)
      dx1 = s1.p2.x - s1.p1.x
      dy1 = s1.p2.y - s1.p1.y
      dx2 = s2.p2.x - s2.p1.x
      dy2 = s2.p2.y - s2.p1.y

      dot = (dx1 * dx2) + (dy1 * dy2)
      len1 = s1.length()
      len2 = s2.length()

      # Right angle check: dot product near 0 and sufficient length to bevel
      minMiterLen = Units.mm(0.3)
      if Math.abs(dot) < 1e-4 and len1 > minMiterLen and len2 > minMiterLen
        # Cut back s1.p2 and s2.p1 by miter distance
        miterDist = Math.min(len1 * 0.4, len2 * 0.4, Units.mm(0.2))

        # Back off s1 along its direction
        u1 = s1.asLineSegment()
        t1 = 1.0 - (miterDist / len1)
        pMiter1 = new Point(
          Math.round(s1.p1.x + t1 * dx1),
          Math.round(s1.p1.y + t1 * dy1)
        )

        # Forward off s2 along its direction
        t2 = miterDist / len2
        pMiter2 = new Point(
          Math.round(s2.p1.x + t2 * dx2),
          Math.round(s2.p1.y + t2 * dy2)
        )

        # Truncated s1
        result.push new TraceSegment({
          p1: s1.p1
          p2: pMiter1
          widthNm: s1.widthNm
          layerId: s1.layerId
          netId: s1.netId
        })

        # 45-degree bevel segment
        result.push new TraceSegment({
          p1: pMiter1
          p2: pMiter2
          widthNm: s1.widthNm
          layerId: s1.layerId
          netId: s1.netId
        })

        # Update s2 start point for next iteration
        chain[i + 1] = new TraceSegment({
          p1: pMiter2
          p2: s2.p2
          widthNm: s2.widthNm
          layerId: s2.layerId
          netId: s2.netId
        })
      else
        result.push(s1)

    result.push(chain[chain.length - 1])
    result

module.exports = TraceSmoother
