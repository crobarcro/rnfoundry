function test_suite = test_radial_pm_field()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_valid_queries_and_round_trip()
f=makeExternalSlottedMachine().Field;
assertElementsAlmostEqual(f.Rmm,0.0755,'absolute',1e-14);
assertElementsAlmostEqual(f.Rbm,0.0665,'absolute',1e-14);
assertElementsAlmostEqual(f.MagnetThickness,0.005,'absolute',1e-14);
assertElementsAlmostEqual(f.BackIronThickness,0.013,'absolute',1e-14);
r=rnfoundry.em.rotary.radial.RadialPMField.fromStruct(f.toStruct());
assertEqual(r.toStruct(),f.toStruct());
end

function test_invalid_radii_and_angle()
s=makeExternalSlottedMachine().Field.toStruct();
s.Rmi=s.Rmo;
assertExceptionThrown(@() rnfoundry.em.rotary.radial.RadialPMField(s), ...
    'rnfoundry:em:InvalidFieldRadii');
s=makeExternalSlottedMachine().Field.toStruct(); s.thetam=0;
assertExceptionThrown(@() rnfoundry.em.rotary.radial.RadialPMField(s), ...
    'rnfoundry:em:InvalidMagnetAngle');
end
