function test_suite = test_magnetic_sweep_mesh_options()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_defaults_match_legacy_main_preparation()
m=makeExternalSlottedMachine(); d=m.toLegacyStruct();
o=rnfoundry.em.rotary.radial.resolveMagneticSweepOptions(m,struct());
assertElementsAlmostEqual(o.MagnetRegionMeshSize,area(d.tm,d.Rmm*d.thetam,1/10),'absolute',1e-15);
assertElementsAlmostEqual(o.BackIronRegionMeshSize,area(min(d.tbi),2*d.Rbm*d.thetap,1/10),'absolute',1e-15);
assertElementsAlmostEqual(o.AirGapMeshSize,area(d.g,d.Rmm*d.thetap,1/10),'absolute',1e-15);
assertElementsAlmostEqual(o.OuterRegionsMeshSize,[area(d.tm,d.Rbo*d.thetap,1/5),-1],'absolute',1e-15);
legacyYoke=mean([area(d.ty,2*d.Rym*d.thetap,1/10), ...
    area(d.tc(1),d.Rcm*(d.thetas-max(d.thetac)),1/10)]);
lowerLevelYoke=mean([area(d.ty,2*d.Rym*d.thetap,1/10), ...
    area(d.tc(1),d.Rcm*(d.thetas-mean(d.thetac)),1/10)]);
assertElementsAlmostEqual(o.YokeRegionMeshSize,legacyYoke,'absolute',1e-15);
assertTrue(abs(o.YokeRegionMeshSize-lowerLevelYoke)>eps);
assertElementsAlmostEqual(o.CoilRegionMeshSize,area(d.tc(1),d.Rcm*mean(d.thetac),0.05),'absolute',1e-15);
assertElementsAlmostEqual(o.ShoeGapRegionMeshSize, ...
    area(max(d.tsg,d.tsb),d.Rmo*d.thetasg,1/20),'absolute',1e-15);
end

function test_small_shoe_gap_uses_tooth_shoe_branch()
m=makeExternalSlottedMachine(); a=m.Armature.toStruct(); a.Rtsg=a.Ra;
a.Winding=rnfoundry.em.winding.Winding.fromStruct(a.Winding);
armature=rnfoundry.em.rotary.radial.SlottedArmature(a);
m=rnfoundry.em.rotary.radial.SlottedPMMachine(m.Field,armature,m.ls,m.NStages);
d=m.toLegacyStruct(); o=rnfoundry.em.rotary.radial.resolveMagneticSweepOptions(m,struct());
assertElementsAlmostEqual(o.ShoeGapRegionMeshSize, ...
    area(d.tsb,d.Rmo*d.thetasg,1/20),'absolute',1e-15);
end

function test_overrides_win_and_outer_shape_is_validated()
m=makeExternalSlottedMachine();
o=rnfoundry.em.rotary.radial.resolveMagneticSweepOptions(m,struct( ...
    'YokeRegionMeshSize',0.123,'OuterRegionsMeshSize',[0.456,-1]));
assertEqual(o.YokeRegionMeshSize,0.123); assertEqual(o.OuterRegionsMeshSize,[0.456,-1]);
bad={0.1,[1,2,3],[1,0],[1,-2],'bad'};
for k=1:numel(bad)
    assertExceptionThrown(@() rnfoundry.em.rotary.radial.resolveMagneticSweepOptions( ...
        m,struct('OuterRegionsMeshSize',bad{k})),'rnfoundry:em:InvalidSweepOptions');
end
end

function value=area(w,h,fraction)
value=min([5*w*fraction,5*h*fraction,sqrt(w^2+h^2)*fraction]);
end
