function test_suite = test_magnetic_sweep_options()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_low_level_controls_are_rejected_before_fea()
m=makeExternalSlottedMachine();
names={'SolveMethod','UseFemm','QuietFemm','RotationMethod'};
values={'femmsession',true,true,'SlidingMesh'};
for k=1:numel(names)
    o=struct(); o.(names{k})=values{k};
    assertExceptionThrown(@() rnfoundry.em.rotary.radial.runRadialSlottedMagneticSweep(m,o), ...
        'rnfoundry:em:UnknownSweepOption');
end
end

function test_invalid_position_counts_are_rejected_before_fea()
m=makeExternalSlottedMachine();
for value={1,2.5,Inf}
    assertExceptionThrown(@() rnfoundry.em.rotary.radial.runRadialSlottedMagneticSweep( ...
        m,struct('NPositions',value{1})),'rnfoundry:em:InvalidSweepOptions');
end
end

function test_invalid_phase_currents_are_rejected_before_fea()
m=makeExternalSlottedMachine();
values={[0;0],[0;0;NaN],'not numeric'};
for k=1:numel(values)
    assertExceptionThrown(@() rnfoundry.em.rotary.radial.runRadialSlottedMagneticSweep( ...
        m,struct('PhaseCurrents',values{k})),'rnfoundry:em:InvalidSweepOptions');
end
end


function test_zero_current_default_and_explicit_values()
m=makeExternalSlottedMachine();
defaults=rnfoundry.em.rotary.radial.resolveMagneticSweepOptions(m,struct());
explicit=rnfoundry.em.rotary.radial.resolveMagneticSweepOptions( ...
    m,struct('PhaseCurrents',zeros(3,1)));
assertEqual(defaults.PhaseCurrents,zeros(3,1));
assertEqual(explicit.PhaseCurrents,zeros(3,1));
assertExceptionThrown(@() rnfoundry.em.rotary.radial.resolveMagneticSweepOptions( ...
    m,struct('PhaseCurrents',[0;1;0])),'rnfoundry:em:NonzeroSweepCurrent');
end

function test_air_gap_material_boundary_does_not_mutate_machine()
m=makeExternalSlottedMachine(); before=m.toStruct();
[defaultDesign,defaults]=rnfoundry.em.rotary.radial.prepareMagneticSweep(m,struct());
material=struct('Name','test vacuum','Mu_x',1,'Mu_y',1);
[explicitDesign,explicit]=rnfoundry.em.rotary.radial.prepareMagneticSweep( ...
    m,struct('AirGapMaterial',material));
assertEqual(defaults.AirGapMaterial,'Air');
assertEqual(explicit.AirGapMaterial,material);
assertEqual(defaultDesign.MagFEASimMaterials.AirGap,'Air');
assertEqual(explicitDesign.MagFEASimMaterials.AirGap,material);
assertEqual(m.toStruct(),before);
assertFalse(isfield(m.toStruct(),'AirGapMaterial'));
end
