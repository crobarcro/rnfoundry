function [modern,legacy,modernSimOptions,legacySimOptions] = assertCandidateLegacyParity(chrom,options,simoptions)
%ASSERTCANDIDATELEGACYPARITY Compare independent repair with legacy oracle.
if nargin<3, simoptions=struct(); end
space=rnfoundry.em.optim.RadialSlottedDesignSpace(options,simoptions);
[candidate,~]=space.repair(space.decode(chrom));
modern=candidate.toLegacyStruct();
modernSimOptions=candidate.Compatibility.SimOptions;
names=fieldnames(options); args=cell(1,2*numel(names));
for k=1:numel(names), args{2*k-1}=names{k}; args{2*k}=options.(names{k}); end
[legacy,legacySimOptions]=chrom2design_RADIAL_SLOTTED(simoptions,chrom,args{:});
fields={'Ryi','Ryo','Rmi','Rmo','Rbi','Rbo','Rtsb','Rtsg','Rcm', ...
    'tc','tsb','tsg','g','tm','tbi','ty','thetacg','thetacy','thetasg', ...
    'RmiVRmo','RyiVRyo','tsgVtsb','thetamVthetap','thetacgVthetas', ...
    'thetacyVthetas','thetasgVthetacg','lsVtm','Hc','Wc','Dc', ...
    'WireStrandDiameter','NStrands','Branches','CoilsPerBranch'};
orientationFields={'RmoVRbo','RaoVRmi','RtsbVRao','RyoVRtsb', ...
    'RtsbVRyi','RaiVRtsb','RmoVRai','RbiVRmi'};
fields=[fields,orientationFields];
for k=1:numel(fields)
    if isfield(legacy,fields{k})
        if isequal(isnan(modern.(fields{k})),isnan(legacy.(fields{k}))) ...
                && all(isnan(legacy.(fields{k}))(:))
            continue;
        end
        try
            rnfoundry.em.test.assertNear(modern.(fields{k}),legacy.(fields{k}),1e-11);
        catch
            error('rnfoundry:em:test:Parity','Parity failed for %s.',fields{k});
        end
    end
end
end
