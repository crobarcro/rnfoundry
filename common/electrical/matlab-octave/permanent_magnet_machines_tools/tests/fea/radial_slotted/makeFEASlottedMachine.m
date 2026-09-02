function machine=makeFEASlottedMachine(position,splitSlot)
%MAKEFEASLOTTEDMACHINE Canonical parity fixture using mfemm library names.
if nargin<2, splitSlot=false; end
if strcmp(position,'external')
    base=makeExternalSlottedMachine(); polarisation='radial';
else
    base=makeInternalSlottedMachine(); polarisation='constant';
end
d=base.toLegacyStruct();
if splitSlot, d.yd=1; end
d.MagnetPolarisation=polarisation;
d.MagFEASimMaterials=struct('Magnet','NdFeB 40 MGOe', ...
    'FieldBackIron','1117 Steel','ArmatureYoke','1117 Steel', ...
    'ArmatureCoil','36 AWG','CoilInsulation','Air');
machine=rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(d);
end
