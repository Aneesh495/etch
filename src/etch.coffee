###
# Etch EDA: High-Precision Electronic Design Automation Suite
#
# Primary module export and public API gateway for Etch EDA engine.
###

# Core Geometry & Math
Units = require './core/units'
{ Point, Vector2D, LineSegment, Arc, BoundingBox } = require './core/geometry'
Matrix2D = require './core/matrix'
Polygon = require './core/polygon'
PolygonOps = require './core/polygon_ops'
SpatialIndex = require './core/spatial_index'
IntersectionDetector = require './core/intersection'

# Board & Component Model
Board = require './model/board'
{ Layer, LayerStackup, LayerType } = require './model/layer'
{ Net, NetClass, Netlist, PinReference } = require './model/net'
{ Pad, PadShape, PadType } = require './model/pad'
{ Via, ViaType } = require './model/via'
{ Trace, TraceSegment } = require './model/trace'
{ Zone, ZoneType, ZoneFillMode } = require './model/zone'
ThermalRelief = require './model/thermal'
Component = require './model/component'

# Footprint Library
Footprints = require './footprints/index'

# Declarative DSL
{ defineBoard, BoardBuilder, Placement } = require './dsl/builder'

# Multi-Layer Autorouter
RoutingGrid = require './router/grid'
{ AStarRouter, BinaryHeap } = require './router/astar_router'
LeeRouter = require './router/lee_router'
PathFinderRouter = require './router/pathfinder'
RipUpRerouter = require './router/ripup'
TraceSmoother = require './router/smoother'
LengthTuner = require './router/length_tuner'

# Design Rule Checker (DRC)
{ DesignRuleChecker, DRCResult } = require './drc/checker'
ClearanceChecker = require './drc/clearance'
GeometryRulesChecker = require './drc/geometry_rules'
NetRulesChecker = require './drc/net_rules'
ManufacturingRulesChecker = require './drc/manufacturing_rules'

# Manufacturing Pipeline
{ GerberWriter, GerberExporter } = require './manufacturing/gerber_rs274x'
ExcellonExporter = require './manufacturing/excellon'
IPCD356Exporter = require './manufacturing/ipc_d_356'
PickAndPlaceExporter = require './manufacturing/pick_and_place'
BOMExporter = require './manufacturing/bom'
FabPackager = require './manufacturing/fab_packager'

# Visualizers & Web CAD
SVGRenderer = require './visualizer/svg_renderer'
TerminalPreview = require './visualizer/terminal_preview'
WebServer = require './visualizer/web_server'

# Schematic Bridges
KiCadNetlistBridge = require './schematic/kicad_bridge'
SPICEBridge = require './schematic/spice_bridge'

# Fastpath
FastGridBridge = require './native/fast_grid_bridge'

module.exports = {
  # Core
  Units
  Point
  Vector2D
  LineSegment
  Arc
  BoundingBox
  Matrix2D
  Polygon
  PolygonOps
  SpatialIndex
  IntersectionDetector

  # Model
  Board
  Layer
  LayerStackup
  LayerType
  Net
  NetClass
  Netlist
  PinReference
  Pad
  PadShape
  PadType
  Via
  ViaType
  Trace
  TraceSegment
  Zone
  ZoneType
  ZoneFillMode
  ThermalRelief
  Component

  # Footprints
  Footprints

  # DSL
  defineBoard
  BoardBuilder
  Placement

  # Router
  RoutingGrid
  AStarRouter
  BinaryHeap
  LeeRouter
  PathFinderRouter
  RipUpRerouter
  TraceSmoother
  LengthTuner

  # DRC
  DesignRuleChecker
  DRCResult
  ClearanceChecker
  GeometryRulesChecker
  NetRulesChecker
  ManufacturingRulesChecker

  # Manufacturing
  GerberWriter
  GerberExporter
  ExcellonExporter
  IPCD356Exporter
  PickAndPlaceExporter
  BOMExporter
  FabPackager

  # Visualizer
  SVGRenderer
  TerminalPreview
  WebServer

  # Schematic
  KiCadNetlistBridge
  SPICEBridge

  # Fastpath
  FastGridBridge
}
