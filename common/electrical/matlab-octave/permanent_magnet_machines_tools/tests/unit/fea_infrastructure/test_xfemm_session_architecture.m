function test_suite = test_xfemm_session_architecture()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_generic_owner_contains_no_machine_topology_policy()
path=which('rnfoundry.em.fea.XFemmSessionAnalysis'); source=lower(fileread(path));
for token={'setageposition','slidingmesh','armature','internal','external', ...
        'setcircuit','num2str'}
    assertTrue(isempty(strfind(source,token{1})), ...
        sprintf('Generic session owner unexpectedly contains %s.',token{1}));
end
end
