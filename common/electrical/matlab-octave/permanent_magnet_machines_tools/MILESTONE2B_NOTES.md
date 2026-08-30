# Milestone 2B implementation notes

`prepareRadialSlottedMagneticModel(machine, rawSweep)` is the pure boundary
from a canonical radial-slotted machine and an already completed
`MagneticSweepResult` to a `PreparedMachineModel`. It performs no drawing,
solving, session creation, or further FEA, and neither input is mutated.

The prepared flux-linkage source is `SlotVectorPotential`, not
`DirectFluxLinkage`. The 2A `[sweep, slot, layer, component]` arrays are mapped
back to the legacy sweep-block ordering without collapsing layers. Positions
are sorted and made unique, the two-pole domain endpoint is interpolated when
needed, and the distinct one- and two-layer SLM paths are retained. The legacy
coil pitch, 1,000-point FEA peak search (including first-index tie behaviour),
200-point offset lookup, and final periodic SLM fit are preserved.
`DirectFluxLinkage` remains a raw diagnostic.

The SLM kernels (`slmengine`, `slmeval`, `periodicslmeval`, `slmpar`) and
`fluxlinkagefrmintAslm` remain the numerical backend. Public evaluation uses
normalized position measured in pole spans and has period two. Flux skew uses
the legacy `simfun_AM` default of ten sections over the canonical
`Field.MagnetSkew` extent. Cogging preparation retains the legacy two-stage
fit, stack-length normalization/rescaling, and the same ten-section skew
average across `[-skew/2,+skew/2]`.

Flux reconstruction deliberately uses the FEA-observed `rawSweep.CoilArea`.
It does not substitute or overwrite canonical
`Winding.CoilGeometry.PackArea`; exact pre-FEA pack geometry remains deferred
by Issue #5. Prepared-model persistence is also deferred rather than encoding
SLM class/struct internals in a premature portable format.

`PreparedMachineModel` contains the unchanged canonical `Machine` and a
`PreparedMagneticModel` with flux-linkage and cogging-torque models. Circuit,
loss, gap-force, mass-property, and diagnostic sections remain empty. Gap-force
characterization, inductance, core loss, external-field winding eddy loss,
mass properties, ODE simulation, evaluation, linear machines, parallel FEA,
and all later Milestone 2 work are outside this sub-stage.
