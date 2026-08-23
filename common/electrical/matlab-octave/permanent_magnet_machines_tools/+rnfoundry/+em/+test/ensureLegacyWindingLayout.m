function outputDirectory = ensureLegacyWindingLayout()
%ENSURELEGACYWINDINGLAYOUT Build the optional legacy test dependency if needed.
outputDirectory=fullfile(tempdir(),'rnfoundry-em-m1a-mex');
if exist('mexmPhaseWL','file')==3, return; end
existing=fullfile(outputDirectory,['mexmPhaseWL.',mexext()]);
if exist(existing,'file'), addpath(outputDirectory,'-begin'); return; end
if ~exist(outputDirectory,'dir'), mkdir(outputDirectory); end
sourceDirectory=fileparts(which('windinglayout'));
names={'wire_size.cpp','wire.cpp','starofslot.cpp','coil.cpp', ...
       'winding.cpp','m_phase_winding.cpp','mexmPhaseWL.cpp'};
sources=cell(size(names));
for k=1:numel(names), sources{k}=fullfile(sourceDirectory,names{k}); end
if exist('OCTAVE_VERSION','builtin')
    command='mkoctfile --mex';
    for k=1:numel(sources), command=[command,' "',sources{k},'"']; end
    command=[command,' -o "',fullfile(outputDirectory,['mexmPhaseWL.',mexext()]),'"'];
    [status,output]=system(command);
    if status~=0, error('rnfoundry:em:test:MexBuildFailed','Could not build mexmPhaseWL: %s',output); end
else
    args=[sources,{'-outdir',outputDirectory,'-output','mexmPhaseWL'}];
    mex(args{:});
end
addpath(outputDirectory,'-begin');
end
