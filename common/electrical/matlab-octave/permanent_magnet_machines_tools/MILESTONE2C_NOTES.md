# Milestone 2C implementation notes

## Legacy characterization

The radial-slotted call chain is `simfun_ROTARY` (default `NForcePoints = 4`)
→ `simfun_RADIAL_SLOTTED` → `closingforce_RADIAL_SLOTTED` →
`slottedfemmprob_radial(..., 'DrawingType', 'Full')` →
`translategroups_mfemm` → `writefemmfile` → `analyse_mfemm`/`fpproc`.
The legacy solver path is retained only as the parity oracle; the modern path
uses `xfemm.femmsession` exclusively.

The default physical displacement samples are
`[linspace(0, 0.9*g, 3), 0.95*g]`, i.e. `[0, .45g, .9g, .95g]` for the
four-point default. They are metres of absolute eccentric translation of the
field assembly (magnet and field back iron) in negative global x, not angular
position, fractional displacement, or uniform air-gap change. Values must be
nonnegative and strictly smaller than `g`. Both internal- and external-field
geometries use this same global translation. A full FEM geometry is rebuilt
for every displacement; no AGE state is involved and no problem/session is
safely reused between samples.

After selecting the translated magnet and field-back-iron blocks, legacy uses
the absolute value of planar force block integral 18 (global x force). Because
the problem is a full-machine drawing whose depth is `ls`, each sample is a
positive closing-force magnitude in newtons for the complete machine, already
stack-length scaled—not a per-pole or per-unit-depth value. Integral 19 is not
used. `simfun_RADIAL_SLOTTED` then prepends an artificial `(0 m, 0 N)` point,
even though the default physical sweep itself also solves displacement zero.
`finfun_AM` fits those stored vectors with `polyfitn`: quadratic when there are
more than two stored points, otherwise linear. There is no normalization,
clipping, or zero special case in `polyvaln`; structural consumers evaluate at
`g`, beyond the default `.95g` sampled endpoint.

`MagneticSweepResult.PerPoleRadialForce` is different: at the nominal angular
sweep's first solve, integrals 18 and 19 are projected onto a radial unit
vector and divided by the number of drawn poles. It maps neither to a raw
variable-gap sample nor to the artificial origin, and remains unchanged.
Legacy `PerPoleAirGapClosingForce` is therefore represented by that existing
nominal magnetic observation, while `RadialGapForceModel.evaluate` represents
the separately fitted full-machine eccentric-force curve.

`finfun_RADIAL_SLOTTED` derives `ForcePerAreaToothSurface` from the nominal
per-pole force times pole count divided by cylindrical tooth-facing area
(`Ra * 2*pi*(1-thetasg/thetas) * ls`). It is consumed by later reporting and
structural/loss-era workflows, not used to construct or evaluate the variable
gap polynomial. It is deliberately deferred rather than duplicated in the
2C model; callers can derive it later from nominal magnetic force and canonical
geometry without mutable prepared state.

## Modern boundaries

`RadialGapForceSweepResult` stores aligned column vectors `Displacements` and
`ClosingForce` plus provenance. `runRadialSlottedGapForceSweep` accepts only
the optional explicit `Displacements` vector, otherwise uses the legacy grid.
It rebuilds a full problem and owns a fresh `XFemmSessionAnalysis` per sample.

`prepareRadialSlottedGapForceModel` is pure, prepends the legacy artificial
origin and performs the exact quadratic `polyfitn`. `RadialGapForceModel`
stores that polynomial and the sampled domain; `evaluate` accepts finite real
scalar or array metres, preserves shape, returns full-machine newtons, and
intentionally extrapolates through `polyvaln`. `PreparedMachineModel` retains
its magnetic-only constructor and can compose this value model through an
optional third constructor input or `withGapForce`.

Inductance, losses, mass, ODE simulation, Issue #5, linear machines, parallel
FEA, and MEX work remain outside this milestone.
