function [design, simoptions] = repairRadialSlottedCandidate(design, options, simoptions)
%REPAIRRADIALSLOTTEDCANDIDATE Independently apply legacy-ordered repairs.
%   completedesign_RADIAL_SLOTTED is used only for deterministic physical
%   and winding completion; optimisation repair and sizing are implemented
%   here and never call chrom2design_RADIAL_SLOTTED.
if strcmp(design.ArmatureType, 'external')
    design = repair_external(design, simoptions, options);
    Rstatorsurface = design.Rai;
elseif strcmp(design.ArmatureType, 'internal')
    design = repair_internal(design, simoptions, options);
    Rstatorsurface = design.Rao;
else
    error('rnfoundry:em:InvalidArmatureType', 'ArmatureType must be internal or external.');
end

% Prevent overlap at the yoke.
m = ((design.thetacg - design.thetacy)/2) / (design.tc(1) - design.tc(2));
cy = design.thetacg/2 - m * design.tc(1);
if cy > ((design.thetas-2e-5) / 2)
    m = ((design.thetacg - (design.thetas-2e-5))/2) / design.tc(1);
    cy = (design.thetas-2e-5) / 2;
    design.thetacy = 2 * (m .* design.tc(2) + cy);
    design.thetacyVthetas = design.thetacy / design.thetas;
    design.thetac = [design.thetacg, design.thetacy];
end

% Prevent overlap in the shoe curve region.
cs = m * (design.tc(1) + (design.tsb-design.tsg)/2) + cy;
if cs > ((design.thetas-2e-5) / 2)
    m = ((design.thetas-2e-5)/2 - design.thetacy/2) / ...
        (design.tc(1) - design.tc(2) + (design.tsb-design.tsg)/2);
    cs = (design.thetacy/2) - m * design.tc(2);
    design.thetacg = 2 * (m .* design.tc(1) + cs);
    design.thetacgVthetas = design.thetacg / design.thetas;
    design.thetac = [design.thetacg, design.thetacy];
end

% Make the slot opening pass the permitted strand diameter.
if simoptions.PreventStrandDiameterGreaterThanSlotOpening
    if (0.5*design.thetasg*Rstatorsurface) > simoptions.MinStrandDiameter
        if ~isfield(simoptions, 'MaxStrandDiameter')
            simoptions.MaxStrandDiameter = 0.5*design.thetasg*Rstatorsurface;
        end
    else
        design.thetasg = 2*simoptions.MinStrandDiameter / Rstatorsurface;
        design.thetasgVthetacg = design.thetasg / design.thetacg;
        if design.thetasgVthetacg >= 1
            design.thetasg = ((design.thetacg*Rstatorsurface) - (2*1e-5)) / Rstatorsurface;
            design.thetasg = max(0, design.thetasg);
            design.thetasgVthetacg = design.thetasg / design.thetacg;
        end
        if ~isfield(simoptions, 'MaxStrandDiameter')
            simoptions.MaxStrandDiameter = simoptions.MinStrandDiameter*1.001;
        end
    end
end

% Recomplete from repaired dimensions, exactly as the legacy path does.
design = rmfield(design, 'RmiVRmo');
design = rmfield(design, 'g');
design = completedesign_RADIAL_SLOTTED(design, simoptions);
design.Hc = design.tc(1) + design.tsb;
if strcmp(design.ArmatureType, 'external')
    design.Wc = mean([design.thetacg*design.Rci, design.thetacy*design.Rco]);
else
    design.Wc = mean([design.thetacg*design.Rco, design.thetacy*design.Rci]);
end
[design, simoptions] = resolve_conductor_and_branches(design, simoptions);
end

function [design, simoptions] = resolve_conductor_and_branches(design, simoptions)
effectiveMaxStrandDiameter = inf;
if isfield(simoptions, 'MaxStrandDiameter')
    effectiveMaxStrandDiameter = simoptions.MaxStrandDiameter;
end
if effectiveMaxStrandDiameter < simoptions.MinStrandDiameter
    error('rnfoundry:em:InvalidStrandLimits', 'Maximum strand diameter is below minimum strand diameter.');
end
design.LgVLc = 0;
design.Dc = sqrt(4*design.Hc*design.Wc*design.CoilFillFactor*design.DcAreaFac/pi);
design.WireStrandDiameter = design.Dc/sqrt(design.NStrands);
if design.WireStrandDiameter < simoptions.MinStrandDiameter
    design.WireStrandDiameter = simoptions.MinStrandDiameter;
    design.Dc = design.WireStrandDiameter*sqrt(design.NStrands);
