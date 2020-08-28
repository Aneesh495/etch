# Etch EDA: Architecture Specification

## 1. System Overview

Etch is an Electronic Design Automation (EDA) and Printed Circuit Board (PCB) CAD engine implemented in literate CoffeeScript with native C11 fastpath acceleration. It bridges the gap between programmatic hardware description and production-ready manufacturing outputs (Gerber RS-274X, Excellon Drill, IPC-D-356).

```
+-----------------------------------------------------------------------------+
|                                Hardware DSL                                 |
|                       (Declarative CoffeeScript API)                        |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                                Board Model                                  |
|     (Stackup, Footprints, Nets, Pads, Traces, Zones, Thermal Reliefs)       |
+-----------------------------------------------------------------------------+
               |                                               |
               v                                               v
+-----------------------------+                 +-----------------------------+
|      3D Autorouter          |                 |    Design Rule Check (DRC)  |
|  * 3D Routing Grid          |                 |  * Spatial Clearance Matrix |
|  * A* Heuristic Pathfinder  |                 |  * Annular Ring Checker     |
|  * PathFinder Congestion    |                 |  * Short Circuit Detection  |
|  * Rip-Up & Reroute (RRR)   |                 |  * Acid Trap Identifier     |
|  * Topological Smoother     |                 |  * Airwire Net Validator    |
+-----------------------------+                 +-----------------------------+
               |                                               |
               +-----------------------+-----------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                           Manufacturing Pipeline                            |
|  * RS-274X Photoplotter Generator (Top/Bottom Copper, Mask, Silkscreen)     |
|  * Excellon NC Drill Tool Table & Coordinates                               |
|  * IPC-D-356 Bare-Board Electrical Test Netlist                             |
|  * SMT Pick-and-Place (CPL / Centroid) CSV Exporter                         |
|  * Structured Bill of Materials (BOM) Exporter                              |
+-----------------------------------------------------------------------------+
                                       |
                                       v
+-----------------------------------------------------------------------------+
|                         Visualizer & Web CAD GUI                            |
|  * Standalone Multi-Layer Vector SVG Renderer                               |
|  * ANSI Terminal ASCII-Art Board Inspector                                  |
|  * Embedded Web CAD Visualizer (HTML5 Canvas, Pan/Zoom, Net Highlighting)    |
+-----------------------------------------------------------------------------+
```

## 2. Fixed-Point Nanometer Quantization

Floating-point representations (IEEE 754 float32/float64) introduce cumulative rounding errors when rotating, projecting, and clipping geometry across thousands of coordinates. This causes subtle photoplotter alignment shifts and false-positive DRC violations.

Etch standardizes all internal dimensional calculations on 64-bit integer nanometers (nm):

* 1 mm = 1,000,000 nm
* 1 mil (thou) = 25,400 nm
* 1 micron (um) = 1,000 nm
* 1 inch = 25,400,000 nm

Integer arithmetic guarantees bit-accurate equality comparisons, deterministic polygon boolean clipping, and exact mapping to Gerber format 4.6 metric photoplotters.

## 3. Module Hierarchy and Subsystems

### Core Geometry (`src/core/`)
* `units.coffee`: Fixed-point unit quantization and metric/imperial conversions.
* `geometry.coffee`: 2D Point, Vector2D, LineSegment, Arc, and BoundingBox primitives.
* `matrix.coffee`: Homogeneous 3x3 affine transformation matrix supporting translation, rotation, scaling, and layer mirroring.
* `polygon.coffee`: 2D polygon representation with hole contours, shoelace signed area, winding number containment, and normal boundary inflation.
* `polygon_ops.coffee`: Constructive 2D polygon boolean operations (Union, Intersection, Difference) based on Weiler-Atherton clipping.
* `spatial_index.coffee`: 2D R-Tree spatial indexing with Sort-Tile-Recursive (STR) bulk-loading for sub-millisecond range queries.
* `intersection.coffee`: Sweep-line segment intersection detector for DRC short checks and acute angle acid trap identification.

### Board Model (`src/model/`)
* `layer.coffee`: Multi-layer physical stackup (2, 4, 6 layers), copper weights (1 oz = 35 um), and dielectric core/prepreg parameters.
* `board.coffee`: Top-level PCB database coordinating physical outline, components, netlist, traces, vias, and copper pour zones.
* `net.coffee`: Electrical nets, NetClass physical constraints (widths, clearances, via sizes, differential pair rules), and Minimum Spanning Tree airwire generation.
* `pad.coffee`: SMD and through-hole pad geometries, annular ring calculations, and solder mask expansion offsets.
* `via.coffee`: Through-vias, blind/buried vias, and micro-vias spanning arbitrary layer intervals.
* `trace.coffee`: Octilinear 45-degree copper tracks, arc bends, and contiguous multi-segment trace paths.
* `zone.coffee`: Polygonal copper pour planes (GND, power rails) with priority-based overlap resolution and dead-copper island pruning.
* `thermal.coffee`: Automated 4-spoke and 2-spoke thermal relief generator for pad-to-plane connections.
* `component.coffee`: Component instances with reference designators, rotation, side assignment, and courtyard bounding envelopes.

