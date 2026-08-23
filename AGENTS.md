# AGENTS.md

## Repository guidance

This repository contains MATLAB and GNU Octave code. Preserve compatibility with both environments unless a task explicitly states otherwise.

Prefer focused changes that preserve existing numerical behaviour. Do not broadly reorganise legacy code as part of an unrelated task, and add or update regression tests when refactoring established algorithms.

## Electrical machines `classdef` refactor

For work under:

```text
common/electrical/matlab-octave/permanent_magnet_machines_tools
```

that implements or modifies the new `classdef`-based electrical-machine architecture, read the following document **in full before changing code**:

```text
common/electrical/matlab-octave/permanent_magnet_machines_tools/CLASSDEF_REFACTOR_PLAN.md
```

Treat `CLASSDEF_REFACTOR_PLAN.md` as the architectural source of truth for this refactor.

In particular:

- implement the migration milestone-by-milestone and do not continue into the next milestone unless explicitly instructed;
- inspect the relevant existing implementation before editing and use legacy numerical behaviour as the initial regression baseline;
- keep the existing global-namespace implementation in place for comparison during the migration;
- preserve MATLAB and GNU Octave compatibility;
- follow the agreed shallow inheritance and composition-first architecture, value/handle semantics, engineering notation, legacy mappings, and milestone scope in the plan;
- treat the legacy implementation as the regression oracle when migrating behaviour, but do not satisfy a migration milestone merely by wrapping or delegating the new implementation to the legacy function being migrated;
- preserve established behavioural ordering where the plan identifies ordering as part of compatibility, including optimisation repair ordering;
- do not silently choose a different architecture when the current repository materially conflicts with the plan—report the conflict instead;
- respect the explicit scope and exclusions of the milestone being implemented, and do not begin work assigned to a later milestone unless explicitly instructed.

Instructions in a more specific `AGENTS.md`, if one is added beneath a subdirectory in future, take precedence for files within that subtree where they do not conflict with an explicit user instruction.
