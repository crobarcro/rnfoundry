# rnfoundry Electrical Machines Toolbox — `classdef` Refactor Plan

## 1. Purpose

This document defines the architecture and staged migration plan for refactoring the electrical machines toolbox in `crobarcro/rnfoundry`, focused on:

```text
common/electrical/matlab-octave/permanent_magnet_machines_tools
```

The existing toolbox is conceptually object-oriented but is implemented primarily through function hierarchies plus evolving `design` and `simoptions` structs. The aim of this refactor is to introduce a clearer `classdef`-based domain model while retaining:

- MATLAB compatibility;
- GNU Octave compatibility;
- the existing numerical algorithms and engineering notation;
- the current legacy implementation for comparison and regression testing;
- current optimisation behaviour, including deterministic design-repair logic;
- current FEA behaviour where intentionally retained;
- existing pure numerical kernels where classes add no value.

This document is the architectural source of truth for the refactor. Implementation work should be performed milestone-by-milestone. Codex or other coding agents should read this document in full before modifying code.

---

## 2. Scope and guiding principles

### 2.1 Namespace

All new code for this refactor should live under:

```text
+rnfoundry/+em/
```

The existing global-namespace toolbox remains in place during migration.

Do **not** move the existing implementation into a `+legacy` package as an initial step. The legacy tree should remain directly runnable so that new classes can be compared against it throughout the migration.

### 2.2 Preserve the existing implementation as the behavioural baseline

The refactor is not a rewrite of the electrical-machine theory. Where behaviour is already implemented and used, the initial migration target is numerical and semantic parity.

This is particularly important for:

- winding completion;
- radial-slotted geometry completion;
- optimisation chromosome decoding and repair;
- mean-turn-length calculations;
- conductor sizing and packing;
- resistance calculations;
- winding external-field eddy-current loss models;
- FEA-derived preparation data;
- cogging-torque handling;
- simulation lifecycle behaviour.

Any deliberate behavioural changes should be made only after the equivalent legacy behaviour is frozen by tests and the change is separately justified.

### 2.3 Shallow inheritance, composition first

Use only a shallow machine inheritance hierarchy:

```text
Machine
├── LinearMachine
└── RotaryMachine
```

Concrete machine types should derive from one of these without reproducing the full legacy folder/function hierarchy through inheritance.

The legacy hierarchy expresses two different concepts:

1. machine taxonomy, e.g. `AM -> ROTARY -> RADIAL -> RADIAL_SLOTTED`;
2. workflow roles, e.g. `completedesign_*`, `simfun_*`, `finfun_*`, `resfun_*`, `designandevaluate_*`.

Only the first maps naturally to inheritance. The second should be represented by composition, service objects, or ordinary functions.

### 2.4 Prefer value classes for physical definitions

Physical machine definitions, materials, options, design candidates, and prepared result data should normally be value classes.

Use handle classes only for identity/resource-owning objects, for example:

- an open `xfemm.femmsession`;
- a live FEA analysis session;
- another external resource whose lifetime must be managed.

The physical `Machine` object itself must not be a handle class.

### 2.5 Keep pure numerical kernels as functions

Do not convert a function into a class method merely because a class exists.

Functions that are mathematically self-contained and naturally reusable should remain functions, especially:

- geometry kernels;
- packing calculations;
- MTL calculations;
- interpolation/fitting kernels;
- resistance formulas;
- loss formulas;
- coordinate transforms;
- numerical repair helpers.

Classes should organise state, invariants, ownership, and domain meaning.

### 2.6 Conservative MATLAB/Octave `classdef` subset

The new API must remain compatible with GNU Octave as well as MATLAB.

Prefer:

- ordinary `classdef`;
- simple properties;
- simple methods;
- ordinary inheritance;
- static factory methods;
- `Dependent` properties only where Octave compatibility is verified;
- value semantics by default.

Avoid initially:

- `arguments` blocks;
- property validation syntax;
- events/listeners;
- enumeration classes;
- heavy reflection/meta-programming;
- advanced MATLAB-only class features.

Where a `Dependent` property is not robust enough across supported Octave versions, provide an ordinary query method instead rather than duplicating canonical state.

---

## 3. Architectural model

The target physical model is based on separate electromagnetic roles rather than mechanical motion roles.

For the first migrated machine family, the radial-flux slotted permanent-magnet machine, the conceptual structure is:

```text
SlottedPMMachine < RotaryMachine
│
├── Field : RadialPMField
│   ├── magnet geometry
│   ├── back-iron geometry
│   ├── MagnetMaterial
│   ├── BackIronMaterial
│   └── magnet arrangement / skew
│
├── Armature : SlottedArmature
│   ├── Position: 'internal' | 'external'
│   ├── slotted iron geometry
│   ├── IronMaterial
│   └── Winding
│       ├── winding layout/topology
│       ├── conductor
│       ├── turns / coils / branches
│       └── coil geometry
│
├── g
├── ls
└── derived ratios and assembled-machine quantities
```

### 3.1 `Field` and `Armature` naming is deliberate

Use `Field` and `Armature`, not `Rotor` and `Stator`, as the electromagnetic component names.

`Rotor` and `Stator` describe mechanical motion. `Field` and `Armature` describe electromagnetic function. A PM field is not intrinsically required to be the moving member.

Do not rename these properties to `Rotor` or `Stator` during implementation.

### 3.2 Armature position

For the radial-slotted family, the armature should contain:

```matlab
Armature.Position
```

with allowed values:

```text
'internal'
'external'
```

This is pragmatically stored on the armature even though the notion is relational between field and armature.

The assembled machine constructor or factory must validate that the field and armature geometry are mutually consistent.

### 3.3 Materials belong to components

Do not make an authoritative monolithic `Machine.MaterialSet` the primary owner of materials.

Preferred ownership:

```text
Field
├── MagnetMaterial
└── BackIronMaterial

Armature
├── IronMaterial
└── Winding
    └── Conductor
        └── Material
```

A convenience machine-level aggregation accessor such as `materials()` may be added later for reporting, but the components remain authoritative.

---

## 4. Engineering notation and naming conventions

### 4.1 Preserve compact physical dimension notation

Compact symbols such as:

```text
Ryi Ryo Rym
Rci Rco Rcm
Rtsb Rtsg
Rai Rao
Rcb
tc tcb
ty tsb tsg
thetas thetasg
thetacg thetacy
```

are deliberate engineering notation and should remain public names where they directly represent physical dimensions.

Do **not** systematically replace them with verbose names such as `ArmatureYokeInnerRadius`.

The compact conventions carry meaning:

- `R` = radial distance from origin;
- `t` = radial thickness;
- `theta` = angular arc measurement;
- `tau` = swept linear distance corresponding to angular extent.

They also map naturally into engineering diagrams and the existing report notation.

### 4.2 Replace overloaded vector fields when they represent distinct physical quantities

The existing radial-slotted representation overloads:

```matlab
design.tc(1)
design.tc(2)
```

These must become separate physical properties without changing the underlying two-stage slot-side geometry:

```matlab
armature.tc
armature.tcb
```

The ratio becomes:

```matlab
armature.tcbVtc
```

`Rcb` remains a derived radius.

This migration is a representation cleanup only. It must **not** simplify or remove the two-section slot geometry because that geometry is important to robust optimisation.

### 4.3 Orientation-neutral armature air-gap radius

On `SlottedArmature`, introduce:

```matlab
armature.Ra
```

meaning the radial location of the armature air-gap-facing surface.

`Armature.Position` determines whether this corresponds to legacy `Rai` or `Rao`.

Legacy adapters must map `Ra` back to the expected orientation-specific field.

Keep `Ryi/Ryo`, `Rmi/Rmo`, etc. where inner and outer surfaces are genuinely meaningful physical surfaces.

### 4.4 Pole-span common interface

Replace the common cross-topology concept currently named `PoleWidth` with:

```matlab
machine.PoleSpan
```

Meaning: physical extent of one magnetic pole along the machine motion coordinate.

Examples:

```matlab
linearMachine.PoleSpan   % metres
rotaryMachine.PoleSpan   % radians
```

Machine-specific quantities should still exist where useful:

```matlab
rotaryMachine.thetap
```

`PoleSpan` is the common interface concept, not a replacement for all machine-specific engineering symbols.

Legacy adapters may expose `PoleWidth` for compatibility.

Common operations may be exposed as methods such as:

```matlab
machine.normalizedPosition(q)
machine.electricalFrequency(speed)
```

but numerical kernels may remain ordinary functions.

---

## 5. Canonical state, derived state, and construction state

A central design rule is that the same quantity may legitimately have different status in different stages of the workflow.

### 5.1 Canonical machine state

The finished machine should contain only mutually consistent physical state.

Derived quantities should not normally be independently writable if they can contradict canonical dimensions.

### 5.2 Ratios

Dimensionless ratios are important engineering information and must always remain readily available.

