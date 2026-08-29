function [available,details]=probe_xfemm_session_runtime()
%PROBE_XFEMM_SESSION_RUNTIME Load the native gateways without solving a model.
% femmsession embeds its mesher/solver in session_interface_mex; there is no
% separate executable to locate. Loading that gateway and constructing the
% inherited postprocessor proves the required native runtime can be used.
available=false; details=''; handle=[];
try
    handle=fpproc_interface_mex('new');
    cleanup=onCleanup(@() deletePostProcessor(handle)); %#ok<NASGU>
catch err
    if isNativeLoadError(err), details=err.message; return; end
    rethrow(err);
end
try
    session_interface_mex();
    error('rnfoundry:test:UnexpectedSessionProbeResult', ...
        'session_interface_mex unexpectedly accepted an empty command.');
catch err
    if strcmp(err.identifier,'MFEMM:session:error') ...
            && ~isempty(strfind(lower(err.message),'first input must be a command'))
        available=true; details='native femmsession gateways loaded'; return;
    end
    if isNativeLoadError(err), details=err.message; return; end
    rethrow(err);
end
end

function deletePostProcessor(handle)
if ~isempty(handle), fpproc_interface_mex('delete',handle); end
end

function tf=isNativeLoadError(err)
message=lower(err.message);
patterns={'invalid mex-file','invalid mex file','failed to load', ...
    'cannot open shared object','specified module could not be found', ...
    'image not found','undefined symbol','wrong architecture', ...
    'not a valid win32'};
tf=strcmp(err.identifier,'MATLAB:invalidMEXFile');
for k=1:numel(patterns), tf=tf||~isempty(strfind(message,patterns{k})); end
end
