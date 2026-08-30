function resolved = resolveMagneticSweepOptions(machine, options)
%RESOLVEMAGNETICSWEEPOPTIONS Resolve legacy-equivalent main-sweep options.
%   Pure preparation boundary: no drawing, xfemm session, or machine mutation.
if nargin < 2, options=struct(); end
if ~isa(machine,'rnfoundry.em.rotary.radial.SlottedPMMachine')
    error('rnfoundry:em:InvalidSweepMachine','machine must be a SlottedPMMachine.');
end
if ~isstruct(options) || ~isscalar(options)
    error('rnfoundry:em:InvalidSweepOptions','options must be a scalar structure.');
end
allowed={'NPositions','PhaseCurrents','AirGapMaterial', ...
    'MagnetRegionMeshSize','BackIronRegionMeshSize','AirGapMeshSize', ...
    'OuterRegionsMeshSize','YokeRegionMeshSize','CoilRegionMeshSize', ...
    'ShoeGapRegionMeshSize'};
names=fieldnames(options);
for k=1:numel(names)
    if ~any(strcmp(names{k},allowed))
        error('rnfoundry:em:UnknownSweepOption','Unknown sweep option: %s',names{k});
    end
end

d=machine.toLegacyStruct();
resolved=struct();
resolved.NPositions=10;
resolved.PhaseCurrents=zeros(machine.Armature.Winding.PhaseCount,1);
resolved.AirGapMaterial='Air';
resolved.MagnetRegionMeshSize=meshArea(d.tm,d.Rmm*d.thetam,1/10);
resolved.BackIronRegionMeshSize=meshArea(min(d.tbi),2*d.Rbm*d.thetap,1/10);
resolved.AirGapMeshSize=meshArea(d.g,d.Rmm*d.thetap,1/10);
resolved.OuterRegionsMeshSize=[meshArea(d.tm,d.Rbo*d.thetap,1/5),-1];
resolved.YokeRegionMeshSize=mean([ ...
    meshArea(d.ty,2*d.Rym*d.thetap,1/10), ...
    meshArea(d.tc(1),d.Rcm*(d.thetas-max(d.thetac)),1/10)]);
resolved.CoilRegionMeshSize=meshArea(d.tc(1),d.Rcm*mean(d.thetac),0.05);
if d.tsg > 1e-5
    if d.tsb > 1e-5, shoeWidth=max(d.tsg,d.tsb); else, shoeWidth=d.tsb; end
    resolved.ShoeGapRegionMeshSize=meshArea(shoeWidth,d.Rmo*d.thetasg,1/20);
elseif d.tsb > 1e-5
    resolved.ShoeGapRegionMeshSize=meshArea(d.tsb,d.Rmo*d.thetasg,1/20);
else
    resolved.ShoeGapRegionMeshSize=-1;
end
for k=1:numel(names), resolved.(names{k})=options.(names{k}); end
validateResolved(resolved,machine);
resolved.PhaseCurrents=resolved.PhaseCurrents(:);
resolved.OuterRegionsMeshSize=reshape(resolved.OuterRegionsMeshSize,1,2);
end

function value=meshArea(w,h,fraction)
% Exact choosemesharea_mfemm numerical definition, kept solver-independent.
value=min([5*w*fraction,5*h*fraction,sqrt(w^2+h^2)*fraction]);
end

function validateResolved(o,machine)
if ~(isscalar(o.NPositions)&&isnumeric(o.NPositions)&&isfinite(o.NPositions) ...
        && o.NPositions==fix(o.NPositions)&&o.NPositions>=2)
    error('rnfoundry:em:InvalidSweepOptions','NPositions must be an integer of at least two.');
end
if ~isnumeric(o.PhaseCurrents) ...
        || numel(o.PhaseCurrents)~=machine.Armature.Winding.PhaseCount ...
        || any(~isfinite(o.PhaseCurrents(:)))
    error('rnfoundry:em:InvalidSweepOptions','PhaseCurrents must contain one finite value per phase.');
end
if any(o.PhaseCurrents(:)~=0)
    error('rnfoundry:em:NonzeroSweepCurrent', ...
        'Milestone 2A is a zero-current cogging and permanent-magnet flux sweep.');
end
validName=ischar(o.AirGapMaterial)&&~isempty(o.AirGapMaterial);
validStruct=isstruct(o.AirGapMaterial)&&isscalar(o.AirGapMaterial) ...
    && isfield(o.AirGapMaterial,'Name')&&ischar(o.AirGapMaterial.Name) ...
    && ~isempty(o.AirGapMaterial.Name);
if ~(validName||validStruct)
    error('rnfoundry:em:InvalidSweepOptions','AirGapMaterial must be a library name or material structure.');
end
scalarMeshes={'MagnetRegionMeshSize','BackIronRegionMeshSize','AirGapMeshSize', ...
    'YokeRegionMeshSize','CoilRegionMeshSize','ShoeGapRegionMeshSize'};
for k=1:numel(scalarMeshes)
    value=o.(scalarMeshes{k});
    if ~(isnumeric(value)&&isscalar(value)&&isfinite(value)&&(value>0||value==-1))
        error('rnfoundry:em:InvalidSweepOptions','%s must be positive or -1.',scalarMeshes{k});
    end
end
value=o.OuterRegionsMeshSize;
if ~(isnumeric(value)&&isvector(value)&&numel(value)==2&&all(isfinite(value(:))) ...
        && all(value(:)>0|value(:)==-1))
    error('rnfoundry:em:InvalidSweepOptions', ...
        'OuterRegionsMeshSize must be a two-element vector of positive values or -1.');
end
end
