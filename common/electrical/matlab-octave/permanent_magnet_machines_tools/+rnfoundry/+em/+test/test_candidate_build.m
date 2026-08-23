function test_candidate_build()
%TEST_CANDIDATE_BUILD Require exact PackArea and reuse canonical 1A model.
chrom=[.32;.8;.2;.1;.5;.002;.1;2;.8;.7;.6;.4;.05;5.2;.025;.7];
s=rnfoundry.em.optim.RadialSlottedDesignSpace(); [c,~]=s.repair(s.decode(chrom));
rnfoundry.em.test.assertError(@()s.build(c,struct()),'rnfoundry:em:MissingPackArea');
m=s.build(c,struct('PackArea',2e-4,'CoilTurns',1));
assert(isa(m,'rnfoundry.em.rotary.radial.SlottedPMMachine'));
assert(m.Armature.Winding.CoilGeometry.PackArea==2e-4);
assert(abs(m.Armature.Winding.CoilGeometry.PackArea-c.Data.Hc*c.Data.Wc)>eps);
end
