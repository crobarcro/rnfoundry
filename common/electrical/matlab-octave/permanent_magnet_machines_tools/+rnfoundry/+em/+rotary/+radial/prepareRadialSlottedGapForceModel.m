function model = prepareRadialSlottedGapForceModel(machine,raw)
%PREPARERADIALSLOTTEDGAPFORCEMODEL Pure legacy-compatible polynomial fit.
if ~isa(machine,'rnfoundry.em.rotary.radial.SlottedPMMachine') ...
        || ~isa(raw,'rnfoundry.em.fea.RadialGapForceSweepResult')
    error('rnfoundry:em:InvalidGapForcePreparation','Expected canonical machine and raw gap-force result.');
end
% simfun_RADIAL_SLOTTED prepended this artificial unloaded origin before
% finfun_AM selected quadratic order only for more than two stored entries.
x=[0;raw.Displacements]; y=[0;raw.ClosingForce];
if numel(x)>2
    order=2;
else
    order=1;
end
p=polyfitn(x,y,order);
model=rnfoundry.em.RadialGapForceModel(p,[min(x),max(x)]);
end
