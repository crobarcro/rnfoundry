function design = initialRadialSlottedRepairState(space, chrom)
%INITIALRADIALSLOTTEDREPAIRSTATE Reconstruct state after initial completion.
%   This deliberately covers only chromosome construction, origin-clearance
%   assertion, and completedesign; fixtures using it keep earlier repairs off.
candidate=space.decode(chrom);
design=candidate.toLegacyStruct();
if strcmp(design.ArmatureType,'external')
    design.Ryi=design.Ryo-design.ty;
    design.Rtsb=design.Ryi-design.tc(1);
    design.Rai=design.Rtsb-design.tsb;
    design.Rmo=design.Rai-design.g;
    design.Rmi=design.Rmo-design.tm;
    design.Rbi=design.Rmi-design.tbi;
    design.RyiVRyo=design.Ryi/design.Ryo;
    design.RtsbVRyi=design.Rtsb/design.Ryi;
    design.RaiVRtsb=design.Rai/design.Rtsb;
    design.RmoVRai=design.Rmo/design.Rai;
    design.RmiVRmo=design.Rmi/design.Rmo;
    design.RbiVRmi=design.Rbi/design.Rmi;
    assert(design.Rbi>=1e-4,'Fixture unexpectedly requires origin repair.');
else
    design.Rmo=design.Rbo-design.tbi;
    design.Rmi=design.Rmo-design.tm;
    design.Rao=design.Rmi-design.g;
    design.Rtsb=design.Rao-design.tsb;
    design.Ryo=design.Rtsb-design.tc(1);
    design.Ryi=design.Ryo-design.ty;
    design.RmoVRbo=design.Rmo/design.Rbo;
    design.RmiVRmo=design.Rmi/design.Rmo;
    design.RaoVRmi=design.Rao/design.Rmi;
    design.RtsbVRao=design.Rtsb/design.Rao;
    design.RyoVRtsb=design.Ryo/design.Rtsb;
    design.RyiVRyo=design.Ryi/design.Ryo;
    assert(design.Ryi>=1e-4,'Fixture unexpectedly requires origin repair.');
end
design.lsVtm=design.ls/design.tm;
design=completedesign_RADIAL_SLOTTED(design,space.SimOptions);
end
