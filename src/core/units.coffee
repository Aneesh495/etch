###
# Etch EDA: Fixed-Point Metric Quantization and Unit Conversions
#
# Standardizes all internal dimensional calculations on 64-bit integer
# nanometers (nm). Nanometer representation avoids floating-point roundoff
# drift during repeated geometric transformations and ensures exact matching
# across photoplotter Gerber output and DRC clearance checks.
###

class Units
  # Scale factors relative to one nanometer (1 nm)
  @NM_PER_UM: 1000
  @NM_PER_MM: 1000000
  @NM_PER_CM: 10000000
  @NM_PER_MIL: 25400          # 1 mil = 0.001 inch = 25.4 um = 25400 nm
  @NM_PER_INCH: 25400000

  # Convert from specified source unit to integer nanometers
  @toNm: (value, unit = 'mm') ->
    switch unit.toLowerCase()
      when 'nm', 'nanometer', 'nanometers'
        Math.round(value)
      when 'um', 'micron', 'microns', 'micrometer', 'micrometers'
        Math.round(value * @NM_PER_UM)
      when 'mm', 'millimeter', 'millimeters'
        Math.round(value * @NM_PER_MM)
      when 'cm', 'centimeter', 'centimeters'
        Math.round(value * @NM_PER_CM)
      when 'mil', 'mils', 'thou'
        Math.round(value * @NM_PER_MIL)
      when 'in', 'inch', 'inches'
        Math.round(value * @NM_PER_INCH)
      else
        throw new Error("Unknown unit: #{unit}")

  # Convert from integer nanometers to desired target unit
  @fromNm: (nm, unit = 'mm') ->
    switch unit.toLowerCase()
      when 'nm', 'nanometer', 'nanometers'
        nm
      when 'um', 'micron', 'microns'
        nm / @NM_PER_UM
      when 'mm', 'millimeter', 'millimeters'
        nm / @NM_PER_MM
      when 'cm', 'centimeter', 'centimeters'
        nm / @NM_PER_CM
      when 'mil', 'mils', 'thou'
        nm / @NM_PER_MIL
      when 'in', 'inch', 'inches'
        nm / @NM_PER_INCH
      else
        throw new Error("Unknown unit: #{unit}")

  # Direct helper constructors returning integer nanometers
  @mm: (val) -> Math.round(val * @NM_PER_MM)
  @mil: (val) -> Math.round(val * @NM_PER_MIL)
  @um: (val) -> Math.round(val * @NM_PER_UM)
  @inch: (val) -> Math.round(val * @NM_PER_INCH)

  # Format nanometer value to human-readable string with units
  @formatMetric: (nm, precision = 4) ->
    val = (nm / @NM_PER_MM).toFixed(precision)
    # Trim trailing zeroes after decimal point
    clean = parseFloat(val).toString()
    "#{clean} mm"

  @formatImperial: (nm, precision = 2) ->
    val = (nm / @NM_PER_MIL).toFixed(precision)
    clean = parseFloat(val).toString()
    "#{clean} mil"

  # Gerber coordinate format helper (default: 4.6 metric, integer scaled)
  # Converts nanometers to 4.6 metric format integer string
  # 1 mm = 1,000,000 nm = 1,000,000 gerber units (format 4.6 means 6 decimals)
  @toGerberMetric: (nm) ->
    # In format 4.6 metric, 1 mm has 6 decimal places, so 1 mm = 1000000
    Math.round(nm)

  # Converts nanometers to 2.6 imperial inch format integer string
  # 1 inch = 25,400,000 nm. In 2.6 imperial, 1 unit = 1e-6 inch = 25.4 nm
  @toGerberImperial: (nm) ->
    Math.round(nm / 25.4)

  # Angle normalization and conversion
  @degToRad: (deg) -> (deg * Math.PI) / 180.0
  @radToDeg: (rad) -> (rad * 180.0) / Math.PI

  @normalizeDeg: (deg) ->
    d = deg % 360.0
    if d < 0 then d + 360.0 else d

  @normalizeRad: (rad) ->
    twoPi = 2.0 * Math.PI
    r = rad % twoPi
    if r < 0 then r + twoPi else r

  # Snap angle to nearest multiple of step degrees (e.g. 45 degrees for PCB routing)
  @snapAngleDeg: (deg, step = 45.0) ->
    norm = @normalizeDeg(deg)
    snapped = Math.round(norm / step) * step
    @normalizeDeg(snapped)

module.exports = Units
