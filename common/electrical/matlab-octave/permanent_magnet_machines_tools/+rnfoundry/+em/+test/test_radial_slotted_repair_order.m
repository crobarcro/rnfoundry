function test_radial_slotted_repair_order()
%TEST_RADIAL_SLOTTED_REPAIR_ORDER Characterize interacting repair sequences.
b=[.12;.2;1.2;1;.001;1e-6;.01;.1;.8;1.1;1.1;.001;.05;3.6;.8;.8];
fixtures={ ...
 'shoe plus tc',setv(b,4,1.2); ...
 'tc plus slot angle',setv(b,[4,10,11],[.1,.99,.01]); ...
 'slot angle plus overlap',setv(b,[3,11],[.02,1.2]); ...
 'gap plus ratios',setv(b,[3,6],[.1,1e-7]); ...
 'opening plus conductor max',setv(b,[12,15],[.001,1]); ...
 'internal shift tc angle',setv(b,[1,3,10],[.03,.001,.99])};
for k=1:size(fixtures,1)
    chrom=fixtures{k,2};
    position='external'; if k==6, position='internal'; end
    sim=struct(); if k==5, sim.MaxStrandDiameter=.6e-3; end
    options=struct('ArmatureType',position);
    if k==2, options.Max_tc=.005; end
    [~,legacy,modernSim,legacySim]=rnfoundry.em.test.assertCandidateLegacyParity( ...
        chrom,options,sim);
    switch k
        case 1 % shoe-base ratio is limited before maximum tc is enforced
            assert(chrom(4)*.2/(chrom(3)*.2)>.9);
            assert(chrom(3)*.2>.2);
            assert(abs(legacy.tsb-.9*(chrom(3)*.2))<1e-13);
            assert(legacy.tsb/legacy.tc(1)>.9);
        case 2 % maximum tc, followed by a slot-side-angle increase
            assert(chrom(3)*options.Max_tc>options.Max_tc);
            assert(legacy.tc(1)>options.Max_tc); % later angle repair grows tc again
            assert(finalSideAngle(legacy,position)>=deg2rad(5)-1e-10);
        case 3 % slot-side-angle growth and subsequent overlap correction
            assert(legacy.tc(1)>chrom(3)*.2);
            assert(abs(legacy.thetacyVthetas-chrom(11))>1e-8 || ...
                   abs(legacy.thetacgVthetas-chrom(10))>1e-8);
        case 4 % air gap movement and ratios recompleted from final radii
            assert(chrom(6)<.5e-3 && legacy.g>=.5e-3-eps);
            assert(abs(legacy.RmiVRmo-legacy.Rmi/legacy.Rmo)<1e-13);
            assert(abs(legacy.RmoVRai-legacy.Rmo/legacy.Rai)<1e-13);
        case 5 % opening-derived limit subsequently changes strand construction
            assert(isfield(modernSim,'MaxStrandDiameter') && ...
                   modernSim.MaxStrandDiameter==legacySim.MaxStrandDiameter);
            assert(legacy.WireStrandDiameter<=legacySim.MaxStrandDiameter);
            assert(legacy.NStrands>1);
        case 6 % small internal stack, minimum tc, then slot-angle growth
            assert(chrom(1)<.1 && legacy.tc(1)>chrom(3)*.2);
            assert(finalSideAngle(legacy,position)>=deg2rad(5)-1e-10);
            assert(legacy.Ryi~=chrom(1)-legacy.tbi-legacy.tm-legacy.g- ...
                legacy.tsb-chrom(3)*.2-legacy.ty);
    end
end
end
function angle=finalSideAngle(d,p)
if strcmp(p,'external'), a=d.thetacg*d.Rci; b=d.thetacy*d.Rco;
else, a=d.thetacg*d.Rco; b=d.thetacy*d.Rci; end
angle=atan((d.tc(1)-d.tc(2))/abs((a-b)/2));
end
function out=setv(in,indices,values)
out=in; out(indices)=values;
end