However, they should not be duplicated as independently mutable canonical state on the finished machine.

Preferred implementation:

- `Dependent` properties if MATLAB/Octave compatibility is satisfactory;
- otherwise ordinary query methods;
- legacy export should reproduce expected ratio fields.

Compact legacy ratio names may be retained, for example:

```text
RmiVRmo
RyiVRyo
thetamVthetap
thetacgVthetas
```

Some ratios span `Field` and `Armature`; those can be machine-level derived quantities.

Ratios serve three distinct roles:

1. human-readable engineering information;
2. optimisation variables;
3. construction parameterisation.

The optimisation/design-candidate representation may therefore store ratios independently even though the canonical machine derives them.

### 5.3 Air gap `g`

This same distinction applies to air gap.

In optimisation/design-space form:

```matlab
candidate.g
```

is an independent variable.

During build/repair, `g` determines relative placement of field and armature.

On the canonical assembled machine:

```matlab
machine.g
```

must be derived from the final air-gap-facing surfaces of `Field` and `Armature`.

Do not store canonical `g` independently if that permits contradiction with component radii.

### 5.4 Stack length `ls`

`ls` remains ordinary canonical machine-level state:

```matlab
machine.ls
```

It represents the common active axial/stack length of the assembled machine and does not belong exclusively to either field or armature.

---

## 6. Core class contracts

The exact file layout may be adjusted slightly for package ergonomics, but the responsibilities and public semantics in this section are authoritative.

## 6.1 `rnfoundry.em.Machine`

### Purpose

Base value class for all electromagnetic machine definitions.

### Responsibilities

- common physical-machine interface;
- common pole-span interface;
- shared validation entry point;
- serialization hooks where genuinely common;
- no simulation state;
- no FEA session state;
- no optimisation candidate state.

### Public API concepts

```matlab
PoleSpan
validate()
toStruct()
```

Potential common methods:

```matlab
normalizedPosition(q)
electricalFrequency(speed)
```

### Non-responsibilities

- workflow orchestration;
- mutable simulation state;
- FEA sessions;
- optimisation repair;
- load models;
- result storage.

---

## 6.2 `rnfoundry.em.LinearMachine < Machine`

### Purpose

Common base for linear machines.

### Responsibilities

- define linear interpretation of motion coordinate and `PoleSpan`;
- host only genuinely common linear-machine behaviour.

Do not reproduce legacy `linear_machines` folder depth through inheritance.

---

## 6.3 `rnfoundry.em.RotaryMachine < Machine`

### Purpose

Common base for rotary machines.

### Responsibilities

- define angular interpretation of motion coordinate and `PoleSpan`;
- expose common rotary quantities such as `thetap` where appropriate;
- host only genuinely common rotary-machine behaviour.

---

## 6.4 `RadialPMField`

Suggested package:

```text
+rnfoundry/+em/+rotary/+radial/
```

### Purpose

Canonical value object describing the PM field component of a radial-flux machine.

### Stored physical properties

Initial implementation should represent at least:

```matlab
Rmi
Rmo
% back-iron surface radius/radii appropriate to orientation
% magnet angular dimensions
% magnet arrangement/skew data
MagnetMaterial
BackIronMaterial
```

Use compact established radial notation.

### Derived/query properties

Examples:

```matlab
Rmm
MagnetThickness
% orientation-specific or geometry-derived back-iron thickness
```

Do not store the machine air gap here.

### Validation

Validate internal self-consistency only. Mutual field/armature gap consistency belongs to the assembled machine.

---

## 6.5 `SlottedArmature`

Suggested package:

```text
+rnfoundry/+em/+rotary/+radial/
```

### Purpose

Canonical value object describing the slotted radial armature.

### Stored physical properties

At minimum:

```matlab
Position      % 'internal' | 'external'
Ryi
Ryo
Rtsb
Rtsg
Ra
tc
tcb
ty
tsb
tsg
thetas
thetasg
thetacg
thetacy
IronMaterial
Winding
```

Not every property above must be independently stored if one is always a deterministic derivative of a smaller canonical set; implementation should minimise contradictory state while keeping compact query access.

### Derived/query properties

Examples:

```matlab
Rym
Rcm
Rcb
thetac       % compatibility/query representation [thetacg thetacy]
tcbVtc
```

### Ownership

The armature owns its `Winding`.

### Validation

Validate:

- allowed `Position` values;
- radial surface ordering;
- non-negative dimensions;
- slot geometry feasibility where this is an intrinsic armature property;
- winding/slot relationship where canonical construction requires it.

Optimisation repair rules do **not** belong here. Invalid optimisation candidates should be repaired before building a canonical armature.

---

## 6.6 `Winding`

### Purpose

Canonical physical winding definition, including electromagnetic layout, conductor construction, connection topology, and resolved coil geometry.

### Stored properties

The initial implementation should cover concepts equivalent to the legacy common winding fields:

```text
PhaseCount
PoleCount or access to machine pole count as appropriate
LayerCount
CoilCount
CoilsPerPolePerPhase
BasicCoilCount
BasicPoleCount
BasicWindingRepetitions
SlotCount
BasicSlotCount
CoilPitchSlots
AverageCoilPitch
SlotsPerPole
CoilsPerPhase
ParallelBranches
Layout
Conductor
CoilGeometry
```

Compact fraction-based legacy quantities such as `qc`, `qcn`, `qcd`, `ypn`, `ypd` may be retained as derived/query compatibility information where useful.

Do not force every legacy field to become an independently stored modern property.

### Derived/query properties

At minimum consider:

```matlab
MeanTurnLength
TurnPathLengthPerCoil
TotalTurnPathLength
TotalStrandLength
CopperVolume
CoilsPerBranch
PackingFactor
CopperFillFactor
```

Definitions must distinguish electrical path length from physical material length.

For a stranded turn:

- one turn has one electrical path around the coil;
- multiple physical strands contribute multiple strand lengths and copper volume.

### Ownership

`Winding` owns:

```matlab
Conductor
CoilGeometry
```

### Non-responsibilities

- machine FEA;
- external load models;
- optimisation repair;
- temperature/frequency simulation state;
- fitted external-field loss models.

---

## 6.7 `RoundWireConductor`

### Purpose

Initial canonical conductor implementation for ordinary round wire, including multi-strand turns.

The first milestone must support the current `NStrands` behaviour. Do not defer ordinary stranded-wire support.

### Stored physical properties

```matlab
Material
StrandCount
StrandDiameter
Insulation
```

The insulation representation can initially be simple provided it can reproduce current insulated-wire diameter behaviour.

### Derived/query properties

```matlab
CopperAreaPerStrand
CopperAreaPerTurn
EquivalentCopperDiameter
InsulatedStrandDiameter
OccupiedAreaPerTurn
```

`EquivalentCopperDiameter` should map to the legacy meaning of `Dc`: the diameter of a single round conductor having the same total copper cross-sectional area as all parallel strands in one turn.

`StrandDiameter` maps to legacy `WireStrandDiameter`.

### Intrinsic electrical methods

Appropriate conductor-level operations may include:

```matlab
dcResistancePerLength(T)
skinEffectResistanceFactor(f, T)
```

or equivalent pure functions consuming a conductor object.

Do not make conductor methods responsible for whole-winding proximity loss or external-field eddy loss because those depend on winding placement and/or field data.

### Future conductor types

The API should not block later addition of:

```text
RectangularWireConductor
LitzWireConductor
RibbonConductor
```

Existing `wireresistancedc` support for round, square and rectangular cross-sections demonstrates a real future need.

Do not model ordinary `NStrands > 1` as litz wire. Litz requires additional construction and AC-behaviour information.

---

## 6.8 `CoilGeometry`

### Decision

Use the term `CoilGeometry`, not `CoilPath`, for the main abstraction.

The existing mean-turn-length calculations encode winding-pack geometry and rounded end/corner assumptions, not merely a centreline path.

### Purpose

Resolved geometrical description of one coil shape as installed in its armature context.

### Initial radial-slotted implementation

A type such as:

```text
RadialSlottedCoilGeometry
```

should provide at least:

```matlab
PackArea
MeanTurnLength
ActiveSegmentLengths
```

and any shape dimensions necessary for reproducibility/serialization.

### `MeanTurnLength`

For radial-slotted parity, reproduce the existing `coilresistance_RADIAL_SLOTTED` behaviour, which computes MTL from:

- `ls`;
- coil pitch `yd * thetas * Rcm` plus the existing extra-length term;
- mean slot angular extent converted at `Rcm`;
- the current rectangular/trapezoidal MTL kernels.

Do not silently substitute a new geometric approximation in Milestone 1A.

### `ActiveSegmentLengths`

This is intentionally distinct from MTL.

The existing external-field winding eddy-current model uses the conductor length interacting with the sampled magnetic field, which for current radial/flat implementations is not necessarily the entire mean turn length.

