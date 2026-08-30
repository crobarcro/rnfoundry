function machine=makeFEASlottedMachine(position)
%MAKEFEASLOTTEDMACHINE Canonical parity fixture using mfemm library names.
if strcmp(position,'external')
    base=makeExternalSlottedMachine(); polarisation='radial';
else
    base=makeInternalSlottedMachine(); polarisation='constant';
end
d=base.toLegacyStruct();
d.MagnetPolarisation=polarisation;
d.MagFEASimMaterials=struct('Magnet','NdFeB 40 MGOe', ...
    'FieldBackIron','1117 Steel','ArmatureYoke','1117 Steel', ...
    'ArmatureCoil','36 AWG');
machine=rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(d);
end
