###
# Etch EDA: Master Footprint Registry and Component Instantiation Factory
#
# Resolves package identifiers and footprint names into fully populated
# Component instances with pads, courtyards, pin mappings, and designators.
###

PassivesFootprints = require './passives'
SmallOutlineFootprints = require './small_outline'
QuadFlatFootprints = require './quad_flat'
QFNFootprints = require './qfn'
BGAFootprints = require './bga'
ThroughHoleFootprints = require './through_hole'
ConnectorFootprints = require './connectors'

class Footprints
  @create: (refDes, footprintName, options = {}) ->
    name = footprintName.trim().toUpperCase()

    # Passives (0201, 0402, 0603, 0805, 1206, 1210, 2010, 2512)
    mPassive = name.match(/^(?:R_|C_|L_|SMD_)?(0201|0402|0603|0805|1206|1210|2010|2512)$/)
    if mPassive
      return PassivesFootprints.create(refDes, mPassive[1], options)

    # SOT-23
    if name is 'SOT-23' or name is 'SOT23'
      return SmallOutlineFootprints.createSOT23(refDes, options)

    # SOT-223
    if name is 'SOT-223' or name is 'SOT223'
      return SmallOutlineFootprints.createSOT223(refDes, options)

    # SOIC
    mSOIC = name.match(/^SOIC-?(\d+)$/)
    if mSOIC
      pinCount = parseInt(mSOIC[1], 10)
      return SmallOutlineFootprints.createSOIC(refDes, pinCount, options)

    # TSSOP
    mTSSOP = name.match(/^TSSOP-?(\d+)$/)
    if mTSSOP
      pinCount = parseInt(mTSSOP[1], 10)
      return SmallOutlineFootprints.createTSSOP(refDes, pinCount, options)

    # QFP / LQFP / TQFP
    mQFP = name.match(/^(?:L|T)?QFP-?(\d+)$/)
    if mQFP
      pinCount = parseInt(mQFP[1], 10)
      return QuadFlatFootprints.create(refDes, pinCount, options)

    # QFN
    mQFN = name.match(/^QFN-?(\d+)$/)
    if mQFN
      pinCount = parseInt(mQFN[1], 10)
      return QFNFootprints.create(refDes, pinCount, options)

    # BGA
    mBGA = name.match(/^BGA-?(\d+)$/)
    if mBGA
      totalBalls = parseInt(mBGA[1], 10)
      matrixSize = Math.round(Math.sqrt(totalBalls))
      return BGAFootprints.create(refDes, matrixSize, 0.8, 0.4, options)

    # DIP
    mDIP = name.match(/^DIP-?(\d+)$/)
    if mDIP
      pinCount = parseInt(mDIP[1], 10)
      return ThroughHoleFootprints.createDIP(refDes, pinCount, options)

    # Pin Headers
    mHeader = name.match(/^HEADER_?(\d+)X(\d+)$/i)
    if mHeader
      rows = parseInt(mHeader[1], 10)
      cols = parseInt(mHeader[2], 10)
      return ThroughHoleFootprints.createPinHeader(refDes, rows, cols, options)

    # Connectors
    if name.indexOf('USB') isnt -1
      return ConnectorFootprints.createUSBC(refDes, options)

    if name.indexOf('SMA') isnt -1
      return ConnectorFootprints.createSMA(refDes, options)

    # Default fallback: 0805 chip passive
    PassivesFootprints.create(refDes, '0805', options)

module.exports = Footprints
