###
# Etch EDA: Electrical Net, Netlist Graph, and NetClass Specifications
#
# Models logical electrical connectivity across schematic pins, topological
# unrouted airwires (ratsnest), and NetClass physical design rule constraints
# (trace widths, clearances, via sizes, and differential impedance pairs).
###

Units = require '../core/units'
{ Point, LineSegment } = require '../core/geometry'

class NetClass
  constructor: (options = {}) ->
    @name = options.name or 'Default'
    @trackWidthNm = options.trackWidthNm or Units.mm(0.2) # ~8 mil default
    @clearanceNm = options.clearanceNm or Units.mm(0.2)   # ~8 mil default
    @viaDiameterNm = options.viaDiameterNm or Units.mm(0.6) # 24 mil
    @viaDrillNm = options.viaDrillNm or Units.mm(0.3)       # 12 mil
    @diffPairWidthNm = options.diffPairWidthNm or Units.mm(0.15)
    @diffPairGapNm = options.diffPairGapNm or Units.mm(0.15)

  @default: -> new NetClass({ name: 'Default' })

  @power: ->
    new NetClass({
      name: 'Power'
      trackWidthNm: Units.mm(0.5) # 20 mil trace for power buses
      clearanceNm: Units.mm(0.25)
      viaDiameterNm: Units.mm(0.8)
      viaDrillNm: Units.mm(0.4)
    })

  @highCurrent: ->
    new NetClass({
      name: 'HighCurrent'
      trackWidthNm: Units.mm(1.0) # 40 mil trace for high-current rails
      clearanceNm: Units.mm(0.3)
      viaDiameterNm: Units.mm(1.0)
      viaDrillNm: Units.mm(0.6)
    })

  @differential: ->
    new NetClass({
      name: 'Differential90'
      trackWidthNm: Units.mm(0.15)
      diffPairWidthNm: Units.mm(0.15)
      diffPairGapNm: Units.mm(0.15)
      clearanceNm: Units.mm(0.2)
    })


class PinReference
  constructor: (@componentRefDes, @pinNumber, @pad = null) ->

  key: -> "#{@componentRefDes}.#{@pinNumber}"

  position: ->
    return @pad.absolutePosition() if @pad?
    new Point(0, 0)


class Net
  constructor: (@id, @name = @id, @netClass = NetClass.default()) ->
    @pins = [] # Array of PinReference
    @isRouted = false

  addPin: (componentRefDes, pinNumber, pad = null) ->
    ref = new PinReference(componentRefDes, pinNumber, pad)
    @pins.push(ref)
    ref

  pinCount: -> @pins.length

  isPowerOrGround: ->
    upper = @name.toUpperCase()
    upper in ['GND', 'GROUND', 'VCC', 'VDD', '3V3', '5V', '12V', 'VIN', '+3.3V', '+5V']

  # Generate unrouted airwires (ratsnest) connecting pins via Minimum Spanning Tree
  generateRatsnest: ->
    airwires = []
    n = @pins.length
    return airwires if n < 2

    # Prim's algorithm for Euclidean Minimum Spanning Tree (MST)
    inTree = new Array(n).fill(false)
    inTree[0] = true
    treeCount = 1

    while treeCount < n
      minDist = Infinity
      bestU = -1
      bestV = -1

      for u in [0...n]
        continue unless inTree[u]
        pU = @pins[u].position()

        for v in [0...n]
          continue if inTree[v]
          pV = @pins[v].position()
          d = pU.dist(pV)
          if d < minDist
            minDist = d
            bestU = u
            bestV = v

      if bestU isnt -1 and bestV isnt -1
        inTree[bestV] = true
        treeCount++
        airwires.push(new LineSegment(@pins[bestU].position(), @pins[bestV].position()))
      else
        break

    airwires


class Netlist
  constructor: ->
    @nets = new Map()

  addNet: (net) ->
    @nets.set(net.id, net)
    net

  getNet: (id) -> @nets.get(id) or null

  hasNet: (id) -> @nets.has(id)

  allNets: -> Array.from(@nets.values())

  count: -> @nets.size

module.exports = {
  NetClass
  PinReference
  Net
  Netlist
}
