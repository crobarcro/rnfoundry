function run_milestone2a_tests()
%RUN_MILESTONE2A_TESTS Run prior milestones then non-FEA 2A tests.
rnfoundry.em.test.run_milestone1a_tests();
rnfoundry.em.test.run_milestone1b_tests();
tests={@rnfoundry.em.test.test_sliding_mesh_positioner, ...
 @rnfoundry.em.test.test_magnetic_sweep_result, ...
 @rnfoundry.em.test.test_magnetic_sweep_options, ...
 @rnfoundry.em.test.test_milestone2a_architecture};
for k=1:numel(tests), feval(tests{k}); end
fprintf('Milestone 2A non-FEA tests passed (%d groups plus Milestones 1A/1B).\n',numel(tests));
if exist('xfemm.femmsession','class') ~= 8
 fprintf('Real femmsession parity tests skipped: xfemm.femmsession is unavailable.\n');
end
end
