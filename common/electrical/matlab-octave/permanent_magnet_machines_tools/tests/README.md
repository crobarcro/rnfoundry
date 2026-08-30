# Shared classdef unit tests

These deterministic MOxUnit tests are the compiler- and solver-free test tier.
They do not run FEMM, build `mexmPhaseWL`, or invoke the legacy winding-layout
generator. The same test files run under MATLAB and GNU Octave.

CI checks out MOxUnit commit
`39de87844cccf33c79283c881e221a97207a9b83`. To run locally, check out that
revision and either pass its path explicitly:

```matlab
addpath(fullfile(pwd, 'common', 'electrical', 'matlab-octave', ...
    'permanent_magnet_machines_tools', 'ci'));
run_unit_tests('/path/to/MOxUnit');
```

or set `MOXUNIT_PATH` to the checkout and call `run_unit_tests()`.
JUnit XML is written to `test-results/moxunit.xml` unless another output path
is supplied.

Test discovery is deliberately tiered: `run_unit_tests` discovers only
`tests/unit`, while fixtures and helpers are path dependencies rather than test
roots. Real solver tests live under `tests/fea` and are run separately with
`run_fea_tests` after setting `RNFOUNDRY_RUN_FEA_TESTS=1`; integration/native
code tests may use `tests/integration` in future without entering Tier 1.
