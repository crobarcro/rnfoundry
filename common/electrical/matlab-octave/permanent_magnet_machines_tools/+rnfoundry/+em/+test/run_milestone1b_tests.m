function run_milestone1b_tests()
%RUN_MILESTONE1B_TESTS Run 1A and optimisation decode/repair/build tests.
rnfoundry.em.test.run_milestone1a_tests();
tests={@rnfoundry.em.test.test_design_candidate_decode, ...
       @rnfoundry.em.test.test_design_space_defaults, ...
       @rnfoundry.em.test.test_radial_slotted_repair_parity, ...
       @rnfoundry.em.test.test_candidate_build};
for k=1:numel(tests), feval(tests{k}); end
fprintf('Milestone 1B tests passed (%d groups plus Milestone 1A).\n',numel(tests));
end
