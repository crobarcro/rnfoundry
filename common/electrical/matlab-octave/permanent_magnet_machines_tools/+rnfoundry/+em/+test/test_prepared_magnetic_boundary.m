function test_prepared_magnetic_boundary()
%TEST_PREPARED_MAGNETIC_BOUNDARY Substantive dependency-free 2B checks.
grid=linspace(-1,3,401);
for layerCount=1:2
    for skew=[0,0.12]
        [machine,raw]=makePreparedMagneticFixture(layerCount,skew);
        machineBefore=machine.toStruct(); rawBefore=raw.SlotVectorPotential;
        prepared=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw);
        assert(isa(prepared.Magnetic.FluxLinkageModel,'rnfoundry.em.FluxLinkageModel'));
        assert(isa(prepared.Magnetic.CoggingTorqueModel,'rnfoundry.em.CoggingTorqueModel'));
        assert(max(abs(prepared.Magnetic.FluxLinkageModel.evaluate(grid) ...
            -prepared.Magnetic.FluxLinkageModel.evaluate(grid+2)))<2e-12);
        assert(max(abs(prepared.Magnetic.CoggingTorqueModel.evaluate(grid) ...
            -prepared.Magnetic.CoggingTorqueModel.evaluate(grid+2)))<2e-10);
        assert(isequal(machine.toStruct(),machineBefore));
        assert(isequal(raw.SlotVectorPotential,rawBefore));
        assert(raw.CoilArea~=machine.Armature.Winding.CoilGeometry.PackArea);
    end
end

[machine,raw]=makePreparedMagneticFixture(2,0.12,true);
assert(numel(unique(raw.SlotVectorPotential.Position(:)))<numel(raw.SlotVectorPotential.Position));
defaultFit=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw);
threeFit=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw,struct('NSkewPositions',3));
assert(max(abs(defaultFit.Magnetic.FluxLinkageModel.evaluate(grid) ...
    -threeFit.Magnetic.FluxLinkageModel.evaluate(grid)))>1e-8);
changed=copyMagneticSweepResult(raw,struct('DirectFluxLinkage',1e12*ones(size(raw.DirectFluxLinkage))));
unchangedFit=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,changed);
assert(max(abs(defaultFit.Magnetic.FluxLinkageModel.evaluate(grid) ...
    -unchangedFit.Magnetic.FluxLinkageModel.evaluate(grid)))<1e-14);
assertThrows(@() rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel( ...
    machine,raw,struct('NSkewPositions',0)),'rnfoundry:em:InvalidMagneticPreparationOptions');

x=linspace(0,2,21); fit=slmengine(x,cos(pi*x),'EndCon','periodic','knots',12,'Plot','off');
assert(max(abs(periodicslmeval(grid,fit)-periodicslmeval(grid,fit,0,false)))<1e-13);
end

function assertThrows(f,errorId)
try
    f();
catch err
    assert(strcmp(err.identifier,errorId));
    return;
end
error('rnfoundry:em:test:ExpectedError','Expected error %s.',errorId);
end
