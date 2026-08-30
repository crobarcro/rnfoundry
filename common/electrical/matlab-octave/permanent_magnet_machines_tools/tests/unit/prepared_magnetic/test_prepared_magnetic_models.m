function test_suite=test_prepared_magnetic_models()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_double_layer_skewed_dense_legacy_parity()
[machine,raw]=makePreparedMagneticFixture(2,0.12);
prepared=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw);
oracle=legacyOracle(machine,raw);
grid=linspace(-2.7,4.3,1701);
assertElementsAlmostEqual(prepared.Magnetic.FluxLinkageModel.evaluate(grid), ...
    periodicslmeval(grid,oracle.fluxFit,0,false),'absolute',2e-12);
assertElementsAlmostEqual(prepared.Magnetic.CoggingTorqueModel.evaluate(grid), ...
    periodicslmeval(grid,oracle.coggingFit,0,false),'absolute',2e-10);
assertElementsAlmostEqual(prepared.Magnetic.FluxLinkageModel.RMS,oracle.rms,'absolute',2e-12);
assertElementsAlmostEqual(prepared.Magnetic.FluxLinkageModel.CoilPeak,oracle.coilPeak,'absolute',2e-12);
assertElementsAlmostEqual(prepared.Magnetic.FluxLinkageModel.PhasePeak,oracle.phasePeak,'absolute',2e-12);
assertEqual(prepared.Magnetic.FluxLinkageModel.PeakFluxLinkageFEAPosition,oracle.peakPosition);
assertElementsAlmostEqual(prepared.Magnetic.CoggingTorqueModel.Peak,oracle.coggingPeak,'absolute',2e-10);
end

function test_single_layer_unskewed_parity_and_orientation()
[machine,raw]=makePreparedMagneticFixture(1,0);
prepared=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw);
oracle=legacyOracle(machine,raw); row=[0,0.3,2,2.3]; column=row.';
assertElementsAlmostEqual(prepared.Magnetic.FluxLinkageModel.evaluate(row), ...
    periodicslmeval(row,oracle.fluxFit,0,false),'absolute',2e-12);
assertEqual(size(prepared.Magnetic.FluxLinkageModel.evaluate(row)),size(row));
assertEqual(size(prepared.Magnetic.FluxLinkageModel.evaluate(column)),size(column));
assertElementsAlmostEqual(prepared.Magnetic.CoggingTorqueModel.evaluate(row(1:2)), ...
    prepared.Magnetic.CoggingTorqueModel.evaluate(row(3:4)),'absolute',2e-10);
end

function test_raw_sources_and_value_boundaries_are_preserved()
[machine,raw]=makePreparedMagneticFixture(2,0.05);
machineBefore=machine.toStruct(); rawArea=raw.CoilArea; packArea=machine.Armature.Winding.CoilGeometry.PackArea;
prepared=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw);
assertEqual(machine.toStruct(),machineBefore); assertEqual(raw.CoilArea,rawArea);
assertEqual(machine.Armature.Winding.CoilGeometry.PackArea,packArea);
assertFalse(rawArea==packArea);
% DirectFluxLinkage is around 50 Wb; the intA-derived prepared waveform is tiny.
assertTrue(max(abs(prepared.Magnetic.FluxLinkageModel.evaluate(linspace(0,2,200))))<1);
assertTrue(isa(prepared.Machine,'rnfoundry.em.rotary.radial.SlottedPMMachine'));
assertTrue(isempty(prepared.Circuit)&&isempty(prepared.Losses)&&isempty(prepared.GapForce));
copy=prepared; assertEqual(copy.Machine.toStruct(),machineBefore);
end

function test_direct_flux_linkage_is_strictly_invariant()
[machine,raw]=makePreparedMagneticFixture(2,0.05);
changed=copyMagneticSweepResult(raw,struct('DirectFluxLinkage', ...
    -1e9+reshape(1:numel(raw.DirectFluxLinkage),size(raw.DirectFluxLinkage))));
a=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw);
b=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,changed);
grid=linspace(-1,3,801); af=a.Magnetic.FluxLinkageModel; bf=b.Magnetic.FluxLinkageModel;
assertElementsAlmostEqual(af.evaluate(grid),bf.evaluate(grid),'absolute',1e-14);
assertElementsAlmostEqual([af.RMS,af.CoilPeak,af.PhasePeak,af.PeakFluxLinkageFEAPosition], ...
    [bf.RMS,bf.CoilPeak,bf.PhasePeak,bf.PeakFluxLinkageFEAPosition],'absolute',1e-14);
end

function test_duplicate_slot_positions_preserve_legacy_unique_behavior()
[machine,raw]=makePreparedMagneticFixture(2,0.05,true); before=raw.SlotVectorPotential;
assertTrue(numel(unique(raw.SlotVectorPotential.Position(:)))<numel(raw.SlotVectorPotential.Position));
prepared=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw);
oracle=legacyOracle(machine,raw,10); grid=linspace(-1,3,801);
assertElementsAlmostEqual(prepared.Magnetic.FluxLinkageModel.evaluate(grid), ...
    periodicslmeval(grid,oracle.fluxFit,0,false),'absolute',2e-12);
assertEqual(raw.SlotVectorPotential,before);
end

function test_skew_position_options()
[machine,raw]=makePreparedMagneticFixture(2,0.18);
implicit=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw);
explicit=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw,struct('NSkewPositions',10));
three=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw,struct('NSkewPositions',3));
grid=linspace(0,2,501);
assertElementsAlmostEqual(implicit.Magnetic.FluxLinkageModel.evaluate(grid), ...
    explicit.Magnetic.FluxLinkageModel.evaluate(grid),'absolute',1e-14);
