function test_gap_force_femmsession_parity()
% RUN_FEA_TESTS is the authoritative opt-in/native-runtime availability gate.
for position={'external','internal'}
    machine=makeFEASlottedMachine(position{1});
    [design,~]=rnfoundry.em.rotary.radial.prepareMagneticSweep(machine,struct());
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
    legacyValues=reshape(polyvaln(legacyFit,grid(:)),size(grid));
    assert(max(abs(modernModel.evaluate(grid)-legacyValues)) < ...
        1e-10*max(1,max(abs(legacyValues))));
end
end
