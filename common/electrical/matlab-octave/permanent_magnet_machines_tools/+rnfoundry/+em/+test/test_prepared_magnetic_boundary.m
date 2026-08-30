function test_prepared_magnetic_boundary()
%TEST_PREPARED_MAGNETIC_BOUNDARY Direct smoke/regression check for runner.
[machine,raw]=makePreparedMagneticFixture(2,0.12);
before=machine.toStruct();
prepared=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw);
assert(isa(prepared.Magnetic.FluxLinkageModel,'rnfoundry.em.FluxLinkageModel'));
assert(isa(prepared.Magnetic.CoggingTorqueModel,'rnfoundry.em.CoggingTorqueModel'));
assert(max(abs(prepared.Magnetic.FluxLinkageModel.evaluate([0,2]) ...
    -prepared.Magnetic.FluxLinkageModel.evaluate([2,4])))<2e-12);
assert(isequal(machine.toStruct(),before));
assert(raw.CoilArea~=machine.Armature.Winding.CoilGeometry.PackArea);
end