end
if design.WireStrandDiameter > effectiveMaxStrandDiameter
    design.WireStrandDiameter = effectiveMaxStrandDiameter;
    area = pi*(design.Dc/2)^2;
    fullDiameter = rnfoundry.em.winding.insulatedWireDiameter( ...
        design.WireStrandDiameter);
    strandArea = pi*(fullDiameter/2)^2;
    strandCount = NaN;
    if strandArea > area
        strandCount = 1;
        design.WireStrandDiameter = 0.99*sqrt(4*area/pi);
    elseif strandArea < area
        strandCount = round(area/strandArea);
    end
    % Deliberately preserve CoilTurns' Ac == area NaN behavior.
    design.NStrands = strandCount;
    design.Dc = design.WireStrandDiameter*sqrt(design.NStrands);
end
active = design.NCoilsPerPhase;
factors = find(rem(active, 1:active) == 0);
target = design.BranchFac*active;
[~, index] = min(abs(factors-target));
design.Branches = factors(index);
design.CoilsPerBranch = active/design.Branches;
end

function design = repair_external (design, simoptions, options)


    
    design.Ryi = design.Ryo - design.ty;
    design.RyiVRyo = design.Ryi / design.Ryo;
    design.Rtsb = design.Ryi - design.tc(1);
    design.RtsbVRyi = design.Rtsb / design.Ryi;
    design.Rai = design.Rtsb - design.tsb;
    design.RaiVRtsb = design.Rai / design.Rtsb;
    design.Rmo = design.Rai - design.g;
    design.RmoVRai = design.Rmo / design.Rai;
    design.Rmi = design.Rmo - design.tm;
    design.RmiVRmo = design.Rmi / design.Rmo;
    design.Rbi = design.Rmi - design.tbi;
    design.RbiVRmi = design.Rbi / design.Rmi;
    design.lsVtm = design.ls / design.tm;
    
    if design.Rbi < 1e-4;
        if design.Rbi < 0
            rshift = -design.Rbi + 1e-4;
        else
            rshift = 1e-4;
        end
        if design.Rbi < 0
            rshift = rshift + abs(design.Rbi);
        end
        design.Rbi = design.Rbi + rshift;
        design.Rmi = design.Rmi + rshift;
        design.Rmo = design.Rmo + rshift;
        design.Rai = design.Rai + rshift;
        design.Rtsb = design.Rtsb + rshift;
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        design.RyiVRyo = design.Ryi / design.Ryo;
        design.RtsbVRyi = design.Rtsb / design.Ryi;
        design.RaiVRtsb = design.Rai / design.Rtsb;
        design.RmoVRai = design.Rmo / design.Rai;
        design.RmiVRmo = design.Rmi / design.Rmo;
        design.RbiVRmi = design.Rbi / design.Rmi;
    end

    design = completedesign_RADIAL_SLOTTED(design, simoptions);
    
    % check if the shoe base is too big relative to the coil body height
    if (design.tsb > 0) && (design.tsb / design.tc(1)) > options.Max_tsbVtc1
        % shift the shoe base inward
        rshift = (design.tsb - (design.tc(1)*options.Max_tsbVtc1));
        design.Rtsb = design.Rtsb - rshift;
        design.tsb = design.tc(1)*options.Max_tsbVtc1;
        % recalculate the shoe gap size
        design.tsg = design.tsb * design.tsgVtsb;
        design.Rtsg = design.Rai + design.tsg;
        design = updatedims_exteral_arm(design);
    end
    
    % check if the coil slot height is greater than the maximum allowed
    if design.tc(1) > options.Max_tc
        % move the stator yoke inwards to reduce the size of the slot
        rshift = (design.tc(1) - options.Max_tc);
        design.Ryi = design.Ryi - rshift;
        design.Ryo = design.Ryo - rshift;
        design = updatedims_exteral_arm(design);
    end
    
    if isempty (options.Min_tc)
        options.Min_tc = 0.05 * mean(design.thetac) * design.Rcm;
        
        if isfield (design, 'CoilInsulationThickness')
            options.Min_tc = options.Min_tc + 3*design.CoilInsulationThickness;
        end
    end
    
    % check if the coil slot height is smaler than the minimum allowed
    if design.tc(1) < options.Min_tc
        % move the stator yoke outwards to increase the size of the slot
        rshift = (options.Min_tc - design.tc(1));
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        design = updatedims_exteral_arm(design);
    end
    

    % check if the configuration of the shoe will cause too small triangles
    % to be created in the mesh
    if design.tsb > 0 && (design.tsg < design.tsb)

        if design.tsg < 1e-5
            x = ((design.thetacg - design.thetasg)/2) * design.Rtsb;
            y = design.tsb;
            tsgangle = rad2deg(atan( y / x ));
        else
            tsgangle = inf;
        end

        if tsgangle < 15
            % remove the shoe altogether
            design.tsb = 0;
            design.tsg = 0;
            design.Rtsb = design.Rci;
            design.Rai = design.Rtsb;

            design = updatedims_exteral_arm(design);
        end

    end

    if design.g < options.Min_g
        % increase the outer diameter
        rshift = (options.Min_g - design.g);
        design.Rai = design.Rai + rshift;
        design.Rtsb = design.Rtsb + rshift;
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        
        design = updatedims_exteral_arm(design);
    end
    
    % set the size of the slot base
    design.tc(2) = design.tc(1) * options.tc2Vtc1;
    design.Rcb = design.Rco - design.tc(2);
    
    % check the angle of slot straight side is not too small
    slotsideangle = atan ((design.tc(1) - design.tc(2)) ...
                                    / abs(((design.thetacg*design.Rci) - (design.thetacy*design.Rco))/2));
                               
    if slotsideangle < deg2rad (5)
        % make the slot height bigger to increase the angle
        newtc = ( tan (deg2rad (5)) ...
                           * abs( ((design.thetacg*design.Rci) - (design.thetacy*design.Rco))/2) ) ...
                         / (1 - options.tc2Vtc1 );
        
        rshift = newtc - design.tc(1);
        design.tc(1) = newtc;
        design.tc(2) = design.tc(1) * options.tc2Vtc1;
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        design.Rcb = design.Ryi - design.tc(2);
        
        design = updatedims_exteral_arm(design);
    end
    
    % check the angle of the base is not too small
    slotbaseangle = 2 * (atan ((design.thetacy/2) * (design.Rco - design.tc(2)) / design.tc(2)));
    minangle = 10;
    if slotbaseangle < deg2rad (minangle)
        % move the slot base to make the angle at least 10 degrees
        tau_cy = design.Rcb * design.thetacy;
        
        newtc2 = tau_cy/2 / tan(deg2rad (minangle/2));
        
        design.tc(2) = newtc2;
        design.Rcb = design.Ryi - design.tc(2);
        
        design = updatedims_exteral_arm(design);
    end
        
