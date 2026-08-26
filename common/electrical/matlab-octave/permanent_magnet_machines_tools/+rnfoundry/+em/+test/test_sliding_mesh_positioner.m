function test_sliding_mesh_positioner()
external=rnfoundry.em.rotary.radial.SlidingMeshPositioner('external',{'age'});
[inner,outer]=external.angles(pi/3);
rnfoundry.em.test.assertNear(inner,60,1e-12);
rnfoundry.em.test.assertNear(outer,0,0);
internal=rnfoundry.em.rotary.radial.SlidingMeshPositioner('internal',{'age'});
[inner,outer]=internal.angles(-pi/4);
rnfoundry.em.test.assertNear(inner,0,0);
rnfoundry.em.test.assertNear(outer,-45,1e-12);
rnfoundry.em.test.assertError(@() rnfoundry.em.rotary.radial.SlidingMeshPositioner('linear',{'age'}), ...
    'rnfoundry:em:InvalidArmaturePosition');
end