assertElementsAlmostEqual(implicit.Magnetic.CoggingTorqueModel.evaluate(grid), ...
    explicit.Magnetic.CoggingTorqueModel.evaluate(grid),'absolute',1e-14);
assertTrue(max(abs(implicit.Magnetic.FluxLinkageModel.evaluate(grid)- ...
    three.Magnetic.FluxLinkageModel.evaluate(grid)))>1e-8);
assertTrue(max(abs(implicit.Magnetic.CoggingTorqueModel.evaluate(grid)- ...
    three.Magnetic.CoggingTorqueModel.evaluate(grid)))>1e-6);
oracle=legacyOracle(machine,raw,3);
assertElementsAlmostEqual(three.Magnetic.FluxLinkageModel.evaluate(grid), ...
    periodicslmeval(grid,oracle.fluxFit,0,false),'absolute',2e-12);
end

function test_zero_skew_is_independent_of_section_count()
[machine,raw]=makePreparedMagneticFixture(1,0);
one=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw,struct('NSkewPositions',1));
thirteen=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw,struct('NSkewPositions',13));
grid=linspace(-2,4,601);
assertElementsAlmostEqual(one.Magnetic.FluxLinkageModel.evaluate(grid), ...
    thirteen.Magnetic.FluxLinkageModel.evaluate(grid),'absolute',2e-14);
assertElementsAlmostEqual(one.Magnetic.CoggingTorqueModel.evaluate(grid), ...
    thirteen.Magnetic.CoggingTorqueModel.evaluate(grid),'absolute',2e-12);
end

function test_invalid_skew_position_options()
[machine,raw]=makePreparedMagneticFixture(2,0.1);
values={0,-2,2.5,Inf,'three'};
for k=1:numel(values)
    options=struct('NSkewPositions',values{k});
    assertExceptionThrown(@() rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,raw,options), ...
        'rnfoundry:em:InvalidMagneticPreparationOptions');
end
end

function test_compatibility_validation()
[machine,raw]=makePreparedMagneticFixture(2,0);
s=makeMagneticSweepData(3); s.Positions=[0;.4;.9]; s.CoilArea=1;
bad=rnfoundry.em.fea.MagneticSweepResult(s);
assertExceptionThrown(@() rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,bad), ...
    'rnfoundry:em:IncompatibleMagneticSweep');
assertExceptionThrown(@() rnfoundry.em.FluxLinkageModel(struct(),1,1,1,0), ...
    'rnfoundry:em:InvalidFluxLinkageModel');
assertEqual(raw.Provenance.PhaseCurrents,zeros(3,1));
end

function oracle=legacyOracle(machine,raw,nSkewPositions)
% Isolated transcription of the relevant finfun_RADIAL_SLOTTED/finfun_AM path.
if nargin < 3, nSkewPositions=10; end
w=machine.Armature.Winding; pos=raw.SlotVectorPotential.Position.'; pos=pos(:);
v=permute(raw.SlotVectorPotential.Integral,[2,1,3,4]);
intA=reshape(v,size(v,1)*size(v,2),size(v,3),size(v,4));
[pos,idx]=sort(pos); intA=intA(idx,:,:); [pos,idx]=unique(pos); intA=intA(idx,:,:);
finish=pos(1)+2; use=pos<=finish; fitPos=pos(use); values=intA(use,1:w.LayerCount,1);
if fitPos(end)<finish
    fitPos(end+1)=finish; values=[values;interp1(pos,intA(:,1:w.LayerCount,1),finish)];
end
for k=1:w.LayerCount
    fits(k)=slmengine(fitPos,values(:,k),'EndCon','periodic', ...
        'knots',ceil(numel(fitPos)/2),'Plot','off'); %#ok<AGROW>
end
pitch=machine.Armature.thetas*w.CoilPitchSlots/machine.thetap; peakGrid=linspace(0,1,1000);
fl=fluxlinkagefrmintAslm(fits,pitch,peakGrid,w.TurnsPerCoil,raw.CoilArea, ...
    'Skew',machine.Field.MagnetSkew,'NSkewPositions',nSkewPositions);
[~,i]=max(abs(fl)); oracle.peakPosition=peakGrid(i(1)); lookup=linspace(0,2,200);
fl=fluxlinkagefrmintAslm(fits,pitch,lookup,w.TurnsPerCoil,raw.CoilArea, ...
    'Skew',machine.Field.MagnetSkew,'NSkewPositions',nSkewPositions,'Offset',oracle.peakPosition);
oracle.fluxFit=slmengine(lookup,fl,'EndCon','periodic','knots',50,'Plot','off');
x=slmeval(linspace(0,2,1000),oracle.fluxFit,0,false); oracle.rms=sqrt(mean(x.^2));
oracle.coilPeak=slmpar(oracle.fluxFit,'maxfun'); oracle.phasePeak=oracle.coilPeak*w.CoilsPerBranch;
rawFit=slmengine(raw.Positions,raw.CoggingTorque/machine.ls,'EndCon','periodic', ...
    'knots',numel(raw.Positions),'Plot','off'); offsets=linspace(-machine.Field.MagnetSkew/2,machine.Field.MagnetSkew/2,nSkewPositions).';
cp=linspace(0,2,100); ct=(machine.ls/nSkewPositions)*sum(periodicslmeval(bsxfun(@plus,cp,offsets),rawFit,0,false),1);
oracle.coggingFit=slmengine(cp,ct,'EndCon','periodic','knots',2*numel(raw.Positions),'Plot','off');
oracle.coggingPeak=slmpar(oracle.coggingFit,'maxfun');
end