The geometry object should therefore be capable of reporting lengths relevant to prepared loss models.

### Avoid object cycles

`CoilGeometry` should not retain a back-reference to `Armature`.

The machine/armature builder should resolve the needed geometry and construct a standalone value object.

---

## 7. Winding packing and conductor sizing

### 7.1 Packing is a construction calculation, not a conductor responsibility

The current functions `checkcoilprops_AM`, `CoilTurns`, `ConductorDiameter`, `stranddiameter`, `equivDcfromstranded`, and `conductord2wired` jointly solve a relationship between:

```text
available coil area
+ conductor construction
+ insulation
+ number of turns
+ strand count
+ packing/fill assumption
```

Do not hide this inside `RoundWireConductor`.

### 7.2 Introduce a deterministic pure packing kernel

Preferred conceptual API:

```matlab
resolved = rnfoundry.em.winding.resolvePacking(spec, coilGeometry);
```

Exact naming may vary slightly, but it should remain a pure deterministic function or small functional module rather than a stateful service.

The input specification must support the existing alternative partial inputs, including at least:

1. equivalent conductor diameter + packing factor -> determine turns;
2. turns + packing factor -> determine conductor diameter;
3. conductor diameter + turns -> determine packing factor;
4. explicit strand diameter + strand count + turns -> determine equivalent conductor diameter.

### 7.3 Preserve legacy semantics first

The current `CoilFillFactor` behaviour is semantically ambiguous: comments call it copper fill factor, but the sizing functions use insulated outside wire area when enforcing it.

In the new API:

- preserve legacy numerical behaviour for parity;
- prefer naming the construction quantity `PackingFactor`;
- optionally expose a conventional `CopperFillFactor` separately as actual copper area divided by pack area.

Do not silently reinterpret the legacy value during migration.

### 7.4 Insulation diameter relation

Centralise the current conductor-diameter to insulated-wire-diameter behaviour so it is implemented once in the modern path.

The legacy implementation currently duplicates this relationship in more than one place.

The new implementation should preserve the current piecewise polynomial/power-fit behaviour unless separately changed after parity is established.

### 7.5 Characterisation target

`checkcoilprops_AM` is the behavioural reference for initial modern packing logic.

Characterization tests should freeze its supported input modes before replacing them with the new kernel.

---

## 8. Circuit and resistance model

### 8.1 Separation of responsibilities

Use the following conceptual split:

```text
Conductor
    intrinsic geometry/material electrical behaviour

Winding
    turns, coil lengths, number of coils, branches, topology

CircuitModel
    coil/phase terminal resistance and inductance behaviour
```

### 8.2 DC resistance

The canonical physical winding should not store an authoritative mutable `CoilResistance` field.

Reference DC values can be derived from:

```text
conductor resistivity
× electrical path length
÷ conductive area
× winding topology
```

Prepared or convenience values may be exposed as:

```matlab
model.Circuit.ReferenceDCCoilResistance
model.Circuit.ReferenceDCPhaseResistance
```

### 8.3 Temperature dependence

Temperature-dependent resistivity belongs to the conductor/material electrical model and simulation scenario, not as mutated physical machine state.

Equivalent functionality to legacy `machineodesim_common_AM` should eventually be expressed through circuit-model evaluation.

### 8.4 Skin effect

The current round-wire frequency-dependent resistance model should be preserved as the initial round-wire skin-effect implementation.

It is intrinsically tied to:

- strand radius;
- material resistivity;
- permeability;
- frequency.

It may live as a conductor method or pure numerical function.

### 8.5 External-field winding eddy-current loss

This is distinct from resistance skin effect.

The current `makesfdeddyslm`/`lossforces_AM` path builds a position-dependent model from:

- FEA-derived field histories;
- conductor/strand diameter;
- turns;
- strand count;
- active conductor length;
- material resistivity.

The prepared-model destination should use an explicit name such as:

```matlab
PreparedMachineModel.Losses.WindingExternalFieldEddyCurrentLossModel
```

Conceptual contract:

```text
WindingExternalFieldEddyCurrentLossModel
    Fit
    FitMethod
    evaluate(position, speed)
```

The current backend may still be SLM.

### 8.6 Proximity loss

`roundwireproximityloss.m` is currently unfinished and deliberately errors.

Therefore:

- reserve an architectural extension point;
- do not claim proximity-loss parity;
- do not include proximity-loss implementation in Milestone 1A, 1B, or 2;
- do not create tests that imply it currently works.

---

## 9. Assembled radial-slotted machine contract

## 9.1 `SlottedPMMachine < RotaryMachine`

### Purpose

Canonical assembled radial-flux slotted PM machine.

### Stored properties

```matlab
Field
Armature
ls
```

plus any genuinely assembled-machine canonical quantities that cannot belong exclusively to either component.

### Derived/query properties

At minimum:

```matlab
g
PoleSpan
% thetap as appropriate
% cross-component ratios
```

### Constructor/factory validation

Validate:

- field/armature orientation compatibility;
- correct radial ordering;
- positive/non-zero air gap as required;
- `g` derived from final surfaces matches expected physical geometry;
- common pole/slot/winding consistency;
- shared `ls` use;
- no contradictory duplicated state.

### Static factories

Support direct construction modes equivalent to current design completion:

```matlab
SlottedPMMachine.fromRatios(...)
SlottedPMMachine.fromRadii(...)
SlottedPMMachine.fromThicknesses(...)
SlottedPMMachine.fromLegacyStruct(...)
```

Exact argument syntax should be designed conservatively for MATLAB/Octave compatibility.

Factories may use pure helper functions internally.

### Legacy export

Provide:

```matlab
toLegacyStruct()
```

that reproduces the legacy fields required by existing downstream functions and parity tests.

This adapter should include expected derived ratios and legacy orientation-specific aliases such as `Rai`/`Rao` and `PoleWidth` where required.

---

## 10. Serialization and persistence

### 10.1 Persist structs, not saved class instances

Canonical designs should be persisted as versioned structs using:

```matlab
toStruct()
fromStruct()
```

Do not rely on MATLAB/Octave serialized class instances as the long-term design-storage format.

### 10.2 Versioning

Serialized structs should contain an explicit format/schema version.

Example concept:

```matlab
s.SchemaVersion = 1;
s.Type = 'SlottedPMMachine';
```

Nested component structs should be explicit enough to reconstruct the machine without depending on hidden workspace state.

### 10.3 Legacy adapter vs canonical serialization

Keep these concepts distinct:

```matlab
toStruct()        % stable modern persistence representation
toLegacyStruct()  % compatibility with existing global functions
```

The modern serialized structure should not be forced to mimic the legacy flat `design` struct.

---

## 11. Optimisation architecture

The optimisation path must be outside the canonical physical machine.

### 11.1 Why

`chrom2design_RADIAL_SLOTTED` performs substantial deterministic repair, including changes to geometry ratios and dimensions. Repairing a supposedly canonical immutable machine would blur the distinction between invalid candidate state and valid physical state.

### 11.2 Target flow

```text
chromosome / optimisation variables
        ↓
RadialSlottedDesignCandidate
        ↓
RadialSlottedDesignSpace.repair(...)
        ↓
valid repaired candidate
        ↓
build(...)
        ↓
SlottedPMMachine
        ↓
prepare(...)
        ↓
PreparedMachineModel
```

### 11.3 `RadialSlottedDesignCandidate`

Value class containing design-space variables, including quantities that are independent during optimisation but derived in the canonical machine.

Examples include current chromosome variables such as:

```text
tyVtm
tcVMax_tc
tsbVMax_tsb
tsgVtsb
g
tmVMax_tm
tbiVtm
thetamVthetap
thetacgVthetas
thetacyVthetas
thetasgVthetacg
lsVMax_ls
NBasicWindings
DcAreaFac
BranchFac
MagnetSkew
```

and any other currently supported variables after complete parity inventory.

### 11.4 `RadialSlottedDesignSpace`

Provisional owner of decode/repair/build orchestration.

Conceptual API:

```matlab
candidate = designSpace.decode(chrom);
[candidate, repairInfo] = designSpace.repair(candidate);
machine = designSpace.build(candidate);
```

### 11.5 Repair behaviour that must be preserved

Characterization tests must freeze the existing order and results of `chrom2design_RADIAL_SLOTTED`, including at least:

- minimum magnet thickness;
- minimum field back-iron thickness;
- minimum armature yoke thickness;
- external-armature radial-stack outward shift when needed;
- shoe-base repair relative to coil height;
- slot-height min/max repair;
- `tcb` construction from current `tc2Vtc1` behaviour;
- minimum slot-side-angle enforcement;
- consequent radius/slot-height modifications;
- slot overlap prevention through `thetacy` / `thetacg` changes;
- slot-opening wire-clearance enforcement;
- resulting `thetasg` enlargement/capping;
- ratio recalculation after modifications;
- any winding/branch construction effects.

