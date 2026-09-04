function test_suite=test_radial_slot_region_area_splitslot()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_external_splitslot_all_faces_match_femm()
machine=makeFEASlottedMachine('external',true);
r=runBoundedRadialSlotAreaOracle(machine,false);
d=machine.toLegacyStruct();
assertEqual(d.CoilLayers,2); assertEqual(d.yd,1);
roffset=d.Rmo+d.g+d.tc(1)+d.tsb+d.ty/2;
g=radialslotregions(d.thetac,d.thetasg,d.ty,d.tc(1),d.tsb,d.tsg, ...
    roffset,'i','NWindingLayers',2,'SplitSlot',true, ...
    'CoilBaseFraction',d.tc(2)/d.tc(1), ...
    'ShoeCurveControlFrac',d.ShoeCurveControlFrac);
assertEqual(numel(r.CoilAreas),2); assertEqual(numel(g.LayerPackAreas),2);
for k=1:2
    relativeError=abs(r.CoilAreas(k)-g.LayerPackAreas(k))/g.LayerPackAreas(k);
    fprintf('area parity external SplitSlot layer=%d analytic=%.16g FEMM=%.16g relative_error=%.6g\n', ...
        k,g.LayerPackAreas(k),r.CoilAreas(k),relativeError);
    assertTrue(relativeError<=1e-3);
end
end
