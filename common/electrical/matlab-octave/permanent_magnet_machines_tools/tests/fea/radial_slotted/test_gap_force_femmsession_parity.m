function test_gap_force_femmsession_parity()
% Conditional Tier-2 parity: invoke only with a working XFEMM native runtime.
if exist('xfemm.femmsession','class') ~= 8
    fprintf('SKIP: xfemm.femmsession unavailable.\n'); return;
end
for position={'external','internal'}
    machine=makeFEASlottedMachine(position{1});
    design=machine.toLegacyStruct();
    displacement=[0,.45,.9,.95].*machine.g;
    modern=rnfoundry.em.rotary.radial.runRadialSlottedGapForceSweep( ...
        machine,struct('Displacements',displacement));
    legacy=closingforce_RADIAL_SLOTTED(design,displacement,'UseFemm',true);
    assert(max(abs(modern.Displacements(:)-displacement(:)))<eps);
    assert(max(abs(modern.ClosingForce(:)-legacy(:))) < ...
        1e-5*max(1,max(abs(legacy(:)))));
    modernModel=rnfoundry.em.rotary.radial.prepareRadialSlottedGapForceModel(machine,modern);
    legacyFit=polyfitn([0,displacement],[0,legacy],2);
    grid=linspace(0,machine.g,101);
    assert(max(abs(modernModel.evaluate(grid)-polyvaln(legacyFit,grid))) < ...
        1e-10*max(1,max(abs(polyvaln(legacyFit,grid)))));
end
end