Do not “simplify” the repair sequence in Milestone 1B.

### 11.6 `repairInfo`

A structured repair log is recommended but optional for initial parity.

If implemented, it should be deterministic and useful for diagnostics without affecting optimisation results.

---

## 12. Prepared machine model boundary

The physical machine should stop before it becomes a prepared numerical simulation object.

Introduce the conceptual boundary:

```matlab
PreparedMachineModel
```

Likely shape:

```matlab
classdef PreparedMachineModel
    properties (SetAccess = private)
        Machine
        Magnetic
        Circuit
        Losses
        GapForce
        MassProperties
        Diagnostics
    end
end
```

Exact syntax must remain Octave-compatible.

### 12.1 Why this boundary exists

Legacy `simfun_*` currently mutates `design` from a physical-machine definition into a mixture of:

- physical machine;
- FEA configuration;
- numerical lookup models;
- processed FEA results;
- loss models;
- circuit properties;
- mass properties;
- simulation-ready state.

The new architecture must keep these separate.

---

## 13. Fitted magnetic models

External SLM objects should be wrapped rather than exposed as the whole domain concept.

### 13.1 Flux linkage

Introduce a wrapper concept such as:

```text
FluxLinkageModel
    Fit
    FitMethod
    RMS
    CoilPeak
    PhasePeak
    PeakFluxLinkageFEAPosition
    evaluate(...)
```

`Fit` may initially contain the existing SLM output.

### 13.2 `PeakFluxLinkageFEAPosition`

This name is deliberate.

The legacy `MagSimFEAPeakFluxLinkagePosition` is important in optimisation screening, where a peak-flux-linkage FEA position is used for a fast single-FEA assessment of poor candidates.

Do not rename this to a vague `ReferenceRotorPosition` or similar.

Preferred modern location:

```matlab
model.Magnetic.FluxLinkageModel.PeakFluxLinkageFEAPosition
```

Retain `FEA` in the name because provenance matters.

### 13.3 Cogging torque

Use an explicit wrapper such as:

```text
CoggingTorqueModel
    Fit
    Peak
    evaluate(...)
```

Do not force consumers to know that the current backend is SLM.

---

## 14. FEA architecture

FEA migration is explicitly **not** part of Milestone 1A or 1B.

### 14.1 New FEA path uses `xfemm.femmsession` only

For the new API, support only the newer single-object solver path:

```matlab
xfemm.femmsession
```

Do not migrate the legacy separate:

```text
fmesher
fsolver
fpproc
analyse_mfemm
```

path into the new architecture.

The legacy code remains available independently.

### 14.2 Generic session wrapper

Future generic handle resource:

```text
XFemmSessionAnalysis < handle
    femmsession
    Problem
    PositionUpdater
    temporary FEM file/resource state
```

It should own lifecycle/resource state, not the physical machine.

### 14.3 Position update strategy

The generic wrapper must not assume sliding mesh because future linear-machine migration cannot use the same radial sliding-mesh mechanism.

Use composition:

```text
XFemmSessionAnalysis
    PositionUpdater
```

For radial-slotted:

```text
SlidingMeshPositioner
```

Future linear implementations may translate/redraw/rebuild without changing the generic session owner.

Avoid premature deep abstract hierarchies. A simple strategy object or function callback is preferable if it remains MATLAB/Octave-friendly.

### 14.4 Public FEA options

Do not expose low-level legacy solver-choice controls such as:

```text
UseFemm
QuietFemm
SolveMethod
RotationMethod
```

as ordinary public user choices in the new API.

The library should choose the appropriate solver mechanics for the machine topology.

Retain meaningful preparation options such as:

- number of sampled positions;
- core-loss inclusion;
- gap-force characterization options;
- displacement sampling;
- named mesh settings;
- geometry tolerances.

---

## 15. Raw FEA result objects

When FEA migration begins, preserve raw observations separately from fitted/prepared models.

Possible type:

```text
rnfoundry.em.fea.MagneticSweepResult
```

Potential contents:

```text
Positions
CoggingTorque
DirectFluxLinkage
ToothFluxDensity
SlotVectorPotential.Position
SlotVectorPotential.Integral
SlotFlux.Position
SlotFlux.Integral
CoreField
AirGapField
ArmatureIronArea
CoilArea
PerPoleRadialForce
```

This raw layer is important for regression testing and for avoiding loss of FEA provenance.

Legacy `intAdata` and `intBdata` belong here, not on the physical machine.

---

## 16. Gap force and mass properties

### 16.1 Gap force

Represent the prepared **variable-gap/eccentric closing-force curve** as an explicit model, for example:

```matlab
PreparedMachineModel.GapForce
```

with an API such as:

```matlab
evaluate(radialDisplacement)
```

This replaces the variable-gap legacy fields:

```text
ForceGapClosingWithDisp
DispGapClosingForce
p_ForceGapClosingWithDisp
```

while preserving their underlying calculations and extrapolation semantics.

Do not conflate this curve with the nominal force observation from the main magnetic sweep. Legacy `PerPoleAirGapClosingForce` corresponds to the nominal per-pole radial force at the reference magnetic position and should remain a distinct prepared observation/diagnostic. `ForcePerAreaToothSurface` is derived from that nominal force and tooth-facing area; it is not derived from the variable-gap polynomial.

### 16.2 Mass properties

Prepared physical results should use a structured model such as:

```text
PreparedMachineModel.MassProperties.Field
PreparedMachineModel.MassProperties.Armature
PreparedMachineModel.MassProperties.Total
```

The physical component materials own densities; mass calculations may use FEA-derived armature-iron area where the current model requires it.

Do not place £/kg or other costing assumptions on material definitions. Those belong in a separate cost/evaluation model.

---

## 17. Dynamic simulation separation

Simulation state and output must not mutate the canonical `Machine`.

The existing `simulatemachine_AM` is already a useful generic ODE lifecycle/plugin engine and should be preserved conceptually rather than gratuitously rewritten.

A future simulation result should use named fields rather than positional array columns.

For radial-slotted torque, for example:

```text
result.Torque.Electromagnetic
result.Torque.Cogging
result.Torque.CoreLoss
result.Torque.Total
```

### 17.1 Cogging torque parity warning

The current `torquefcn_RADIAL_SLOTTED` appends cogging torque to the breakdown but does **not** add it into the returned total torque because the addition line is commented out.

The first migration must preserve this exact behaviour.

Freeze it with tests before investigating whether the behaviour should later change.

Do not “fix” it opportunistically during refactoring.

---

## 18. Evaluation and optimisation orchestration

Physical machine objects should not own optimisation/evaluation workflows.

Future orchestration concept:

```text
DesignEvaluator
├── ScreeningPolicy
├── PreparationOptions
├── Scenario
├── StructuralEvaluator
├── Objective
└── CostModel
```

Validation should return an explicit result rather than adding arbitrary fields to the machine:

```text
ValidationResult
```

External scenario/load quantities such as legacy:

```text
RlVRp
LoadResistance
```

must not become intrinsic physical winding or circuit properties.

---

## 19. Legacy coexistence strategy

The new and old APIs must coexist throughout migration.

Typical comparison pattern:

```matlab
legacy = completedesign_RADIAL_SLOTTED(design, simoptions);
modern = rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(design);
```

or equivalent.

Do not replace the global implementation before parity is demonstrated.

### 19.1 Legacy adapter responsibilities

`fromLegacyStruct` and `toLegacyStruct` should bridge:

- flat legacy design structs;
- nested component ownership;
- legacy aliases;
- derived ratios;
- orientation-dependent fields;
- winding topology fields;
- conductor fields;
- MTL/packing values.

Legacy adapters may be verbose. The canonical modern object should remain clean.

---

## 20. Legacy-to-modern mapping for the first migration

### 20.1 Winding and conductor

| Legacy field | Modern concept |
|---|---|
| `CoilTurns` | `Winding.TurnsPerCoil` |
| `NStrands` | `Winding.Conductor.StrandCount` |
| `WireStrandDiameter` | `Winding.Conductor.StrandDiameter` |
| `Dc` | `Winding.Conductor.EquivalentCopperDiameter` |
| `ConductorArea` | `Winding.Conductor.CopperAreaPerTurn` |
| `CoilArea` | `Winding.CoilGeometry.PackArea` |
| `MTL` | `Winding.CoilGeometry.MeanTurnLength` / winding convenience accessor |
| `CoilFillFactor` | legacy packing input; modern `PackingFactor` semantics for construction |
| `CoilResistance` | derived/reference DC coil resistance |
| `Branches` | `Winding.ParallelBranches` |
| `CoilsPerBranch` | derived winding connection quantity |
| `NCoilsPerPhase` | `Winding.CoilsPerPhase` |
| `CoilLayers` | `Winding.LayerCount` |
| `WindingLayout` | `Winding.Layout` |

