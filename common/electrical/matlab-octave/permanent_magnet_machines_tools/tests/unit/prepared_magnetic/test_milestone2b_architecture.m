function test_suite=test_milestone2b_architecture()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_preparer_has_no_fea_or_legacy_workflow_dependency()
path=which('rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel'); text=fileread(path);
forbidden={'runRadialSlottedMagneticSweep','XFemmSessionAnalysis','xfemm.femmsession', ...
    'feasim_RADIAL_SLOTTED','simfun_RADIAL_SLOTTED','finfun_RADIAL_SLOTTED','finfun_AM'};
for k=1:numel(forbidden), assertTrue(isempty(strfind(text,forbidden{k}))); end
end
function test_canonical_classes_do_not_gain_prepared_state()
root=fileparts(fileparts(fileparts(fileparts(which('rnfoundry.em.Machine')))));
files={which('rnfoundry.em.rotary.radial.SlottedPMMachine'), ...
 which('rnfoundry.em.rotary.radial.RadialPMField'),which('rnfoundry.em.rotary.radial.SlottedArmature'), ...
 which('rnfoundry.em.winding.Winding')};
for k=1:numel(files)
 text=fileread(files{k}); assertTrue(isempty(strfind(text,'slm_fluxlinkage'))); assertTrue(isempty(strfind(text,'RawCoggingTorque')));
end
assertFalse(isempty(root));
end
