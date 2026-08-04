function design = completedesign_RADIAL_SLOTTED(design, simoptions, setchoice)
% converts a minimal design specification to a complete design suitable for
% use by simfun_RADIAL_SLOTTED
%
% Syntax
%
% design = completedesign_RADIAL_SLOTTED(design, simoptions, setchoice)
%
% Description
%
% completedesign_RADIAL_SLOTTED takes a minimal design structure describing
% a slotted radial flux permanent magnet machine design and completes it by
% calculating various dimensions and parameters and properties of the
% machine windings etc. The design dimensions can be specified either as
% dimensionless ratios or actual dimensions. All variables are supplied as
% fields in a machine design structure.
%
% The design can be for either an internal or external armature. This is
% specified in the field 'ArmatureType' which must contain a string, either
% 'internal' or 'external'. Any unambiguous substring is also acceptable,
% e.g 'e' or'i', or 'ext', or 'in'.
%
% In general, all dimensions which refer to a radial measurement from the
% center of the machine are prefixed with the capital letter 'R'.
%
% For an INTERNAL ARMATURE machine, the design structure must also contain
% either all the fields:
%
%    Rbo - radial distance to outer back iron surface
%
%    Rmo - radial distance to outer magnet surface
%
%    Rmi - radial distance to inner magnet surface
%
%    Rao - radial distance to armature outer surface (surface of teeth or coils)
%
%    Rtsb - radial distance to tooth shoe base
%
%    Ryi - radial distance to armature yoke inner surface
%
%    Ryo - radial distance to armature yoke outer surface
%
%    tsg - thickness of shoe in radial direction at shoe gap
%
%    thetam -  angular pitch of magnet in radians
%
%    thetacg - coil inner slot pitch in radians at the end of the coil closest
%      to the slot opening
%
%    thetacy - coil inner slot pitch in radians at the end of the coil closest
%      to the yoke
%
%    thetasg - angular pitch of the coil slot opening between shoes
%
%    ls - stack length (depth 'into the page' of simulation)
%
% or all the fields below, which represent ratios of the previous dimensions:
%
%    Rbo - radial distance to outer back iron surface
%    RmoVRbo - Rmo to Rbo ratio
%    RmiVRmo - Rmi to Rmo ratio
%    RsoVRmi -  Rso to Rmi ratio
%    RtsbVRao - Rtsb to Rao ratio
%    RyoVRtsb - Ryo to Rtsb ratio
%    RyiVRyo -  Ryi to Ryo ratio
%    tsgVtsb -  tsg to tsb ratio
%    thetamVthetap - thetam to thetap ratio
%    thetacgVthetas - thetacg to thetas ratio
%    thetacyVthetas - thetacy to thetas ratio
%    thetasgVthetacg - thetasg to thetacg ratio
%    lsVtm - ls to tm ratio
%
% or all the fields
%
%    Rbo - radial distance to outer back iron surface
%
%    g - air gap length
%
%    ty - yoke thickness in radial direction
%
%    tm - magnet thickness in radial direction
%
%    tc - length of coil body in radial direction
%
%    tsb - slot shoe base thickness in radial direction
%
%    tbi - thickness of the back iron in radial direction
%
%    tsg - thickness of shoe in radial direction at shoe gap
%
%    thetam -  angular pitch of magnet in radians
%
%    thetacg - coil inner slot pitch in radians at the end of the coil closest
%      to the slot opening
%
%    thetacy - coil inner slot pitch in radians at the end of the coil closest
%      to the yoke
%
%    thetasg - angular pitch of the coil slot opening between shoes
%
%    ls - stack length (depth 'into the page' of simulation)
%
% For an EXTERNAL ARMATURE machine, the design structure must also contain
% either all the fields:
%
%    Ryo - radial distance to armature yoke outer surface
%
%    Ryi - radial distance to armature yoke inner surface
%
%    Rtsb - radial distance to tooth shoe base
%
%    Rai - radial distance to armature inner surface (surface of teeth or coils)
%
%    Rmi - radial distance to inner magnet surface
%
%    Rmo - radial distance to outer magnet surface
%
%    Rbi - radial distance to back iron inner surface
%
%    tsg - thickness of shoe in radial direction at shoe gap
%
%    thetam -  angular pitch of magnet in radians
%
%    thetacg - coil inner slot pitch in radians at the end of the coil closest
%      to the slot opening
%
%    thetacy - coil inner slot pitch in radians at the end of the coil closest
%      to the yoke
%
%    thetasg - angular pitch of the coil slot opening between shoes
%
%    ls - stack length (depth 'into the page' of simulation)
%
% or all the fields:
%
%    Ryo - radial distance to armature yoke outer surface
%    RyiVRyo - Ryi to Ryo
%    RtsbVRyi - Rtsb to Ryi ratio
%    RaiVRtsb - Rai to Rtsb ratio
%    RmoVRai - Rmo to Rai ratio
%    RmiVRmo - Rmi to Rmo ratio
%    RbiVRmi - Rbi to Rmi ratio
%    tsgVtsb - tsg to tsb ratio
%    thetamVthetap - thetam to thetap ratio
%    thetacgVthetas - thetacg to thetas ratio
%    thetacyVthetas - thetacy to thetas ratio
%    thetasgVthetacg - thetasg to thetacg ratio
%    lsVtm - ls to tm ratio
%
% or all the fields:
%
%    Ryo - radial distance to armature yoke outer surface
%
%    g - air gap length
%
%    ty - yoke thickness in radial direction
%
%    tm - magnet thickness in radial direction
%
%    tc - length of coil body in radial direction
%
%    tsb - slot base thickness in radial direction
%
%    tbi - thickness of the back iron in radial direction
%
%    tsg - thickness of shoe in radial direction at shoe gap
%
%    thetam - angular pitch of magnet in radians
%
%    thetacg - coil inner slot pitch in radians at the end of the coil closest
%      to the slot opening
%
%    thetacy - coil inner slot pitch in radians at the end of the coil closest
%      to the yoke
%
%    thetasg - angular pitch of the coil slot opening between shoes
%
%    ls - stack length (depth 'into the page' of simulation)
%
% This completes the specification of the physical dimentions of the
% armature and field.
%
% In addition, a winding specification must be supplied. The winding is
% described using the following variables:
%
%  yp - Average coil pitch as defined by (Qs/Poles)
%  yd - Actual coil pitch as defined by round(yp) +/- k
%  Qs  -  total number of stator slots in machine
%  Qc  -  total number of winding coils in machine
%  q  -  number of slots per pole and phase
%  qn  -  numerator of q
%  qd  -  denominator of q
%  qc - number of coils per pole and phase
%  qcn  -  numerator of qc
%  qcd  -  denominator of qc
%  Qcb - basic winding (the minimum number of coils required to make up a
%    repetitive segment of the machine that can be modelled using symmetry)
%  pb - the number of poles corresponding to the basic winding in Qcb
%
% This pole/slot/coil/winding terminology is based on that presented in
% [1].
%
% Machine windings can be single or double layered, in which case:
%
% Single layer
%   q = 2qc
%   Qs = 2Qc
% Double layer
%   q = qc
%   Qs = Qc
%
% To specify a winding, the 'minimum spec' that must be provided is based on
% a combination of some or all of the following variables:
%
%  Phases - The number of phases in the machine
%  Poles - The number of magnetic poles in the machine
%  NBasicWindings - the number of basic winding segments in the machine
%  qc - number of coils per pole and phase (as a fraction object)
%  Qc - total number of coils (in all phases) in the machine
%
% Any of the following combinations may be supplied to specify the winding:
%
%   Poles, Phases, Qc
%   Poles, Phases, qc
%   qc, Phases, NBasicWindings
%
% These variables must be provided as fields in the design structure. If
% 'qc' is supplied, it must be an object of the class 'fr'. This is a class
% designed for handling fractions. See the help for the ''fr'' class for
% further information.
%
% Example:
%
%
%
% See also: fr.m, completedesign_RADIAL.m, completedesign_ROTARY.m,
%           completedesign_AM.m
%
% [1] J. J. Germishuizen and M. J. Kamper, "Classification of symmetrical
% non-overlapping three-phase windings," in The XIX International
% Conference on Electrical Machines - ICEM 2010, 2010, pp. 1-6.
%

    if nargin < 2
        simoptions = struct ();
    end

    if nargin < 3
        setchoice = 'firstcomplete';
    end

    % perform processing common to all radial machines, primarily the
    % winding specification
    design = completedesign_RADIAL(design, simoptions);

    % calculate the various dimensions from the supplied ratios depending
    % on the specified stator type
    if strncmpi(design.ArmatureType, 'external', 1)

        design = completeexternalarmature (design, setchoice);

    elseif strncmpi(design.ArmatureType, 'internal', 1)

        design = completeinternalarmature (design, setchoice);

    else
        error('Unrecognised armature type.')
    end

    simoptions = setfieldifabsent (simoptions, 'ForceParallelSlotSides', false);

    if simoptions.ForceParallelSlotSides
        design.thetacg = design.thetacy;
        design.thetacgVthetas = design.thetacg / design.thetas;
        design.thetacyVthetas = design.thetacy / design.thetas;
    end

    % mean radial position of magnets and coils
    design.Rmm = mean([design.Rmo, design.Rmi]);
    design.Rcm = mean([design.Rci, design.Rco]);
    design.Rbm = mean([design.Rbo, design.Rbi]);
    design.Rym = mean([design.Ryi, design.Ryo]);
    design.thetac = [design.thetacg, design.thetacy];

    % get the mean air gap position
    if strcmp(design.ArmatureType, 'external')
        design.Rgm = design.Rmo + design.g/2;
    elseif strcmp(design.ArmatureType, 'internal')
        design.Rgm = design.Rmi - design.g/2;
    end

    [design.NCoilsPerPhase,~] = rat(fr(design.Qc,design.Phases));

    % slot pitch at the mean slot height
    design.tausm = design.thetas * design.Rcm;

