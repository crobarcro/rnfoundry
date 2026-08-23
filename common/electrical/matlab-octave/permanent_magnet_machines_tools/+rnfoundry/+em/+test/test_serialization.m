function test_serialization()
[input,legacy]=rnfoundry.em.test.modeInput('external','tdims',2,'integral');
m=rnfoundry.em.rotary.radial.SlottedPMMachine.fromThicknesses(input);
s=m.toStruct(); assert(strcmp(s.Schema,'rnfoundry.em.SlottedPMMachine') && s.SchemaVersion==1 && strcmp(s.Type,'SlottedPMMachine'));
m2=rnfoundry.em.rotary.radial.SlottedPMMachine.fromStruct(s);
compareMachine(m,m2);
c2=rnfoundry.em.winding.RoundWireConductor.fromStruct(m.Armature.Winding.Conductor.toStruct());
rnfoundry.em.test.assertNear(c2.StrandDiameter,m.Armature.Winding.Conductor.StrandDiameter);
g2=rnfoundry.em.winding.RadialSlottedCoilGeometry.fromStruct(m.Armature.Winding.CoilGeometry.toStruct());
rnfoundry.em.test.assertNear(g2.MeanTurnLength,m.Armature.Winding.MeanTurnLength);
w2=rnfoundry.em.winding.Winding.fromStruct(m.Armature.Winding.toStruct());
rnfoundry.em.test.assertNear(w2.CopperVolume,m.Armature.Winding.CopperVolume);
out=m2.toLegacyStruct();
assert(isequal(out.WindingLayout.Coils,legacy.WindingLayout.Coils));
assert(isequal(out.WindingLayout.Phases,legacy.WindingLayout.Phases));
rnfoundry.em.test.assertNear(out.CoilInsulationThickness,input.CoilInsulationThickness);
% Scalar legacy tc resolves to the drawing kernel's 0.05 CoilBaseFraction.
scalarLegacy=legacy; scalarLegacy.tc=scalarLegacy.tc(1); scalarLegacy=rmfield(scalarLegacy,'Rcb');
scalar=rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(scalarLegacy);
rnfoundry.em.test.assertNear(scalar.Armature.tcb,.05*scalar.Armature.tc);
rnfoundry.em.test.assertNear(scalar.toLegacyStruct().tc,[scalar.Armature.tc,scalar.Armature.tcb]);
% Explicit tc(2) and Rcb survive import and persistence.
explicit=rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(legacy);
rnfoundry.em.test.assertNear(explicit.Armature.tcb,legacy.tc(2));
rnfoundry.em.test.assertNear(rnfoundry.em.rotary.radial.SlottedPMMachine.fromStruct(explicit.toStruct()).Armature.Rcb,legacy.Rcb);
% Explicit CoilArea is exact; omission is rejected.
missing=legacy; missing=rmfield(missing,'CoilArea');
rnfoundry.em.test.assertError(@() rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(missing),'rnfoundry:em:MissingPackArea');
% Nested type dispatch rejects unknown types.
bad=s; bad.Armature.Winding.Conductor.Type='FutureConductor';
rnfoundry.em.test.assertError(@() rnfoundry.em.rotary.radial.SlottedPMMachine.fromStruct(bad),'rnfoundry:em:UnsupportedType');
bad=s; bad.Armature.Winding.CoilGeometry.Type='FutureGeometry';
rnfoundry.em.test.assertError(@() rnfoundry.em.rotary.radial.SlottedPMMachine.fromStruct(bad),'rnfoundry:em:UnsupportedType');
end
function compareMachine(a,b)
rnfoundry.em.test.assertNear(a.ls,b.ls); rnfoundry.em.test.assertNear(a.NStages,b.NStages);
rnfoundry.em.test.assertNear(a.PoleSpan,b.PoleSpan); rnfoundry.em.test.assertNear(a.g,b.g);
fields={'Rmi','Rmo','Rbi','Rbo','thetam','MagnetSkew'};
for k=1:numel(fields), rnfoundry.em.test.assertNear(a.Field.(fields{k}),b.Field.(fields{k})); end
assert(isequal(a.Field.MagnetMaterial,b.Field.MagnetMaterial)); assert(isequal(a.Field.BackIronMaterial,b.Field.BackIronMaterial));
fields={'Ryi','Ryo','Rtsb','Rtsg','Ra','tc','tcb','thetasg','thetacg','thetacy'};
for k=1:numel(fields), rnfoundry.em.test.assertNear(a.Armature.(fields{k}),b.Armature.(fields{k})); end
assert(strcmp(a.Armature.Position,b.Armature.Position)); assert(isequal(a.Armature.IronMaterial,b.Armature.IronMaterial));
wa=a.Armature.Winding; wb=b.Armature.Winding;
fields={'PhaseCount','PoleCount','LayerCount','CoilCount','BasicCoilCount','BasicPoleCount','BasicWindingRepetitions','SlotCount','BasicSlotCount','CoilPitchSlots','TurnsPerCoil','ParallelBranches','PackingFactor'};
for k=1:numel(fields), rnfoundry.em.test.assertNear(wa.(fields{k}),wb.(fields{k})); end
assert(isequal(wa.Layout,wb.Layout)); assert(isequal(wa.Conductor.Material,wb.Conductor.Material)); assert(isequal(wa.Conductor.Insulation,wb.Conductor.Insulation));
rnfoundry.em.test.assertNear(wa.Conductor.StrandCount,wb.Conductor.StrandCount); rnfoundry.em.test.assertNear(wa.Conductor.StrandDiameter,wb.Conductor.StrandDiameter);
ga=wa.CoilGeometry; gb=wb.CoilGeometry;
fields={'PackArea','MeanTurnLength','ls','PitchLength','SlotWidth','ActiveSegmentLengths','CoilInsulationThickness'};
for k=1:numel(fields), rnfoundry.em.test.assertNear(ga.(fields{k}),gb.(fields{k})); end
end
