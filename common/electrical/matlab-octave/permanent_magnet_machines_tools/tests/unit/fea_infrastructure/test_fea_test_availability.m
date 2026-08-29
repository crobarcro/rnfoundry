function test_suite=test_fea_test_availability()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_not_opted_in_is_skipped()
s=classify_fea_test_availability(false,false,false,false,false);
assertFalse(s.CanRun); assertEqual(s.Kind,'skipped');
assertTrue(~isempty(strfind(s.Message,'SKIPPED')));
end

function test_missing_api_is_unavailable()
s=classify_fea_test_availability(true,false,false,false,false);
assertFalse(s.CanRun); assertEqual(s.Kind,'unavailable-api');
assertTrue(~isempty(strfind(s.Message,'xfemm.femmsession')));
end

function test_missing_or_unloadable_native_runtime_is_unavailable()
cases={[false,true,true],[true,false,true],[true,true,false]};
for k=1:numel(cases)
    values=cases{k};
    s=classify_fea_test_availability(true,true,values(1),values(2),values(3));
    assertFalse(s.CanRun); assertEqual(s.Kind,'unavailable-runtime');
    assertTrue(~isempty(strfind(s.Message,'UNAVAILABLE')));
end
end

function test_fully_configured_environment_runs()
s=classify_fea_test_availability(true,true,true,true,true);
assertTrue(s.CanRun); assertEqual(s.Kind,'available');
end
