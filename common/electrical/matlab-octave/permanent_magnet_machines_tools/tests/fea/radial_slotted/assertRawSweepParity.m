function assertRawSweepParity(position)
machine=makeFEASlottedMachine(position); before=machine.toStruct();
options=struct('NPositions',3,'AirGapMaterial','Air');
legacy=runLegacyRawMagneticSweep(machine,options);
modern=rnfoundry.em.rotary.radial.runRadialSlottedMagneticSweep(machine,options);
assertEqual(machine.toStruct(),before);
assertElementsAlmostEqual(modern.Positions,legacy.Positions,'absolute',1e-13);
assertElementsAlmostEqual(machine.thetap*modern.Positions,legacy.PhysicalAngles,'absolute',1e-13);
assertClose(modern.CoggingTorque,legacy.CoggingTorque,1e-8,1e-6);
assertClose(modern.DirectFluxLinkage,legacy.DirectFluxLinkage,1e-10,1e-6);
assertClose(modern.ToothFluxDensity,legacy.ToothFluxDensity,1e-8,1e-6);
assertClose(modern.SlotVectorPotential.Position,legacy.SlotVectorPotential.Position,1e-12,1e-9);
assertClose(modern.SlotVectorPotential.Integral,legacy.SlotVectorPotential.Integral,1e-10,1e-6);
assertClose(modern.SlotFlux.Position,legacy.SlotFlux.Position,1e-12,1e-9);
assertClose(modern.SlotFlux.Integral,legacy.SlotFlux.Integral,1e-10,1e-6);
assertClose(modern.AirGapField.Magnitude,legacy.AirGapField.Magnitude,1e-8,1e-6);
assertClose(modern.CoilArea,legacy.CoilArea,1e-12,1e-7);
assertClose(modern.ArmatureIronArea,legacy.ArmatureIronArea,1e-12,1e-7);
assertClose(modern.PerPoleRadialForce,legacy.PerPoleRadialForce,1e-7,1e-6);
end

function assertClose(a,b,absoluteTolerance,relativeTolerance)
limit=absoluteTolerance+relativeTolerance*max([1;abs(b(:))]);
assertTrue(isequal(size(a),size(b))&&all(abs(a(:)-b(:))<=limit));
end
