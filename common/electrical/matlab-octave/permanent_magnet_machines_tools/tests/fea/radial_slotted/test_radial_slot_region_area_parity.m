function test_suite=test_radial_slot_region_area_parity()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_external_uninsulated_all_faces_match_femm()
assertAreaParity('external',false);
end
function test_internal_uninsulated_all_faces_match_femm()
assertAreaParity('internal',false);
end
function test_external_insulated_all_faces_match_femm()
assertAreaParity('external',true);
end
function test_internal_insulated_all_faces_match_femm()
assertAreaParity('internal',true);
end
function assertAreaParity(position,drawInsulation)
machine=makeFEASlottedMachine(position);
r=runLegacyRawMagneticSweep(machine,struct('NPositions',1, ...
    'DrawCoilInsulation',drawInsulation));
d=machine.toLegacyStruct();
if strcmp(position,'external')
    side='i'; roffset=d.Rmo+d.g+d.tc(1)+d.tsb+d.ty/2;
else
    side='o'; roffset=d.Rmi-d.g-d.tc(1)-d.tsb-d.ty/2;
end
basefrac=.05; if numel(d.tc)>1, basefrac=d.tc(2)/d.tc(1); end
shoe=.5; if isfield(d,'ShoeCurveControlFrac'), shoe=d.ShoeCurveControlFrac; end
g=radialslotregions(d.thetac,d.thetasg,d.ty,d.tc(1),d.tsb,d.tsg, ...
    roffset,side,'NWindingLayers',d.CoilLayers, ...
    'CoilBaseFraction',basefrac,'ShoeCurveControlFrac',shoe, ...
    'DrawCoilInsulation',drawInsulation, ...
    'CoilInsulationThickness',d.CoilInsulationThickness);
assertEqual(r.DrawCoilInsulation,drawInsulation);
assertEqual(numel(r.CoilAreas),numel(g.LayerPackAreas));
% This tolerance is for FEMM boundary-mesh discretization. It should be
% revisited from observed refinement convergence when Tier 2 is available.
for k=1:numel(r.CoilAreas)
    tol=max(1e-9,1e-3*g.LayerPackAreas(k));
    assertTrue(abs(r.CoilAreas(k)-g.LayerPackAreas(k))<=tol);
end
end
