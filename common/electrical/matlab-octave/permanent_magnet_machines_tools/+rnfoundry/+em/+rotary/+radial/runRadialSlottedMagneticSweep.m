function result = runRadialSlottedMagneticSweep(machine, options)
%RUNRADIALSLOTTEDMAGNETICSWEEP Raw femmsession-only sliding-mesh sweep.
%   RESULT = ... (MACHINE, OPTIONS) accepts a canonical SlottedPMMachine.
%   OPTIONS contains high-level sampling/current choices and optional named
%   mesh sizes.  Solver selection and rotation mechanics are intentionally
%   not public options.

if nargin < 2, options = struct(); end
if ~isa(machine,'rnfoundry.em.rotary.radial.SlottedPMMachine')
    error('rnfoundry:em:InvalidSweepMachine','machine must be a SlottedPMMachine.');
end
options = validateOptions(options,machine);

design = machine.toLegacyStruct();
design.FirstSlotCenter = 0;
positions = linspace(0,1,options.NPositions);
angles = machine.thetap .* positions;
npolePairs = max(1,ceil(design.pb/2));

args = {'NPolePairs',npolePairs,'NWindingLayers',design.CoilLayers, ...
    'SplitSlot',(design.CoilLayers == 2) && (design.yd == 1), ...
    'Position',angles(1),'CoilCurrent',options.PhaseCurrents, ...
    'DrawingType','SlidingMesh'};
meshMap = {'MagnetRegionMeshSize','MagnetRegionMeshSize'; ...
    'BackIronRegionMeshSize','BackIronRegionMeshSize'; ...
    'AirGapMeshSize','AirGapMeshSize'; ...
    'OuterRegionsMeshSize','StatorOuterRegionsMeshSize'; ...
    'OuterRegionsMeshSize','RotorOuterRegionsMeshSize'; ...
    'YokeRegionMeshSize','YokeRegionMeshSize'; ...
    'CoilRegionMeshSize','CoilRegionMeshSize'; ...
    'ShoeGapRegionMeshSize','ShoeGapRegionMeshSize'};
for k = 1:size(meshMap,1)
    if isfield(options,meshMap{k,1})
        args(end+1:end+2) = {meshMap{k,2},options.(meshMap{k,1})}; %#ok<AGROW>
    end
end
[problem,rotorInfo,statorInfo] = slottedfemmprob_radial(design,args{:});
analysis = rnfoundry.em.fea.XFemmSessionAnalysis(problem);
cleanup = onCleanup(@() delete(analysis)); %#ok<NASGU>
positioner = rnfoundry.em.rotary.radial.SlidingMeshPositioner( ...
    machine.Armature.Position,problem.AGEBoundNames);

n = numel(positions); torque = zeros(n,1); toothB = zeros(n,1);
directFlux = []; airGapMagnitude = zeros(n,100);
slotAPosition = []; slotAIntegral = []; slotBPosition = []; slotBIntegral = [];
coilArea = NaN; ironArea = NaN; radialForce = NaN;
for posind = 1:n
    % Apply at the first position too: this makes the positioner the single
    % authority for AGE state and preserves the legacy zero-angle first solve.
    positioner.apply(analysis,angles(posind));
    analysis.setCircuitCurrents(options.PhaseCurrents);
    analysis.solve();
    session = analysis.Session;
    session.smoothon();

    if posind == 1
        session.clearblock();
        session.groupselectblock([problem.Groups.Magnet,problem.Groups.RotorBackIron]);
        poleAngle = rotorInfo.NDrawnPoles .* design.thetap ./ 2;
        gvector = [cos(poleAngle),sin(poleAngle)];
        radialForce = dot([session.blockintegral(18),session.blockintegral(19)] ...
            ./ rotorInfo.NDrawnPoles,gvector);
        session.clearblock();
        session.groupselectblock(problem.Groups.ArmatureBackIron);
        ironArea = (session.blockintegral(5) ./ statorInfo.NDrawnSlots) .* design.Qs;
        labels = statorInfo.CoilLabelLocations;
        coilArea = session.blockintegral(5,labels(1,1),labels(1,2));
    end

    [toothX,toothY] = toothSamplePoints(design,100);
    toothB(posind) = max(vectorMagnitude(session.getb(toothX,toothY)));
    gapTheta = linspace(0,2 .* design.thetap,100);
    [gapX,gapY] = pol2cart(gapTheta,repmat(design.Rgm,1,100));
    airGapMagnitude(posind,:) = vectorMagnitude(session.getb(gapX,gapY));

    flux = circuitFlux(problem,session,design,npolePairs);
    if isempty(directFlux), directFlux = zeros(n,numel(flux)); end
    directFlux(posind,:) = flux;
    session.clearblock();
    session.groupselectblock([problem.Groups.Magnet,problem.Groups.RotorBackIron]);
    torque(posind) = design.Poles(1) .* session.blockintegral(22) ./ (2 .* npolePairs);

    extractDesign = design; extractDesign.FemmProblem = problem;
    extractDesign.StatorDrawingInfo = statorInfo;
    [apos,aint] = slotintAdata_RADIAL_SLOTTED(extractDesign,angles(posind),session);
    [bpos,bint] = slotBData(extractDesign,angles(posind),session);
    if isempty(slotAPosition)
        slotAPosition=zeros(n,numel(apos));
        slotAIntegral=zeros(n,size(aint,1),size(aint,2),size(aint,3));
        slotBPosition=zeros(n,numel(bpos));
        slotBIntegral=zeros(n,size(bint,1),size(bint,2),size(bint,3));
    end
    slotAPosition(posind,:)=apos(:).';
    slotAIntegral(posind,:,:,:)=reshape(aint,[1,size(aint,1),size(aint,2),size(aint,3)]);
    slotBPosition(posind,:)=bpos(:).';
    slotBIntegral(posind,:,:,:)=reshape(bint,[1,size(bint,1),size(bint,2),size(bint,3)]);
