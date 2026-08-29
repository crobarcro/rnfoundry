function test_suite=test_external_femmsession_parity()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_external_raw_sweep_parity()
assertRawSweepParity('external');
end
