function [design, simoptions] = simfun_RADIAL_SLOTTED(design, simoptions)
% generates simulation data for a radial flux slotted machine in
% preparation for a time series ode simulation
%
% Syntax
%
% [design, simoptions] = simfun_RADIAL_SLOTTED(design, simoptions)
%
% Description
%
% simfun_RADIAL_SLOTTED takes a slotted radial flux machine design,
% specified in the fields of a structure and performs a series of
% electromagnetic simulation to obtain  data on the machine performance. In
% addition, various other calculations are  performed such as estimating
% the resistance and inductance etc. The results of the calcualtions are
% added as fields to the design structure, which is returned with the
% appended fields. Also expected to be provided is a simoptions structure
% containing fields which specify various options and settings determining
% what simulation data will be gathered. More information on the simoptions
% fields is given later in this help.
%
% The design can be for either an internal or external armature. This is
% specified in the field 'ArmatureType' which must contain a string, either
% 'internal' or 'external'. Any unambiguous substring is also acceptable,
% e.g 'e' or'i', or 'ext', or 'in'.
%
% Both internal and external armature designs must have the following
% fields:
%
%    tsg - thickness of shoe in radial direction at shoe gap
%
%    thetam - angular pitch of magnet in radians
%
%    thetac - angular pitch of coil slot, this can be a single value or two
%      values. If two values, it is the pitch at the base (close to
%      armature yoke) and top (close to slot opening) of the slot
%      respectively. If this is a single value, the same pitch is used for
%      both the base and the top.
%
%    thetasg - angular pitch of the coil slot opening between shoes.
%
%    ls - stack length (depth 'into the page' of simulation)
%
% In general, all dimensions which refer to a radial measurement from the
% center of the machine are prefixed with the capital letter 'R'.
%
% For an INTERNAL ARMATURE machine, the design structure must also contain
% all the fields:
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
%
% For an EXTERNAL ARMATURE machine, the design structure must also contain the
% fields:
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
%
% This completes the specification of the physical dimentions of the
% armature and field. Alternative methods of specifying the dimensions
% (such as as a set of dimensionless ratios) are possible which can be
% easily converted to this form using the helper function
% completedesign_RADIAL_SLOTTED.m. See the help for
% completedesign_RADIAL_SLOTTED for more details.
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
%  CoilLayers - number of layers in the winding
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
% a combination of some or all of the following fields:
%
%  Phases - The number of phases in the machine
%  Poles - The number of magnetic poles in the machine
%  NBasicWindings - the number of basic winding segments in the machine
%  qc - number of coils per pole and phase (as a fraction object)
%  Qc - total number of coils (in all phases) in the machine
%  CoilLayers - the number of layers in the coil, either 1 or 2
%
% Any of the following combinations may be supplied to specify the winding:
%
%   Poles, Phases, Qc, CoilLayers
%   Poles, Phases, qc, CoilLayers
%   qc, Phases, NBasicWindings, CoilLayers
%
% These variables must be provided as fields in the design structure. If
% 'qc' is supplied, it must be an object of the class 'fr'. This is a class
% designed for handling fractions. See the help for the ''fr'' class for
% further information.
%
% In addition some further design option fields may be specified if desired:
%
%   MagnetSkew - skew in the rotor or stator specified as a fraction of a
%     pole width
%
%   NStrands - number of parallel strands each coil turn is made up of,
%     default is 1
%
%   WireResistivityBase - base or reference resistivity of the coil
%     material at the base temperature specified in the TemperatureBase
%     field
%
%   TemperatureBase - base or reference temperature atwhich the coil
%     material has the resistivity in the field WireResistivityBase
%
%   AlphaResistivity - resistivity temperature coefficient such that the
%     actual resistivity may be calculated from
%
%     rho = WireResistivityBase * (1 + AlphaResistivity * (T - TemperatureBase))
%
%     where T is the temperature. The temperature used in the simulation is
%     specified in the simoptions struture.
%
%   FEMMTol - tolerance used in FEA drawings to determine if components are
%    separate. Defaults to 1e-5 if not supplied.
%
%
% SIMOPTIONS
%
% Also expected to be provided is a structure containing various simulation
% options.
%
%  GetVariableGapForce - optional flag determining if a series of force
%   simulations with various air gap sizes will be performed. Must be supplied.
%
%  NForcePoints - optional number of gap sizes to use if GetVariableGapForce is
%   true. Defaults to 4 if not supplied. The force positions will be linearly
%   spaced from zero air gap (plus a small toperance value) to twice the air gap
%   length.
%
%  MagFEASim - structure containing options specific to the magnetics
%    finitie element analysis. The possible fields of this structure are
%    shown below:
%
%    MagnetRegionMeshSize : optional mesh size in the magnet regions
%
%    BackIronRegionMeshSize : optional mesh size in the rotor back iron
%
%    AirGapMeshSize : optional mesh size in the air gap
%
%    StatorOuterRegionsMeshSize :
%
%    RotorOuterRegionsMeshSize :
%
%    YokeRegionMeshSize : optional mesh size in the armature back iron (the
%      yoke)
%
%    CoilRegionMeshSize : optional mesh size in the coil regions
%
%    ShoeGapRegionMeshSize : optional mesh size ing the gap between tooth
%      shoes
%
%    UseParFor : determines whether parfor will be used to split
%      computation of the fea over multiple processors. Default is false if
%      not supplied.
%
%    UseFemm : optional flag to allow forcing the use of FEMM for Magnetics
%      FEA simulation rather than mfemm. If true FEMM will be used,
%      otherwise, mfemm will be used if it is available. Defaults to false
%      if not supplied.
%
%    QuietFemm : optional flag determining if output to the command line
%      from mfemm should be suppressed. Defaults to true if not supplied.
%
%
%  SkipMainFEA - optional flag which allows skipping the main fea simulations.
%   This can be desirable when only coil winding configurations change etc.
%   Defaults to false if not supplied.
%
%  SkipInductanceFEA - optional flag which allows skipping the inductance fea
%   simulations. This can be desirable when only coil winding configurations
%   change etc. Defaults to false if not supplied.
%
%
%
% [1] J. J. Germishuizen and M. J. Kamper, "Classification of symmetrical
% non-overlapping three-phase windings," in The XIX International
% Conference on Electrical Machines - ICEM 2010, 2010, pp. 1-6.
%
%
% See also: completedesign_RADIAL_SLOTTED.m, simfun_RADIAL.m, simfun_ROTARY.m
%           simfun_AM.m, fr.m
%
%

    if nargin == 0
        % return the internal subfunctions
        design = [feasim_RADIAL_SLOTTED(), {@coilresistance}];
        return;
    end

    if design.ypd ~= 1 && design.ypd ~= 2
    	error('denominator of slots per pole must be 1 or 2, other values not yet supported')
    end

    simoptions = setfieldifabsent (simoptions, 'DoBackIronCoreLoss', false);
    if ~isfield(simoptions, 'MagFEASim')
        simoptions.MagFEASim = struct();
    end
    if ~isfield(simoptions.MagFEASim, 'RotationMethod')
        if simoptions.MagFEASim.SolveMethod == 'femmsession'
            simoptions.MagFEASim.RotationMethod = 'SlidingMesh';
        else
            simoptions.MagFEASim.RotationMethod = 'MagnetRedraw';
        end
    end

    if ~isfield(design, 'CoreLoss')
        % CoreLoss will be the armature back iron data
        [ design.CoreLoss.kh, ...
          design.CoreLoss.kc, ...
          design.CoreLoss.ke, ...
          design.CoreLoss.beta ] = corelosscoeffs ('M-36', '26', 'InterpolateMissing', false);

        if simoptions.DoBackIronCoreLoss
            % CoreLoss will be the armature back iron data
            design.CoreLoss(end+1).kh = mean ([7.54, 22.61] * 1e2);
            design.CoreLoss(end+1).kc = design.CoreLoss.kc;
            design.CoreLoss(end+1).ke = 0;
            design.CoreLoss(end+1).beta = 2;
        end
    end

    % We don't check the coil turns etc at this stage (done by default in
    % simfun_RADIAL) as we don't yet know the coil cross-sectional area, this is
    % done later below
    simoptions.SkipCheckCoilProps = true;
    rmcoilturns = false;
    if ~isfield (design, 'CoilTurns')
        % set the coil turns to 1 temporarily to keep the drawing functions
        % happy
        design.CoilTurns = 1;
        rmcoilturns = true;
    end

    % call the common radial simulation function
    [design, simoptions] = simfun_RADIAL (design, simoptions);

    if design.tsg > 1e-5
        if design.tsb > 1e-5
            simoptions.MagFEASim = ...
                setfieldifabsent (simoptions.MagFEASim, ...
                                  'ShoeGapRegionMeshSize', ...
                                  choosemesharea_mfemm(max(design.tsg, design.tsb), (design.Rmo*design.thetasg), 1/20) );
        else
            simoptions.MagFEASim = ...
                setfieldifabsent (simoptions.MagFEASim, ...
                                  'ShoeGapRegionMeshSize', ...
                                  choosemesharea_mfemm(design.tsb, (design.Rmo*design.thetasg), 1/20));
        end
    else
        if design.tsb > 1e-5
            simoptions.MagFEASim = ...
                setfieldifabsent (simoptions.MagFEASim, ...
                                  'ShoeGapRegionMeshSize', ...
                                  choosemesharea_mfemm(design.tsb, (design.Rmo*design.thetasg), 1/20));
        else
            simoptions.MagFEASim = ...
                setfieldifabsent (simoptions.MagFEASim, ...
                                  'ShoeGapRegionMeshSize', -1);
        end
    end

    % now get the flux linkage in the coils, we will do this by getting the
    % integral of the vector potential in a slot at a range of rotor
    % positions

    % choose an appropriate number of pole pairs for the simulation based
    % on the basic winding
    NPolePairs = max(1, ceil (design.pb/2));

    if ~simoptions.SkipMainFEA

        simoptions = setfieldifabsent (simoptions, 'NMagFEAPositions', 10);

    %     design.FirstSlotCenter = design.thetap + (design.thetap / slotsperpole / 2);
        design.FirstSlotCenter = 0;
        feapos = linspace (0, 1, simoptions.NMagFEAPositions);
        design.MagFEASimPositions = feapos;
        % determine a unit vector pointing in the direction tangential to the
        % radius half way between the Poles for the purpose of extracting
        % the cogging forces
        %
        % The dot product of orthogonal vectors is zero. In two dimensions the
        % slopes of perpendicular lines are negative reciprocals. Switch the x
        % and y coefficients and change the sign of one of them.
        %
        % For vector V1 = <a, b>, the reciprocal V2 = <b, -a>. Now make it a
        % unit vector by dividing by the magnitude.
