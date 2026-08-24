function test_candidate_build()
%TEST_CANDIDATE_BUILD Require exact PackArea and reuse canonical 1A model.
chrom=[.32;.8;.2;.1;.5;.002;.1;2;.8;.7;.6;.4;.05;5.2;.025;.7];
s=rnfoundry.em.optim.RadialSlottedDesignSpace(); [c,~]=s.repair(s.decode(chrom));
rnfoundry.em.test.assertError(@()s.build(c,struct()),'rnfoundry:em:MissingPackArea');
m=s.build(c,struct('PackArea',2e-4));
assert(isa(m,'rnfoundry.em.rotary.radial.SlottedPMMachine'));
assert(m.Armature.Winding.CoilGeometry.PackArea==2e-4);
assert(abs(m.Armature.Winding.CoilGeometry.PackArea-c.ConductorSizing.Hc*c.ConductorSizing.Wc)>eps);
spec=struct('Dc',c.ConductorSizing.Dc, ...
    'CoilFillFactor',c.ConductorSizing.CoilFillFactor, ...
    'NStrands',c.ConductorSizing.NStrands);
expected=rnfoundry.em.winding.resolvePacking(spec,m.Armature.Winding.CoilGeometry);
assert(m.Armature.Winding.TurnsPerCoil==expected.TurnsPerCoil);
rnfoundry.em.test.assertNear(m.Armature.Winding.Conductor.EquivalentCopperDiameter, ...
    expected.Conductor.EquivalentCopperDiameter,1e-12);
rnfoundry.em.test.assertNear(m.Armature.Winding.Conductor.StrandDiameter, ...
    expected.Conductor.StrandDiameter,1e-12);
assert(m.Armature.Winding.Conductor.StrandCount==expected.Conductor.StrandCount);
rnfoundry.em.test.assertNear(m.Armature.Winding.PackingFactor,expected.PackingFactor,1e-12);
rnfoundry.em.test.assertNear(m.Armature.Winding.CopperFillFactor,expected.CopperFillFactor,1e-12);
rnfoundry.em.test.assertError(@()s.build(c,struct('PackArea',2e-4,'Ryo',1)), ...
    'rnfoundry:em:UnsupportedBuildData');
rnfoundry.em.test.assertError(@()s.build(c,struct('PackArea',2e-4,'CoilArea',3e-4)), ...
    'rnfoundry:em:ConflictingPackArea');
end
