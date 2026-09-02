# Issue #5B: equal-area radial slot geometry

Ordinary radial dividers formerly equalised area in local `(r, theta)` construction
coordinates. The physical map has Jacobian `r`, so the mapped regions were unequal.
Production geometry now uses a bounded deterministic bisection in physical divider
radius. Each trial intersects the existing authoritative side chords, retains the
one-layer perimeter, and evaluates the resulting exact line/arc faces. The stopping
criterion is `5e-13` of total uninsulated area and the iteration cap is 80.

`LayerPartitionMode='legacy-local'` retains the Issue #5A oracle. Single-layer and
`SplitSlot` geometry bypass radial-depth bisection. The physical feature default is
`max(1e-9*radiusScale, 1000*eps(radiusScale))`; the independent snap tolerance is
twice that value. Invalid brackets fail deterministically rather than emitting a
malformed face. Diagnostics report mode, targets, achieved areas, iterations,
positions, imbalance, and minimum feature measurements.

Divider locations are defined by uninsulated geometry. Physical slot insulation is
then drawn without making the FEMM `DrawCoilInsulation` choice part of partition
policy. Canonical `LayerPackAreas` are usable post-insulation areas,
`TotalPackArea=sum(LayerPackAreas)`, and `PackArea=min(LayerPackAreas)`: one turn
specification must fit the smallest coil-side region. `ShoeCurveControlFrac` is now
canonical and defaults to the legacy value 0.5.

The Cartesian `internalslotnodelinks` algorithm is unchanged. FEMM
`blockintegral(5)` remains a discretised regression oracle, not canonical state.
Legacy `CoilArea` input is accepted for compatibility but cannot override exact
geometry. Issue #5C remains: magnetic preparation still consumes raw FEA coil-area
diagnostics and is intentionally unchanged here.
