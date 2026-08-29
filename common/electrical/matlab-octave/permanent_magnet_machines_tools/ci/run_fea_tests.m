function success = run_fea_tests(moxunitRoot,reportFile)
%RUN_FEA_TESTS Opt-in real xfemm parity tier; never called by Tier-1 CI.
if nargin < 1, moxunitRoot=''; end
paths=setup_test_paths(moxunitRoot);
if ~strcmp(getenv('RNFOUNDRY_RUN_FEA_TESTS'),'1')
    fprintf(['FEA parity tests SKIPPED: set RNFOUNDRY_RUN_FEA_TESTS=1 ' ...
             'in a configured xfemm/FEMM environment.\n']);
    success=[]; return;
end
if exist('xfemm.femmsession','class') ~= 8
    fprintf('FEA parity tests UNAVAILABLE: xfemm.femmsession is not on the path.\n');
    success=[]; return;
end
if nargin < 2 || isempty(reportFile)
    reportFile=fullfile(paths.RepositoryRoot,'test-results','fea.xml');
end
reportDir=fileparts(reportFile);
if exist(reportDir,'dir') ~= 7, mkdir(reportDir); end
success=moxunit_runtests(paths.FEATestRoot,'-recursive','-verbose', ...
    '-junit_xml_file',reportFile);
if ~success, error('rnfoundry:test:FEATestsFailed','Real FEA parity failed.'); end
end