end

function design = updatedims_exteral_arm (design)

    % some additional radial variables
    design.Rci = design.Rtsb;
    design.Rco = design.Ryi;
    design.Rbo = design.Rmi;

    % lengths in radial direction
    design.ty = design.Ryo - design.Ryi;
    design.tc(1) = design.Rco - design.Rci;
    if isfield (design, 'Rcb')
        design.tc(2) = design.Rco - design.Rcb;
    end
    design.tsb = design.Rtsb - design.Rai;
    design.g = design.Rai - design.Rmo;
    design.tm = design.Rmo - design.Rmi;
    design.tbi = design.Rbo - design.Rbi;

    % the shoe tip length
    design.Rtsg = design.Rai + design.tsg;

    % mean radial position of magnets
    design.Rmm = mean([design.Rmo, design.Rmi]);
    design.Rcm = mean([design.Rci, design.Rco]);
    design.Rbm = mean([design.Rbo, design.Rbi]);
    design.Rym = mean([design.Ryi, design.Ryo]);
    
    % update the ratios
    design.RyiVRyo = design.Ryi / design.Ryo;
    design.RtsbVRyi = design.Rtsb / design.Ryi;
    design.RaiVRtsb = design.Rai / design.Rtsb;
    design.RmoVRai = design.Rmo / design.Rai;
    design.RmiVRmo = design.Rmi / design.Rmo;
    design.RbiVRmi = design.Rbi / design.Rmi;
    design.tsgVtsb = design.tsg / design.tsb;

    % thetap and thetas are calculated in completedesign_RADIAL
    design.thetamVthetap = design.thetam / design.thetap;
    design.thetacgVthetas = design.thetacg / design.thetas;
    design.thetacyVthetas = design.thetacy / design.thetas;
    design.thetasgVthetacg = design.thetasg / design.thetacg;
    design.lsVtm = design.ls / design.tm;
    design.thetac = [design.thetacg, design.thetacy];
    
end


