function result=runBoundedRadialSlotAreaOracle(machine,drawCoilInsulation)
%RUNBOUNDEDRADIALSLOTAREAORACLE Solve one production-drawn slot in air.
%   This Tier-2 fixture deliberately omits the rotor, repeated slots, iron,
%   and magnetic post-processing. CURVEDSTATORHALF2DFEMMPROBLEM still draws
%   the real legacy radial slot from RADIALSLOTGEOMETRY, including internal
%   reflection, line/arc primitives, divider topology, and label positions.
d=machine.toLegacyStruct();
if strncmpi(d.ArmatureType,'external',1)
    side='i'; roffset=d.Rmo+d.g+d.tc(1)+d.tsb+d.ty/2;
else
    side='o'; roffset=d.Rmi-d.g-d.tc(1)-d.tsb-d.ty/2;
end
basefrac=.05; if numel(d.tc)>1, basefrac=d.tc(2)/d.tc(1); end
shoe=.5; if isfield(d,'ShoeCurveControlFrac'), shoe=d.ShoeCurveControlFrac; end

problem=newproblem_mfemm('planar','LengthUnits','meters','Depth',1);
problem.Materials=newmaterial_mfemm('Air');
[problem,~,coilLabels,slotInfo]=curvedstatorhalf2dfemmproblem( ...
    1,0,d.thetac,d.thetasg,d.ty,d.tc(1),d.tsb,d.tsg,roffset,side, ...
    'NWindingLayers',d.CoilLayers,'FemmProblem',problem, ...
    'ShoeGapMaterial',1,'ShoeGapRegionMeshSize',-1, ...
    'CoilBaseFraction',basefrac,'ShoeCurveControlFrac',shoe, ...
    'DrawCoilInsulation',drawCoilInsulation, ...
    'CoilInsulationThickness',d.CoilInsulationThickness);

% Label every explicitly bounded region with the same zero-source material.
for k=1:size(coilLabels,1)
    problem=addblocklabel_mfemm(problem,coilLabels(k,1),coilLabels(k,2), ...
        'BlockType','Air','MaxArea',-1);
end
for k=1:size(slotInfo.inslabelloc,1)
    problem=addblocklabel_mfemm(problem,slotInfo.inslabelloc(k,1), ...
        slotInfo.inslabelloc(k,2),'BlockType','Air','MaxArea',-1);
end

% Close the otherwise intentionally open single-slot drawing in a small air
% box. A default label fills tooth/ambient regions without adding geometry to
% the slot boundary under test.
coords=reshape([problem.Nodes.Coords],2,[])';
span=max(max(coords)-min(coords)); margin=max(.01,.25*span);
lo=min(coords)-margin; hi=max(coords)+margin;
[problem,boundarySegments]=addrectangle_mfemm(problem,lo(1),lo(2), ...
    hi(1)-lo(1),hi(2)-lo(2));
[problem,~,boundaryName]=addboundaryprop_mfemm(problem,'Area oracle A=0',0,'A0',0);
for k=boundarySegments
    problem.Segments(k).BoundaryMarker=boundaryName;
end
problem=addblocklabel_mfemm(problem,lo(1)+margin/4,lo(2)+margin/4, ...
    'BlockType','Air','MaxArea',-1,'IsDefault',true);

filename=[tempname(),'_rnfoundry_slot_area.fem'];
cleanupFile=onCleanup(@() deleteIfPresent(filename)); %#ok<NASGU>
writefemmfile(filename,problem);
session=xfemm.femmsession(filename);
cleanupSession=onCleanup(@() delete(session)); %#ok<NASGU>
session.solve();
areas=zeros(size(coilLabels,1),1);
for k=1:numel(areas)
    areas(k)=session.blockintegral(5,coilLabels(k,1),coilLabels(k,2));
end
result=struct('CoilAreas',areas,'CoilLabelLocations',coilLabels, ...
    'PhysicalGeometry',slotInfo.PhysicalGeometry, ...
    'DrawCoilInsulation',drawCoilInsulation);
end

function deleteIfPresent(filename)
if exist(filename,'file')==2, delete(filename); end
end
