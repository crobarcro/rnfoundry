# Issue #5B: equal-area radial slot geometry

Ordinary radial dividers formerly equalised area in local `(r, theta)` construction
coordinates. The physical map has Jacobian `r`, so mapped regions were unequal.
For an ordinary two-layer slot, production construction now bisects the physical
circular-divider radius and intersects that circle with the authoritative one-layer
side chords. The stopping criterion is `5e-13` of total uninsulated area and the
iteration cap is 80.

`LayerPartitionMode='legacy-local'` retains the Issue #5A oracle. Single-layer and
`SplitSlot` geometry bypass radial-depth bisection. Equal-area requests above two
layers are rejected explicitly rather than silently emitting legacy-local geometry;
general arbitrary-layer construction remains unsupported. The minimum physical
feature default is `max(2 um, 1e-6*radiusScale)`, separate from historical drawing
`Tol`; the default partition snap band is twice that distance. Invalid brackets fail
deterministically rather than emitting a malformed face. Diagnostics report mode,
targets, achieved areas, iterations, positions, imbalance, and minimum feature
measurements.

<<<<<<< ours
=======
Candidate acceptance is local to features created or shortened by the divider:
the two authoritative chord fragments, separation from other authoritative
boundary nodes, refreshed divider-adjacent line/arc lengths, and the divider
length. Existing unrelated small perimeter features do not become invalid merely
because the partition policy is enabled. If the ideal root enters the snap band,
bounded nearby candidates are tested and the safe candidate with the least area
error is retained. Diagnostics identify the limiting divider endpoint, chord, and
authoritative endpoint. The deterministic regression scales the established
base/body fixture by `0.0042`; its ideal divider approaches lower endpoint node 111
of authoritative chord 1-111, and the default 2 um feature/4 um snap policy moves
it to a placement with a chord fragment just over 4 um.

>>>>>>> theirs
Divider locations are solved on uninsulated geometry and then frozen when explicit
insulation geometry is constructed. Canonical `LayerPackAreas` are usable
post-insulation areas, `TotalPackArea=sum(LayerPackAreas)`, and
`PackArea=min(LayerPackAreas)`: one turn specification must fit the smallest
coil-side region. `ShoeCurveControlFrac` is canonical, defaults to 0.5 in direct and
persisted construction, and retains explicit non-default values.

Radial coil-geometry persistence version 1 accepts its historical scalar
`PackArea`. Version 2 stores all three area representations and rejects disagreement
between the scalar, per-layer vector, and total. Unrelated version-1 schemas remain
unchanged.

The Cartesian `internalslotnodelinks` algorithm is unchanged. FEMM
`blockintegral(5)` remains a discretised regression oracle, not canonical state.
Legacy `CoilArea`/`PackArea` build inputs are accepted as deprecated ignored inputs
and cannot override exact geometry. Issue #5C remains: magnetic preparation still
consumes raw FEA coil-area diagnostics and is intentionally unchanged here.

<<<<<<< ours
Construction seeds a directed boundary walk from the single known ordinary divider and integrates only the two adjacent slot-region loops with `radialslotcumulativearea`. It performs no arbitrary face discovery, polygon construction, `inpolygon`, or label assignment. Construction and the independent public analyzer share `greenareaedge` for exact line and general non-origin-centred circular-arc contributions; `radialslotregions` invokes the public analyzer only after construction.
=======
Construction seeds a directed boundary walk from the single known ordinary divider
and integrates only the two adjacent slot-region loops with
`radialslotcumulativearea`. It performs no arbitrary face discovery, polygon
construction, `inpolygon`, or label assignment. Construction and the independent
public analyzer share `greenareaedge` for exact line and general non-origin-centred
circular-arc contributions; `radialslotregions` invokes the public analyzer only
after construction.
>>>>>>> theirs