### 20.2 Radial-slotted dimensions

| Legacy field | Modern concept |
|---|---|
| `tc(1)` | `Armature.tc` |
| `tc(2)` | `Armature.tcb` |
| `tc2Vtc1` | candidate/construction ratio, canonical `Armature.tcbVtc` query |
| `Rai` / `Rao` | orientation-specific legacy mapping of `Armature.Ra` |
| `g` | candidate independent variable; canonical assembled-machine derived gap |
| `ls` | `Machine.ls` |
| `PoleWidth` | legacy alias for `Machine.PoleSpan` |

---

## 21. Regression and characterization strategy

The first migration should be test-led from legacy behaviour.

### 21.1 Existing tests are not sufficient as goldens

Current tests are largely smoke tests and include at least one known stale/incorrect internal-armature line in `test_design_RADIAL_SLOTTED` where `Rmi` is referenced before assignment.

Do not assume current tests alone fully define the behaviour.

### 21.2 Canonical geometry fixtures

Create representative fixtures for at least:

1. external armature, double-layer winding — primary fixture;
2. internal armature, double-layer winding;
3. tooth-wound / `yd = 1` case;
4. single-layer winding;
5. fractional-slot case with `ypd = 2`.

### 21.3 Parity levels

Long-term parity should be checked in stages:

1. machine construction;
2. raw FEA;
3. prepared model;
4. dynamic simulation;
5. evaluation/optimisation.

Milestone 1A covers only the first level plus winding/conductor numerical kernels. Milestone 2 is responsible for levels 2 and 3 for the radial-slotted offline-preparation path.

### 21.4 Numeric comparison

Use explicit tolerances appropriate to the operation.

For deterministic algebraic construction, parity should generally be very tight.

Do not use loose tolerances merely to make tests pass.

### 21.5 Packing characterization cases

Freeze at least the current supported `checkcoilprops_AM` modes:

- `Dc + CoilFillFactor -> CoilTurns`;
- `CoilTurns + CoilFillFactor -> Dc`;
- `Dc + CoilTurns -> CoilFillFactor`;
- explicit stranded-wire fields;
- `NStrands = 1` and `NStrands > 1`;
- insulation diameter conversion;
- conductor area conversion.

### 21.6 Radial-slotted winding geometry tests

Freeze:

- radial-slotted MTL;
- `tc/tcb` geometry representation parity;
- coil pack area;
- conductor/copper volume;
- reference DC coil resistance;
- branch/series phase-resistance derivation where included in the milestone.

### 21.7 Optimisation repair fixtures

For Milestone 1B, include deliberately infeasible chromosomes that independently trigger each known repair mechanism.

The test should compare both the final design and, where practical, intermediate consequences that depend on repair order.

---

## 22. Milestone plan

## Milestone 1A — canonical physical model, winding, packing, and legacy parity

### Objective

Introduce the first usable class-based physical representation for the radial-flux slotted PM machine **without FEA** and without migrating optimisation repair.

### Deliverables

Implement under `+rnfoundry/+em/`:

- `Machine`;
- `LinearMachine`;
- `RotaryMachine`;
- `RadialPMField`;
- `SlottedArmature`;
- `Winding`;
- `RoundWireConductor`;
- `CoilGeometry` abstraction or equivalent minimal common contract;
- `RadialSlottedCoilGeometry`;
- `SlottedPMMachine`;
- deterministic winding-packing resolution kernel;
- static factories:
  - `fromRatios`;
  - `fromRadii`;
  - `fromThicknesses`;
  - `fromLegacyStruct`;
- `toStruct` / `fromStruct` modern persistence;
- `toLegacyStruct` compatibility export;
- canonical validation;
- construction parity tests against `completedesign_RADIAL_SLOTTED` and relevant common winding helpers.

### Required behaviour

Milestone 1A must preserve:

- compact physical dimension names;
- the two-section `tc/tcb` slot-side geometry;
- internal/external armature handling;
- winding completion behaviour needed for the radial-slotted family;
- single- and multi-strand round conductors;
- legacy conductor insulation diameter relation;
- existing winding packing semantics;
- existing radial-slotted MTL calculation;
- existing reference DC resistance calculation;
- legacy struct round-trip fields needed by the migrated physical model.

### Explicitly out of scope

Do **not** implement in Milestone 1A:

- optimisation chromosome decode/repair;
- FEA;
- `xfemm.femmsession` wrappers;
- sliding mesh;
- inductance FEA;
- prepared magnetic fits;
- external-field winding eddy-current fitted models;
- dynamic ODE simulation refactor;
- evaluation/scoring refactor;
- proximity loss;
- full litz-wire modelling;
- rectangular/ribbon conductor classes unless trivial and clearly isolated.

### Acceptance criteria

Milestone 1A is complete when:

1. the new class tree can construct the agreed radial-slotted fixtures;
2. values exported through `toLegacyStruct()` match `completedesign_RADIAL_SLOTTED` for the covered physical/winding fields within defined tolerances;
3. all packing characterization tests pass;
4. radial-slotted MTL and reference DC coil resistance match legacy results;
5. both MATLAB and GNU Octave test runs pass for the new milestone test set;
6. no legacy implementation has been moved or broadly rewritten;
7. no FEA work has begun;
8. serialization round-trips through `toStruct()` / `fromStruct()` without relying on saved class instances.

### Review gate

Stop after Milestone 1A and review the API before beginning optimisation repair.

In particular, check whether:

- physical immutability is practical;
- candidate construction will be ergonomic;
- derived ratios remain easy to query;
- `g` is correctly canonical/derived;
- `Winding`/`Conductor`/`CoilGeometry` responsibilities are appropriately separated;
- MATLAB/Octave compatibility is satisfactory.

Do not automatically continue to Milestone 1B in the same implementation session.

---

## Milestone 1B — radial-slotted optimisation candidate and deterministic repair

### Objective

Migrate the design-space representation and repair logic while continuing to build the canonical Milestone-1A physical machine.

### Deliverables

Implement:

- `RadialSlottedDesignCandidate`;
- `RadialSlottedDesignSpace` or equivalent narrowly-scoped owner;
- chromosome decode;
- deterministic repair preserving `chrom2design_RADIAL_SLOTTED` behaviour/order;
- candidate-to-`SlottedPMMachine` build;
- repair diagnostics if useful;
- valid and repair-triggering parity tests.

### Acceptance criteria

- equivalent valid chromosomes produce matching canonical designs;
- each known repair mechanism is covered by characterization tests;
- repair order is preserved;
- ratios are recalculated consistently after repair;
- canonical machine contains no contradictory candidate-only state;
- no FEA work is included.

Stop for review after Milestone 1B.

---

## Milestone 2 — complete offline preparation of the radial-slotted machine

### Objective

Starting from a valid canonical `SlottedPMMachine`, produce a value-semantic `PreparedMachineModel` containing the machine-intrinsic numerical models and prepared physical properties required by later dynamic simulation and evaluation.

New FEA work in this milestone must use `xfemm.femmsession` exclusively. The canonical `Machine` remains solver-free and must not be mutated during preparation.

Milestone 2 ends at the **offline prepared-model boundary**. It does not migrate dynamic ODE simulation, external electrical loads, converter/controller configuration, optimisation scoring, or structural evaluation.

The intended high-level division is therefore:

```text
Milestone 1: construct a valid physical machine
Milestone 2: prepare that machine numerically
Milestone 3: simulate the prepared machine dynamically
```

### 22.2.1 Common preparation pattern

Where a preparation step uses FEA, preserve the separation:

```text
canonical Machine
       ↓
FEA characterization
       ↓
raw result value object
       ↓
pure preparation / fitting
       ↓
prepared domain model
       ↓
PreparedMachineModel section
```

Raw observations must remain separately inspectable. Do not hide the only copy of FEA observations inside fitted SLMs or other opaque prepared models.

Where no FEA is required, keep the preparation stage as a deterministic pure calculation from canonical machine state and/or existing raw observations.

### 22.2.2 Status of work already completed

The work completed before this consolidation should be treated as the first Milestone-2 sub-stages:

#### Milestone 2A — raw main magnetic characterization — complete

Delivered:

- `XFemmSessionAnalysis < handle` as the generic femmsession resource owner;
- composed position-update policy;
- `SlidingMeshPositioner` for radial machines;
- femmsession-only radial-slotted main magnetic sweep;
- reusable session across angular positions;
- raw value-semantic `MagneticSweepResult`;
- raw observations including cogging torque, direct flux linkage, slot vector-potential integrals, slot-flux integrals, tooth flux density, air-gap field, armature-iron area, FEA coil-area measurement, and nominal per-pole radial force;
- architecture/unit tests and opt-in real-FEA parity infrastructure.

The main sweep is the authoritative modern source of reusable zero-current magnetic observations. Subsequent prepared-model stages should reuse its raw data rather than repeat equivalent solves unnecessarily.