function design = repair_internal (design, simoptions, options)

    
    design.Rmo = design.Rbo - design.tbi;
    design.Rmi = design.Rmo - design.tm;
    design.Rao = design.Rmi - design.g;
    design.Rtsb = design.Rao - design.tsb;
    design.Ryo = design.Rtsb - design.tc(1);
    design.Ryi = design.Ryo - design.ty;
    
    design.RmoVRbo = design.Rmo / design.Rbo;
    design.RmiVRmo = design.Rmi / design.Rmo;
    design.RaoVRmi = design.Rao / design.Rmi;
    design.RtsbVRao = design.Rtsb / design.Rao;
    design.RyoVRtsb = design.Ryo / design.Rtsb;
    design.RyiVRyo = design.Ryi / design.Ryo;
    design.lsVtm = design.ls / design.tm;
    
    % check if the dimensions result in a design with too small an inner
    % radius
    if design.Ryi < 1e-4;
        if design.Ryi < 0
            rshift = -design.Ryi + 1e-4;
        else
            rshift = 1e-4;
        end
        if design.Ryi < 0
            rshift = rshift + abs(design.Ryi);
        end
        design.Rbo = design.Rbo + rshift;
        design.Rmo = design.Rmo + rshift;
        design.Rmi = design.Rmi + rshift;
        design.Rao = design.Rao + rshift;
        design.Rtsb = design.Rtsb + rshift;
        design.Ryo = design.Ryo + rshift;
        design.Ryi = design.Ryi + rshift;
        
        design.RmoVRbo = design.Rmo / design.Rbo;
        design.RmiVRmo = design.Rmi / design.Rmo;
        design.RaoVRmi = design.Rao / design.Rmi;
        design.RtsbVRao = design.Rtsb / design.Rao;
        design.RyoVRtsb = design.Ryo / design.Rtsb;
        design.RyiVRyo = design.Ryi / design.Ryo;
    end


    design = completedesign_RADIAL_SLOTTED(design, simoptions);

    % check for too big tooth shoe
    if (design.tsb > 0) && (design.tsb / design.tc(1)) > options.Max_tsbVtc1
        % shift the shoe base radial position outward
        design.tsb = design.tc(1)*options.Max_tsbVtc1;
        design.Rtsb = design.Rao - design.tsb;
        % recalculate the shoe gap size
        design.tsg = design.tsb * design.tsgVtsb;
        design.Rtsg = design.Rao - design.tsg;
        design = updatedims_interal_arm(design);
    end

    % check if the coil slot height is greater than the maximum allowed
    if design.tc(1) > options.Max_tc
        % move the stator yoke outwards to reduce the size of the slot
        rshift = (design.tc(1) - options.Max_tc);
        design.tc(1) = options.Max_tc;
        design.Ryi = design.Ryi + rshift;
        design.Ryo = design.Ryo + rshift;
        design = updatedims_interal_arm(design);
    end
    
    if isempty (options.Min_tc)
        options.Min_tc = 0.05 * mean(design.thetac) * design.Rcm;
        
        if isfield (design, 'CoilInsulationThickness')
            options.Min_tc = options.Min_tc + 3*design.CoilInsulationThickness;
        end
    end
    
    % check if the coil slot height is smaller than the minimum allowed
    if design.tc(1) < options.Min_tc
        % move the stator yoke inwards to increase the size of the slot
        rshift = (options.Min_tc - design.tc(1));
        
        if rshift >= design.Ryi
            % the amount we need to shift inwards is greater than the space
            % available, so we'll have to shift everything outwards a bit
            % to make the space
            rshift2 = design.Ryi - rshift + 1e-5;
        else
            rshift2 = 0;
        end
        
        % first shift yoke inwards by rshift
        design.Ryi = design.Ryi - rshift;
        design.Ryo = design.Ryo - rshift;
        
        % then shift everything outwards by rshift2
        design.Rbo = design.Rbo + rshift2;
        design.Rmo = design.Rmo + rshift2;
        design.Rmi = design.Rmi + rshift2;
        design.Rao = design.Rao + rshift2;
        design.Rtsb = design.Rtsb + rshift2;
        design.Ryo = design.Ryo + rshift2;
        design.Ryi = design.Ryi + rshift2;
        
        design = updatedims_interal_arm(design);
    end
    

    % check if the configuration of the shoe will cause too small triangles
    % to be created in the mesh
    if design.tsb > 0 && (design.tsg < design.tsb)

        if design.tsg < 1e-5
            x = ((design.thetacg - design.thetasg)/2) * design.Rtsb;
            y = design.tsb;
            tsgangle = rad2deg(atan( y / x ));
        else
            tsgangle = inf;
        end

        if tsgangle < 15
            % remove the shoe altogether
            design.tsb = 0;
            design.tsg = 0;
            design.Rtsb = design.Rco;
            design.Rao = design.Rtsb;

            design = updatedims_interal_arm(design);
        end

    end

    if design.g < options.Min_g
        % increase the outer diameter
        rshift = (options.Min_g - design.g);
        
        design.Rbo = design.Rbo + rshift;
        design.Rmo = design.Rmo + rshift;
        design.Rmi = design.Rmi + rshift;
        
        design = updatedims_interal_arm (design);
    end
    
    % set the size of the slot base
    design.tc(2) = design.tc(1) * options.tc2Vtc1;
    design.Rcb = design.Ryo + design.tc(2);
    
    % check the angle of slot straight side is not too small
    slotsideangle = atan ((design.tc(1) - design.tc(2)) ...
                                    / abs(((design.thetacg*design.Rco) - (design.thetacy*design.Rci))/2));
                               
    if slotsideangle < deg2rad (5)
        % make the slot height bigger to increase the angle
        newtc = ( tan (deg2rad (5)) ...
                           * abs( ((design.thetacg*design.Rco) - (design.thetacy*design.Rci))/2) ) ...
                         / (1 - options.tc2Vtc1 );
        
        rshift = newtc - design.tc(1);
        design.tc(1) = newtc;
        design.tc(2) = design.tc(1) * options.tc2Vtc1;
        
        if rshift >= design.Ryi
            % the amount we need to shift inwards is greater than the space
            % available, so we'll have to shift everything outwards a bit
            % to make the space
            rshift2 = design.Ryi - rshift;
        else
            rshift2 = 0;
        end
        
        % first shift yoke inwards by rshift
        design.Ryi = design.Ryi - rshift;
        design.Ryo = design.Ryo - rshift;
        
        % then shift everything outwards by rshift2
        design.Rbo = design.Rbo + rshift2;
        design.Rmo = design.Rmo + rshift2;
        design.Rmi = design.Rmi + rshift2;
        design.Rao = design.Rao + rshift2;
        design.Rtsb = design.Rtsb + rshift2;
        design.Ryo = design.Ryo + rshift2;
        design.Ryi = design.Ryi + rshift2;
        
        design.Rcb = design.Ryo + design.tc(2);
        
        design = updatedims_interal_arm (design);
        
    end
    
    % check the angle of the base is not too small
    slotbaseangle = 2 * (atan ((design.thetacy/2) * (design.Ryo + design.tc(2)) / design.tc(2)));
    minangle = 10;
    if slotbaseangle < deg2rad (minangle)
        % move the slot base to make the angle at least 10 degrees
        tau_cy = design.Rcb * design.thetacy;
        
        newtc2 = tau_cy/2 / tan(deg2rad (minangle/2));
        
        design.tc(2) = newtc2;
        design.Rcb = design.Ryo + design.tc(2);
        
        design = updatedims_interal_arm (design);
    end
    
    
