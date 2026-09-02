function assertRadialSlotRegionAreaParity(position,drawInsulation)
%ASSERTRADIALSLOTREGIONAREAPARITY Compare every exact region with FEMM.
machine=makeFEASlottedMachine(position);
% Area parity does not need the production magnetic-sweep refinement. Using
% FEMM automatic region meshes reduces the oracle's native-memory footprint;
% the actual line/arc boundary remains unchanged.
meshOptions=struct('MagnetRegionMeshSize',-1,'BackIronRegionMeshSize',-1, ...
    'AirGapMeshSize',-1,'OuterRegionsMeshSize',[-1,-1], ...
    'YokeRegionMeshSize',-1,'CoilRegionMeshSize',-1, ...
    'ShoeGapRegionMeshSize',-1);
meshOptions.NPositions=2;
meshOptions.DrawCoilInsulation=drawInsulation;
meshOptions.AreaOnly=true;
r=runLegacyRawMagneticSweep(machine,meshOptions);
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
% This tolerance covers FEMM boundary-mesh discretization while remaining
% well below the geometry mismatch that this oracle is intended to detect.
for k=1:numel(r.CoilAreas)
    relativeError=abs(r.CoilAreas(k)-g.LayerPackAreas(k))/g.LayerPackAreas(k);
    fprintf('area parity %s insulation=%d layer=%d analytic=%.16g FEMM=%.16g relative_error=%.6g\n', ...
        position,drawInsulation,k,g.LayerPackAreas(k),r.CoilAreas(k),relativeError);
    tol=max(1e-9,1e-3*g.LayerPackAreas(k));
    assertTrue(abs(r.CoilAreas(k)-g.LayerPackAreas(k))<=tol);
end
end
