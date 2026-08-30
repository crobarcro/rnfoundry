function prepared=prepareRadialSlottedMagneticModel(machine,sweepResult,options)
%PREPARERADIALSLOTTEDMAGNETICMODEL Fit an existing raw zero-current sweep.
%   This deterministic service performs no FEA.  Positions are normalized
%   in pole spans and both returned public models have period two. OPTIONS
%   may contain NSkewPositions, a positive integer with default value 10.

validateInputs(machine,sweepResult);
if nargin < 3, options=struct(); end
nSkewPositions=resolveOptions(options);
w=machine.Armature.Winding;

[slotPosition,slotIntegral]=flattenSlotA(sweepResult.SlotVectorPotential);
[slotPosition,order]=sort(slotPosition);
slotIntegral=slotIntegral(order,:,:);
[slotPosition,uniqueIndex]=unique(slotPosition);
slotIntegral=slotIntegral(uniqueIndex,:,:);
domainEnd=slotPosition(1)+2;
use=slotPosition <= domainEnd;
position=slotPosition(use);
coilPitch=machine.Armature.thetas*w.CoilPitchSlots/machine.thetap;

if w.LayerCount == 1
    integral=slotIntegral(use,1,1);
    if position(end) < domainEnd
        position(end+1)=domainEnd;
        integral=[integral;interp1(slotPosition,slotIntegral(:,1,1),domainEnd)];
    end
    intAFit=slmengine(position,integral,'EndCon','periodic', ...
        'knots',ceil(numel(position)/2),'Plot','off');
else
    integral=slotIntegral(use,1:2,1);
    if position(end) < domainEnd
        position(end+1)=domainEnd;
        integral=[integral;interp1(slotPosition,slotIntegral(:,1:2,1),domainEnd)];
    end
    intAFit(1)=slmengine(position,integral(:,1),'EndCon','periodic', ...
        'knots',ceil(numel(position)/2),'Plot','off');
    intAFit(2)=slmengine(position,integral(:,2),'EndCon','periodic', ...
        'knots',ceil(numel(position)/2),'Plot','off');
end

peakGrid=linspace(0,1,1000);
peakWave=fluxlinkagefrmintAslm(intAFit,coilPitch,peakGrid,w.TurnsPerCoil, ...
    sweepResult.CoilArea,'Skew',machine.Field.MagnetSkew, ...
    'NSkewPositions',nSkewPositions);
[~,peakIndex]=max(abs(peakWave));
peakPosition=peakGrid(peakIndex(1));
lookupPosition=linspace(0,2,200);
lookupFlux=fluxlinkagefrmintAslm(intAFit,coilPitch,lookupPosition,w.TurnsPerCoil, ...
    sweepResult.CoilArea,'Skew',machine.Field.MagnetSkew, ...
    'NSkewPositions',nSkewPositions,'Offset',peakPosition);
% Preserve the legacy final-fit's historically odd max(50,min(20,...)) expression.
fluxFit=slmengine(lookupPosition,lookupFlux,'EndCon','periodic','knots',50,'Plot','off');
samples=slmeval(linspace(0,2,1000),fluxFit,0,false);
fluxRMS=sqrt(mean(samples.^2));
coilPeak=slmpar(fluxFit,'maxfun');
fluxModel=rnfoundry.em.FluxLinkageModel(fluxFit,fluxRMS,coilPeak, ...
    coilPeak*w.CoilsPerBranch,peakPosition);

rawFit=slmengine(sweepResult.Positions,sweepResult.CoggingTorque./machine.ls, ...
    'EndCon','periodic','knots',numel(sweepResult.Positions),'Plot','off');
skewOffset=linspace(-machine.Field.MagnetSkew/2,machine.Field.MagnetSkew/2, ...
    nSkewPositions).';
coggingPosition=linspace(0,2,100);
sections=periodicslmeval(bsxfun(@plus,coggingPosition,skewOffset),rawFit,0,false);
coggingTorque=(machine.ls/nSkewPositions)*sum(sections,1);
coggingFit=slmengine(coggingPosition,coggingTorque,'EndCon','periodic', ...
    'knots',2*numel(sweepResult.Positions),'Plot','off');
coggingModel=rnfoundry.em.CoggingTorqueModel(coggingFit,slmpar(coggingFit,'maxfun'));
prepared=rnfoundry.em.PreparedMachineModel(machine, ...
    rnfoundry.em.PreparedMagneticModel(fluxModel,coggingModel));
end

function nSkewPositions=resolveOptions(options)
if ~isstruct(options) || ~isscalar(options)
    error('rnfoundry:em:InvalidMagneticPreparationOptions', ...
        'Magnetic preparation options must be a scalar structure.');
end
names=fieldnames(options);
if any(~strcmp(names,'NSkewPositions'))
    error('rnfoundry:em:InvalidMagneticPreparationOptions', ...
        'Only NSkewPositions is supported by magnetic preparation.');
end
if isfield(options,'NSkewPositions'), nSkewPositions=options.NSkewPositions;
else, nSkewPositions=10;
end
if ~isnumeric(nSkewPositions) || ~isscalar(nSkewPositions) ...
        || ~isfinite(nSkewPositions) || nSkewPositions<1 ...
        || nSkewPositions~=fix(nSkewPositions)
    error('rnfoundry:em:InvalidMagneticPreparationOptions', ...
        'NSkewPositions must be a finite positive integer scalar.');
end
end

function validateInputs(machine,result)
if ~isa(machine,'rnfoundry.em.rotary.radial.SlottedPMMachine') ...
        || ~isa(result,'rnfoundry.em.fea.MagneticSweepResult')
    error('rnfoundry:em:InvalidMagneticPreparationInput', ...
        'Inputs must be a SlottedPMMachine and MagneticSweepResult.');
end
p=result.Positions(:);
if any(diff(p)<=0) || abs(p(1))>100*eps || abs(p(end)-1)>100*eps ...
        || ~(isscalar(result.CoilArea)&&isfinite(result.CoilArea)&&result.CoilArea>0)
    error('rnfoundry:em:IncompatibleMagneticSweep', ...
        'The sweep must span [0,1] monotonically and contain finite positive CoilArea.');
end
if isfield(result.Provenance,'PhaseCurrents') ...
        && (numel(result.Provenance.PhaseCurrents)~=machine.Armature.Winding.PhaseCount ...
        || any(result.Provenance.PhaseCurrents(:)~=0))
    error('rnfoundry:em:IncompatibleMagneticSweep','A compatible zero-current sweep is required.');
end
sv=result.SlotVectorPotential;
if ~isstruct(sv) || ~all(isfield(sv,{'Position','Integral'})) ...
        || size(sv.Position,1)~=numel(p) || size(sv.Integral,1)~=numel(p) ...
        || size(sv.Integral,2)~=size(sv.Position,2) ...
        || size(sv.Integral,3)<machine.Armature.Winding.LayerCount ...
        || any(~isfinite(sv.Position(:))) || any(~isfinite(sv.Integral(:)))
    error('rnfoundry:em:IncompatibleMagneticSweep','Slot-vector-potential dimensions are incompatible.');
end
end

function [position,integral]=flattenSlotA(slotA)
% 2A stores [sweep,slot,layer,component]; legacy concatenates sweep blocks.
position=slotA.Position.'; position=position(:);
v=permute(slotA.Integral,[2,1,3,4]);
integral=reshape(v,size(v,1)*size(v,2),size(v,3),size(v,4));
end
