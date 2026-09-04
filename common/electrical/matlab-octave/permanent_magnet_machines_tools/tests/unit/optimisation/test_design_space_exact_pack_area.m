function test_suite=test_design_space_exact_pack_area()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_build_without_injected_pack_area()
base=makeExternalSlottedMachine(); d=base.toLegacyStruct();
if isfield(d,'CoilArea'), d=rmfield(d,'CoilArea'); end
candidate=rnfoundry.em.optim.RadialSlottedDesignCandidate.fromFlat(zeros(16,1),d,true,struct());
space=rnfoundry.em.optim.RadialSlottedDesignSpace(struct('ArmatureType','external'));
machine=space.build(candidate,struct()); g=machine.Armature.Winding.CoilGeometry;
assertTrue(all(isfinite(g.LayerPackAreas))&&all(g.LayerPackAreas>0));
assertElementsAlmostEqual(g.PackArea,min(g.LayerPackAreas),'absolute',1e-15);
assertElementsAlmostEqual(g.TotalPackArea,sum(g.LayerPackAreas),'absolute',1e-15);
end