end

function design = completeexternalarmature (design, setchoice)

    if nargin < 2
        setchoice = 'firstcomplete';
    end

    switch lower (setchoice)

        case 'ratios'

            forceratios = true;
            forcerdims = false;
            forcetdims = false;

        case 'radims'

            forceratios = false;
            forcerdims = true;
            forcetdims = false;

        case 'tdims'

            forceratios = false;
            forcerdims = false;
            forcetdims = true;

        case 'firstcomplete'

            forceratios = false;
            forcerdims = false;
            forcetdims = false;

        otherwise

            forceratios = false;
            forcerdims = false;
            forcetdims = false;

    end


    ratiofields = { 'RyiVRyo', 0, 1.0;
                    'RtsbVRyi', 0, 1.0;
                    'RaiVRtsb', 0, 1.0;
                    'RmoVRai', 0, 1.0;
                    'RmiVRmo', 0, 1.0;
                    'RbiVRmi', 0, 1.0;
                    'tsgVtsb', 0, 1.0;
                    'thetamVthetap', 0, 1.0;
                    'thetacgVthetas', 0, 1.0;
                    'thetacyVthetas', 0, 1.0;
                    'thetasgVthetacg', 0, 1.0;
                    'lsVtm', 0, inf; };

    rdimsfields = { 'Ryo';
                    'Ryi';
                    'Rtsb';
                    'Rai';
                    'Rmi';
                    'Rmo';
                    'Rbi';
                    'tsg';
                    'thetam';
                    'thetacg';
                    'thetacy';
                    'thetasg';
                    'ls'; };

    tdimsfields = { 'Ryo';
                    'g';
                    'ty';
                    'tm';
                    'tc';
                    'tsb';
                    'tbi';
                    'tsg';
                    'thetam';
                    'thetacg';
                    'thetacy';
                    'thetasg';
                    'ls'; };

    if forceratios || (all(isfield(design, ratiofields(:,1))) && ~(forcerdims || forcetdims))
        % convert the ratio set to actual dimensions
        design = structratios2structvals(design, ratiofields(1:6), 'Ryo', 'V');

        % process the angular ratios, thetas is calculated in
        % completedesign_RADIAL.m based on the number of slots
        design.thetam = design.thetamVthetap * design.thetap;
        design.thetacg = design.thetacgVthetas * design.thetas;
        design.thetacy = design.thetacyVthetas * design.thetas;
        design.thetasg = design.thetasgVthetacg * design.thetacg;

        % the shoe tip length
        design.tsb = design.Rtsb - design.Rai;
        design.tsg = design.tsgVtsb * design.tsb;

        design.Rco = design.Ryi;
        design.Rci = design.Rtsb;
        design.Rbo = design.Rmi;
        design.Rtsg = design.Rai + design.tsg;

        % calculate the lengths
        design.ty = design.Ryo - design.Ryi;
        design.tc = design.Rco - design.Rci;

        if isfield (design, 'Rcb')
            design.tc(2) = design.Rco - design.Rcb;
        end

        design.tsb = design.Rtsb - design.Rai;
        design.g = design.Rai - design.Rmo;
        design.tm = design.Rmo - design.Rmi;
        design.tbi = design.Rbo - design.Rbi;

        % finally calculate the stack length
        design.ls = design.lsVtm * design.tm;

    elseif forcerdims || (all(isfield(design, rdimsfields)) && ~(forceratios || forcetdims))
        % The dimensions are present already, specified using the
        % radial dimensions, calculate the lengths
        design.ty = design.Ryo - design.Ryi;
        design.tsb = design.Rtsb - design.Rai;
        design.g = design.Rai - design.Rmo;
        design.tm = design.Rmo - design.Rmi;
        design.tbi = design.Rmi - design.Rbi;

        design.Rco = design.Ryi;
        design.Rci = design.Rtsb;
        design.Rbo = design.Rmi;
        design.Rtsg = design.Rai + design.tsg;

        design.tc = design.Rco - design.Rci;

        if isfield (design, 'Rcb')
            design.tc(2) = design.Rco - design.Rcb;
            design.RcbVRyi = design.Rcb / design.Ryi;
        end

        % complete the ratios
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

    elseif forcetdims || (all(isfield(design, tdimsfields)) && ~(forceratios || forcerdims))

        % The dimensions are present already, specified using lengths,
        % calculate the radial dimensions
        design.Ryi = design.Ryo - design.ty;
        design.Rtsb = design.Ryi - design.tc(1);
        design.Rai = design.Rtsb - design.tsb;
        design.Rmo = design.Rai - design.g;
        design.Rmi = design.Rmo - design.tm;
        design.Rbi = design.Rmi - design.tbi;

        design.Rco = design.Ryi;
        design.Rci = design.Rtsb;

        if numel (design.tc) > 1
            design.Rcb = design.Rco - design.tc(2);
            design.RcbVRyi = design.Rcb / design.Ryi;
        end

        design.Rbo = design.Rmi;
        design.Rtsg = design.Rai + design.tsg;

        % complete the ratios
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

    else
        % something's missing
        error( 'RENEWNET:pmmachines:slottedradspec', ...
               'For a slotted radial flux design with external armature you must have the\nfields %s OR %s OR %s in the design structure.', ...
               sprintf('%s, ', ratiofields{:,1}), ...
               sprintf('%s, ', rdimsfields{:,1}), ...
               sprintf('%s, ', tdimsfields{:,1}))
    end

 %   checkdesignratios_AM (design, ratiofields, true);

