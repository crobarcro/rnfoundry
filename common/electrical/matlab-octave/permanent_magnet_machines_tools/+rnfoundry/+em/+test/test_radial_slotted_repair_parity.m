function test_radial_slotted_repair_parity()
%TEST_RADIAL_SLOTTED_REPAIR_PARITY Compare both orientations to baseline.
chrom=[.32;.8;.2;.1;.5;.002;.1;2;.8;.7;.6;.4;.5;5.2;.025;.7;.25];
for position={'internal','external'}
    opts=struct('ArmatureType',position{1}); s=rnfoundry.em.optim.RadialSlottedDesignSpace(opts);
    [legacy,legacyOptions]=chrom2design_RADIAL_SLOTTED(struct(),chrom,'ArmatureType',position{1});
    [candidate,info]=s.repair(s.decode(chrom)); modern=candidate.toLegacyStruct();
    fields={'Ryi','Ryo','Rmi','Rmo','Rbi','Rbo','tc','tsb','tsg','g', ...
        'thetacg','thetacy','thetasg','Dc','WireStrandDiameter','NStrands','Branches','CoilsPerBranch'};
    for k=1:numel(fields), rnfoundry.em.test.assertNear(modern.(fields{k}),legacy.(fields{k}),1e-12); end
    assert(candidate.IsRepaired && isempty(info.Applied));
    assert(candidate.Compatibility.SimOptions.MaxStrandDiameter==legacyOptions.MaxStrandDiameter);
end
end
