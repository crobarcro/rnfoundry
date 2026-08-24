function test_design_candidate_decode()
%TEST_DESIGN_CANDIDATE_DECODE Characterize the 16/17 element mapping.
space=rnfoundry.em.optim.RadialSlottedDesignSpace();
c=space.decode(baseChrom()); d=c.toLegacyStruct();
assert(d.Rbo==0.32 && d.NBasicWindings==5 && ~isfield(d,'MagnetSkew'));
x=[baseChrom();0.25]; c=space.decode(x); assert(c.Geometry.MagnetSkew==0.25);
rnfoundry.em.test.assertNear(c.Geometry.tm,0.005,1e-15);
rnfoundry.em.test.assertNear(c.Geometry.ls,2,1e-15);
end
function c=baseChrom()
c=[.32;.8;.2;.1;.5;.002;.1;2;.8;.7;.6;.4;.5;5.2;.025;.7];
end
