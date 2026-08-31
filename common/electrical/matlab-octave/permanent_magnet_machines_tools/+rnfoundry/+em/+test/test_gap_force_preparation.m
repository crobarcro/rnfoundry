function test_gap_force_preparation()
%TEST_GAP_FORCE_PREPARATION Dependency-free Milestone 2C regression checks.
p=struct('Solver','fixture');
r=rnfoundry.em.fea.RadialGapForceSweepResult([0 .2 .4],[3 7 15],p);
assert(isequal(size(r.Displacements),[3 1])); assert(r.ClosingForce(2)==7);
rnfoundry.em.test.assertError(@() rnfoundry.em.fea.RadialGapForceSweepResult([0 1],[1],p), ...
    'rnfoundry:em:InvalidRadialGapForceSweepResult');
rnfoundry.em.test.assertError(@() rnfoundry.em.fea.RadialGapForceSweepResult([0 NaN],[1 2],p), ...
    'rnfoundry:em:InvalidRadialGapForceSweepResult');
rnfoundry.em.test.assertError(@() rnfoundry.em.fea.RadialGapForceSweepResult([0 1i],[1 2],p), ...
    'rnfoundry:em:InvalidRadialGapForceSweepResult');

[machine,magRaw]=makePreparedMagneticFixture(1,0); before=machine.toStruct();
raw=rnfoundry.em.fea.RadialGapForceSweepResult([0;.2;.4].*machine.g, ...
    [4;9;20],p); rawBefore=raw.ClosingForce;
model=rnfoundry.em.rotary.radial.prepareRadialSlottedGapForceModel(machine,raw);
oracle=polyfitn([0;raw.Displacements],[0;raw.ClosingForce],2);
x=reshape(linspace(-.1,1.1,12).*machine.g,[3 4]);
evaluated=model.evaluate(x);
assert(max(abs(evaluated(:)-polyvaln(oracle,x(:))))<1e-10);
assert(isequal(size(model.evaluate(x)),size(x)));
assert(isfinite(model.evaluate(machine.g))); % legacy permits extrapolation
rnfoundry.em.test.assertError(@() model.evaluate(NaN),'rnfoundry:em:InvalidRadialDisplacement');
assert(isequal(machine.toStruct(),before)); assert(isequal(raw.ClosingForce,rawBefore));

% Freeze finfun_AM's order rule after simfun's artificial origin is added.
fitCases={.5.*machine.g,5,1; ...
          [.25;.75].*machine.g,[2;11],2; ...
          [0;.45;.9;.95].*machine.g,[4;8;19;27],2};
dense=linspace(-.1.*machine.g,1.1.*machine.g,101);
for caseInd=1:size(fitCases,1)
    caseRaw=rnfoundry.em.fea.RadialGapForceSweepResult( ...
        fitCases{caseInd,1},fitCases{caseInd,2},p);
    caseModel=rnfoundry.em.rotary.radial.prepareRadialSlottedGapForceModel(machine,caseRaw);
    expectedOrder=fitCases{caseInd,3};
    caseOracle=polyfitn([0;caseRaw.Displacements], ...
        [0;caseRaw.ClosingForce],expectedOrder);
    assert(max(caseModel.Polynomial.ModelTerms(:))==expectedOrder);
    assert(isequal(caseModel.Polynomial.ModelTerms,caseOracle.ModelTerms));
    oracleValues=reshape(polyvaln(caseOracle,dense(:)),size(dense));
    assert(max(abs(caseModel.evaluate(dense)-oracleValues))<1e-10);
end

prepared=rnfoundry.em.rotary.radial.prepareRadialSlottedMagneticModel(machine,magRaw);
assert(isempty(prepared.GapForce)); magnetic=prepared.Magnetic;
sectionsBefore={prepared.Machine,prepared.Magnetic,prepared.Circuit, ...
    prepared.Losses,prepared.MassProperties,prepared.Diagnostics};
combined=prepared.withGapForce(model);
assert(isa(combined.GapForce,'rnfoundry.em.RadialGapForceModel'));
assert(isempty(prepared.GapForce)); assert(isequal(combined.Magnetic,magnetic));
sectionsAfter={combined.Machine,combined.Magnetic,combined.Circuit, ...
    combined.Losses,combined.MassProperties,combined.Diagnostics};
assert(isequal(sectionsAfter,sectionsBefore));
rnfoundry.em.test.assertError(@() prepared.withGapForce(3), ...
    'rnfoundry:em:InvalidPreparedMachineModel');

o=rnfoundry.em.rotary.radial.resolveGapForceSweepOptions(machine,struct());
assert(numel(o.Displacements)==4); assert(o.Displacements(1)==0);
assert(abs(o.Displacements(end)-.95*machine.g)<eps);
o=rnfoundry.em.rotary.radial.resolveGapForceSweepOptions(machine,struct('Displacements',[0,.1*machine.g]));
assert(isequal(size(o.Displacements),[2 1]));
bad={NaN,[0 1i],zeros(2),machine.g,-1};
for k=1:numel(bad)
    rnfoundry.em.test.assertError(@() rnfoundry.em.rotary.radial.resolveGapForceSweepOptions( ...
        machine,struct('Displacements',bad{k})),'rnfoundry:em:InvalidGapForceSweepOptions');
end
rnfoundry.em.test.assertError(@() rnfoundry.em.rotary.radial.resolveGapForceSweepOptions( ...
    machine,struct('UseFemm',true)),'rnfoundry:em:InvalidGapForceSweepOptions');
end
