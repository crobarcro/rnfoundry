# Milestone 2A implementation notes

The modern call path is `runRadialSlottedMagneticSweep` →
`slottedfemmprob_radial` → `writefemmfile` → `xfemm.femmsession`.  The first
solve creates the drawing and session.  Every position, including the first,
is sent through `SlidingMeshPositioner`; circuit currents are set and the same
owned session is solved again.  Raw circuit linkage, torque, tooth and air-gap
field samples, slot A/B integrals, and first-solve area/force observations are
returned in `MagneticSweepResult`.

The legacy oracle follows `simfun_RADIAL_SLOTTED` → `feasim_RADIAL_SLOTTED` →
`slottedfemmprob_radial`/`writefemmfile` → `xfemm.femmsession`, then reuses the
returned session with AGE updates.  Its extraction path uses
`slotintAdata_RADIAL_SLOTTED`, a local slot-B integral implementation, direct
`getcircuitprops`, block integral 22 for torque, and initial block integrals for
coil/iron areas and radial force.  Core-loss setup is intentionally deferred.

## PackArea seam

The drawing kernel creates curved, multi-section coil regions as part of the
stator drawing and exposes only interior label locations, not a pure boundary
polygon or exact area kernel.  No existing pure rnfoundry/mfemm helper was
found that returns that region's exact area.  Consequently 2A does not weaken
the canonical invariant: `SlottedPMMachine` still requires an explicit exact
`CoilGeometry.PackArea`.  The sweep accepts that approved canonical physical
input and independently records FEMM's block-integral `CoilArea`, allowing the
two values to be checked.  Extracting a shared deterministic curved-slot area
kernel is therefore an unresolved pre-canonical preparation boundary and is
not disguised with `Hc*Wc`, a placeholder, or post-FEA machine mutation.

No fitted/prepared magnetic models, core-loss preparation, inductance,
gap-displacement, mass, ODE, evaluation, or linear-machine work is included.
