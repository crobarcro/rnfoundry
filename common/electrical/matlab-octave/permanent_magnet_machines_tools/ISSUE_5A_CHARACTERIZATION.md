# Issue #5A radial slot-area characterization

`internalslotnodelinks` partitions ordinary layers by area in its local
Cartesian coordinates. That remains correct and unchanged for linear-machine
callers. The radial drawing interprets local `x` as radial displacement and
local `y` as angle, so its `pol2cart` map has a radius-dependent Jacobian.
Consequently, the existing equal-local-area boundary produces unequal physical
areas. Issue #5A deliberately freezes that placement; Issue #5B will review a
bounded equal-physical-area placement algorithm with topology and minimum
feature size taking priority over equality.

`radialslotregions` is the shared solver-free single-slot kernel. It consumes
the nodes, links, labels, insulation topology, and `vertlinkinds` produced by
`internalslotnodelinks`, then performs the same orientation, offset, and radial
mapping as the FEMM drawing. Its areas use Green's theorem over actual FEMM
primitives: Cartesian cross products for segments and `r^2*dtheta/2` for the
origin-centred arcs. Polygon sampling is used only for label-to-face lookup.

For the deterministic tapered fixture used by Tier 1 (`roffset=0.48 m`), the
legacy ordinary external layers are `1.1816232313e-3` and
`1.2448728114e-3 m^2`; internal layers are `1.0658919175e-3` and
`1.0009100422e-3 m^2`. The circumferential `SplitSlot` regions are both
`1.2101862080e-3 m^2`. External insulation changes those ordinary layer pack
areas to `1.1551024455e-3` and `1.1441616599e-3 m^2`.

Legacy `CoilArea` is FEMM block integral 5 at the first coil label. It therefore
means the single pack region for one layer, the first physical radial region
for ordinary multilayer slots, and the first circumferential half for
`SplitSlot`; internal/external orientation and insulation affect that physical
region. It is not the sum of layer regions. Issue #5A does not change this or
canonical `PackArea`, factory inputs, or magnetic preparation.

The result also reports node separation, segment/arc length, face closure, and
per-region boundaries. Near-threshold tests expose these metrics without
snapping or relocating any layer boundary; that correction remains gated on
Issue #5B review. `ShoeCurveControlFrac` is confirmed to alter authoritative
physical geometry but is still absent from canonical `SlottedArmature`; adding
it to canonical/factory serialization is likewise deferred to #5B.
