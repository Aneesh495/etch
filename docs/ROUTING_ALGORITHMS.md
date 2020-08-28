# Etch EDA: Routing Algorithms & Topological Optimization

## 1. 3D Multi-Layer Grid Discretization

The board routing domain is discretized into a 3D lattice:

$$\text{cols} = \left\lceil \frac{W}{\Delta} \right\rceil + 1, \quad \text{rows} = \left\lceil \frac{H}{\Delta} \right\rceil + 1, \quad \text{layers} = N_{cu}$$

where $W$ and $H$ are board outline width and height, $\Delta$ is grid cell pitch (typically 0.1 mm to 0.25 mm), and $N_{cu}$ is the number of copper routing layers.

Each grid node represents a possible trace waypoint or via location. Nodes are indexed into flat typed arrays:

$$\text{index}(c, r, l) = (l \cdot \text{rows} + r) \cdot \text{cols} + c$$

### Directional Layer Cost Biasing
To prevent chaotic routing where tracks wander across layers creating dense cross-layer blockages, Etch enforces directional layer preferences:

* **Layer 0 (Top Copper, F.Cu)**: Prefers horizontal travel. Horizontal steps cost $1.0$, while vertical steps are penalized by factor $\beta_y = 2.0$.
* **Layer 1 (Bottom Copper, B.Cu)**: Prefers vertical travel. Vertical steps cost $1.0$, while horizontal steps are penalized by factor $\beta_x = 2.0$.
* **Via Transition Cost**: Moving in the $Z$-axis (changing layers) incurs a constant via penalty $C_{via} = 50.0$, penalizing unnecessary via insertion.

## 2. 3D A-Star Heuristic Pathfinder

The A* search maintains an open set ordered by estimated total path cost:

$$f(n) = g(n) + h(n)$$

where $g(n)$ is the exact accumulated path cost from the start pin, and $h(n)$ is an admissible 3D heuristic function.

### Octilinear 3D Heuristic
Because traces can move in 8 planar directions (cardinal plus 45-degree diagonals) and transition between layers, the heuristic is derived as:

$$\Delta c = |c_1 - c_2|, \quad \Delta r = |r_1 - r_2|, \quad \Delta l = |l_1 - l_2|$$

$$h_{2D} = \max(\Delta c, \Delta r) + (\sqrt{2} - 1) \cdot \min(\Delta c, \Delta r)$$

$$h(n) = h_{2D} + \Delta l \cdot C_{via}$$

This heuristic is strictly admissible (it never overestimates the true distance to the target) and monotonic, ensuring the first arrival at the target cell is guaranteed to be optimal.

### Binary Min-Heap Priority Queue
To achieve sub-millisecond route evaluations, the open set is implemented using a cache-friendly 1D binary min-heap supporting $O(\log N)$ push and pop operations.

## 3. PathFinder: Negotiated Congestion Routing

In dense layouts with hundreds of pins, routing nets sequentially with hard obstacle barriers can cause early nets to greedily consume critical routing channels, causing later nets to fail completely.

Etch implements the PathFinder negotiated congestion algorithm:

### Cost Function
During each iteration $k$, the cost of traversing cell $n$ is computed as:

$$c(n) = \big( b(n) + p(n) \big) \cdot h(n)$$

where:
* $b(n)$ is the base traversal cost of the cell.
* $p(n)$ is the current congestion penalty, proportional to the number of nets currently sharing cell $n$.
* $h(n)$ is the historical congestion accumulation across prior iterations:

$$h^{(k)}(n) = h^{(k-1)}(n) \cdot \gamma \quad \text{if cell } n \text{ is overused, else } h^{(k-1)}(n)$$

with history multiplier $\gamma = 1.5$. Over successive iterations, cells that experience persistent contention become prohibitively expensive, compelling conflicting nets to negotiate and discover alternative detour corridors until zero cell sharing remains.

## 4. Rip-Up and Reroute (RRR) Engine

When a net cannot find a path due to an unroutable bottleneck:
1. **Conflict Identification**: Identifies existing routed nets intersecting the bounding corridor between the disconnected terminals.
2. **Rip-Up**: Removes the conflicting victim nets from the board database and frees their occupied lattice cells.
3. **Target Routing**: Routes the blocked net through the cleared corridor.
4. **Victim Rerouting**: Reroutes the ripped-up victim nets with escalating history penalties to prevent cyclic oscillation loops.

## 5. Topological Trace Smoothing & Corner Mitering

Grid-based A* routing initially yields stair-stepped tracks with 90-degree corners. The post-routing topological optimizer executes two cleanup passes:

### Collinear Segment Merging
Scans contiguous segments on each layer. If consecutive segments share identical direction vectors:

$$\frac{|\vec{v}_1 \times \vec{v}_2|}{|\vec{v}_1| \cdot |\vec{v}_2|} < \epsilon \quad \text{and} \quad \vec{v}_1 \cdot \vec{v}_2 > 0$$

the intermediate junction vertex is pruned, merging the chain into a single uninterrupted trace.

### 45-Degree Corner Mitering
Right angles (90 degrees) cause high-frequency impedance discontinuities and trap etching chemicals. The mitering engine locates 90-degree corners, backs off the endpoints by miter distance $d_{miter}$, and inserts a smooth 45-degree bevel segment.

## 6. Serpentine Differential Pair Length Tuning

High-speed differential pairs (USB 2.0 / 3.0, PCIe, HDMI) require matched electrical lengths to prevent differential skew:

$$\Delta L = |L_{positive} - L_{negative}| \le \text{tolerance}$$

The length tuning engine:
1. Evaluates total trace lengths of both differential legs.
2. Identifies the longest straight segment on the shorter trace.
3. Synthesizes serpentine accordion meanders with specified amplitude $A$ and pitch $P$:

$$\text{extra length per bump} \approx 2 \cdot A$$

Each meander alternates normal direction vectors $(\vec{n}, -\vec{n})$ to create symmetrical tuning waves, equalizing propagation delay to within 0.1 mm of target.
