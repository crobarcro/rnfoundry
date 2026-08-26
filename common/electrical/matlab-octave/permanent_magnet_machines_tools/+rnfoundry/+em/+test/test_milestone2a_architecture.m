function test_milestone2a_architecture()
root=fileparts(fileparts(fileparts(fileparts(mfilename('fullpath')))));
sweep=fileread(fullfile(root,'+rnfoundry','+em','+rotary','+radial', ...
    'runRadialSlottedMagneticSweep.m'));
owner=fileread(fullfile(root,'+rnfoundry','+em','+fea','XFemmSessionAnalysis.m'));
forbidden={'simfun_RADIAL_SLOTTED','feasim_RADIAL_SLOTTED','analyse_mfemm', ...
    'fmesher','fsolver','fpproc','xfemm_legacy'};
for k=1:numel(forbidden)
    assert(isempty(strfind(sweep,forbidden{k})), ...
        'rnfoundry:em:ForbiddenSolverPath','New sweep contains forbidden legacy path %s.',forbidden{k});
end
assert(isempty(strfind(owner,'setAGEPosition(')) == false); % generic delegate only
assert(isempty(strfind(owner,'Armature')) && isempty(strfind(owner,'SlidingMesh')));
end
