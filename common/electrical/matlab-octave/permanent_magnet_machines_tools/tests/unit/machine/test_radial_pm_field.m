function test_suite = test_radial_pm_field()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_valid_queries_and_round_trip()
f=makeExternalSlottedMachine().Field;
assertEqual(f.MagnetPolarisation,'radial');
assertElementsAlmostEqual(f.Rmm,0.0755,'absolute',1e-14);
assertElementsAlmostEqual(f.Rbm,0.0665,'absolute',1e-14);
assertElementsAlmostEqual(f.MagnetThickness,0.005,'absolute',1e-14);
assertElementsAlmostEqual(f.BackIronThickness,0.013,'absolute',1e-14);
r=rnfoundry.em.rotary.radial.RadialPMField.fromStruct(f.toStruct());
assertEqual(r.toStruct(),f.toStruct());
end

function test_polarisation_default_old_struct_and_legacy_export()
m=makeInternalSlottedMachine();
assertEqual(m.Field.MagnetPolarisation,'constant');
old=m.Field.toStruct(); old=rmfield(old,'MagnetPolarisation');
loaded=rnfoundry.em.rotary.radial.RadialPMField.fromStruct(old);
assertEqual(loaded.MagnetPolarisation,'constant');
roundTrip=rnfoundry.em.rotary.radial.RadialPMField.fromStruct( ...
    makeExternalSlottedMachine().Field.toStruct());
assertEqual(roundTrip.MagnetPolarisation,'radial');
assertEqual(makeExternalSlottedMachine().toLegacyStruct().MagnetPolarisation,'radial');
end

function test_invalid_radii_and_angle()
s=makeExternalSlottedMachine().Field.toStruct();
s.Rmi=s.Rmo;
assertExceptionThrown(@() rnfoundry.em.rotary.radial.RadialPMField(s), ...
    'rnfoundry:em:InvalidFieldRadii');
s=makeExternalSlottedMachine().Field.toStruct(); s.thetam=0;
assertExceptionThrown(@() rnfoundry.em.rotary.radial.RadialPMField(s), ...
    'rnfoundry:em:InvalidMagnetAngle');
s=makeExternalSlottedMachine().Field.toStruct(); s.MagnetPolarisation='axial';
assertExceptionThrown(@() rnfoundry.em.rotary.radial.RadialPMField(s), ...
    'rnfoundry:em:InvalidMagnetPolarisation');
end