#### Milestone 2B — prepared magnetic models — complete

Delivered:

- pure raw-to-prepared magnetic conversion with no FEA;
- `FluxLinkageModel`;
- `CoggingTorqueModel`;
- `PreparedMagneticModel`;
- initial `PreparedMachineModel` boundary;
- legacy-compatible `intA` / vector-potential flux-linkage path;
- legacy skew, peak-position, lookup-grid and fitted-SLM semantics;
- prepared-model parity and architecture tests.

The direct circuit flux-linkage observation remains raw diagnostic/provenance data; it does not replace the legacy `intA`-derived prepared flux-linkage path unless a later separately justified change is made.

#### Milestone 2C — variable-gap closing-force characterization — implemented

Delivered by the Milestone-2C work, including PR #7 at the time of this plan consolidation:

- raw `RadialGapForceSweepResult`;
- femmsession-only full-machine eccentric displacement sweep;
- negative-global-x field-assembly translation matching legacy semantics;
- absolute global-x force block integral 18;
- explicit full-machine force scaling;
- `RadialGapForceModel`;
- pure legacy-compatible fit preparation, including the artificial origin and legacy linear/quadratic order rule;
- `PreparedMachineModel.GapForce` composition;
- dependency-free tests and opt-in internal/external real-FEA parity coverage.

The nominal `MagneticSweepResult.PerPoleRadialForce` is deliberately distinct from the variable-gap full-machine force curve.

### 22.2.3 Cross-cutting Milestone-2 closure prerequisite — exact coil-region geometry / Issue #5

Issue #5, **“Derive exact radial-slotted coil pack area from slot geometry without FEA”**, is a Milestone-2 completion blocker even though it is not another electromagnetic FEA characterization sub-stage.

The required final construction order is:

```text
candidate
   ↓
repair
   ↓
exact slot / coil-region geometry
   ↓
exact PackArea
   ↓
canonical SlottedPMMachine
   ↓
FEA / preparation
```

The current transitional path still uses the first magnetic FEA solve's block-area measurement to obtain the legacy `CoilArea` used by prepared flux-linkage calculations. That measurement is valuable as a regression oracle, but the modern architecture must not require an FEA solve to complete canonical winding geometry.

The Issue-#5 work must:

- characterize the exact legacy meaning of `CoilArea` for single layer, ordinary double layer, and `SplitSlot` / `yd = 1` cases;
- handle internal and external armatures;
- preserve the full tapered/two-section `tc/tcb` slot geometry;
- distinguish slot void, insulation region, per-layer pack regions and the canonical `PackArea` concept;
- reuse or extract the authoritative slot-region geometry rather than create an unrelated approximation;
- calculate the relevant region areas in MATLAB/Octave without a magnetic solve;
- compare each applicable pure-geometry region area with FEMM block-integral area as a Tier-2 regression oracle;
- remove the architectural dependency of prepared flux linkage on FEA-derived `CoilArea` once canonical area parity is demonstrated.

After this work, `MagneticSweepResult.CoilArea` may remain as a raw FEA diagnostic/regression observation, but it must no longer be needed to make the physical machine definition complete.

### 22.2.4 Milestone 2D — inductance characterization and intrinsic circuit preparation

#### Objective

Migrate the remaining radial-slotted inductance FEA and construct the machine-intrinsic prepared circuit model without importing external load/controller concerns from legacy `circuitprops_AM`.

#### Raw FEA characterization

Use `xfemm.femmsession` only to reproduce the currently active legacy d-axis and q-axis inductance solves.

Introduce a raw value object such as:

```text
rnfoundry.em.fea.RadialSlottedInductanceResult
    ExcitationCurrent
    DAxis
        Position
        SelfInductance
        MutualInductance
    QAxis
        Position
        SelfInductance
        MutualInductance
    Provenance
```

Exact names may vary, but the result must retain:

- excitation current used for characterization;
- the legacy d/q characterization positions;
- per-coil self inductance;
- neighbouring-phase/co-winding mutual inductance information currently extracted by the legacy solve;
- enough provenance to reproduce and regression-test the calculation.

Preserve the existing `inductancesimcurrent` choice and legacy d/q position semantics unless separately characterized and intentionally changed.

#### Prepared circuit model

Introduce or complete an intrinsic circuit section such as:

```text
PreparedMachineModel.Circuit
    ReferenceDCCoilResistance
    ReferenceDCPhaseResistance
    DAxisInductance
    QAxisInductance
    % self/mutual or matrix representations as required
```

The exact public representation should make self, mutual, phase and d/q meanings unambiguous.

Reference DC resistance should come from the canonical winding/conductor/path geometry and material model. Do **not** make the resistance returned incidentally by the inductance FEA circuit solve authoritative: legacy subsequently recalculates `CoilResistance` from the winding geometry, and the modern model should preserve that separation of responsibilities.

The prepared circuit model should derive phase values from winding topology (`ParallelBranches`, `CoilsPerBranch`, phases) without mutating the physical winding.

#### Explicit exclusions from 2D

Do not migrate the scenario/network portions of `circuitprops_AM` into the machine-intrinsic circuit model, including:

- `RlVRp` / load resistance;
- load inductance / `LgVLc`;
- `LoadModel` selection;
- machine-side converter parasitic configuration;
- field-oriented-control PID setup;
- controller natural-frequency/timestep design;
- scenario-dependent temperature adjustment;
- dynamic frequency-dependent resistance application.

Those belong to later simulation/scenario orchestration. The underlying pure conductor skin-effect kernel may exist independently, but integrating scenario frequency/temperature state is not required to close Milestone 2.

#### 2D acceptance criteria

- d-axis and q-axis raw inductance observations match the legacy radial-slotted solves within justified FEA tolerances;
- self and mutual inductance semantics are explicitly documented and parity-tested;
- reference DC coil and phase resistance match the established winding/conductor calculations;
- prepared circuit state is machine-intrinsic and contains no external load/controller state;
- the canonical `Machine` and `Winding` remain unchanged.

### 22.2.5 Milestone 2E — prepared machine-intrinsic loss models

Milestone 2E migrates the currently active radial-slotted offline loss preparation needed by later ODE simulation. Keep core loss and winding external-field eddy-current loss as separate domain concepts.

#### 2E.1 Core-loss raw observations

The legacy main magnetic FEA gathers spatial core-field samples at every magnetic position. The current modern `MagneticSweepResult` must therefore be extended with explicit raw core-field history before core-loss parity can be claimed.

Use a structure such as:

```text
MagneticSweepResult.CoreField
    Position
    Region(...)
        SamplingGeometry / coordinates
        Bx
        By
        Bz
        dV or equivalent integration weights/volumes
        Provenance
```

The exact layout may follow the actual core-loss sampling kernel, but raw field history and its spatial weighting must not be hidden inside the prepared fit.

Prefer gathering this data in the existing main magnetic sweep rather than performing another equivalent angular FEA sweep.

#### 2E.2 Core-loss prepared model

Reproduce the currently active legacy `makelossfcns_RADIAL_SLOTTED` / `softferrolossrectregionvarxpartcalc` preparation before changing the physical loss model.

Use an explicit prepared concept such as:

```text
PreparedMachineModel.Losses.Core
    Hysteresis
    ClassicalEddyCurrent
    Excess
    evaluate(position, speed)
```

or an equivalent wrapper that hides the current SLM backend.

Initial parity is with the **currently active** legacy behaviour. In particular, do not silently enable dormant/commented accumulation of additional core-loss regions such as field back iron. If field-back-iron loss is later desired, add it as a separately characterized post-parity enhancement.

Material loss coefficients should ultimately be associated with the appropriate material/component model rather than silently introduced as mutable simulation fields.

#### 2E.3 External-field winding eddy-current loss

Use the existing raw `MagneticSweepResult.SlotFlux` observations to reproduce the legacy `intBdata` → `makesfdeddyslm` path.

Prepared destination:

```text
PreparedMachineModel.Losses.WindingExternalFieldEddyCurrentLossModel
    Fit
    FitMethod
    evaluate(position, speed)
```

The implementation must preserve the distinction between:

- winding external-field eddy-current loss;
- ordinary DC resistance;
- round-wire skin-effect resistance;
- unfinished proximity-effect loss.

Use conductor strand diameter/count, material resistivity, turns, winding topology, and `CoilGeometry.ActiveSegmentLengths` as the physical inputs required by the current SFD formulation. Do not substitute full MTL where the legacy calculation uses only active conductor length in the changing field.

#### 2E.4 Loss-model acceptance criteria

- raw core-field histories match legacy observations for representative fixtures;
- prepared hysteresis/classical-eddy/excess loss functions match the currently active legacy output over representative position/speed grids;
- winding external-field eddy-current prepared output matches legacy `makesfdeddyslm`/`lossforces_AM` semantics;
- the prepared loss API does not expose raw SLM objects as the domain abstraction;
- no proximity-loss parity is claimed;
- no dormant field-back-iron loss behaviour is opportunistically enabled.

