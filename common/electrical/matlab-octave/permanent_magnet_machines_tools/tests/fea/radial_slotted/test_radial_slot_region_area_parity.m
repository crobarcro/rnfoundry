function test_suite=test_radial_slot_region_area_parity()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_external_all_coil_faces_match_femm()
assertAreaParity('external');
end
function test_internal_all_coil_faces_match_femm()
assertAreaParity('internal');
end
function assertAreaParity(position)
machine=makeFEASlottedMachine(position);
r=runLegacyRawMagneticSweep(machine,struct('NPositions',1));
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
    'DrawCoilInsulation',d.CoilInsulationThickness>0, ...
    'CoilInsulationThickness',d.CoilInsulationThickness);
assertEqual(numel(r.CoilAreas),numel(g.LayerPackAreas));
% Block integral 5 integrates the meshed curved boundary. A 0.1% relative
% tolerance allows normal FEMM boundary-mesh convergence while remaining
% tighter than the historical 0.25--0.30% layer-count perimeter defect.
for k=1:numel(r.CoilAreas)
    tol=max(1e-9,1e-3*g.LayerPackAreas(k));
    assertTrue(abs(r.CoilAreas(k)-g.LayerPackAreas(k))<=tol);
end
end
