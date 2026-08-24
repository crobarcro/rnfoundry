function test_radial_slotted_repair_characterization()
%TEST_RADIAL_SLOTTED_REPAIR_CHARACTERIZATION Prove each repair consequence.
b=baseChrom();

% Decode-time construction clamps and winding rounding.
c=b; c(7)=1e-4; [~,d]=parity(c,'external'); assert(abs(d.tm-1e-3)<1e-14);
c=b; c(8)=1e-4; [~,d]=parity(c,'external'); assert(abs(d.tbi-1e-3)<1e-14);
c=b; c(2)=1e-4; [~,d]=parity(c,'external'); assert(abs(d.ty-1e-3)<1e-14);
c=b; c(14)=5.6; [~,d]=parity(c,'external'); assert(d.NBasicWindings==6);

for position={'external','internal'}
    p=position{1};
    c=b; c(1)=.03; [~,d]=parity(c,p);
    if strcmp(p,'external'), assert(d.Rbi>=1e-4); else, assert(d.Ryi>=1e-4); end

    c=b; c(4)=1; [~,d]=parity(c,p); assert(d.tsb/d.tc(1)<=.9+eps);
    c=b; c(3)=1.5; [~,d]=parity(c,p); assert(d.tc(1)<=.2+eps);
    c=b; c(3)=1e-4; [~,d]=parity(c,p); assert(d.tc(1)>c(3)*.2);

    % A shallow shoe and zero tip ratio genuinely satisfy the <15 degree test.
    c=b; c(4)=.001; c(5)=0; [~,d]=parity(c,p);
    assert(d.tsb==0 && d.tsg==0);

    c=b; c(6)=1e-7; [~,d]=parity(c,p); assert(d.g>=.5e-3-eps);

    % Tiny tc and strongly tapered sides start below five degrees.
    c=b; c(3)=.001; c(10)=.99; c(11)=.01;
    requestedTc=c(3)*.2; requestedTcb=.1*requestedTc;
    requestedAngle=atan((requestedTc-requestedTcb)/ ...
        abs((c(10)-c(11))*d.thetas*d.Rcm/2));
    assert(requestedAngle<deg2rad(5));
    [~,d]=parity(c,p); assert(d.tc(1)>requestedTc);
    assert(slotSideAngle(d,p)>=deg2rad(5)-1e-10);

    c=b; c(11)=1e-5; [~,d]=parity(c,p);
    assert(abs(d.tc(2)-.1*d.tc(1))>1e-12);
end

% Internal minimum-tc secondary shift: requested increase exceeds inner space.
c=b; c(1)=.03; c(3)=1e-4;
[~,d]=parity(c,'internal',struct('Min_tc',.02));
assert(.02-c(3)*.2>=1e-4); assert(d.tc(1)>=.02-1e-12);

% Internal slot-angle secondary shift with very small available inner radius.
c=b; c(1)=.03; c(3)=.001; c(10)=.99; c(11)=.01;
[~,d]=parity(c,'internal');
assert(slotSideAngle(d,'internal')>=deg2rad(5)-1e-10);

% Both overlap repairs change their requested angular ratios.
c=b; c(11)=1.2; [~,d]=parity(c,'external');
assert(abs(d.thetacyVthetas-c(11))>1e-8);
c=b; c(10)=1.2; [~,d]=parity(c,'external');
assert(abs(d.thetacgVthetas-c(10))>1e-8);

% Slot opening: unchanged large case, enlarged case, and capped case.
c=b; [~,d,ms,ls]=parity(c,'external'); assert(isfield(ls,'MaxStrandDiameter'));
assert(isfield(ms,'MaxStrandDiameter') && d.thetasg>0);
c=b; c(12)=1e-4; [~,d]=parity(c,'external');
assert(d.thetasg>=0 && d.thetasgVthetacg>c(12));
c=b; c(10)=1e-4; c(12)=1e-4; [~,d]=parity(c,'external');
assert(d.thetasgVthetacg<1 || d.thetasg==0);

% Strand clamps and branch-factor selection.
c=b; c(15)=1e-10; [~,d]=parity(c,'internal'); assert(abs(d.WireStrandDiameter-.5e-3)<1e-14);
c=b; [~,d]=parity(c,'internal',struct(),struct('MaxStrandDiameter',.6e-3));
assert(d.WireStrandDiameter<=.6e-3 && d.NStrands>1);
for branch=[0,.1,.49,.51,.9,1]
    c=b; c(16)=branch; [~,d]=parity(c,'internal');
    assert(rem(d.NCoilsPerPhase,d.Branches)==0);
    assert(d.CoilsPerBranch==d.NCoilsPerPhase/d.Branches);
end
end

function [modern,legacy,modernSim,legacySim]=parity(chrom,position,extraOptions,sim)
if nargin<3, extraOptions=struct(); end
if nargin<4, sim=struct(); end
extraOptions.ArmatureType=position;
[modern,legacy,modernSim,legacySim]= ...
    rnfoundry.em.test.assertCandidateLegacyParity(chrom,extraOptions,sim);
end
function angle=slotSideAngle(d,p)
if strcmp(p,'external'), a=d.thetacg*d.Rci; b=d.thetacy*d.Rco;
else, a=d.thetacg*d.Rco; b=d.thetacy*d.Rci; end
angle=atan((d.tc(1)-d.tc(2))/abs((a-b)/2));
end
function angle=slotBaseAngle(d,p)
if strcmp(p,'external'), radius=d.Rco-d.tc(2); else, radius=d.Ryo+d.tc(2); end
angle=2*atan((d.thetacy/2)*radius/d.tc(2));
end
function c=baseChrom()
c=[.32;.8;.2;.1;.5;.002;.1;2;.8;.7;.6;.4;.05;5.2;.025;.7];
end
