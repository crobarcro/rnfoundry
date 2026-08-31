function test_suite = test_gap_force_models
try test_functions=localfunctions(); catch, test_functions={}; end
initTestSuite;
end
function test_dependency_free_2c
rnfoundry.em.test.test_gap_force_preparation();
end