%         coggingvector = unit([gvector(2), -gvector(1)]);

        femfilename = [tempname(), '_simfun_RADIAL_SLOTTED.fem'];

        fprintf (1, 'Performing FEA simulation %d of %d\n', 1, simoptions.NMagFEAPositions);


        [ RawCoggingTorque, ...
          BxCoreLossData, ...
          ByCoreLossData, ...
          ArmatureToothFluxDensity, ...
          FemmDirectFluxLinkage, ...
          AslotPos, ...
          slotIntA, ...
          BslotPos, ...
          slotIntB, ...
          design, ...
          session ] = feasim_RADIAL_SLOTTED (design, simoptions, design.thetap * feapos(1), ...
                                            'IsInitialisation', true, ...
                                            'NPolePairs', NPolePairs, ...
                                            'RotationMethod', simoptions.MagFEASim.RotationMethod, ...
                                            'FemFileName', femfilename, ...
                                            'SolveMethod', simoptions.MagFEASim.SolveMethod);

        parameterCell{1} = { RawCoggingTorque, ...
                             BxCoreLossData, ...
                             ByCoreLossData, ...
                             ArmatureToothFluxDensity, ...
                             FemmDirectFluxLinkage, ...
                             AslotPos, slotIntA, ...
                             BslotPos, slotIntB };

        reuseFemmSession = strcmpi (simoptions.MagFEASim.SolveMethod, 'femmsession') ...
                           && strcmpi (simoptions.MagFEASim.RotationMethod, 'SlidingMesh');
        if ~reuseFemmSession && isa (session, 'xfemm.femmsession')
            delete (session);
            session = [];
        end

        simoptions.MagFEASim = setfieldifabsent ( simoptions.MagFEASim, 'UseParFor', false);

        if simoptions.MagFEASim.UseParFor

            parfor posind = 2:numel (feapos)

                fprintf (1, 'Performing FEA simulation %d of %d\n', posind, simoptions.NMagFEAPositions);

                [ RawCoggingTorque, ...
                  BxCoreLossData, ...
                  ByCoreLossData, ...
                  ArmatureToothFluxDensity, ...
                  FemmDirectFluxLinkage, ...
                  AslotPos, ...
                  slotIntA, ...
                  BslotPos, ...
                  slotIntB ] = feasim_RADIAL_SLOTTED (design, simoptions, design.thetap * feapos(posind), ...
                                                        'IsInitialisation', false, ...
                                                        'NPolePairs', NPolePairs, ...
                                                        'RotationMethod', simoptions.MagFEASim.RotationMethod, ...
                                                        'SolveMethod', simoptions.MagFEASim.SolveMethod);

                parameterCell{posind} = { RawCoggingTorque, ...
                                          BxCoreLossData, ...
                                          ByCoreLossData, ...
                                          ArmatureToothFluxDensity, ...
                                          FemmDirectFluxLinkage, ...
                                          AslotPos, slotIntA, ...
                                          BslotPos, slotIntB };

            end

        else

            for posind = 2:numel (feapos)

                fprintf (1, 'Performing FEA simulation %d of %d\n', posind, simoptions.NMagFEAPositions);

                femmSessionArgs = {};
                if reuseFemmSession
                    femmSessionArgs = {'FemmSession', session};
                end

                [ RawCoggingTorque, ...
                  BxCoreLossData, ...
                  ByCoreLossData, ...
                  ArmatureToothFluxDensity, ...
                  FemmDirectFluxLinkage, ...
                  AslotPos, ...
                  slotIntA, ...
                  BslotPos, ...
                  slotIntB, ...
                  ~, ...
                  session ] = feasim_RADIAL_SLOTTED (design, simoptions, design.thetap * feapos(posind), ...
                                                        'IsInitialisation', false, ...
                                                        'NPolePairs', NPolePairs, ...
                                                        'RotationMethod', simoptions.MagFEASim.RotationMethod, ...
                                                        'FemFileName', femfilename, ...
                                                        'SolveMethod', simoptions.MagFEASim.SolveMethod, ...
                                                        femmSessionArgs{:});

                parameterCell{posind} = { RawCoggingTorque, ...
                                          BxCoreLossData, ...
                                          ByCoreLossData, ...
                                          ArmatureToothFluxDensity, ...
                                          FemmDirectFluxLinkage, ...
                                          AslotPos, slotIntA, ...
                                          BslotPos, slotIntB };

                if ~reuseFemmSession && isa (session, 'xfemm.femmsession')
                    delete (session);
                    session = [];
                end

            end

        end

        % consolidate the gathered data in the design structure
        design = assimilate_fea_data (design, simoptions, parameterCell);

        % we divide the flux linkage extracted from femm by the number of
        % turns in the simulation, to get the per-turn flux linkage, as
        % later we update the coil properties which could result in a
        % different number of turns, and then multiply by the updated
        % number number of turns
        design.FemmDirectFluxLinkage = design.FemmDirectFluxLinkage / design.CoilTurns;

    end % ~SkipMainFEA


    if simoptions.GetVariableGapForce

        if ~isfield (simoptions, 'VariableGapForcePositions')

            % get more force points if requested
            pos = linspace (0, 0.9*design.g, simoptions.NForcePoints-1);
            pos(end+1) = 0.95*design.g;

            simoptions.VariableGapForcePositions = pos;

        end

        assert ( isnumeric (simoptions.VariableGapForcePositions) ...
                 && isvector (simoptions.VariableGapForcePositions), ...
                 'VariableGapForcePositions must be a numeric vector' );

        simoptions = setfieldifabsent (simoptions, 'VariableGapForceDeleteFEMFiles', true);
        simoptions = setfieldifabsent (simoptions, 'VariableGapForceDeleteANSFiles', true);

        tmpforce = closingforce_RADIAL_SLOTTED( design, ...
                                                simoptions.VariableGapForcePositions, ...
                                                'UseFemm', simoptions.MagFEASim.UseFemm, ...
                                                'Verbose', ~simoptions.MagFEASim.QuietFemm, ...
                                                'DeleteFEMFiles', simoptions.VariableGapForceDeleteFEMFiles, ...
                                                'DeleteANSFiles', simoptions.VariableGapForceDeleteANSFiles );

        design.ForceGapClosingWithDisp = [0, tmpforce];

        design.DispGapClosingForce = [0, simoptions.VariableGapForcePositions];

    end


    % make sure the winding properties (number of turns etc.) are up to date
    if rmcoilturns
        design = rmfield (design, 'CoilTurns');
    end
    design = checkcoilprops_AM (design);
    design.FemmDirectFluxLinkage = design.FemmDirectFluxLinkage * design.CoilTurns;

    if ~simoptions.SkipInductanceFEA

        fprintf (1, 'Performing FEA simulation to determine inductance\n');

        % perform an inductance sim to get the d axis inductance
        Lcurrent = inductancesimcurrent (design.CoilArea, design.CoilTurns);
        [design.InductanceFemmProblem, ~] = slottedLfemmprob_radial (design, ...
            'FractionalPolePosition', -0.5 + (design.yd/2 * 1/design.qsp), ... + (1/design.qsp)/2, ...
            'NWindingLayers', design.CoilLayers, ...
            'CoilCurrent', [Lcurrent, 0, 0], ...
            'MagnetRegionMeshSize', simoptions.MagFEASim.MagnetRegionMeshSize, ...
            'BackIronRegionMeshSize', simoptions.MagFEASim.BackIronRegionMeshSize, ...
            'RotorOuterRegionsMeshSize', simoptions.MagFEASim.OuterRegionsMeshSize, ...
            'StatorOuterRegionsMeshSize', simoptions.MagFEASim.OuterRegionsMeshSize, ...
            'AirGapMeshSize', simoptions.MagFEASim.AirGapMeshSize, ...
            'ShoeGapRegionMeshSize', simoptions.MagFEASim.ShoeGapRegionMeshSize, ...
            'YokeRegionMeshSize', simoptions.MagFEASim.YokeRegionMeshSize, ...
            'CoilRegionMeshSize', simoptions.MagFEASim.CoilRegionMeshSize);

        % analyse the problem
        [ansfilename, femfilename] = analyse_mfemm ( design.InductanceFemmProblem, ...
                                                     simoptions.MagFEASim.UseFemm, ...
                                                     simoptions.MagFEASim.QuietFemm );

        solution = fpproc (ansfilename);
        [design.CoilResistance, design.CoilInductance] = solution.circuitRL ('1');
        % get the mutual inductance by dividing the flux in a neighbouring
        % phase by the applied current in the first phase
        temp = solution.getcircuitprops ('2');
        % explicitly call the delete method on the solution
        delete (solution);
        clear solution;

        design.CoilInductance(2) = abs (temp(3)) / Lcurrent;

        % clean up the FEA files
        delete (femfilename);
        delete (ansfilename);

        % get the q axis inductance
        [design.QAxisInductanceFemmProblem, ~] = slottedLfemmprob_radial (design, ...
            'FractionalPolePosition', -0.25 + (design.yd/2 * 1/design.qsp), ...
            'NWindingLayers', design.CoilLayers, ...
            'CoilCurrent', [Lcurrent, 0, 0], ...
            'MagnetRegionMeshSize', simoptions.MagFEASim.MagnetRegionMeshSize, ...
            'BackIronRegionMeshSize', simoptions.MagFEASim.BackIronRegionMeshSize, ...
            'RotorOuterRegionsMeshSize', simoptions.MagFEASim.OuterRegionsMeshSize, ...
            'StatorOuterRegionsMeshSize', simoptions.MagFEASim.OuterRegionsMeshSize, ...
            'AirGapMeshSize', simoptions.MagFEASim.AirGapMeshSize, ...
            'ShoeGapRegionMeshSize', simoptions.MagFEASim.ShoeGapRegionMeshSize, ...
            'YokeRegionMeshSize', simoptions.MagFEASim.YokeRegionMeshSize, ...
            'CoilRegionMeshSize', simoptions.MagFEASim.CoilRegionMeshSize);

        % analyse the problem
        [ansfilename, femfilename] = analyse_mfemm ( design.QAxisInductanceFemmProblem, ...
                                                     simoptions.MagFEASim.UseFemm, ...
                                                     simoptions.MagFEASim.QuietFemm );

        solution = fpproc (ansfilename);
        [~, design.QAxisCoilInductance] = solution.circuitRL ('1');
        % get the mutual inductance by dividing the flux in a neighbouring
        % phase by the applied current in the first phase
        temp = solution.getcircuitprops ('2');
        % explicitly call the delete method on the solution
        delete (solution);
        clear solution;

        design.QAxisCoilInductance(2) = abs (temp(3)) / Lcurrent;

        % clean up the FEA files
        delete (femfilename);
        delete (ansfilename);

    end % ~simoptions.SkipInductanceFEA

    % calculate coil mean turn lenth and resistance unless this is
    % overridden by settings in the simoptions structure
    if isfield (simoptions, 'set_MTL')
        design.MTL = simoptions.set_MTL;
    end

    % now recalculate coil resistance
    if isfield (simoptions, 'set_CoilResistance')
        design.CoilResistance = simoptions.set_CoilResistance;
    else
        design = coilresistance_RADIAL_SLOTTED (design);
    end

