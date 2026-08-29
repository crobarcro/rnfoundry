function success = run_unit_tests(moxunitRoot,reportFile)
%RUN_UNIT_TESTS Run shared MATLAB/Octave MOxUnit tests and emit JUnit XML.
if nargin < 1, moxunitRoot=''; end
paths=setup_test_paths(moxunitRoot);
if nargin < 2 || isempty(reportFile)
    reportFile=fullfile(paths.RepositoryRoot,'test-results','moxunit.xml');
end
reportDir=fileparts(reportFile);
if exist(reportDir,'dir') ~= 7, mkdir(reportDir); end
success=moxunit_runtests(paths.TestRoot,'-recursive','-verbose', ...
    '-junit_xml_file',reportFile);
if ~success
    error('rnfoundry:test:UnitTestsFailed','One or more MOxUnit tests failed.');
end
end
