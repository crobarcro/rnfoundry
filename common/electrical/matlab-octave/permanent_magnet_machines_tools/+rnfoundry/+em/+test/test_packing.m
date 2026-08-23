function test_packing()
geometry=rnfoundry.em.winding.CoilGeometry(1e-4,1,[]);
modes={struct('Dc',1e-3,'CoilFillFactor',.6), ...
       struct('CoilTurns',20,'CoilFillFactor',.6), ...
       struct('Dc',1e-3,'CoilTurns',20), ...
       struct('WireStrandDiameter',.35e-3,'CoilTurns',20)};
for strands=[1,4]
    for k=1:numel(modes)
        spec=modes{k}; spec.NStrands=strands; spec.CoilArea=geometry.PackArea;
        legacy=checkcoilprops_AM(spec); modern=rnfoundry.em.winding.resolvePacking(spec,geometry);
        rnfoundry.em.test.assertNear(modern.TurnsPerCoil,legacy.CoilTurns);
        rnfoundry.em.test.assertNear(modern.Conductor.EquivalentCopperDiameter,legacy.Dc);
        if isfield(legacy,'CoilFillFactor'), rnfoundry.em.test.assertNear(modern.PackingFactor,legacy.CoilFillFactor); end
        c=modern.Conductor;
        rnfoundry.em.test.assertNear(c.CopperAreaPerStrand,pi*(c.StrandDiameter/2)^2);
        rnfoundry.em.test.assertNear(c.CopperAreaPerTurn,strands*c.CopperAreaPerStrand);
        rnfoundry.em.test.assertNear(c.EquivalentCopperDiameter,c.StrandDiameter*sqrt(strands));
        rnfoundry.em.test.assertNear(c.OccupiedAreaPerTurn,strands*pi*(c.InsulatedStrandDiameter/2)^2);
        rnfoundry.em.test.assertNear(modern.CopperFillFactor,modern.TurnsPerCoil*c.CopperAreaPerTurn/geometry.PackArea);
    end
end
for diameter=[.4,1,1.59,1.60,2]*1e-3
    rnfoundry.em.test.assertNear(rnfoundry.em.winding.insulatedWireDiameter(diameter),conductord2wired(diameter));
end
end
