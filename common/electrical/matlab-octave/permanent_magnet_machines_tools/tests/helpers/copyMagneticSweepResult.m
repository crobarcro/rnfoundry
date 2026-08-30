function copy=copyMagneticSweepResult(result,overrides)
%COPYMAGNETICSWEEPRESULT Rebuild a raw value object with selected test changes.
names={'Positions','CoggingTorque','DirectFluxLinkage','ToothFluxDensity', ...
    'SlotVectorPotential','SlotFlux','AirGapField','CoilArea', ...
    'ArmatureIronArea','PerPoleRadialForce','Provenance'};
s=struct();
for k=1:numel(names), s.(names{k})=result.(names{k}); end
overrideNames=fieldnames(overrides);
for k=1:numel(overrideNames), s.(overrideNames{k})=overrides.(overrideNames{k}); end
copy=rnfoundry.em.fea.MagneticSweepResult(s);
end
