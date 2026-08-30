function run_milestone2c_tests()
%RUN_MILESTONE2C_TESTS Run the dependency-free 2C tests.
% Earlier milestone coverage remains in the Tier-1 runner; deliberately do
% not call the legacy 1A characterization runner here because it attempts to
% compile its optional legacy winding-layout MEX when absent.
rnfoundry.em.test.test_gap_force_preparation();
fprintf('Milestone 2C gap-force preparation tests passed.\n');
end