### 22.2.6 Milestone 2F — mass properties and prepared scalar diagnostics

#### Objective

Complete the pure prepared physical properties that legacy `finfun_RADIAL_SLOTTED` derives after magnetic/loss preparation.

#### Mass properties

Use a structured value model such as:

```text
PreparedMachineModel.MassProperties
    Field
        Magnet
        BackIron
        Support
        Total
        PolarMomentOfInertia
    Armature
        Iron
        Winding
        Support
        Total
    Total
```

Exact nesting may be adjusted, but electromagnetic component terminology should remain `Field` / `Armature`, not mechanically assumed `Rotor` / `Stator`.

Preserve current mass calculations initially:

- magnet volume/mass;
- field back-iron volume/mass;
- winding copper volume/mass;
- armature-iron volume/mass;
- currently-zero support/epoxy contributions where that is the active legacy behaviour;
- total component and machine masses;
- the current hollow-cylinder approximation for the field component polar moment of inertia where applicable.

Densities must come from the canonical component materials/conductor material, not from a new authoritative `simoptions.Evaluation.*Density` bag.

Using FEA-derived `ArmatureIronArea` for the armature-iron mass is acceptable for Milestone 2 because it is a prepared physical result, unlike canonical winding `PackArea` which must be known before FEA.

#### Prepared diagnostics / scalar observations

Do not leave useful main-sweep observations as anonymous legacy-compatible fields. Give explicit prepared homes to at least the currently consumed quantities:

```text
PeakArmatureToothFluxDensity
PeakAirGapFluxDensity
NominalPerPoleRadialForce
ForcePerAreaToothSurface
```

The exact nesting may be chosen during implementation, for example under `Magnetic`, `GapForce`, or `Diagnostics`, provided the semantics are explicit and no quantity is duplicated as contradictory mutable state.

`NominalPerPoleRadialForce` must remain distinct from the full-machine eccentric `GapForce` curve.

#### 2F acceptance criteria

- material volumes/masses and field-component inertia match currently active legacy calculations within deterministic tolerances;
- material densities are obtained from component-owned materials;
- armature-iron area provenance remains explicit;
- nominal force/tooth-area and peak-flux diagnostics match legacy values;
- `PreparedMachineModel` composition preserves all already-prepared sections.

### 22.2.7 Milestone 2G — integrated radial-slotted preparation workflow

Individual raw and pure-preparation services must remain usable independently, but Milestone 2 is not complete until they are also composed through one supported high-level radial-slotted preparation workflow.

Conceptual API:

```matlab
[prepared, raw] = rnfoundry.em.rotary.radial.prepare(machine, options)
```

Exact function naming may differ, but the ordinary user-facing flow should be equivalent to:

```text
SlottedPMMachine
  │
  ├── main magnetic sweep ──────> MagneticSweepResult
  │                                ├── Magnetic
  │                                ├── core-loss preparation
  │                                ├── winding external-field loss
  │                                ├── mass/diagnostics
  │                                └── raw geometry/force observations
  │
  ├── gap-force sweep ──────────> RadialGapForceSweepResult
  │                                └── GapForce
  │
  └── inductance characterization -> RadialSlottedInductanceResult
                                   └── Circuit

                       ↓

                PreparedMachineModel
```

`raw` may be a struct or another simple value container grouping the independent raw result objects. Do not require consumers to discard raw FEA provenance merely because they request the integrated prepared model.

#### Preparation options

The high-level preparation options may expose meaningful engineering/numerical choices such as:

- main magnetic sample count;
- magnet-skew fitting sample count;
- whether variable-gap characterization is requested;
- variable-gap displacement sample locations;
- whether core-field observations/loss preparation are requested where optional;
- named mesh sizes;
- geometry tolerances;
- future worker/parallel policy at the orchestration boundary.

Do not expose ordinary public switches for:

```text
UseFemm
QuietFemm
SolveMethod
RotationMethod
```

The new API chooses the femmsession/sliding-mesh/rebuild mechanics appropriate to the operation.

The orchestration should avoid duplicated FEA work. In particular, loss/mass/diagnostic preparation should consume observations already gathered by the main magnetic sweep wherever possible.

### 22.2.8 FEA resource and parallel-execution constraints

Across all Milestone-2 FEA work:

- resource-owning solver state remains in handle/session objects, never the canonical machine;
- raw and prepared result objects remain value-semantic;
- the generic FEA owner must not assume radial sliding mesh;
- radial angular sweeps may reuse one femmsession where the geometry/AGE contract permits it;
- eccentric gap-force samples may rebuild full geometry where required for parity;
- future parallel execution must use one independent session/resource set per worker;
- implementing parallel orchestration itself is not required for Milestone-2 completion.

### 22.2.9 Milestone-2 regression and parity requirements

Testing must distinguish three categories:

#### Tier 1 — dependency-free deterministic tests

Cover:

- raw value-object validation;
- pure raw-to-prepared transformations;
- fit construction/evaluation;
- winding/circuit topology calculations;
- resistance calculations;
- mass/property calculations where fed characterized raw fixtures;
- immutability/value-copy composition;
- option validation and public-API architecture constraints.

Run the shared suite under both MATLAB and GNU Octave.

#### Tier 2 — real `xfemm.femmsession` parity

The opt-in FEA test runner remains the authoritative native-runtime availability gate.

Before formally closing Milestone 2, the real-FEA parity tier must have been successfully executed in at least one suitable XFEMM environment, covering the applicable operations:

- main magnetic raw sweep;
- variable-gap force sweep;
- d/q inductance characterization;
- FEA coil-region area as the Issue-#5 regression oracle;
- raw core-field acquisition.

Representative fixtures should include, where the operation applies:

- external armature, ordinary double layer;
- internal armature, ordinary double layer;
- single-layer winding;
- `CoilLayers = 2`, `yd = 1` / `SplitSlot` case;
- a supported fractional-slot fixture.

Do not weaken tolerances merely to accommodate unexplained discrepancies. Record and justify FEA-specific tolerances separately from deterministic algebraic tolerances.

#### Legacy parity boundaries

Freeze initial parity for:

- raw main magnetic observations required by modern preparation;
- flux-linkage lookup/model and peak position;
- cogging-torque fit and peak;
- nominal per-pole radial force;
- full-machine variable-gap force samples and fitted curve;
- d/q self and mutual inductance;
- active core-loss prepared functions;
- external-field winding eddy-current prepared function;
- reference DC coil/phase resistance;
- relevant material masses and field-component inertia;
- peak tooth/air-gap flux diagnostics and tooth-surface force metric.

### 22.2.10 Milestone-2 acceptance criteria

Milestone 2 is complete only when all of the following are true:

1. A valid canonical radial-slotted `SlottedPMMachine` can be passed through one supported high-level preparation workflow to produce a complete `PreparedMachineModel` without mutating the canonical machine.
2. All new FEA code used by that workflow uses `xfemm.femmsession`; the new API does not depend on `analyse_mfemm`, standalone `fmesher`/`fsolver`/`fpproc`, or public solver-selection flags.
3. Main magnetic, variable-gap force, and inductance FEA observations are represented by explicit raw value objects and remain separately inspectable from fitted/prepared models.
4. `PreparedMachineModel` has meaningful populated `Magnetic`, `Circuit`, `Losses`, `GapForce`, and `MassProperties` sections for the radial-slotted family, plus an explicit home for the retained prepared diagnostics.
5. Issue #5 is complete: exact/controlled-accuracy radial-slotted coil-region area is available without a magnetic solve, canonical `CoilGeometry.PackArea` semantics are explicit, and prepared flux linkage no longer architecturally depends on FEA to complete canonical winding geometry.
6. Legacy parity is characterized and tested for the magnetic, gap-force, inductance, active loss, resistance, mass/inertia, and scalar diagnostic quantities listed above.
7. Raw core-field history required by the active legacy core-loss preparation is represented explicitly rather than hidden inside a fit.
8. The physical `Machine`, `Field`, `Armature`, `Winding`, `Conductor`, and `CoilGeometry` remain value-semantic and solver-free; resource ownership remains confined to FEA handle/session wrappers.
9. MATLAB and GNU Octave Tier-1 tests pass for the complete Milestone-2 path.
10. The opt-in real-femmsession Tier-2 parity suite has been successfully run in a working native XFEMM environment before the milestone is formally declared closed.
11. The integrated preparation workflow avoids avoidable duplicate FEA solves by reusing main-sweep observations for loss, mass, and diagnostic preparation.
12. No external load, converter/controller, dynamic ODE, optimisation-scoring, or structural-evaluation state has leaked into `PreparedMachineModel` merely to reproduce the legacy monolithic `simfun`/`finfun` structs.