end

function design = assimilate_fea_data (design, simoptions, parameterCell)

    ind_RawCoggingTorque = 1;
    ind_BxCoreLossData = 2;
    ind_ByCoreLossData = 3;
    ind_ArmatureToothFluxDensity = 4;
    ind_FemmDirectFluxLinkage = 5;
    ind_intA_slotPos = 6;
    ind_intA_IntAData = 7;
    ind_intB_slotPos = 8;
    ind_intB_IntBData= 9;

    design.intAdata.slotPos = [];
    design.intAdata.slotIntA = [];
    design.intBdata.slotPos = [];
    design.intBdata.slotIntB = [];
    design = setfieldifabsent (design, 'FemmDirectFluxLinkage', []);

    for ind = 1:numel (parameterCell)

        design.intAdata.slotPos = [design.intAdata.slotPos; parameterCell{ind}{ind_intA_slotPos}];
        design.intAdata.slotIntA = [design.intAdata.slotIntA; parameterCell{ind}{ind_intA_IntAData}];
        design.intBdata.slotPos = [design.intBdata.slotPos; parameterCell{ind}{ind_intB_slotPos}];
        design.intBdata.slotIntB = [design.intBdata.slotIntB; parameterCell{ind}{ind_intB_IntBData}];
        design.RawCoggingTorque(ind) = parameterCell{ind}{ind_RawCoggingTorque};
        design.ArmatureToothFluxDensity(ind) = parameterCell{ind}{ind_ArmatureToothFluxDensity};
        design.FemmDirectFluxLinkage(ind,:) = parameterCell{ind}{ind_FemmDirectFluxLinkage};

        for ii = 1:numel(design.CoreLoss)

            design.CoreLoss(ii).By(:,ind,:) = parameterCell{ind}{ind_ByCoreLossData}{ii};

            design.CoreLoss(ii).Bx(:,ind,:) = parameterCell{ind}{ind_BxCoreLossData}{ii};

        end

    end

    % sort the B integral data in ascending position order
    [design.intBdata.slotPos, idx] = sort (design.intBdata.slotPos);
    design.intBdata.slotIntB = design.intBdata.slotIntB(idx,:,:);

    [design.intAdata.slotPos, idx] = sort (design.intAdata.slotPos);
    design.intAdata.slotIntA = design.intAdata.slotIntA(idx,:,:);

end
