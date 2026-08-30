function test_suite=test_internal_femmsession_parity()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_internal_raw_sweep_parity()
assertRawSweepParity('internal');
end
