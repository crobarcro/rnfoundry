function test_suite = test_winding_value_objects()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_round_wire_conductor()
c=rnfoundry.em.winding.RoundWireConductor(struct('Resistivity',1.8e-8),4,0.4e-3, ...
    struct('Type','LegacyEnamelCorrelation'));
assertEqual(c.StrandCount,4);
assertElementsAlmostEqual(c.CopperAreaPerTurn,4*pi*(0.2e-3)^2,'absolute',1e-18);
assertElementsAlmostEqual(c.EquivalentCopperDiameter,0.8e-3,'absolute',1e-15);
assertEqual(rnfoundry.em.winding.RoundWireConductor.fromStruct(c.toStruct()).toStruct(),c.toStruct());
assertExceptionThrown(@() rnfoundry.em.winding.RoundWireConductor(struct(),0,1e-3), ...
    'rnfoundry:em:InvalidStrandCount');
assertExceptionThrown(@() rnfoundry.em.winding.RoundWireConductor(struct(),1,0), ...
    'rnfoundry:em:InvalidStrandDiameter');
end

function test_explicit_coil_geometry()
g=rnfoundry.em.winding.RadialSlottedCoilGeometry(2.5e-4,0.1,0.08,0.012,[0.1,0.1],0.2e-3);
assertEqual(g.PackArea,2.5e-4);
assertEqual(g.ls,0.1);
assertEqual(g.CoilInsulationThickness,0.2e-3);
expected=2*(0.08+0.012)+2*0.1+2*0.012+pi*0.012;
assertElementsAlmostEqual(g.MeanTurnLength,expected,'absolute',1e-14);
assertEqual(rnfoundry.em.winding.RadialSlottedCoilGeometry.fromStruct(g.toStruct()).PackArea,2.5e-4);
assertExceptionThrown(@() rnfoundry.em.winding.RadialSlottedCoilGeometry(0,0.1,0.08,0.012), ...
    'rnfoundry:em:InvalidPackArea');
end

function test_resolved_winding_without_generator()
w=makeResolvedWinding();
assertEqual([w.PhaseCount,w.PoleCount,w.SlotCount,w.LayerCount],[3,12,36,2]);
assertEqual([w.CoilPitchSlots,w.ParallelBranches,w.CoilsPerBranch],[3,2,6]);
assertEqual(w.TurnsPerCoil,20); assertEqual(w.PackingFactor,0.7);
assertTrue(isa(w.Conductor,'rnfoundry.em.winding.RoundWireConductor'));
assertTrue(isa(w.CoilGeometry,'rnfoundry.em.winding.RadialSlottedCoilGeometry'));
r=rnfoundry.em.winding.Winding.fromStruct(w.toStruct());
assertEqual(r.toStruct(),w.toStruct());
end