end


function [design, ratiofields] = completeinternalarmature (design, setchoice)

    if nargin < 2
        setchoice = 'firstcomplete';
    end

    switch lower (setchoice)

        case 'ratios'

            forceratios = true;
            forcerdims = false;
            forcetdims = false;

        case 'radims'

            forceratios = false;
            forcerdims = true;
            forcetdims = false;

        case 'tdims'

            forceratios = false;
            forcerdims = false;
            forcetdims = true;

        case 'firstcomplete'

            forceratios = false;
            forcerdims = false;
            forcetdims = false;

        otherwise

            forceratios = false;
            forcerdims = false;
            forcetdims = false;

    end

    ratiofields = { 'RmoVRbo', 0, 1.0;
                    'RmiVRmo', 0, 1.0;
                    'RaoVRmi', 0, 1.0;
                    'RtsbVRao', 0, 1.0;
                    'RyoVRtsb', 0, 1.0;
                    'RyiVRyo', 0, 1.0;
                    'tsgVtsb', 0, 1.0;
                    'thetamVthetap', 0, 1.0;
                    'thetacgVthetas', 0, 1.0;
                    'thetacyVthetas', 0, 1.0;
                    'thetasgVthetacg', 0, 1.0;
                    'lsVtm', 0, inf };

    rdimsfields = { 'Rbo';
                    'Rmo';
                    'Rmi';
                    'Rao';
                    'Rtsb';
                    'Ryo';
                    'Ryi';
                    'tsg';
                    'thetam';
                    'thetacg';
                    'thetacy';
                    'thetasg';
                    'ls'; };

    tdimsfields = { 'Rbo';
                    'g';
                    'ty';
                    'tm';
                    'tc';
                    'tsb';
                    'tbi';
                    'tsg';
                    'thetam';
                    'thetacg';
                    'thetacy';
                    'thetasg';
                    'ls'; };

    if forceratios || (all(isfield(design, ratiofields(:,1))) && ~(forcerdims || forcetdims))
        % convert the ratio set to actual dimensions
        design = structratios2structvals(design, ratiofields(1:6), 'Rbo', 'V');

        % process the angular ratios, thetas is calculated in
        % completedesign_RADIAL.m based on the number of slots
        design.thetam = design.thetamVthetap * design.thetap;
        design.thetacg = design.thetacgVthetas * design.thetas;
        design.thetacy = design.thetacyVthetas * design.thetas;
        design.thetasg = design.thetasgVthetacg * design.thetacg;

        % the shoe tip length
        design.tsb = design.Rao - design.Rtsb;
        design.tsg = design.tsgVtsb * design.tsb;

        design.Rco = design.Rtsb;
        design.Rci = design.Ryo;
        design.Rbi = design.Rmo;
        design.Rtsg = design.Rao - design.tsg;

        % calculate the lengths
        design.ty = design.Ryo - design.Ryi;
        design.tc = design.Rco - design.Rci;

        if isfield (design, 'Rcb')
            design.tc(2) = design.Rcb - design.Ryo;
        end

        design.tsb = design.Rao - design.Rtsb;
        design.g = design.Rmi - design.Rao;
        design.tm = design.Rmo - design.Rmi;
        design.tbi = design.Rbo - design.Rbi;

        % finally calculate the stack length
        design.ls = design.lsVtm * design.tm;

    elseif forcerdims || (all(isfield(design, rdimsfields)) && ~(forceratios || forcetdims))
        % The dimensions are present already, specified using the
        % radial dimensions, calculate the lengths
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

    elseif forcetdims || (all(isfield(design, tdimsfields)) && ~(forceratios || forcetdims))
        % The dimensions are present already, specified using lengths,
        % calculate the radial dimensions
        design.Rmo = design.Rbo - design.tbi;
        design.Rmi = design.Rmo - design.tm;
        design.Rao = design.Rmi - design.g;
        design.Rtsb = design.Rao - design.tsb;
        design.Ryo = design.Rtsb - design.tc(1);
        design.Ryi = design.Ryo - design.ty;

        design.Rco = design.Rtsb;
        design.Rci = design.Ryo;
        design.Rbi = design.Rmo;
        design.Rtsg = design.Rao - design.tsg;

        if numel (design.tc) > 1
            design.Rcb = design.Ryo + design.tc(2);
            design.RcbVRtsb = design.Rcb / design.Ryo;
        end

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

    else
        % something's missing
        error( 'RENEWNET:pmmachines:slottedradspec', ...
               'For a slotted radial flux design with internal armature you must have the\nfields %s\n OR %s\n OR %s in the design structure.', ...
               sprintf('%s, ', ratiofields{:,1}), ...
               sprintf('%s, ', rdimsfields{:,1}), ...
               sprintf('%s, ', tdimsfields{:,1}));
    end

%    checkdesignratios_AM (design, ratiofields, true);

end
