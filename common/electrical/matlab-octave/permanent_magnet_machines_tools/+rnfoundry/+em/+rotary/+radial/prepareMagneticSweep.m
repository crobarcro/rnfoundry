function [design,options]=prepareMagneticSweep(machine,options)
%PREPAREMAGNETICSWEEP Build temporary drawing input without machine mutation.
if nargin < 2, options=struct(); end
options=rnfoundry.em.rotary.radial.resolveMagneticSweepOptions(machine,options);
design=machine.toLegacyStruct();
design.MagFEASimMaterials.AirGap=options.AirGapMaterial;
design.FirstSlotCenter=0;
end
