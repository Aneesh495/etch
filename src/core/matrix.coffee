###
# Etch EDA: 2D Affine Transformation Matrix (3x3)
#
# Implements homogeneous 3x3 transformation matrices for board layout
# positioning, footprint rotation, component mirroring between top and bottom
# copper layers, and photoplotter coordinate mapping.
###

{ Point, BoundingBox } = require './geometry'
Units = require './units'

class Matrix2D
  # Matrix entries stored as:
  # [ a  c  tx ]
  # [ b  d  ty ]
  # [ 0  0   1 ]
  constructor: (@a = 1.0, @b = 0.0, @c = 0.0, @d = 1.0, @tx = 0.0, @ty = 0.0) ->

  @identity: -> new Matrix2D(1.0, 0.0, 0.0, 1.0, 0.0, 0.0)

  @translation: (tx, ty) -> new Matrix2D(1.0, 0.0, 0.0, 1.0, tx, ty)

  @rotationRad: (rad) ->
    cosA = Math.cos(rad)
    sinA = Math.sin(rad)
    new Matrix2D(cosA, sinA, -sinA, cosA, 0.0, 0.0)

  @rotationDeg: (deg) ->
    @rotationRad(Units.degToRad(deg))

  @scaling: (sx, sy = sx) -> new Matrix2D(sx, 0.0, 0.0, sy, 0.0, 0.0)

  # Mirroring along Y axis (flips X coordinates; used for bottom layer placement)
  @mirrorX: -> new Matrix2D(-1.0, 0.0, 0.0, 1.0, 0.0, 0.0)

  # Mirroring along X axis (flips Y coordinates)
  @mirrorY: -> new Matrix2D(1.0, 0.0, 0.0, -1.0, 0.0, 0.0)

  clone: -> new Matrix2D(@a, @b, @c, @d, @tx, @ty)

  # Matrix multiplication: this * other
  multiply: (other) ->
    new Matrix2D(
      @a * other.a + @c * other.b,
      @b * other.a + @d * other.b,
      @a * other.c + @c * other.d,
      @b * other.c + @d * other.d,
      @a * other.tx + @c * other.ty + @tx,
      @b * other.tx + @d * other.ty + @ty
    )

  # Apply transformation in-place fluently
  translate: (tx, ty) ->
    t = Matrix2D.translation(tx, ty)
    m = @multiply(t)
    @setFrom(m)
    this

  rotateDeg: (deg) ->
    r = Matrix2D.rotationDeg(deg)
    m = @multiply(r)
    @setFrom(m)
    this

  scale: (sx, sy = sx) ->
    s = Matrix2D.scaling(sx, sy)
    m = @multiply(s)
    @setFrom(m)
    this

  setFrom: (m) ->
    @a = m.a
    @b = m.b
    @c = m.c
    @d = m.d
    @tx = m.tx
    @ty = m.ty

  # Transform a Point to a new Point with integer nanometer rounding
  transformPoint: (pt) ->
    nx = @a * pt.x + @c * pt.y + @tx
    ny = @b * pt.x + @d * pt.y + @ty
    new Point(Math.round(nx), Math.round(ny))

  transformPoints: (points) ->
    (@transformPoint(pt) for pt in points)

  # Transform a BoundingBox into an axis-aligned bounding box enclosing the transformed corners
  transformBoundingBox: (bb) ->
    return new BoundingBox() unless bb.isValid()
    c1 = new Point(bb.minX, bb.minY)
    c2 = new Point(bb.maxX, bb.minY)
    c3 = new Point(bb.maxX, bb.maxY)
    c4 = new Point(bb.minX, bb.maxY)
    tc1 = @transformPoint(c1)
    tc2 = @transformPoint(c2)
    tc3 = @transformPoint(c3)
    tc4 = @transformPoint(c4)
    BoundingBox.fromPoints([tc1, tc2, tc3, tc4])

  # Invert matrix
  inverse: ->
    det = @a * @d - @b * @c
    if Math.abs(det) < 1e-12
      throw new Error("Matrix is singular and cannot be inverted")
    invDet = 1.0 / det
    new Matrix2D(
      @d * invDet,
      -@b * invDet,
      -@c * invDet,
      @a * invDet,
      (@c * @ty - @d * @tx) * invDet,
      (@b * @tx - @a * @ty) * invDet
    )

module.exports = Matrix2D
