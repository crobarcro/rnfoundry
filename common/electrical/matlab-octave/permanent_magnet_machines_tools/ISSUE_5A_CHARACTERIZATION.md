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
`2.278073900072925e-3 m^2` within numerical roundoff for one, two, and
three layers; internal totals likewise agree at approximately
`1.949103895770560e-3 m^2`.

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
the exact centre/radius/sweep integral for general circular arcs. Polygon sampling is used only for
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
face assignments have deterministic errors. Each region records its face index, closed status, and directed half-edge
count; the former structurally-zero numeric closure metric has been removed.

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

The Tier-2 area oracle covers four explicit drawing modes: external/internal
ordinary two-layer geometry with insulation off, and external/internal ordinary
two-layer geometry with insulation on. `DrawCoilInsulation` is passed
independently to both FEMM and pure geometry; it is not inferred from nonzero
canonical insulation thickness. Every layer label is checked independently
with block integral 5.

The bounded oracle calls `curvedstatorhalf2dfemmproblem` for one real slot, so
it exercises the same `radialslotgeometry` construction, internal reflection,
FEMM line/arc conversion, and physical labels as production drawing. It closes
that otherwise intentionally open drawing in a small zero-source air box and
solves it with `xfemm.femmsession`. Omitting the rotor, repeated slots, iron,
and unrelated magnetic post-processing changes neither the slot boundary nor
its block-integral area, but avoids the pathological refinement of the former
full internal-machine fixture.


## Final review characterization

Targeted fixtures prove the intended situations rather than relying only on
parameter variation: base/body and body/shoe clearances reach tens of
micrometres, sampled base/shoe node identities are explicit, and an insulated
fixture reaches a `2.47 um` boundary feature. No divider is snapped or
repositioned.

FEMM arc primitives are represented by their actual centre, radius, and signed
sweep. Most radial links are origin-centred; clipped insulation arcs need not
be. All arc endpoints are validated as co-radial about the represented arc
centre, and zero/non-finite sweeps or lengths fail deterministically. Exact
Green-theorem integration includes the general circular-arc centre term.

## Continuous MATLAB FEA execution

The repository workflow now has three independent jobs: Octave Tier 1, MATLAB
Tier 1, and required MATLAB real FEA. The FEA job uses Ubuntu 22.04 with MATLAB
R2024b, matching XFEMM's supported MEX compiler pairing. It checks out
`crobarcro/xfemm` without a ref (latest default development branch, deliberately
unpinned), prints the exact checkout SHA, builds only the session interfaces via
`mfemm_setup(..., 'SessionOnly', true)`, runs `Test_femmsession`, and then runs
all four external/internal Issue #5A area-oracle modes in fresh MATLAB
processes. The broader raw-sweep and gap-force Tier-2 tests remain
available through `run_fea_tests` for opt-in local testing, but are excluded
from this focused gate: they exercise unrelated solver parity and made failures
outside the radial-slot-area work prevent the oracle from running. An
unavailable native runtime is an Actions failure rather than a successful skip.
Separate JUnit files are uploaded together as the MATLAB FEA artifact.

Actions run `33599556435` tested XFEMM revision
`b4ab66acdfc382ae7c75e20cf8a2e40ac3533319` and passed both external modes.
The checkout deliberately remains unpinned, and every run prints the exact SHA.
Observed external relative errors were `0.01683%` and `0.01846%` without
insulation, and `0.01839%` and `0.02270%` with insulation. A local native run of
the bounded internal fixture completed in approximately `1.1 s` uninsulated
and `1.5 s` insulated, with errors of `0.01739%` / `0.01457%` and `0.01387%` /
`0.01331%`, respectively. These results support the retained `0.1%` tolerance
as a conservative FEMM boundary-discretization allowance; no mesh-convergence
precision beyond this comparison is claimed.

| Drawing mode | Layer | Analytic area (m^2) | FEMM area (m^2) | Relative error |
| --- | ---: | ---: | ---: | ---: |
| external, insulation off | 1 | `1.204389094346384e-4` | `1.204591789828378e-4` | `0.01683%` |
| external, insulation off | 2 | `1.078443473065970e-4` | `1.078244395298201e-4` | `0.01846%` |
| external, insulation on | 1 | `1.201061695305003e-4` | `1.201282606028852e-4` | `0.01839%` |
| external, insulation on | 2 | `9.502697391254811e-5` | `9.500539870493741e-5` | `0.02270%` |
| internal, insulation off | 1 | `8.549729287503225e-5` | `8.548242171855098e-5` | `0.01739%` |
| internal, insulation off | 2 | `9.939552693688153e-5` | `9.941001350274738e-5` | `0.01457%` |
| internal, insulation on | 1 | `8.543818596916147e-5` | `8.542634000718536e-5` | `0.01387%` |
| internal, insulation on | 2 | `8.454755084816541e-5` | `8.455880135472243e-5` | `0.01331%` |

The earlier full-machine internal fixture exceeded `8 GiB` during meshing. The
bounded fixture is not a synthetic replacement for slot geometry: it uses the
production single-slot drawer and changes only the unnecessary surrounding FEA
domain. The internal Actions results must still be recorded from the final run
before merge readiness is claimed.

## Near-degenerate legacy placement baseline

Deterministic characterization now reaches the tolerance-relevant regime:

- external and internal base/body cases leave `42.7 um` between a partition
  attachment and the specific authoritative chord endpoint pairs `1/111` and
  `5/112`;
- a body/shoe case leaves `34.2 um`, while a separate fixture identifies the
  sampled shoe-node pair `14/39` exactly;
- the sampled curved-base fixture identifies node pair `81/106` exactly;
- an insulated eight-layer case leaves only `2.47 um` at the explicit
  insulation-side chord pairs `114/176` and `137/192`, with the same value
  appearing as minimum node separation and straight-segment length;
- a valid shallow sixteen-layer case produces `0.672 mm` neighbouring-divider
  spacing.

These fixtures record existing legacy behavior only. Issue #5A performs no
snapping, repositioning, or minimum-clearance enforcement.
