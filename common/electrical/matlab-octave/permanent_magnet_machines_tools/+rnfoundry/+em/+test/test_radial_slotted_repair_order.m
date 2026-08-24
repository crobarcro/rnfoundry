function test_radial_slotted_repair_order()
%TEST_RADIAL_SLOTTED_REPAIR_ORDER Characterize interacting repair sequences.
b=[.12;.2;1.2;1;.001;1e-6;.01;.1;.8;1.1;1.1;.001;.05;3.6;.8;.8];
fixtures={ ...
 'shoe plus tc',setv(b,4,1.2); ...
 'tc plus slot angle',setv(b,[4,6,10,11],[0,.002,.99,.1]); ...
 'slot angle plus overlap',setv(b,[3,4,6,10,11],[.005,0,.002,.01,1.2]); ...
 'gap plus ratios',setv(b,[3,6],[.1,1e-7]); ...
 'opening plus conductor max',setv(b,[12,15],[.001,1]); ...
 'internal shift tc angle',setv(b,[1,3,4,10,11],[.01,.005,0,100,.1])};
for k=1:size(fixtures,1)
    chrom=fixtures{k,2};
    position='external'; if k==6, position='internal'; end
    sim=struct();
    options=struct('ArmatureType',position);
    if k==2, options.Max_tc=.001; options.Min_tc=1e-4; end
    if k==3, options.Min_tc=1e-4; end
    if k==6, options.Min_tc=.01; end
    [~,legacy,modernSim,legacySim]=rnfoundry.em.test.assertCandidateLegacyParity( ...
        chrom,options,sim);
    switch k
        case 1 % shoe-base ratio is limited before maximum tc is enforced
            assert(chrom(4)*.2/(chrom(3)*.2)>.9);
            assert(chrom(3)*.2>.2);
            assert(abs(legacy.tsb-.9*(chrom(3)*.2))<1e-13);
            assert(legacy.tsb/legacy.tc(1)>.9);
        case 2 % maximum tc, followed by a slot-side-angle increase
            space=rnfoundry.em.optim.RadialSlottedDesignSpace(options,sim);
            pre=rnfoundry.em.test.initialRadialSlottedRepairState(space,chrom);
            assert(pre.tsb==0 && pre.tc(1)>options.Max_tc);
            afterTc=applyExternalMaxTc(pre,options.Max_tc);
            afterTc.tc(2)=afterTc.tc(1)*space.Options.tc2Vtc1;
            newtc=requiredTc(afterTc,position,space.Options.tc2Vtc1);
            assert(sideAngle(afterTc,position)<deg2rad(5) && newtc>afterTc.tc(1));
            assert(abs(legacy.tc(1)-newtc)<1e-12);
            assert(finalSideAngle(legacy,position)>=deg2rad(5)-1e-10);
        case 3 % slot-side-angle growth and subsequent overlap correction
            space=rnfoundry.em.optim.RadialSlottedDesignSpace(options,sim);
            pre=rnfoundry.em.test.initialRadialSlottedRepairState(space,chrom);
            pre.tc(2)=pre.tc(1)*space.Options.tc2Vtc1;
            newtc=requiredTc(pre,position,space.Options.tc2Vtc1);
            assert(pre.tsb==0 && sideAngle(pre,position)<deg2rad(5) && newtc>pre.tc(1));
            assert(abs(legacy.tc(1)-newtc)<1e-12);
            assert(abs(legacy.thetacyVthetas-chrom(11))>1e-8 || ...
                   abs(legacy.thetacgVthetas-chrom(10))>1e-8);
        case 4 % air gap movement and ratios recompleted from final radii
            assert(chrom(6)<.5e-3 && legacy.g>=.5e-3-eps);
            assert(abs(legacy.RmiVRmo-legacy.Rmi/legacy.Rmo)<1e-13);
            assert(abs(legacy.RmoVRai-legacy.Rmo/legacy.Rai)<1e-13);
        case 5 % opening-derived limit subsequently changes strand construction
            assert(~isfield(sim,'MaxStrandDiameter'));
            assert(isfield(modernSim,'MaxStrandDiameter') && ...
                   modernSim.MaxStrandDiameter==legacySim.MaxStrandDiameter);
            expectedLimit=legacySim.MinStrandDiameter*1.001;
            assert(abs(legacySim.MaxStrandDiameter-expectedLimit)<1e-15);
            unconstrainedDc=sqrt(4*legacy.Hc*legacy.Wc*legacy.CoilFillFactor* ...
                chrom(15)/pi);
            candidateStrandDiameter=unconstrainedDc/sqrt(1);
            assert(candidateStrandDiameter>legacySim.MaxStrandDiameter);
            assert(legacy.WireStrandDiameter<=legacySim.MaxStrandDiameter);
            assert(legacy.NStrands>1);
        case 6 % small internal stack, minimum tc, then slot-angle growth
            space=rnfoundry.em.optim.RadialSlottedDesignSpace(options,sim);
            pre=rnfoundry.em.test.initialRadialSlottedRepairState(space,chrom);
            minShift=options.Min_tc-pre.tc(1);
            assert(minShift>=pre.Ryi);
            afterMin=applyInternalMinTc(pre,options.Min_tc);
            afterMin.tc(2)=afterMin.tc(1)*space.Options.tc2Vtc1;
            newtc=requiredTc(afterMin,position,space.Options.tc2Vtc1);
            slotShift=newtc-afterMin.tc(1);
            assert(sideAngle(afterMin,position)<deg2rad(5) && slotShift>=afterMin.Ryi);
            assert(abs(legacy.tc(1)-newtc)<1e-12);
    end
end
end
function angle=finalSideAngle(d,p)
if strcmp(p,'external'), a=d.thetacg*d.Rci; b=d.thetacy*d.Rco;
else, a=d.thetacg*d.Rco; b=d.thetacy*d.Rci; end
angle=atan((d.tc(1)-d.tc(2))/abs((a-b)/2));
end
function angle=sideAngle(d,p)
angle=finalSideAngle(d,p);
end
function newtc=requiredTc(d,p,ratio)
if strcmp(p,'external'), a=d.thetacg*d.Rci; z=d.thetacy*d.Rco;
else, a=d.thetacg*d.Rco; z=d.thetacy*d.Rci; end
newtc=tan(deg2rad(5))*abs((a-z)/2)/(1-ratio);
end
function d=applyExternalMaxTc(d,maxTc)
rshift=d.tc(1)-maxTc; d.Ryi=d.Ryi-rshift; d.Ryo=d.Ryo-rshift;
d.Rco=d.Ryi; d.tc(1)=d.Rco-d.Rci; d.Rcm=mean([d.Rci,d.Rco]);
end
function d=applyInternalMinTc(d,minTc)
rshift=minTc-d.tc(1); rshift2=0;
if rshift>=d.Ryi, rshift2=d.Ryi-rshift+1e-5; end
d.Ryi=d.Ryi-rshift+rshift2; d.Ryo=d.Ryo-rshift+rshift2;
d.Rbo=d.Rbo+rshift2; d.Rmo=d.Rmo+rshift2; d.Rmi=d.Rmi+rshift2;
d.Rao=d.Rao+rshift2; d.Rtsb=d.Rtsb+rshift2;
d.Rci=d.Ryo; d.Rco=d.Rtsb; d.tc(1)=d.Rco-d.Rci; d.Rcm=mean([d.Rci,d.Rco]);
end
function out=setv(in,indices,values)
out=in; out(indices)=values;
end
