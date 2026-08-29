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
