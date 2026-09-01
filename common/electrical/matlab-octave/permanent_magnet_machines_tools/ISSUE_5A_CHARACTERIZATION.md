# Issue #5A radial slot-area characterization

`internalslotnodelinks` partitions ordinary layers by area in its local
Cartesian coordinates. That remains correct and unchanged for linear-machine
callers. The radial drawing interprets local `x` as radial displacement and
local `y` as angle, so its `pol2cart` map has a radius-dependent Jacobian.
Ordinary physical layer areas therefore remain unequal; changing their
placement to target equal physical area is deferred to Issue #5B.

## Layer-count-dependent perimeter defect and correction

The first #5A implementation exposed a second radial-only defect. When a legacy
layer divider fell in the straight local slot body, `internalslotnodelinks`
inserted its endpoints into the local side lines. This is harmless in Cartesian
geometry. After radial mapping, however, the inserted point and the two original
endpoints are not generally collinear. Drawing two FEMM chords through that
point changed the physical outer perimeter compared with the single chord used
by a one-layer slot.

For the tapered uninsulated fixture, the previous totals were:

- external: one layer `2.42037241591124e-3 m^2`, two layers
  `2.42649604267317e-3 m^2` (`+0.25%`);
- internal: one layer `2.07291625406635e-3 m^2`, two layers
  `2.06680195968585e-3 m^2` (`-0.30%`).

`radialslotregions` now constructs an authoritative one-layer physical boundary
independently of ordinary partition count. A newly created divider endpoint is
identified from its existing local topology and attached to the corresponding
fixed physical chord. Splitting that chord adds no bend and changes no enclosed
area. No extra perimeter points are introduced beyond the divider endpoints
already created by the legacy algorithm.

After correction, the same external fixture has totals
`2.420372415911237e-3`, `2.420372415911239e-3`, and
`2.420372415911239e-3 m^2` for one, two, and three layers. The internal totals
are respectively `2.072916254066352e-3`, `2.072916254066354e-3`, and
`2.072916254066354e-3 m^2`. With `0.6 mm` insulation, external totals are
`2.278073917524149e-3`, `2.278073917524149e-3`, and
`2.278073917524146e-3 m^2`; internal totals agree at approximately
`1.949103878319335e-3 m^2`.

The ordinary two-layer areas are still deliberately unequal: external
`1.178404114275779e-3` and `1.241968301635460e-3 m^2`; internal
`1.069027610527237e-3` and `1.003888643539117e-3 m^2`. Thus the fixed invariant
is `sum(LayerPackAreas) == single-layer TotalPackArea`, not equal layers.
`SplitSlot` remains circumferentially symmetric and uses the same perimeter.

## Geometry and legacy semantics

The solver-free kernel consumes the nodes, links, labels, insulation topology,
and `vertlinkinds` produced by `internalslotnodelinks`, then performs the same
orientation, offset, and radial mapping as the FEMM drawing. Areas use Green's
theorem over actual FEMM primitives: Cartesian cross products for segments and
`r^2*dtheta/2` for origin-centred arcs. Polygon sampling is used only for
label-to-face lookup.

Legacy `CoilArea` is FEMM block integral 5 at the first coil label. It means the
single pack region for one layer, the first physical radial region for ordinary
multilayer slots, and the first circumferential half for `SplitSlot`; it is not
the sum of layers. This work does not change canonical `PackArea`, factory
inputs, magnetic preparation, or legacy local layer-position selection.

## Construction and analysis boundary

The pure API is deliberately split:

1. `radialslotgeometry` constructs the fixed-perimeter physical drawing,
   segment/arc primitives, and labels. This is the only kernel consumed by the
   production FEMM drawing.
2. `analyzeRadialSlotRegions` traces and validates faces, associates each coil
   label with one distinct face, and integrates its exact primitive area.
3. `radialslotregions` is the convenience composition of those two operations.

Consequently a new face-analysis diagnostic cannot prevent an otherwise valid
legacy FEMM geometry from being drawn.

Coordinate-frame fields are explicit. `Local*` fields are the untouched
Cartesian-style legacy output (`x` length-like, `y` dimensionless/angle-like in
the radial interpretation). `MappedRadial*` records the oriented and
radius-offset candidate mapping. `Radial*` is the actual `[radius, angle]`
representation of final physical geometry, including fixed-chord attachment,
and unqualified `Nodes`/label locations are physical Cartesian coordinates.
`LegacySlotInfo` is untouched local metadata; `SlotInfo` contains physical
label locations for drawing consumers.

Face closure is validated from the directed half-edge walk and consecutive
edge-node identities before a polygon is closed for point containment. Open or
malformed edges, ambiguous assignments, missing faces, and duplicate label-to-
face assignments have deterministic errors. Each region records its face index,
closed status, and measured boundary connection error.

## Tolerance and minimum-feature characterization

The geometry reports separate physical minima for node separation, straight
segments, arcs, partition arcs, and the perimeter pieces adjacent to attached
dividers. In the tapered fixtures, sampled boundary segments are approximately
`1.01e-4` to `1.15e-4 m`, divider arcs exceed `4.2e-2 m`, and the densest tested
six-layer/perimeter case leaves a `1.73e-3 m` adjacent boundary piece. These are
characterization baselines, not new snapping or acceptance rules.

The legacy scalar `Tol` is dimensionally imperfect for radial use: local `x` is
length-like while local `y` becomes an angle, so one numerical tolerance cannot
represent a uniform physical Cartesian feature size after radius-dependent
mapping. Issue #5A records physical metrics but deliberately leaves tolerance
redesign, snapping, and physical minimum-feature enforcement to Issue #5B.

## FEMM oracle

The opt-in Tier-2 test `test_radial_slot_region_area_parity` runs the ordinary
internal and external two-layer fixtures through `xfemm.femmsession`, evaluates
block integral 5 at every layer label, and compares every result with the pure
Green-theorem area. Its `0.1%` relative tolerance permits normal boundary-mesh
convergence while remaining tighter than the original `0.25--0.30%`
layer-count perimeter defect. Tier 1 remains solver-free.