### IPC-7351B Footprint Library (`src/footprints/`)
* `passives.coffee`: Rectangular SMD chip passives (0201, 0402, 0603, 0805, 1206, 1210, 2010, 2512).
* `small_outline.coffee`: Discrete and IC gull-wing packages (SOT-23, SOT-223 with tab, SOIC-8 to SOIC-28, TSSOP-16 to TSSOP-28).
* `quad_flat.coffee`: 4-sided gull-wing packages (QFP-32, QFP-48, QFP-64, QFP-100).
* `qfn.coffee`: Quad Flat No-leads packages (QFN-16 to QFN-64) with central exposed ground thermal pad.
* `bga.coffee`: High-density Ball Grid Arrays (BGA-36, BGA-64, BGA-144) using JEDEC standard row lettering (A..H, skipping I, O, Q, S, X, Z).
* `through_hole.coffee`: Plated through-hole packages (DIP-8 to DIP-28, 2.54mm pin headers, TO-92, TO-220).
* `connectors.coffee`: Modern board interfaces including USB Type-C 16-pin, Micro-USB, and SMA coaxial edge-launch RF receptacles.
* `index.coffee`: Master footprint registry resolving package strings into fully populated Component models.

### Multi-Layer Autorouter (`src/router/`)
* `grid.coffee`: 3D discretized occupancy lattice with directional layer bias (horizontal on top, vertical on bottom) and clearance obstacle dilation.
* `astar_router.coffee`: 3D A* maze router with binary min-heap priority queue, octilinear distance heuristics, and via insertion penalties.
* `lee_router.coffee`: Breadth-first search wavefront expansion guaranteeing shortest path connectivity on unweighted grids.
* `pathfinder.coffee`: Negotiated congestion iterative router applying history cost multipliers to overused grid cells.
* `ripup.coffee`: Intelligent Rip-Up and Reroute (RRR) engine resolving routing bottlenecks by ripping up blocking nets and rerouting with detour penalties.
* `smoother.coffee`: Post-routing topological trace optimizer merging collinear segments, beveling 90-degree corners to 45 degrees, and eliminating redundant dog-legs.
* `length_tuner.coffee`: Serpentine accordion meander generator for high-speed differential pairs (USB, PCIe, DDR) to equalize propagation delay.

### Design Rule Checker (`src/drc/`)
* `clearance.coffee`: Spatial clearance matrix verification (Track-to-Track, Track-to-Pad, Pad-to-Pad, Via-to-Track, Copper-to-Edge).
* `geometry_rules.coffee`: Minimum trace width, annular ring thickness, drill diameter, and drill-to-drill distance checks.
* `net_rules.coffee`: Topological netlist continuity validation, airwire unrouted detection, and electrical short circuit discovery.
* `manufacturing_rules.coffee`: Acid trap (<90 degree acute angle) detection, silkscreen pad encroachment, and floating copper island identification.
* `checker.coffee`: Master DRC orchestrator emitting structured violation reports and pass/fail statuses.

### Manufacturing Pipeline (`src/manufacturing/`)
* `gerber_rs274x.coffee`: RS-274X photoplotter format generator for copper, solder mask, silkscreen, and edge cut layers.
* `excellon.coffee`: Excellon format 2 NC drill generator with sorted tool table and metric coordinates.
* `ipc_d_356.coffee`: Bare-board electrical test netlist (records 317 and 327) for automated flying-probe continuity testing.
* `pick_and_place.coffee`: SMT component centroid CSV exporter (RefDes, Value, Package, X, Y, Rotation, Layer).
* `bom.coffee`: Structured Bill of Materials aggregator emitting grouped component counts in CSV, Markdown, and JSON.
* `fab_packager.coffee`: Fabrication archive bundler creating production-ready packages for commercial board houses.

### Visualizer & Web CAD (`src/visualizer/`, `web/`)
* `svg_renderer.coffee`: Standalone vector SVG generator supporting multiple solder mask themes (Matte Black, Classic Green, OSH Park Purple).
* `terminal_preview.coffee`: Headless terminal ASCII-art board inspector.
* `web_server.coffee`: Embedded HTTP server serving dark-mode interactive Web CAD GUI on localhost:8080.
