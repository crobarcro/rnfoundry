function test_suite = test_armature_and_machine()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_external_and_internal_armature()
e=makeExternalSlottedMachine().Armature;
i=makeInternalSlottedMachine().Armature;
assertEqual(e.Position,'external'); assertEqual(i.Position,'internal');
assertElementsAlmostEqual(e.Rci,0.082,'absolute',1e-14);
assertElementsAlmostEqual(e.Rco,0.102,'absolute',1e-14);
assertElementsAlmostEqual(i.Rci,0.060,'absolute',1e-14);
assertElementsAlmostEqual(i.Rco,0.080,'absolute',1e-14);
assertTrue(isa(e.Winding,'rnfoundry.em.winding.Winding'));
assertEqual(rnfoundry.em.rotary.radial.SlottedArmature.fromStruct(e.toStruct()).toStruct(),e.toStruct());
end

function test_invalid_armature_radial_order()
s=makeExternalSlottedMachine().Armature.toStruct(); s.Rtsb=s.Ra;
assertExceptionThrown(@() rnfoundry.em.rotary.radial.SlottedArmature(s), ...
    'rnfoundry:em:InvalidRadialOrder');
end

function test_machine_geometry_round_trip_and_value_semantics()
e=makeExternalSlottedMachine(); i=makeInternalSlottedMachine();
assertElementsAlmostEqual(e.g,0.002,'absolute',1e-14);
assertElementsAlmostEqual(e.Rgm,0.079,'absolute',1e-14);
assertElementsAlmostEqual(i.g,0.002,'absolute',1e-14);
assertElementsAlmostEqual(i.Rgm,0.086,'absolute',1e-14);
assertElementsAlmostEqual(e.PoleSpan,2*pi/12,'absolute',1e-14);
assertElementsAlmostEqual(e.Armature.thetas,2*pi/36,'absolute',1e-14);
r=rnfoundry.em.rotary.radial.SlottedPMMachine.fromStruct(e.toStruct());
assertEqual(r.toStruct(),e.toStruct());
copy=e; copyStruct=copy.toStruct(); copyStruct.ls=99;
assertEqual(e.ls,0.1); assertEqual(copy.ls,0.1);
end

function test_machine_rejects_wrong_field_orientation()
e=makeExternalSlottedMachine(); f=makeInternalSlottedMachine().Field;
assertExceptionThrown(@() rnfoundry.em.rotary.radial.SlottedPMMachine(f,e.Armature,e.ls), ...
    'rnfoundry:em:InvalidFieldOrientation');
end
