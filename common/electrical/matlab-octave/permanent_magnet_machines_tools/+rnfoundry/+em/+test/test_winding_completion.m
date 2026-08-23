function test_winding_completion()
forms={'Qc_poles','qc_poles','qc_basic'};
for k=1:numel(forms)
    input=rnfoundry.em.test.baseInput('external',2,forms{k});
    if strcmp(forms{k},'qc_basic')
        input.qc=fr(1,1); input.NBasicWindings=3;
    end
    legacy=completedesign_RADIAL_SLOTTED(input,struct(),'tdims');
    fallback=input; if isfield(fallback,'qc'), fallback.qc=double(fallback.qc); end
    fallback.WindingLayout=legacy.WindingLayout;
    modern=rnfoundry.em.rotary.radial.SlottedPMMachine.fromThicknesses(fallback).toLegacyStruct();
    fields={'Qc','Poles','Qcb','pb','NBasicWindings','Qs','Qsb','qcn','qcd','ypn','ypd','yd'};
    for j=1:numel(fields), rnfoundry.em.test.assertNear(modern.(fields{j}),legacy.(fields{j})); end
end
% pb == 1 forces an odd basic-winding count to become even.
input=rnfoundry.em.test.baseInput('external',2,'qc_basic');
input.qc=fr(1,1); input.NBasicWindings=3;
legacy=completedesign_RADIAL_SLOTTED(input,struct(),'tdims');
assert(legacy.NBasicWindings==4 && legacy.Poles==4);
% Fractional slots require explicit yd.
input=rnfoundry.em.test.baseInput('external',2,'fractional'); input=rmfield(input,'yd');
assertFails(@() completedesign_RADIAL_SLOTTED(input,struct(),'tdims'));
assertFails(@() rnfoundry.em.rotary.radial.SlottedPMMachine.fromThicknesses(input));
% Impossible basic winding and unsupported layers are rejected.
input=rnfoundry.em.test.baseInput('external',2,'qc_poles'); input.qc=0.5; input.Poles=1;
assertFails(@() rnfoundry.em.rotary.radial.SlottedPMMachine.fromThicknesses(input));
input=rnfoundry.em.test.baseInput('external',3,'qc_poles'); input.qc=double(input.qc);
assertFails(@() rnfoundry.em.rotary.radial.SlottedPMMachine.fromThicknesses(input));
end
function assertFails(f)
failed=false; try, f(); catch, failed=true; end; assert(failed);
end
