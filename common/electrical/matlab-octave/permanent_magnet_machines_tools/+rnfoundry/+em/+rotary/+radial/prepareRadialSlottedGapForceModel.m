function model = prepareRadialSlottedGapForceModel(machine,raw)
%PREPARERADIALSLOTTEDGAPFORCEMODEL Pure legacy-compatible quadratic fit.
if ~isa(machine,'rnfoundry.em.rotary.radial.SlottedPMMachine') ...
        || ~isa(raw,'rnfoundry.em.fea.RadialGapForceSweepResult')
    error('rnfoundry:em:InvalidGapForcePreparation','Expected canonical machine and raw gap-force result.');
end
% simfun_RADIAL_SLOTTED prepended this artificial unloaded origin before
% finfun_AM selected quadratic order for more than two displacement entries.
x=[0;raw.Displacements]; y=[0;raw.ClosingForce];
p=polyfitn(x,y,2);
model=rnfoundry.em.RadialGapForceModel(p,[min(x),max(x)]);
end
