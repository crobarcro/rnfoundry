function paths = setup_test_paths(moxunitRoot)
%SETUP_TEST_PATHS Configure the compiler- and solver-free unit-test tier.
toolboxRoot=fileparts(fileparts(mfilename('fullpath')));
repoRoot=fileparts(fileparts(fileparts(fileparts(toolboxRoot))));
if nargin < 1 || isempty(moxunitRoot)
    moxunitRoot=getenv('MOXUNIT_PATH');
end
if isempty(moxunitRoot)
    moxunitRoot=fullfile(repoRoot,'.ci-tools','MOxUnit');
end
if exist(fullfile(moxunitRoot,'MOxUnit','moxunit_set_path.m'),'file') ~= 2
    error('rnfoundry:test:MissingMOxUnit', ...
        ['MOxUnit was not found. Set MOXUNIT_PATH to a checkout, or place ' ...
         'the pinned checkout at .ci-tools/MOxUnit.']);
end
addpath(fullfile(moxunitRoot,'MOxUnit'));
moxunit_set_path();
addpath(genpath(toolboxRoot));
paths=struct('RepositoryRoot',repoRoot,'ToolboxRoot',toolboxRoot, ...
    'UnitTestRoot',fullfile(toolboxRoot,'tests','unit'), ...
    'FEATestRoot',fullfile(toolboxRoot,'tests','fea'),'MOxUnitRoot',moxunitRoot);
end