end

s = struct('Positions',positions(:),'CoggingTorque',torque, ...
    'DirectFluxLinkage',directFlux,'ToothFluxDensity',toothB, ...
    'SlotVectorPotential',struct('Position',slotAPosition,'Integral',slotAIntegral), ...
    'SlotFlux',struct('Position',slotBPosition,'Integral',slotBIntegral), ...
    'AirGapField',struct('Theta',gapTheta,'Magnitude',airGapMagnitude), ...
    'CoilArea',coilArea,'ArmatureIronArea',ironArea, ...
    'PerPoleRadialForce',radialForce, ...
    'Provenance',struct('Solver','xfemm.femmsession','Rotation','SlidingMesh', ...
        'NPolePairs',npolePairs,'AGEBoundaryNames',{problem.AGEBoundNames}, ...
        'NPositions',n,'PhaseCurrents',options.PhaseCurrents));
result = rnfoundry.em.fea.MagneticSweepResult(s);
end

function options = validateOptions(options,machine)
if ~isstruct(options) || ~isscalar(options)
    error('rnfoundry:em:InvalidSweepOptions','options must be a scalar structure.');
end
allowed = {'NPositions','PhaseCurrents','MagnetRegionMeshSize', ...
    'BackIronRegionMeshSize','AirGapMeshSize','OuterRegionsMeshSize', ...
    'YokeRegionMeshSize','CoilRegionMeshSize','ShoeGapRegionMeshSize'};
names = fieldnames(options);
for k=1:numel(names)
    if ~any(strcmp(names{k},allowed))
        error('rnfoundry:em:UnknownSweepOption','Unknown sweep option: %s',names{k});
    end
end
if ~isfield(options,'NPositions'), options.NPositions=10; end
if ~isfield(options,'PhaseCurrents')
    options.PhaseCurrents=zeros(machine.Armature.Winding.PhaseCount,1);
end
if ~(isscalar(options.NPositions) && isfinite(options.NPositions) && ...
        options.NPositions == fix(options.NPositions) && options.NPositions >= 2)
    error('rnfoundry:em:InvalidSweepOptions','NPositions must be an integer of at least two.');
end
if ~isnumeric(options.PhaseCurrents) || ...
        numel(options.PhaseCurrents) ~= machine.Armature.Winding.PhaseCount || ...
        any(~isfinite(options.PhaseCurrents(:)))
    error('rnfoundry:em:InvalidSweepOptions','PhaseCurrents must contain one finite value per phase.');
end
options.PhaseCurrents=options.PhaseCurrents(:);
for k=3:numel(allowed)
    name=allowed{k};
    if isfield(options,name) && ~(isscalar(options.(name)) && isfinite(options.(name)))
        error('rnfoundry:em:InvalidSweepOptions','%s must be a finite scalar.',name);
    end
end
end

function [x,y] = toothSamplePoints(design,n)
if strcmpi(design.ArmatureType,'external')
    radii=linspace(design.Rai,design.Ryo,n);
else
    radii=linspace(design.Ryi,design.Rao,n);
end
[x,y]=pol2cart(repmat(design.thetas,1,n),radii);
end

function value = vectorMagnitude(b)
value=sqrt(sum(b.^2,1));
end

function flux = circuitFlux(problem,session,design,npolePairs)
if isempty(problem.Circuits), flux=NaN; return; end
flux=zeros(1,numel(problem.Circuits));
for k=1:numel(problem.Circuits)
    props=session.getcircuitprops(problem.Circuits(k).Name);
    flux(k)=props(3);
end
flux=flux ./ double(design.qc .* npolePairs .* 2);
end

function [slotPos,slotIntB] = slotBData(design,theta,session)
labels=design.StatorDrawingInfo.CoilLabelLocations;
if design.CoilLayers == 1
    x=labels(:,1); y=labels(:,2); slotIntB=zeros(size(labels,1),2);
    for k=1:numel(y)
        session.clearblock(); session.selectblock(x(k),y(k));
        slotIntB(k,:)=[session.blockintegral(8),session.blockintegral(9)];
    end
else
    x=[labels(1:2:end,1),labels(2:2:end,1)];
    y=[labels(1:2:end,2),labels(2:2:end,2)]; slotIntB=zeros(size(y,1),4);
    for k=1:size(y,1)
        session.clearblock(); session.selectblock(x(k,1),y(k,1));
        slotIntB(k,1:2)=[session.blockintegral(8),session.blockintegral(9)];
        session.clearblock(); session.selectblock(x(k,2),y(k,2));
        slotIntB(k,3:4)=[session.blockintegral(8),session.blockintegral(9)];
    end
end
[thetaSlot,~]=cart2pol(x(:,1),y(:,1));
slotPos=(-thetaSlot./design.thetap)+design.FirstSlotCenter+theta./design.thetap;
end