### 22.2.11 Explicitly out of scope for Milestone 2

Do **not** pull the following into Milestone 2 merely because related legacy fields are produced during `simfun_*` / `finfun_*`:

- dynamic ODE simulation or result refactor;
- `simulatemachine_AM` lifecycle migration;
- live FEA at each ODE step;
- external `LoadResistance`, `RlVRp`, load inductance, or load-model orchestration;
- machine-side converter and field-oriented-controller setup;
- scenario-dependent temperature/frequency application to the circuit during simulation;
- full migration of `circuitprops_AM` as a monolithic function;
- optimisation objective/scoring/evaluation orchestration;
- structural evaluator/model refactor;
- advanced proximity-effect winding loss;
- full litz/rectangular/ribbon conductor implementations;
- dormant/new field-back-iron core-loss behaviour beyond the currently active legacy calculation;
- linear-machine FEA/preparation;
- parallel FEA orchestration/performance work;
- redesign of the legacy cogging-torque total-torque semantics.

### 22.2.12 Review gate

Stop after the Milestone-2 acceptance criteria are met and review the complete `Machine -> PreparedMachineModel` API before beginning dynamic simulation migration.

The review should confirm that Milestone 3 can consume `PreparedMachineModel` without needing to rediscover missing radial-slotted FEA/preparation work or mutate the canonical machine.

---

## 23. Deferred future work

The following are explicitly deferred and should not be pulled into early milestones:

- linear-machine FEA migration;
- live FEA at every ODE step;
- `LiveFEMagneticModel`;
- advanced proximity-effect winding models;
- full litz conductor model;
- rectangular/ribbon conductor implementations;
- redesign of cogging-torque semantics;
- full evaluation/scoring OO migration;
- structural-model refactor;
- broad cleanup of legacy naming inconsistencies;
- movement/removal of the legacy global namespace.

A possible later magnetic-model interface is:

```text
LookupMagneticModel
LiveFEMagneticModel
```

with common operations such as:

```matlab
fluxLinkage(position, currents)
torque(position, currents)
losses(position, speed, currents)
```

but this should not influence Milestone 1A implementation beyond avoiding architectural dead ends.

---

## 24. Known legacy inconsistencies to avoid propagating

The new API may resolve these while leaving legacy behaviour untouched:

- `Evaluation` / `evaloptions` naming mismatches;
- `SolveMethod` default/type inconsistencies;
- stale legacy test typo noted above;
- positional result arrays where named result fields are clearer;
- duplicated insulated-wire diameter logic;
- ambiguous legacy `CoilFillFactor` terminology.

Resolving an inconsistency does **not** mean changing numerical behaviour without parity tests.

---

## 25. Implementation rules for Codex / coding agents

When implementing any milestone from this plan:

1. Read this entire document first.
2. Inspect the current repository state before editing.
3. Read the specific legacy functions named by the relevant milestone.
4. Treat legacy numerical behaviour as the initial regression baseline.
5. Do not redesign agreed public notation.
6. Do not replace `Field`/`Armature` with `Rotor`/`Stator`.
7. Do not expand compact engineering symbols into verbose names.
8. Prefer composition over additional inheritance.
9. Keep physical classes as value classes.
10. Keep resource-owning solver sessions as handle classes.
11. Preserve MATLAB and GNU Octave compatibility.
12. Avoid MATLAB-only convenience syntax unless verified in Octave.
13. Keep pure numerical kernels as functions where appropriate.
14. Do not move or broadly rewrite legacy code unless explicitly required.
15. Add characterization/regression tests before or alongside refactoring of complex behaviour.
16. Do not continue into the next milestone unless explicitly instructed.
17. If the current repository contradicts this plan materially, stop and report the conflict rather than silently choosing a different architecture.

---

# Appendix A — Milestone 1A Codex execution prompt

Use the following as the starting prompt for a Codex implementation session after this document has been committed or otherwise made available in the working tree.

```text
Implement Milestone 1A from CLASSDEF_REFACTOR_PLAN.md for the rnfoundry
permanent-magnet electrical machines toolbox.

Read CLASSDEF_REFACTOR_PLAN.md in full before modifying any code. Treat it as
the architectural source of truth for this refactor. Also inspect the current
repository state and read the relevant legacy implementation, especially the
radial-slotted completedesign/winding/conductor/MTL/resistance code identified
by the plan.

Scope this session strictly to Milestone 1A. Do not begin Milestone 1B and do
not perform any FEA migration.

Before editing:
1. inspect the current tree and relevant legacy tests/functions;
2. summarise the concrete new files/classes/functions you intend to add;
3. identify any material conflict between the repository and the plan;
4. if there is a material architectural conflict, report it before proceeding
   rather than silently deviating from the plan.

Then implement Milestone 1A, including the required characterization and
regression tests.

Important constraints:
- new code goes under +rnfoundry/+em/;
- preserve MATLAB and GNU Octave compatibility;
- use shallow Machine -> LinearMachine / RotaryMachine inheritance;
- prefer composition below that hierarchy;
- physical classes are value classes;
- retain Field and Armature terminology;
- retain compact engineering dimension names such as Ryi, Ryo, tc, tcb,
  thetacg, etc.;
- preserve the full two-section tc/tcb radial-slotted geometry;
- canonical machine g is derived from final field/armature geometry;
- optimisation/candidate g is not part of this milestone;
- support ordinary multi-strand round conductors in the first implementation;
- preserve the current packing semantics used by checkcoilprops_AM;
- keep winding packing as a deterministic construction kernel rather than a
  responsibility of the Conductor class;
- reproduce the existing radial-slotted MTL calculation for parity;
- do not reinterpret CoilFillFactor silently as conventional copper fill
  factor;
- persist modern designs through versioned structs via toStruct/fromStruct,
  not saved class instances;
- provide fromLegacyStruct/toLegacyStruct adapters;
- leave the existing global legacy implementation in place for direct
  comparison;
- do not migrate fmesher/fsolver/fpproc/analyse_mfemm or femmsession work;
- do not implement proximity loss, litz, rectangular or ribbon conductors
  beyond interfaces that are naturally required by the agreed design.

Acceptance criteria are those stated under Milestone 1A in the plan. Run the
relevant MATLAB tests where available and GNU Octave tests where supported.
Report:
- files added/changed;
- tests added;
- test results;
- any parity differences;
- any API decisions that could not exactly follow the plan and why.

Stop after Milestone 1A. Do not continue to Milestone 1B automatically.
```

---

# Appendix B — Key legacy functions to inspect during Milestone 1A

This list is not necessarily exhaustive, but these functions are known to be central to first-stage parity:

```text
common/completedesign_AM.m
rotary_machines/.../completedesign_ROTARY.m
rotary_machines/radial_flux/.../completedesign_RADIAL.m
rotary_machines/radial_flux/slotted/completedesign_RADIAL_SLOTTED.m

common/checkcoilprops_AM.m
common/CoilTurns.m
common/ConductorDiameter.m
common/conductord2wired.m
common/stranddiameter.m
common/equivDcfromstranded.m
common/rectcoilmtl.m
common/isotrapzcoilmtl.m

rotary_machines/radial_flux/slotted/coilresistance_RADIAL_SLOTTED.m
common/circuitprops_AM.m
common/odesim/machineodesim_common_AM.m

common/winding_losses/roundwirefreqdepresistance.m
common/winding_losses/roundwireextfieldeddyloss.m
common/winding_losses/makesfdeddyslm.m
common/roundwireproximityloss.m

general_electromagnetics/wireresistancedc.m
```

The implementation agent should locate the exact current paths rather than assuming this appendix is path-perfect if the repository has moved files since this document was written.

---

# Appendix C — Review checklist after Milestone 1A

Before authorising Milestone 1B, review the following:

- Can a radial-slotted machine be constructed naturally from ratios, radii, and thicknesses?
- Does `fromLegacyStruct` reproduce all required canonical physical information?
- Does `toLegacyStruct` reproduce legacy fields without hidden mutable caches?
- Is `g` derived canonically rather than duplicated?
- Are ratios readily queryable without becoming contradictory stored state?
- Is `Ra` cleanly mapped to `Rai`/`Rao`?
- Is the `tc/tcb` two-stage slot geometry fully preserved?
- Are `Field` and `Armature` sufficiently independent and composable?
- Is `Winding` free of machine-level responsibilities?
- Is `RoundWireConductor` representing strands rather than conflating them with winding packing?
- Is `CoilGeometry` free of back-references that create object cycles?
- Are MTL and active conductor length distinct concepts?
- Are packing semantics parity-tested against the legacy implementation?
- Is the modern persistence struct stable, explicit, and versioned?
- Do the new classes work in both MATLAB and GNU Octave?
- Has any accidental FEA/optimisation work leaked into Milestone 1A?

Only after this review should Milestone 1B begin.
