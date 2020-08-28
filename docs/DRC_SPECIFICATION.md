# Etch EDA: Design Rule Checking (DRC) Specification

## 1. Overview

The Design Rule Check (DRC) engine validates physical printed circuit board geometry against industrial manufacturing tolerances. Violations are categorized by severity:
* **ERROR**: Catastrophic defects that cause functional failures (short circuits, insufficient clearance causing solder bridging, broken annular rings).
* **WARNING**: Fabrication risks that degrade manufacturing yield or long-term reliability (acid traps, silkscreen over pads, unrouted airwires).

## 2. Clearance Rules Matrix

The clearance matrix enforces spatial separation between copper features on identical physical layers:

| Rule Code | Description | Default Threshold |
| :--- | :--- | :--- |
| `CLEARANCE_TRACK_TO_TRACK` | Minimum separation between edges of different nets | 0.15 mm (6 mil) |
| `CLEARANCE_TRACK_TO_PAD` | Separation between track edge and component pad copper | 0.15 mm (6 mil) |
| `CLEARANCE_PAD_TO_PAD` | Separation between adjacent pads of different nets | 0.15 mm (6 mil) |
| `CLEARANCE_VIA_TO_TRACK` | Separation between via outer annular ring and track edge | 0.15 mm (6 mil) |
| `CLEARANCE_VIA_TO_VIA` | Separation between adjacent via outer copper rings | 0.20 mm (8 mil) |
| `CLEARANCE_COPPER_TO_EDGE` | Setback from board edge outline to copper traces/pads | 0.30 mm (12 mil) |

Centerline distances between segments $\vec{s}_1$ and $\vec{s}_2$ are converted to edge-to-edge clearances:

$$d_{edge} = d_{center}(\vec{s}_1, \vec{s}_2) - \left( \frac{w_1}{2} + \frac{w_2}{2} \right)$$

Clearance violations are flagged when $d_{edge} < \text{minClearance}$.

## 3. Geometric Constraints

### Minimum Trace Width
* **Rule**: `MIN_TRACE_WIDTH`
* **Check**: Validates that all trace segments meet the minimum width:

$$w_{segment} \ge w_{min} \quad (\text{default: } 0.15\text{ mm} / 6\text{ mil})$$

Traces below this limit risk necking down or vaporizing during chemical etching.

### Annular Ring Verification
* **Rule**: `MIN_ANNULAR_RING`
* **Check**: Plated through-holes (THT pads and vias) must maintain an annular ring of copper surrounding the drilled hole:

$$t_{ring} = \frac{d_{copper} - d_{drill}}{2} \ge t_{min} \quad (\text{default: } 0.15\text{ mm} / 6\text{ mil})$$

An insufficient annular ring causes drill breakout, severing interlayer connections.

### Drill-to-Drill Spacing
* **Rule**: `DRILL_TO_DRILL_CLEARANCE`
* **Check**: Separation between adjacent drilled holes:

$$d_{drill\_edge} = \text{dist}(h_1, h_2) - \left( \frac{d_1}{2} + \frac{d_2}{2} \right) \ge d_{min\_drill} \quad (\text{default: } 0.50\text{ mm})$$

Drill holes placed too closely can crack the FR4 epoxy-glass substrate during high-speed CNC drilling.

## 4. Netlist Integrity & Continuity

### Unrouted Nets (Airwires)
* **Rule**: `UNROUTED_NET`
* **Check**: Evaluates topological connectivity for all nets with $\ge 2$ pins. If a net has unrouted pin pairs and is not assigned to a continuous copper plane zone, an unrouted airwire violation is reported.

### Electrical Short Circuits
* **Rule**: `ELECTRICAL_SHORT`
* **Check**: Detects physical intersections between copper traces belonging to different electrical nets on the same layer using the Bentley-Ottmann sweep-line algorithm:

$$\text{layer}(s_1) = \text{layer}(s_2) \quad \land \quad \text{net}(s_1) \ne \text{net}(s_2) \quad \land \quad s_1 \cap s_2 \ne \emptyset$$

Short circuits represent fatal board layout errors.

## 5. Manufacturing Risk Rules

### Acute Angle Acid Traps
* **Rule**: `ACID_TRAP`
* **Check**: Locates sharp acute angles ($\theta < 85^\circ$) between connected trace segments. During chemical etching, surface tension causes liquid etchant to pool in narrow corners, resulting in localized over-etching and trace pinch-off.

### Silkscreen Over Solder Pads
* **Rule**: `SILKSCREEN_OVER_PAD`
* **Check**: Detects component silkscreen lines or reference designators encroaching on exposed solder pads. Non-conductive epoxy silkscreen ink over pads prevents proper solder wetting and causes open circuit solder joints.