end


function design = updatedims_interal_arm (design)

    % some additional radial variables
    design.ty = design.Ryo - design.Ryi;
    design.tc = design.Rtsb - design.Ryo;
    design.tsb = design.Rao - design.Rtsb;
    design.g = design.Rmi - design.Rao;
    design.tm = design.Rmo - design.Rmi;
    design.tbi = design.Rbo - design.Rmo;

    design.Rco = design.Rtsb;
    design.Rci = design.Ryo;
    design.Rbi = design.Rmo;
    design.Rtsg = design.Rao - design.tsg;

    if isfield (design, 'Rcb')
        design.tc(2) = design.Rcb - design.Ryo;
        design.RcbVRtsb = design.Rcb / design.Rtsb;
    end

    % mean radial position of magnets
    design.Rmm = mean([design.Rmo, design.Rmi]);
    design.Rcm = mean([design.Rci, design.Rco]);
    design.Rbm = mean([design.Rbo, design.Rbi]);
    design.Rym = mean([design.Ryi, design.Ryo]);
    
    % complete the ratios
    design.RmoVRbo = design.Rmo / design.Rbo;
    design.RmiVRmo = design.Rmi / design.Rmo;
    design.RaoVRmi = design.Rao / design.Rmi;
    design.RtsbVRao = design.Rtsb / design.Rao;
    design.RyoVRtsb = design.Ryo / design.Rtsb;
    design.RyiVRyo = design.Ryi / design.Ryo;
    design.tsgVtsb = design.tsg / design.tsb;

    design.thetamVthetap = design.thetam / design.thetap;
    design.thetacgVthetas = design.thetacg / design.thetas;
    design.thetacyVthetas = design.thetacy / design.thetas;
    design.thetasgVthetacg = design.thetasg / design.thetacg;
    design.lsVtm = design.ls / design.tm;

end
