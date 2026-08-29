function test_suite = test_sliding_mesh_positioner()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_external_orientation()
p=rnfoundry.em.rotary.radial.SlidingMeshPositioner('external',{'age-1'});
[inner,outer]=p.angles(pi/3);
assertElementsAlmostEqual(inner,60,'absolute',1e-12); assertEqual(outer,0);
end

function test_internal_orientation()
p=rnfoundry.em.rotary.radial.SlidingMeshPositioner('internal',{'age-1'});
[inner,outer]=p.angles(-pi/4);
assertEqual(inner,0); assertElementsAlmostEqual(outer,-45,'absolute',1e-12);
end

function test_signed_positions_and_boundary_collection()
p=rnfoundry.em.rotary.radial.SlidingMeshPositioner('external',{'age-a','age-b'});
assertEqual(p.BoundaryNames,{'age-a','age-b'});
[a,~]=p.angles([-pi/6,pi/6]);
assertElementsAlmostEqual(a,[-30,30],'absolute',1e-12);
end

function test_invalid_position_and_boundaries()
assertExceptionThrown(@() rnfoundry.em.rotary.radial.SlidingMeshPositioner('linear',{'age'}), ...
    'rnfoundry:em:InvalidArmaturePosition');
assertExceptionThrown(@() rnfoundry.em.rotary.radial.SlidingMeshPositioner('external',{}), ...
    'rnfoundry:em:InvalidAGEBoundaries');
end
