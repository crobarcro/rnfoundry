function [input, legacy] = modeInput(position, mode, layers, windingCase)
seed = rnfoundry.em.test.baseInput(position,layers,windingCase);
legacy = completedesign_RADIAL_SLOTTED(seed,struct(),'tdims');
common = {'ArmatureType','Phases','CoilLayers','Poles','qc','yd','CoilTurns', ...
          'CoilFillFactor','NStrands','Branches','CoilArea', ...
          'CoilInsulationThickness','MagnetSkew','NStages','MagFEASimMaterials'};
input = copyFields(legacy,common);
switch mode
    case 'tdims'
        names={'g','ty','tm','tc','tsb','tbi','tsg','thetam','thetacg', ...
               'thetacy','thetasg','ls'};
        if strcmp(position,'external'), names=[{'Ryo'},names]; else, names=[{'Rbo'},names]; end
    case 'radims'
        names={'Rmi','Rmo','Rbi','Rbo','Ryi','Ryo','Rtsb','tsg','thetam', ...
               'thetacg','thetacy','thetasg','ls','Rcb'};
        if strcmp(position,'external'), names=[names,{'Rai'}]; else, names=[names,{'Rao'}]; end
    case 'ratios'
        names={'RmiVRmo','RyiVRyo','tsgVtsb','thetamVthetap', ...
               'thetacgVthetas','thetacyVthetas','thetasgVthetacg','lsVtm','Rcb'};
        if strcmp(position,'external')
            names=[{'Ryo','RtsbVRyi','RaiVRtsb','RmoVRai','RbiVRmi'},names];
        else
            names=[{'Rbo','RmoVRbo','RaoVRmi','RtsbVRao','RyoVRtsb'},names];
        end
end
input=mergeFields(input,legacy,names);
end
function out=copyFields(source,names)
out=struct();
for k=1:numel(names), if isfield(source,names{k}), out.(names{k})=source.(names{k}); end; end
end
function out=mergeFields(out,source,names)
for k=1:numel(names), if isfield(source,names{k}), out.(names{k})=source.(names{k}); end; end
end
