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
