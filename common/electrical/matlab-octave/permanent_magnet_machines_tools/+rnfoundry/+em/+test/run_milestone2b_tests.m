function run_milestone2b_tests()
%RUN_MILESTONE2B_TESTS Run all prior milestones then pure 2B tests.
rnfoundry.em.test.run_milestone1a_tests();
rnfoundry.em.test.run_milestone1b_tests();
rnfoundry.em.test.run_milestone2a_tests();
rnfoundry.em.test.test_prepared_magnetic_boundary();
fprintf('Milestone 2B fitted magnetic model tests passed.\n');
end
