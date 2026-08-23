function test_validation()
[input,~]=rnfoundry.em.test.modeInput('external','tdims',2,'integral');
m=rnfoundry.em.rotary.radial.SlottedPMMachine.fromThicknesses(input); s=m.toStruct();
bad=s; bad.PoleSpan=bad.PoleSpan*2; expect(bad,'rnfoundry:em:InvalidPoles');
bad=s; bad.Armature.Winding.SlotCount=bad.Armature.Winding.SlotCount+1; expectAny(bad);
bad=s; bad.Armature.tc=bad.Armature.tc*.9; expect(bad,'rnfoundry:em:InconsistentGeometry');
bad=s; bad.Armature.Winding.LayerCount=3; expect(bad,'rnfoundry:em:InvalidLayers');
bad=s; bad.Armature.Winding.CoilCount=bad.Armature.Winding.CoilCount+1; expectAny(bad);
bad=s; bad.Armature.Winding.ParallelBranches=5; expect(bad,'rnfoundry:em:InvalidCombinatorics');
bad=s; bad.Armature.Ra=bad.Field.Rmo; expect(bad,'rnfoundry:em:InvalidAirGap');
bad=s; bad.Armature.Rtsb=bad.Armature.Ryo+.01; expectAny(bad);
bad=s; bad.Armature.Winding.Layout=struct(); expect(bad,'rnfoundry:em:UnresolvedWindingLayout');
bad=s; bad.Field.Rbi=-1; expect(bad,'rnfoundry:em:InvalidFieldRadii');
bad=s; bad.Field.Rbo=bad.Field.Rbi; expectAny(bad);
bad=s; bad.Field.thetam=2*bad.PoleSpan; expect(bad,'rnfoundry:em:InvalidMagnetAngle');
bad=s; bad.Armature.thetacy=0; expect(bad,'rnfoundry:em:InvalidSlotGeometry');
bad=s; bad.Armature.Rtsg=bad.Armature.Rtsb+.001; expect(bad,'rnfoundry:em:InvalidRadialOrder');
bad=s; bad.Armature.Winding.Layout.Coils=bad.Armature.Winding.Layout.Coils(:,1:end-1); expect(bad,'rnfoundry:em:InvalidWindingLayout');
bad=s; bad.Armature.Winding.Layout.Coils(1)=bad.Armature.Winding.SlotCount+1; expect(bad,'rnfoundry:em:InvalidWindingLayout');
bad=s; bad.Armature.Winding.Layout.Coils(1)=1.5; expect(bad,'rnfoundry:em:InvalidWindingLayout');
bad=s; bad.Armature.Winding.Layout.Phases=bad.Armature.Winding.Layout.Phases(1:end-1,:); expect(bad,'rnfoundry:em:InvalidWindingLayout');
bad=s; bad.Armature.Winding.Layout.Phases=bad.Armature.Winding.Layout.Phases(:,1); expect(bad,'rnfoundry:em:InvalidWindingLayout');
bad=s; bad.Armature.Winding.Layout.Phases(1)=bad.Armature.Winding.PhaseCount+1; expect(bad,'rnfoundry:em:InvalidWindingLayout');
bad=s; bad.Armature.Winding.Conductor.Insulation.Type='Unsupported'; expect(bad,'rnfoundry:em:UnsupportedInsulation');
% Missing generated and supplied layout must fail clearly in the no-MEX path.
raw=input; raw.qc=double(raw.qc); if isfield(raw,'WindingLayout'), raw=rmfield(raw,'WindingLayout'); end
oldPath=path(); cleanup=onCleanup(@() path(oldPath));
mexPath=fullfile(tempdir(),'rnfoundry-em-m1a-mex');
if exist(mexPath,'dir'), rmpath(mexPath); end
% Numeric qc forces modern completion. Without mexmPhaseWL it must fail explicitly.
rnfoundry.em.test.assertError( ...
    @() rnfoundry.em.rotary.radial.SlottedPMMachine.fromThicknesses(raw), ...
    'rnfoundry:em:WindingLayoutUnavailable');
end
function expect(s,id)
rnfoundry.em.test.assertError(@() rnfoundry.em.rotary.radial.SlottedPMMachine.fromStruct(s),id);
end
function expectAny(s)
failed=false; try, rnfoundry.em.rotary.radial.SlottedPMMachine.fromStruct(s); catch, failed=true; end; assert(failed);
end
