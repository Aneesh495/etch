assert = require 'assert'
Etch = require '../src/etch'
stm32Board = require '../examples/stm32_sensor_hub'
dacBoard = require '../examples/hifi_audio_dac'
keyboardBoard = require '../examples/keyboard_controller'
powerBoard = require '../examples/power_distribution'

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

describe 'End-to-End System Integration Tests', ->
  it 'validates STM32 sensor hub layout, netlist connectivity, and design rules', ->
    stats = stm32Board.statistics()
    assert.strictEqual stats.name, 'stm32_sensor_hub'
    assert.strictEqual stats.layerCount, 4
    assert.strictEqual stats.componentCount, 13
    assert.ok stats.padCount >= 100
    assert.strictEqual stats.mountingHoleCount, 4

    # Run DRC
    drc = Etch.DesignRuleChecker.run(stm32Board)
    assert.strictEqual drc.errorCount, 0

    # Export Gerbers
    gbrFcu = Etch.GerberExporter.exportCopperLayer(stm32Board, 'F.Cu')
    assert.ok gbrFcu.indexOf('%FSLAX46Y46*%') isnt -1

  it 'validates HiFi Audio DAC 4-layer split-plane architecture', ->
    stats = dacBoard.statistics()
    assert.strictEqual stats.name, 'hifi_audio_dac'
    assert.strictEqual stats.layerCount, 4
    assert.strictEqual stats.componentCount, 12
    assert.ok dacBoard.netlist.hasNet('AGND')
    assert.ok dacBoard.netlist.hasNet('DGND')

    drc = Etch.DesignRuleChecker.run(dacBoard)
    assert.strictEqual drc.errorCount, 0

  it 'validates RP2040 Keyboard Controller 2-layer matrix layout', ->
    stats = keyboardBoard.statistics()
    assert.strictEqual stats.name, 'keyboard_controller'
    assert.strictEqual stats.layerCount, 2
    assert.strictEqual stats.componentCount, 11
    assert.ok keyboardBoard.netlist.hasNet('USB_DP')
    assert.ok keyboardBoard.netlist.hasNet('USB_DM')

    drc = Etch.DesignRuleChecker.run(keyboardBoard)
    assert.strictEqual drc.errorCount, 0

  it 'validates High-Current Power Distribution module and power NetClasses', ->
    stats = powerBoard.statistics()
    assert.strictEqual stats.name, 'power_distribution'
    assert.strictEqual stats.layerCount, 2
    assert.strictEqual stats.componentCount, 8

    drc = Etch.DesignRuleChecker.run(powerBoard)
    assert.strictEqual drc.errorCount, 0

    bom = Etch.BOMExporter.exportCSV(powerBoard)
    assert.ok bom.indexOf('TPS5450DDAR') isnt -1

console.log 'All End-to-End Integration tests passed.'
