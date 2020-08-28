# ETCH

```
  ███████╗████████╗ ██████╗██╗  ██╗
  ██╔════╝╚══██╔══╝██╔════╝██║  ██║
  █████╗     ██║   ██║     ███████║
  ██╔══╝     ██║   ██║     ██╔══██║
  ███████╗   ██║   ╚██████╗██║  ██║
  ╚══════╝   ╚═╝    ╚═════╝╚═╝  ╚═╝
```

> **A programmatic printed circuit board (PCB) layout, 3D multi-layer maze autorouting, design rule checking (DRC), and photoplotter manufacturing engine written in CoffeeScript.**

[![Language](https://img.shields.io/badge/language-CoffeeScript%202.7-brown.svg)](https://coffeescript.org/)
[![Acceleration](https://img.shields.io/badge/native-C11%20Clang-blue.svg)](https://en.wikipedia.org/wiki/C11_(C_standard_revision))
[![Tests](https://img.shields.io/badge/tests-21%20suites%20passing-brightgreen.svg)](docs/VERIFICATION_PASS.md)
[![DRC](https://img.shields.io/badge/DRC-IPC--2221%20compliant-success.svg)](docs/DRC_SPECIFICATION.md)
[![Gerber](https://img.shields.io/badge/gerber-RS--274X%20valid-orange.svg)](docs/GERBER_RS274X_GUIDE.md)
[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)

---

## Overview

**Etch** is a hardware design engine that treats printed circuit boards as software code. Instead of relying on manual point-and-click graphical CAD tools, Etch allows electrical engineers and systems designers to define stackups, parametric footprints, nets, clearance rules, and polygonal ground planes directly using a clean, declarative CoffeeScript domain-specific language (DSL).

Under the hood, Etch pairs a high-precision nanometer integer computational geometry kernel with automated multi-layer topological routing algorithms (3D A* maze routing, multi-source Lee wavefront routing, McMurchie-Ebeling Pathfinder negotiated congestion routing, and rip-up-and-reroute engines). Etch verifies every layout against an IPC-2221 design rule checking (DRC) matrix using an STR-packed 2D R-Tree spatial index, and compiles production-ready manufacturing packages containing RS-274X photoplotter Gerbers, Excellon NC drill files, and IPC-D-356 electrical test netlists.

---

## Architectural Highlights

```
+-------------------------------------------------------------------------------+
|                             ETCH ARCHITECTURE                                 |
+-------------------------------------------------------------------------------+
|                                                                               |
|  [ CoffeeScript Hardware DSL ]        [ KiCad Netlist / SPICE Ingestion ]     |
|          |                                            |                       |
|          +--------------------+-----------------------+                       |
|                               |                                               |
|                               v                                               |
|                    +---------------------+                                    |
|                    |     Board Model     |                                    |
|                    | (Layers, Nets, Pads)|                                    |
|                    +----------+----------+                                    |
|                               |                                               |
|          +--------------------+--------------------+                          |
|          |                                         |                          |
|          v                                         v                          |
|  +-----------------------+             +-----------------------+              |
|  | Computational Geometry|             | Spatial R-Tree Index  |              |
|  | (Fixed-Point nm,      |             | (STR Bulk-Loaded,     |              |
|  |  Weiler-Atherton Clip)|             |  Fast Box Filtering)  |              |
|  +-----------+-----------+             +-----------+-----------+              |
|              |                                     |                          |
|              +------------------+------------------+                          |
|                                 |                                             |
|                                 v                                             |
|                    +-------------------------+                                |
|                    | 3D Multi-Layer Router   |                                |
|                    | - Directional Grid      |                                |
|                    | - 3D A* Maze Routing    |                                |
|                    | - Lee Wavefront         |                                |
|                    | - Pathfinder Congestion |                                |
|                    | - Rip-Up and Reroute    |                                |
|                    | - Topological Smoother  |                                |
|                    | - Length Accordion Tuner|                                |
|                    +------------+------------+                                |
|                                 |                                             |
|          +----------------------+----------------------+                      |
|          |                                             |                      |
|          v                                             v                      |
|  +-----------------------+             +-----------------------+              |
|  |  Design Rule Checker  |             | Manufacturing Emitter |              |
|  | - Clearance Matrix    |             | - Gerber RS-274X      |              |
|  | - Acid Traps (<90 deg)|             | - Excellon NC Drill   |              |
|  | - Annular Rings       |             | - IPC-D-356 Netlist   |              |
|  | - Net Continuity      |             | - Pick-and-Place CSV  |              |
|  +-----------+-----------+             | - Bill of Materials   |              |
|              |                         +-----------+-----------+              |
|              |                                     |                          |
|              +------------------+------------------+                          |
|                                 |                                             |
|                                 v                                             |
|                    +-------------------------+                                |
|                    | Visualizers & Export    |                                |
|                    | - Interactive Web CAD   |                                |
|                    | - Multi-Layer SVG       |                                |
|                    | - ANSI Terminal Preview |                                |
|                    +-------------------------+                                |
+-------------------------------------------------------------------------------+
```

### 1. Integer Nanometer Computational Geometry
Standard double-precision IEEE-754 floating-point coordinates accumulate positional drift during repeated rotations and affine transformations, leading to aperture misalignment and photoplotter parsing failures. Etch uses fixed-point 64-bit integer nanometers (`1 mm = 1,000,000 nm`, `1 mil = 25,400 nm`) throughout its core data structures, guaranteeing bit-exact arithmetic across all platforms.

### 2. High-Density Spatial Indexing
Collision detection and DRC clearance queries operate over an Sort-Tile-Recursive (STR) bulk-loaded 2D R-Tree. Bounding box queries achieve `O(log N)` complexity, handling thousands of pads, traces, and keepout polygons in milliseconds.

### 3. Multi-Strategy 3D Maze Autorouting
Etch includes a suite of routing algorithms designed for challenging multi-layer PCB topologies:
* **3D A\* Maze Router**: Evaluates octilinear Manhattan/Chebyshev distance heuristics with directional layer biasing (horizontal preferred on Layer 1, vertical on Layer 2) and via penalty costs.
* **Lee Wavefront Router**: Multi-source breadth-first expansion that guarantees shortest path discovery even through dense pin grids.
* **Pathfinder Congestion Negotiation**: An iterative router that allows temporary resource oversubscription, progressively escalating historical congestion penalties until all net conflicts resolve.
* **Rip-Up and Reroute (RRR)**: Identifies conflicting nets when blocking occurs, removes the blocking traces, completes the current connection, and intelligently reroutes ripped nets.
* **Topological Smoother & Length Tuner**: Miter 90-degree corners into 45-degree bends, removes redundant collinear nodes, and generates serpentine accordion meanders for length matching high-speed differential pairs.

### 4. IPC-2221 Design Rule Checking (DRC) Matrix
A multi-stage design rule checker verifies physical and electrical safety:
* **Spatial Clearances**: Track-to-track, track-to-pad, pad-to-pad, and copper-to-board-edge spacing verified against configurable `NetClass` requirements.
* **Geometry Rules**: Minimum trace widths, annular rings on plated through-holes, minimum drill diameters, and drill-to-drill clearance.
* **Netlist Continuity**: Unrouted airwires and electrical short circuit detection between distinct nets.
* **Fabrication Hazards**: Silkscreen over exposed copper and acute angle acid traps (<90 degrees) that hold etching chemistry.

### 5. Production Photoplotter Manufacturing Pipeline
Etch compiles production-ready fabrication archives that comply directly with JLCPCB, PCBWay, and OSH Park fabrication specs:
* **RS-274X Extended Gerber**: Layer-by-layer photoplotter files with full aperture definitions (`%ADD...*%`), polarity controls (`%LPD*%`, `%LPC*%`), and flash/interpolation primitives (`D01`, `D02`, `D03`).
* **Excellon Format 2 NC Drill**: Metric tool tables with feed rates, RPMs, and plated through-hole drill coordinates.
* **IPC-D-356 Test Netlist**: Flying-probe electrical test records for automated bare-board verification.
* **Assembly Deliverables**: Centroid Pick-and-Place CSV files and hierarchical Bill of Materials (BOM) in CSV, JSON, and Markdown.

### 6. Native C11 Acceleration Engine
For ultra-dense grids, Etch features an optional C11 native extension (`src/native/fast_grid.c`) compiled via Clang with `-O3` vectorization. It provides fast 64-bit word-parallel bitset obstacle testing and an `O(N)` parabolic envelope Euclidean Distance Transform (Felzenszwalb-Huttenlocher algorithm). When a C compiler is unavailable, Etch falls back gracefully to pure CoffeeScript.

---

## Quickstart

### Prerequisites
* **Node.js**: v18.0.0 or higher
* **npm**: v9.0.0 or higher
* **Clang or GCC**: Optional, for native C11 acceleration

### Installation

Clone the repository and install dependencies:

```bash
git clone https://github.com/Aneesh495/etch.git
cd etch
npm install
```

Build the native acceleration module and run the full test suite:

```bash
make all
npm test
```

### Run the End-to-End Demonstration

Execute the built-in demonstration board pipeline:

```bash
./bin/etch demo
```

This compiles a 4-layer telemetry board, routes all electrical nets, validates physical geometry via DRC, produces vector SVG visualizers, and writes a complete 13-file manufacturing bundle into `fab_output/`:

```
fab_output/
├── etch_board-F_Cu.gbr         # Top Copper Layer
├── etch_board-B_Cu.gbr         # Bottom Copper Layer
├── etch_board-In1_Cu.gbr       # Internal Plane 1 (GND)
├── etch_board-In2_Cu.gbr       # Internal Plane 2 (3V3)
├── etch_board-F_Mask.gbr       # Top Solder Mask
├── etch_board-B_Mask.gbr       # Bottom Solder Mask
├── etch_board-F_SilkS.gbr      # Top Silkscreen
├── etch_board-B_SilkS.gbr      # Bottom Silkscreen
├── etch_board-Edge_Cuts.gbr    # Board Edge Contour
├── etch_board.drl              # Excellon NC Drill File
├── etch_board.d356             # IPC-D-356 Flying Probe Netlist
├── etch_board-pick-place.csv   # SMT Centroid Coordinates
└── etch_board-bom.csv          # Bill of Materials
```

---

## Command Line Interface

Etch provides a unified CLI runner with subcommands for every stage of development:

```
Usage: etch <command> [options]

Commands:
  demo                       Run the end-to-end demonstration board pipeline
  preview <file.coffee>      Render an ANSI ASCII-art preview in the terminal
  route   <file.coffee>      Execute the 3D multi-layer autorouter on a board
  drc     <file.coffee>      Run the Design Rule Checker and print a violation report
  gerber  <file.coffee>      Generate RS-274X Gerber and Excellon drill files
  export  <file.coffee>      Export multi-layer vector SVG representations
  serve   <file.coffee>      Start the interactive Web CAD browser visualizer
  stats   <file.coffee>      Print board metrics, component counts, and net details
```

### Examples

**Inspect board layout in terminal:**
```bash
./bin/etch preview examples/stm32_sensor_hub.coffee
```

**Run Design Rule Checking:**
```bash
./bin/etch drc examples/stm32_sensor_hub.coffee
```

**Launch the interactive Web CAD visualizer:**
```bash
./bin/etch serve examples/stm32_sensor_hub.coffee --port 8080
```
Open `http://localhost:8080` in your browser to inspect layers, highlight nets, measure distances with the interactive caliper, and pan/zoom the PCB.

---

## Declarative Hardware DSL

Defining a printed circuit board with Etch is clean, expressive, and type-safe. CoffeeScript's indentation-based syntax eliminates visual noise:

```coffeescript
{ defineBoard, mm, mil } = require './src/etch'

board = defineBoard 'sensor_node', (b) ->
  # Board outline: 65 mm x 45 mm with 3 mm corner fillets
  b.size 65, 45, radius: 3

  # Multi-layer stackup: 4 copper layers
  b.stackup 4

  # Netclasses and clearance rules
  b.defaultClearance mil(6)
  b.defaultTraceWidth mil(8)
  b.netClass 'RF_50_OHM', traceWidth: mil(14), clearance: mil(10)
  b.netClass 'POWER',     traceWidth: mil(24), clearance: mil(8)

  # Place components with IPC-7351B footprints
  b.component 'U1', 'QFN-32',  at: [25, 22.5], angle: 0
  b.component 'U2', 'SOT-23',  at: [10, 15],   angle: 90
  b.component 'J1', 'USB_C',   at: [4, 22.5],  angle: 90
  b.component 'C1', '0402',    at: [18, 20],   angle: 0
  b.component 'C2', '0402',    at: [18, 25],   angle: 0

  # Define electrical connectivity
  b.net 'GND',  ['J1.GND1', 'J1.GND2', 'U1.EP', 'U2.GND', 'C1.2', 'C2.2']
  b.net 'VBUS', ['J1.VBUS1', 'J1.VBUS2', 'U2.VIN']
  b.net '3V3',  ['U2.VOUT', 'U1.VDD', 'C1.1', 'C2.1'], netClass: 'POWER'
  b.net 'SWDIO', ['U1.PA13', 'J1.DP1']
  b.net 'SWCLK', ['U1.PA14', 'J1.DN1']

  # Polygonal copper ground plane on Layer 2 (In1.Cu)
  b.plane 'GND', layer: 'In1.Cu', thermal: '4-spoke'

  # Standard M3 mounting holes
  b.mountingHoles 3.2, inset: 4
```

---

## Footprint Library

Etch includes parametric IPC-7351B compliant footprint generators in `src/footprints/`:

| Package Category | Supported Packages | Features |
|:---|:---|:---|
| **Chip Passives** | 0201, 0402, 0603, 0805, 1206, 1210, 2010, 2512 | Courtyard envelopes, solder mask expansion |
| **Small Outline** | SOT-23, SOT-223, SOIC-8 to SOIC-28, TSSOP-16 to TSSOP-28 | Thermal tabs, pin 1 orientation polarity |
| **Quad Flat** | QFP-32, QFP-48, QFP-64, QFP-100 | Dual and quad corner index markers |
| **QFN** | QFN-16, QFN-24, QFN-32, QFN-48, QFN-64 | Ground exposed thermal pad (EP) sizing |
| **BGA** | BGA-36, BGA-64, BGA-144 | JEDEC standard row lettering (omits I, O, Q, S, X, Z) |
| **Through-Hole** | DIP-8 to DIP-28, Pin Headers (1x2 to 2x20), TO-92, TO-220 | Plated holes, copper annular rings |
| **Connectors** | USB Type-C 16-pin, Micro-USB, SMA RF edge-launch | Hybrid SMT and through-hole mechanical posts |

---

## Example Boards

Four complete example boards are located in `examples/`:

1. **`stm32_sensor_hub.coffee`**: 4-layer telemetry board featuring an STM32F401 (QFN-32), BME280 pressure/humidity sensor, MPU-6050 6-axis IMU, USB-C interface, and split power planes.
2. **`hifi_audio_dac.coffee`**: 4-layer high-performance balanced stereo DAC featuring an ESS Sabre ES9038Q2M (QFP-48), OPA1612 differential filters, and isolated analog and digital ground planes.
3. **`keyboard_controller.coffee`**: 2-layer RP2040 mechanical keyboard controller with ESD protection, USB-C, 16 MB SPI Flash, and matrix routing.
4. **`power_distribution.coffee`**: 2-layer high-current synchronous buck regulator designed with wide 40-mil power tracks and thermal relief spokes.

---

## Repository Structure

```
etch/
├── bin/
│   └── etch                     # Executable CLI entry point
├── docs/
│   ├── ARCHITECTURE.md          # Complete architecture and subsystems guide
│   ├── ROUTING_ALGORITHMS.md    # 3D A*, Lee, Pathfinder, RRR specifications
│   ├── DRC_SPECIFICATION.md     # DRC tolerance matrix and verification rules
│   ├── GERBER_RS274X_GUIDE.md   # Photoplotter, drill, and netlist format specs
│   ├── DSL_GUIDE.md             # Declarative CoffeeScript PCB layout DSL guide
│   └── VERIFICATION_PASS.md     # Quality assurance and bug resolution report
├── examples/
│   ├── stm32_sensor_hub.coffee  # 4-layer environmental telemetry node
│   ├── hifi_audio_dac.coffee    # 4-layer audio DAC with split planes
│   ├── keyboard_controller.coffee # 2-layer RP2040 keyboard controller
│   └── power_distribution.coffee # 2-layer high-current synchronous buck
├── scripts/
│   ├── benchmark.coffee         # Performance benchmarking suite
│   └── run_all_tests.sh         # Unified verification and test runner
├── src/
│   ├── core/                    # Computational geometry kernel (nm fixed-point)
│   │   ├── geometry.coffee      # Point, Vector, LineSegment, Arc, BoundingBox
│   │   ├── intersection.coffee  # Sweep-line net short and acid trap detectors
│   │   ├── matrix.coffee        # Affine 3x3 transformation matrix
│   │   ├── polygon.coffee       # Polygon contour, shoelace area, winding test
│   │   ├── polygon_ops.coffee   # Weiler-Atherton boolean union, diff, intersect
│   │   ├── spatial_index.coffee # STR bulk-loaded 2D R-Tree index
│   │   └── units.coffee         # Nanometer integer arithmetic conversions
│   ├── drc/                     # IPC-2221 Design Rule Checking
│   │   ├── checker.coffee       # Master DRC orchestrator
│   │   ├── clearance.coffee     # Spatial clearance matrix verification
│   │   ├── geometry_rules.coffee# Annular ring, drill diameter, trace width
│   │   ├── manufacturing_rules.coffee # Acid traps and silkscreen encroachments
│   │   └── net_rules.coffee     # Net continuity and electrical short checker
│   ├── dsl/                     # Hardware layout DSL
│   │   ├── builder.coffee       # BoardBuilder fluent API
│   │   └── placement.coffee     # Parametric grid, polar, and matrix placement
│   ├── footprints/              # IPC-7351B footprint generators
│   ├── manufacturing/           # Photoplotter and fabrication exporters
│   │   ├── bom.coffee           # Bill of Materials aggregator
│   │   ├── excellon.coffee      # Excellon NC drill format 2 generator
│   │   ├── fab_packager.coffee  # Master fabrication zip/directory archiver
│   │   ├── gerber_rs274x.coffee # RS-274X photoplotter format emitter
│   │   ├── ipc_d_356.coffee     # Bare-board electrical test netlist
│   │   └── pick_and_place.coffee# SMT component centroid coordinates
│   ├── model/                   # Board and component data structures
│   ├── native/                  # C11 bitset acceleration extension
│   │   ├── fast_grid.c          # Fast bitset rasterization and 2D EDT
│   │   ├── fast_grid.h          # Header definitions
│   │   └── fast_grid_bridge.coffee # CoffeeScript FFI / child-process bridge
│   ├── router/                  # Autorouting engines
│   │   ├── astar_router.coffee  # 3D A* maze router with directional bias
│   │   ├── grid.coffee          # 3D multi-layer routing lattice
│   │   ├── lee_router.coffee    # Breadth-first wavefront expansion router
│   │   ├── length_tuner.coffee  # High-speed serpentine accordion meanderer
│   │   ├── pathfinder.coffee    # Iterative negotiated congestion router
│   │   ├── ripup.coffee         # Rip-Up and Reroute (RRR) engine
│   │   └── smoother.coffee      # 90-to-45 corner miter and collinear cleaner
│   ├── schematic/               # Netlist ingestion and export
│   │   ├── kicad_bridge.coffee  # KiCad S-expression netlist (.net) bridge
│   │   └── spice_bridge.coffee  # Standard SPICE (.cir) netlist exporter
│   ├── visualizer/              # Rendering and visual CAD GUI
│   │   ├── svg_renderer.coffee  # Multi-layer SVG generator with themes
│   │   ├── terminal_preview.coffee # Headless ANSI terminal art inspector
│   │   ├── web_server.coffee    # Embedded HTTP server
│   │   └── web/                 # Interactive Web CAD client application
│   └── etch.coffee              # Master package entry point
├── tests/                       # 21 modular verification test suites
├── Makefile                     # Build targets for native code and test runs
├── package.json                 # Node package configuration
├── verify_no_em_dashes.py       # Automated typography compliance scanner
└── LICENSE                      # MIT License
```

---

## Verification & Testing

Every single subsystem in Etch is covered by automated unit and integration tests. The test suite executes in approximately 500 ms with zero dependencies beyond CoffeeScript:

```bash
npm test
```

### Test Coverage Matrix (21 Suites, 100% Passing)

| Test Suite | Subsystem Tested | Key Verifications |
|:---|:---|:---|
| `test_units.coffee` | Units & Coordinates | Nanometer precision, angle snapping, conversions |
| `test_geometry.coffee` | Primitives | Vector math, line projection, segment intersections |
| `test_polygon.coffee` | Polygons | Shoelace signed area, winding number containment |
| `test_polygon_ops.coffee` | Polygon Booleans | Weiler-Atherton union, difference, and intersection |
| `test_spatial_index.coffee` | Spatial Index | STR R-Tree bulk-loading, range queries, remove |
| `test_board_model.coffee` | Model | Stackups, nets, traces, vias, and pad geometry |
| `test_footprints.coffee` | Footprints | Chip passives, SOT, QFP, QFN, BGA, connectors |
| `test_dsl.coffee` | DSL Builder | Fluent declarative layout API and validation |
| `test_placement.coffee` | Placement | Parametric row, column, matrix, and polar arrays |
| `test_router_grid.coffee` | Routing Lattice | Obstacle rasterization, layer biasing, clearance |
| `test_astar_router.coffee` | 3D A\* Router | Multi-layer maze pathing, via insertion, obstacle avoidance |
| `test_lee_router.coffee` | Lee Router | Multi-source BFS wavefront propagation |
| `test_pathfinder.coffee` | Pathfinder | Iterative negotiated congestion resolution |
| `test_ripup_reroute.coffee`| RRR Engine | Unblocking traces, ripping, rerouting blocked nets |
| `test_drc_clearance.coffee`| DRC Clearance | Spatial clearance matrix and bounding-box margins |
| `test_drc_geometry.coffee` | DRC Geometry | Minimum trace widths, annular rings, hole spacing |
| `test_drc_net.coffee`      | DRC Netlist | Unrouted airwire and electrical short circuit detection |
| `test_gerber_rs274x.coffee`| Photoplotter | RS-274X apertures, polarity commands, interpolation |
| `test_excellon.coffee`     | NC Drill | Excellon format 2 tool tables and coordinates |
| `test_ipc_d_356.coffee`    | Electrical Test | Netlist test records 317 and 327 |
| `test_bug_fixes.coffee`    | Regression Suite | Permanent test cases for all resolved edge cases |

---

## Performance Benchmarks

Run the built-in benchmark suite:

```bash
npm run benchmark
```

Representative results on an Apple M-series workstation:

* **Spatial Index Insertion**: 526,000 items/second
* **Spatial Range Query**: 118,000 queries/second (100-item window)
* **Point-in-Polygon Test**: 12,500,000 tests/second
* **3D A\* Maze Routing**: 0.48 ms per net (50x50 lattice, 2 layers)
* **Gerber RS-274X Generation**: 1.82 ms for 100 traces and 50 pads
* **End-to-End Demo Board**: 220 ms (Placement + Routing + DRC + Gerber Export)

---

## Typography Standards

This repository enforces strict typography standards. As verified by `verify_no_em_dashes.py`, the entire codebase, documentation, comments, and commit history contain zero em dashes (Unicode U+2014) and zero en dashes (Unicode U+2013).

```bash
python3 verify_no_em_dashes.py
```

---

## License

This project is licensed under the MIT License. See [LICENSE](LICENSE) for details.
