function test_winding_configuration_parity()
%TEST_WINDING_CONFIGURATION_PARITY Cover single-layer and fractional slots.
c=[.32;.8;.2;.1;.5;.002;.1;2;.8;.7;.6;.4;.05;6;.025;.7];

% Single layer doubles slots relative to coils and builds canonically.
options=struct('ArmatureType','external','CoilLayers',1);
[~,legacy]=rnfoundry.em.test.assertCandidateLegacyParity(c,options,struct());
assert(legacy.Qs==2*legacy.Qc && size(legacy.WindingLayout.Phases,2)==1);
space=rnfoundry.em.optim.RadialSlottedDesignSpace(options);
[candidate,~]=space.repair(space.decode(c));
machine=space.build(candidate,struct('PackArea',2e-4));
assert(machine.Armature.Winding.LayerCount==1);
assert(machine.Armature.Winding.SlotCount==2*machine.Armature.Winding.CoilCount);

% qc=1/2 produces a non-integral slots-per-pole winding; yd is explicit.
options=struct('ArmatureType','internal','qc',fr(1,2),'yd',1);
[~,legacy]=rnfoundry.em.test.assertCandidateLegacyParity(c,options,struct());
assert(legacy.ypd~=1 && legacy.yd==1);
space=rnfoundry.em.optim.RadialSlottedDesignSpace(options);
[candidate,~]=space.repair(space.decode(c));
machine=space.build(candidate,struct('PackArea',2e-4));
assert(machine.Armature.Winding.ypd~=1);
assert(machine.Armature.Winding.CoilPitchSlots==1);
end
