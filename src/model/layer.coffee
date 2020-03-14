###
# Etch EDA: PCB Layer Taxonomy, Stackup Management, and Dielectric Modeling
#
# Represents physical copper and technical fabrication layers conforming to
# IPC-2581 and standard photoplotter conventions. Manages multi-layer board
# stackups, dielectric prepreg spacing, copper weights, and layer ordering.
###

Units = require '../core/units'

LayerType = {
  COPPER_SIGNAL: 'copper_signal'
  COPPER_PLANE: 'copper_plane'
  COPPER_MIXED: 'copper_mixed'
  DIELECTRIC: 'dielectric'
  SOLDER_MASK: 'solder_mask'
  SILKSCREEN: 'silkscreen'
  SOLDER_PASTE: 'solder_paste'
  EDGE_CUTS: 'edge_cuts'
  COURTYARD: 'courtyard'
  FABRICATION: 'fabrication'
}

class Layer
  constructor: (options = {}) ->
    @id = options.id or 'F.Cu'
    @name = options.name or 'Top Copper'
    @type = options.type or LayerType.COPPER_SIGNAL
    @copperIndex = options.copperIndex ? 0   # 0 for F.Cu, N-1 for B.Cu
    @thicknessNm = options.thicknessNm or Units.um(35) # 1 oz copper = 35 um = 35000 nm
    @colorHex = options.colorHex or '#c82828'
    @visible = options.visible ? true
    @dielectricConstant = options.dielectricConstant or 4.5 # Standard FR4 Er
    @lossTangent = options.lossTangent or 0.02

  isCopper: ->
    @type in [LayerType.COPPER_SIGNAL, LayerType.COPPER_PLANE, LayerType.COPPER_MIXED]

  isSignal: -> @type is LayerType.COPPER_SIGNAL
  isPlane: -> @type is LayerType.COPPER_PLANE


class LayerStackup
  constructor: (@layerCount = 2) ->
    @layers = []
    @_initializeStandardStackup(@layerCount)

  _initializeStandardStackup: (count) ->
    @layers = []
    switch count
      when 2
        @layers.push new Layer({
          id: 'F.Cu', name: 'Top Layer', type: LayerType.COPPER_SIGNAL,
          copperIndex: 0, colorHex: '#d32f2f'
        })
        @layers.push new Layer({
          id: 'B.Cu', name: 'Bottom Layer', type: LayerType.COPPER_SIGNAL,
          copperIndex: 1, colorHex: '#1976d2'
        })
      when 4
        # Standard 4-layer stackup: Signal (Top), Ground (Inner 1), Power (Inner 2), Signal (Bottom)
        @layers.push new Layer({
          id: 'F.Cu', name: 'Top Layer', type: LayerType.COPPER_SIGNAL,
          copperIndex: 0, colorHex: '#d32f2f'
        })
        @layers.push new Layer({
          id: 'In1.Cu', name: 'GND Plane', type: LayerType.COPPER_PLANE,
          copperIndex: 1, colorHex: '#388e3c'
        })
        @layers.push new Layer({
          id: 'In2.Cu', name: 'Power Plane', type: LayerType.COPPER_PLANE,
          copperIndex: 2, colorHex: '#f57c00'
        })
        @layers.push new Layer({
          id: 'B.Cu', name: 'Bottom Layer', type: LayerType.COPPER_SIGNAL,
          copperIndex: 3, colorHex: '#1976d2'
        })
      when 6
        @layers.push new Layer({ id: 'F.Cu', name: 'Top Signal', type: LayerType.COPPER_SIGNAL, copperIndex: 0, colorHex: '#d32f2f' })
        @layers.push new Layer({ id: 'In1.Cu', name: 'GND Plane 1', type: LayerType.COPPER_PLANE, copperIndex: 1, colorHex: '#388e3c' })
        @layers.push new Layer({ id: 'In2.Cu', name: 'Inner Signal 1', type: LayerType.COPPER_SIGNAL, copperIndex: 2, colorHex: '#7b1fa2' })
        @layers.push new Layer({ id: 'In3.Cu', name: 'Inner Signal 2', type: LayerType.COPPER_SIGNAL, copperIndex: 3, colorHex: '#0097a7' })
        @layers.push new Layer({ id: 'In4.Cu', name: 'Power Plane', type: LayerType.COPPER_PLANE, copperIndex: 4, colorHex: '#f57c00' })
        @layers.push new Layer({ id: 'B.Cu', name: 'Bottom Signal', type: LayerType.COPPER_SIGNAL, copperIndex: 5, colorHex: '#1976d2' })
      else
        throw new Error("Unsupported stackup layer count: #{count}. Supported: 2, 4, 6.")

  copperLayers: ->
    (l for l in @layers when l.isCopper())

  getLayer: (id) ->
    for l in @layers
      return l if l.id is id
    null

  copperIndexToId: (index) ->
    cu = @copperLayers()
    if index >= 0 and index < cu.length
      cu[index].id
    else
      null

  idToCopperIndex: (id) ->
    cu = @copperLayers()
    for i in [0...cu.length]
      return i if cu[i].id is id
    -1

  totalBoardThicknessNm: ->
    # Standard 1.6 mm PCB: core + prepreg + copper layers
    Units.mm(1.6)

module.exports = {
  LayerType
  Layer
  LayerStackup
}
