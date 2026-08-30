function test_suite = test_magnetic_sweep_result()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_valid_construction_and_value_semantics()
s=makeMagneticSweepData(3); r=rnfoundry.em.fea.MagneticSweepResult(s);
assertEqual(r.CoilArea,1); assertEqual(r.DirectFluxLinkage,zeros(3,3));
s.CoilArea=99; assertEqual(r.CoilArea,1);
copy=r; assertEqual(copy.Positions,r.Positions);
end

function test_inconsistent_torque_length()
s=makeMagneticSweepData(3); s.CoggingTorque=zeros(2,1);
assertInvalid(s);
end

function test_inconsistent_flux_dimensions()
s=makeMagneticSweepData(3); s.DirectFluxLinkage=zeros(2,3);
assertInvalid(s);
end

function test_inconsistent_air_gap_dimensions()
s=makeMagneticSweepData(3); s.AirGapField.Magnitude=zeros(2,2);
assertInvalid(s);
end

function assertInvalid(s)
assertExceptionThrown(@() rnfoundry.em.fea.MagneticSweepResult(s), ...
    'rnfoundry:em:InvalidMagneticSweepResult');
end
