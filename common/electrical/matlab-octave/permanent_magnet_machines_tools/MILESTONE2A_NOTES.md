# Milestone 2A implementation notes

The modern call path is `runRadialSlottedMagneticSweep` →
`slottedfemmprob_radial` → `writefemmfile` → `xfemm.femmsession`.  The first
solve creates the drawing and session. The generic owner has no AGE or winding
policy: `SlidingMeshPositioner` applies AGE positions directly to the owned
session, while the sweep sets zero current using the names in the drawn circuit
definitions. The same owned session is solved again at every position. Raw
circuit linkage, cogging torque, tooth and air-gap
field samples, slot A/B integrals, and first-solve area/force observations are
returned in `MagneticSweepResult`.

The legacy preparation path follows `simfun_RADIAL_SLOTTED` → `feasim_RADIAL_SLOTTED` →
`slottedfemmprob_radial`/`writefemmfile` → `xfemm.femmsession`, then reuses the
returned session with AGE updates.  Its extraction path uses
`slotintAdata_RADIAL_SLOTTED`, a local slot-B integral implementation, direct
`getcircuitprops`, block integral 22 for torque, and initial block integrals for
coil/iron areas and radial force.  Core-loss setup is intentionally deferred.

`RadialPMField` owns the physical `MagnetPolarisation` definition (`constant`
or `radial`), with backward-compatible `constant` defaulting. The background
medium is not field-component state: `AirGapMaterial` belongs to sweep
preparation, defaults to the mfemm library material `Air`, and is added only to
the temporary drawing structure. The main 2A operation is intentionally a
zero-current PM-flux/cogging sweep; nonzero `PhaseCurrents` are rejected.

`resolveMagneticSweepOptions` is a pure boundary which reproduces the defaults
established by `simfun_ROTARY`, `simfun_RADIAL`, and the slotted preparation
path before applying caller overrides. This includes the legacy yoke formula
using `max(thetac)` and two-element outer-region mesh semantics ending in `-1`.

External and internal real-femmsession parity tests live under
`tests/fea/radial_slotted` and use `feasim_RADIAL_SLOTTED` with femmsession and
sliding mesh as the oracle. They compare raw observations and machine
immutability, but are opt-in because no solver is installed in Tier-1 CI.
`run_fea_tests` reports them skipped/unavailable unless explicitly enabled;
no real parity pass is claimed by this document.

## PackArea seam

The drawing kernel creates curved, multi-section coil regions as part of the
stator drawing and exposes only interior label locations, not a pure boundary
polygon or exact area kernel.  No existing pure rnfoundry/mfemm helper was
found that returns that region's exact area.  Consequently 2A does not weaken
the canonical invariant: `SlottedPMMachine` still requires an explicit exact
`CoilGeometry.PackArea`.  The sweep accepts that approved canonical physical
input and independently records FEMM's block-integral `CoilArea`, allowing the
two values to be checked.  Extracting a shared deterministic curved-slot area
kernel is therefore an unresolved pre-canonical preparation boundary tracked
by repository Issue #5 and is
not disguised with `Hc*Wc`, a placeholder, or post-FEA machine mutation.

No fitted/prepared magnetic models, core-loss preparation, inductance,
gap-displacement, mass, ODE, evaluation, or linear-machine work is included.
