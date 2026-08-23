function test_radial_slotted_factories()
modes={'ratios','radims','tdims'};
positions={'external','internal'};
for i=1:numel(modes)
    for j=1:numel(positions)
        [input,~]=rnfoundry.em.test.modeInput(positions{j},modes{i},2,'integral');
        legacy=completedesign_RADIAL_SLOTTED(input,struct(),modes{i});
        switch modes{i}
            case 'ratios', modern=rnfoundry.em.rotary.radial.SlottedPMMachine.fromRatios(input);
            case 'radims', modern=rnfoundry.em.rotary.radial.SlottedPMMachine.fromRadii(input);
            otherwise, modern=rnfoundry.em.rotary.radial.SlottedPMMachine.fromThicknesses(input);
        end
        compareDesign(modern.toLegacyStruct(),legacy,positions{j});
    end
end
% Remaining required winding fixtures use thickness construction.
cases={{'external',2,'tooth'},{'external',1,'integral'},{'external',2,'fractional'}};
for k=1:numel(cases)
    c=cases{k}; [input,~]=rnfoundry.em.test.modeInput(c{1},'tdims',c{2},c{3});
    legacy=completedesign_RADIAL_SLOTTED(input,struct(),'tdims');
    modern=rnfoundry.em.rotary.radial.SlottedPMMachine.fromThicknesses(input);
    compareDesign(modern.toLegacyStruct(),legacy,c{1});
    expectedMTL=rectcoilmtl(legacy.ls,legacy.yd*legacy.thetas*legacy.Rcm+legacy.thetas*legacy.Rcm/2,mean(legacy.thetac)*legacy.Rcm);
    rnfoundry.em.test.assertNear(modern.Armature.Winding.MeanTurnLength,expectedMTL);
    expectedR=wireresistancedc('round',modern.Armature.Winding.Conductor.EquivalentCopperDiameter,expectedMTL*modern.Armature.Winding.TurnsPerCoil,'Resistivity',1.9e-8);
    rnfoundry.em.test.assertNear(modern.Armature.Winding.ReferenceDCCoilResistance,expectedR);
end
% Exercise the no-MEX/numeric-qc ratio fallback, including ls reconstruction.
[input,legacy]=rnfoundry.em.test.modeInput('external','ratios',2,'integral');
input.qc=double(input.qc); input.WindingLayout=legacy.WindingLayout;
modern=rnfoundry.em.rotary.radial.SlottedPMMachine.fromRatios(input);
compareDesign(modern.toLegacyStruct(),legacy,'external');
[input,legacy]=rnfoundry.em.test.modeInput('internal','ratios',2,'integral');
input.qc=double(input.qc); input.WindingLayout=legacy.WindingLayout;
modern=rnfoundry.em.rotary.radial.SlottedPMMachine.fromRatios(input);
compareDesign(modern.toLegacyStruct(),legacy,'internal');
end
function compareDesign(actual,expected,position)
if ~isfield(expected,'Branches'), expected.Branches=1; end
if ~isfield(expected,'CoilsPerBranch'), expected.CoilsPerBranch=expected.NCoilsPerPhase/expected.Branches; end
winding={'Poles','Phases','CoilLayers','Qc','Qcb','pb','NBasicWindings','Qs','Qsb', ...
         'qcn','qcd','ypn','ypd','yp','yd','qsp','NCoilsPerPhase','Branches','CoilsPerBranch'};
geometry={'Rmi','Rmo','Rbi','Rbo','Ryi','Ryo','Rtsb','Rtsg','Rci','Rco','Rcm', ...
          'Rmm','Rbm','Rym','Rgm','g','tm','tbi','ty','tsb','tsg','thetap','thetas', ...
          'thetam','thetacg','thetacy','thetasg','tausm','ls'};
for k=1:numel(winding), rnfoundry.em.test.assertNear(actual.(winding{k}),expected.(winding{k})); end
for k=1:numel(geometry), rnfoundry.em.test.assertNear(actual.(geometry{k}),expected.(geometry{k})); end
rnfoundry.em.test.assertNear(actual.tc(1),expected.tc(1));
if numel(expected.tc)>1, rnfoundry.em.test.assertNear(actual.tc(2),expected.tc(2)); end
assert(isequal(actual.WindingLayout.Coils,expected.WindingLayout.Coils));
assert(isequal(actual.WindingLayout.Phases,expected.WindingLayout.Phases));
if strcmp(position,'external')
    rnfoundry.em.test.assertNear(actual.Rai,expected.Rai);
    ratios={'RyiVRyo','RtsbVRyi','RaiVRtsb','RmoVRai','RmiVRmo','RbiVRmi'};
else
    rnfoundry.em.test.assertNear(actual.Rao,expected.Rao);
    ratios={'RmoVRbo','RmiVRmo','RaoVRmi','RtsbVRao','RyoVRtsb','RyiVRyo'};
end
ratios=[ratios,{'tsgVtsb','thetamVthetap','thetacgVthetas','thetacyVthetas','thetasgVthetacg','lsVtm'}];
for k=1:numel(ratios), rnfoundry.em.test.assertNear(actual.(ratios{k}),expected.(ratios{k})); end
end
