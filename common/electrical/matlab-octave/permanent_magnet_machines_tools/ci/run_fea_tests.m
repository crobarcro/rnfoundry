function success = run_fea_tests(moxunitRoot,reportFile,testTarget)
%RUN_FEA_TESTS Opt-in real xfemm parity tier; never called by Tier-1 CI.
%   TESTTARGET optionally selects one test file or directory. The default is
%   the complete Tier-2 tree. CI uses this only to run that tree in isolated
%   MATLAB processes so native solver memory is returned between fixtures.
if nargin < 1, moxunitRoot=''; end
paths=setup_test_paths(moxunitRoot);
optedIn=strcmp(getenv('RNFOUNDRY_RUN_FEA_TESTS'),'1');
% WHICH is portable for package classes; Octave may report zero from EXIST
% even when +xfemm/femmsession.m is resolvable.
classAvailable=~isempty(which('xfemm.femmsession'));
sessionGatewayAvailable=exist('session_interface_mex','file')==3;
postProcessorGatewayAvailable=exist('fpproc_interface_mex','file')==3;
runtimeLoadable=false;
if optedIn&&classAvailable&&sessionGatewayAvailable&&postProcessorGatewayAvailable
    [runtimeLoadable,details]=probe_xfemm_session_runtime();
    if ~runtimeLoadable&&~isempty(details)
        fprintf('xfemm native runtime probe: %s\n',details);
    end
end
state=classify_fea_test_availability(optedIn,classAvailable, ...
    sessionGatewayAvailable,postProcessorGatewayAvailable,runtimeLoadable);
fprintf('%s\n',state.Message);
if ~state.CanRun, success=[]; return; end
if nargin < 2 || isempty(reportFile)
    reportFile=fullfile(paths.RepositoryRoot,'test-results','fea.xml');
end
if nargin < 3 || isempty(testTarget), testTarget=paths.FEATestRoot; end
if exist(testTarget,'file')~=2 && exist(testTarget,'dir')~=7
    error('rnfoundry:test:InvalidFEATestTarget', ...
        'FEA test target does not exist: %s',testTarget);
end
reportDir=fileparts(reportFile);
if exist(reportDir,'dir') ~= 7, mkdir(reportDir); end
success=moxunit_runtests(testTarget,'-recursive','-verbose', ...
    '-junit_xml_file',reportFile);
if ~success, error('rnfoundry:test:FEATestsFailed','Real FEA parity failed.'); end
end
