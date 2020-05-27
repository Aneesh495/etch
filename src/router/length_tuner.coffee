###
# Etch EDA: Serpentine High-Speed Differential Trace Length Tuning
#
# Generates trombone and serpentine meanders along routed copper tracks to
# equalize electrical propagation delays for high-speed differential pairs
# (USB 2.0 / 3.0, Ethernet, PCIe) and synchronous buses (DDR, SPI, I2S).
###

Units = require '../core/units'
{ Point, LineSegment } = require '../core/geometry'
{ TraceSegment } = require '../model/trace'

class LengthTuner
  # Tune shorter trace by adding serpentine meanders to match target length
  @tuneToLength: (segments, targetLengthNm, meanderAmplitudeNm = Units.mm(0.8), meanderPitchNm = Units.mm(0.6)) ->
    currentLen = 0
    for s in segments
      currentLen += s.length()

    deltaNm = targetLengthNm - currentLen
    return segments if deltaNm <= 0 # Already long enough

    # Find longest straight segment in trace to host meanders
    longestIdx = -1
    maxLen = 0
    for i in [0...segments.length]
      len = segments[i].length()
      if len > maxLen
        maxLen = len
        longestIdx = i

    return segments if longestIdx is -1 or maxLen < Units.mm(2.0)

    hostSeg = segments[longestIdx]
    tunedMeanders = @_generateSerpentine(hostSeg, deltaNm, meanderAmplitudeNm, meanderPitchNm)

    # Replace hostSeg with tuned meander segments
    newSegments = []
    for i in [0...segments.length]
      if i is longestIdx
        newSegments.push(tunedMeanders...)
      else
        newSegments.push(segments[i])

    newSegments

  # Generate serpentine accordion meanders along a straight baseline segment
  @_generateSerpentine: (baseSeg, requiredExtraLenNm, amplitudeNm, pitchNm) ->
    p1 = baseSeg.p1
    p2 = baseSeg.p2
    baseLen = baseSeg.length()

    # Direction and normal vectors
    dx = (p2.x - p1.x) / baseLen
    dy = (p2.y - p1.y) / baseLen
    nx = -dy # 90 degree perpendicular
    ny = dx

    # Number of half-waves needed
    # Each rectangular bump of height H adds roughly 2 * H of extra length
    extraPerMeander = 2.0 * amplitudeNm
    bumpsNeeded = Math.ceil(requiredExtraLenNm / extraPerMeander)

    totalMeanderSpan = bumpsNeeded * pitchNm
    if totalMeanderSpan > baseLen * 0.8
      # Scale down pitch and amplitude to fit inside available segment span
      scale = (baseLen * 0.8) / totalMeanderSpan
      bumpsNeeded = Math.max(1, Math.floor(bumpsNeeded * scale))
      pitchNm = Math.round(pitchNm * scale)
      totalMeanderSpan = bumpsNeeded * pitchNm

    startDist = Math.round((baseLen - totalMeanderSpan) / 2)
    startPt = new Point(
      Math.round(p1.x + startDist * dx),
      Math.round(p1.y + startDist * dy)
    )

    result = []
    # Lead-in segment
    result.push new TraceSegment({
      p1: p1
      p2: startPt
      widthNm: baseSeg.widthNm
      layerId: baseSeg.layerId
      netId: baseSeg.netId
    })

    currPt = startPt
    sign = 1

    for b in [0...bumpsNeeded]
      # Step forward along baseline by half-pitch
      midPt = new Point(
        Math.round(currPt.x + (pitchNm / 2) * dx),
        Math.round(currPt.y + (pitchNm / 2) * dy)
      )

      # Push out along normal by amplitude
      bumpTop1 = new Point(
        Math.round(currPt.x + sign * amplitudeNm * nx),
        Math.round(currPt.y + sign * amplitudeNm * ny)
      )
      bumpTop2 = new Point(
        Math.round(midPt.x + sign * amplitudeNm * nx),
        Math.round(midPt.y + sign * amplitudeNm * ny)
      )

      # 3 segments per serpentine bump: up, across, down
      result.push new TraceSegment({ p1: currPt, p2: bumpTop1, widthNm: baseSeg.widthNm, layerId: baseSeg.layerId, netId: baseSeg.netId })
      result.push new TraceSegment({ p1: bumpTop1, p2: bumpTop2, widthNm: baseSeg.widthNm, layerId: baseSeg.layerId, netId: baseSeg.netId })
      result.push new TraceSegment({ p1: bumpTop2, p2: midPt, widthNm: baseSeg.widthNm, layerId: baseSeg.layerId, netId: baseSeg.netId })

      currPt = midPt
      sign = -sign # Alternate sides for symmetrical accordion

    # Lead-out segment to p2
    result.push new TraceSegment({
      p1: currPt
      p2: p2
      widthNm: baseSeg.widthNm
      layerId: baseSeg.layerId
      netId: baseSeg.netId
    })

    result

module.exports = LengthTuner
