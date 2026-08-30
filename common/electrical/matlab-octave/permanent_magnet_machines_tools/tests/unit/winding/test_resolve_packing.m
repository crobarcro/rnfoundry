function test_suite = test_resolve_packing()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_turns_and_diameter_resolve_packing_and_copper_fill()
g=geometry();
r=rnfoundry.em.winding.resolvePacking(struct('CoilTurns',20,'Dc',0.7e-3,'NStrands',4),g);
assertEqual(r.TurnsPerCoil,20); assertEqual(r.Conductor.StrandCount,4);
assertElementsAlmostEqual(r.Conductor.EquivalentCopperDiameter,0.7e-3,'absolute',1e-15);
assertElementsAlmostEqual(r.CopperFillFactor,20*r.Conductor.CopperAreaPerTurn/g.PackArea,'absolute',1e-15);
end

function test_turns_and_packing_resolve_diameter()
r=rnfoundry.em.winding.resolvePacking(struct('TurnsPerCoil',20,'PackingFactor',0.6,'StrandCount',2),geometry());
assertEqual(r.TurnsPerCoil,20); assertEqual(r.PackingFactor,0.6);
assertTrue(r.Conductor.StrandDiameter>0); assertTrue(r.CopperFillFactor<r.PackingFactor);
end

function test_diameter_and_packing_resolve_turns()
r=rnfoundry.em.winding.resolvePacking(struct('Dc',0.5e-3,'CoilFillFactor',0.6,'NStrands',1),geometry());
assertTrue(r.TurnsPerCoil>0); assertEqual(r.PackingFactor,0.6);
end

function test_invalid_or_insufficient_input()
assertExceptionThrown(@() rnfoundry.em.winding.resolvePacking(struct('CoilTurns',20),geometry()), ...
    'rnfoundry:em:InsufficientPackingSpecification');
assertExceptionThrown(@() rnfoundry.em.winding.resolvePacking( ...
    struct('CoilTurns',20,'Dc',-1e-3),geometry()),'rnfoundry:em:InvalidStrandDiameter');
end

function g=geometry()
g=rnfoundry.em.winding.RadialSlottedCoilGeometry(2.5e-4,0.1,0.08,0.012);
end
