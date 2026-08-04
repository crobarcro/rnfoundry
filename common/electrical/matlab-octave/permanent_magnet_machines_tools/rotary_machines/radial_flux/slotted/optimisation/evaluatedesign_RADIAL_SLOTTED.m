function [score, design, simoptions, T, Y, results] = evaluatedesign_RADIAL_SLOTTED(design, simoptions)
% evaluates a slotted radial flux pm machine design and assigns it a score
%
% Syntax
%
% [score, design, simoptions, T, Y, results] = evaluatedesign_RADIAL_SLOTTED(design, simoptions)
%
% Description
%
% evaluatedesign_RADIAL_SLOTTED simulates a slotted radial flux permanent
% magnet machine according to the specified simulation parameters, and
% evaluates the design according to supplied scoring criteria and data.
%
% Input
%
%  design - a structure containing the parameters of the machine or system
%   to be evaluated. The specific fields of this structure depend on the
%   system.
%
%  simoptions - structure used to control how the system is evaluated. It
%  can contain the following fields:
%
%   Evaluation -
%
%   ForceFullSim : true/false flag indicating whether to perform design
%    screening or not. If true, no screening function is run on the
%    design, and evaluation proceeds direclty to the full simulation as
%    specified in the simoptions structure. If false, a screening function
%    is first applied which does a more basic analysis to determine
%    whether to proceed to a full simulation. If not present, default is
%    false, screening is performed.
%
%   DStructEval : true/false flag indicating whether to run the evaluation
%    function which (if present) is found in
%    simoptions.Evaluation.structevalfcn
%
%   ODESim : a substructure controlling the time series ODE simulation of
%    the design which can contain the following fields:
%
%    PreProcFcn : optional function handle or string containing the function
%     which will be run to generate data prior to running the simulation.
%     simfun will be passed the design and simoptions structure, and can
%     also be supplied with additional arguments by using the
%     'ExtraPreProcFcnArgs' parameter-value pair. The extra arguments must be
%     placed in a cell array. It must return two arguments which will
%     overwrite the design and simoptions variables.
%
%     The supplied function must have the calling syntax
%
%     [design, simoptions] = thefunction(design, simoptions, simfunarg1, simfunarg2, ...)
%
%     Where simfunarg1, simfunarg2, ... if supplied are the elements of the
%     a cell array, passed in using the Parameter-value pair
%     ExtraPreProcFcnArgs, e.g.
%
%     simulatemachine_AM(design, simoptions, 'ExtraPreProcFcnArgs', {1, 'another', [1,2;3,4]})
%
%    PostPreProcFcn : optional function handle or string containing a
%     function which will be run after simfun. finfun will also be passed
%     the design and simoptions structure, and can also be supplied with
%     additional arguments by using the 'ExtraPostPreProcFcnArgs'
%     parameter-value pair. The extra arguments must be placed in a cell
%     array. It must return two arguments which will overwrite the design
%     and simoptions variables.
%
%     The supplied function must have the calling syntax
%
%     [design, simoptions] = thefunction(design, simoptions, finfunarg1, finfunarg2, ...)
%
%     Where finfunarg1, finfunarg2, ... if supplied are the elements of the
%     a cell array, passed in using the Parameter-value pair
%     ExtraPostPreProcFcnArgs, e.g.
%
%     simulatemachine_AM(design, simoptions, 'ExtraPostPreProcFcnArgs', {1, 'another', [1,2;3,4]})
%
%    EvalFcn : function handle or string containing the function which will
%     be evaluated by the ode solver routines to solve the system of
%     equations. see the ode solvers (e.g. ode45, ode15s) for further
%     information on how to create a suitible function.
%
%    SolutionComponents : Structure containing information on the various
%     components of the system to be solved. This structure will contain
%     fields with names corresponding to the solution components. Each of
%     these fields is then also a structure with information about each of
%     these solution components. The information is contained in the
%     following fields:
%
%     SolutionIndices : these are the indices of the ode system
%       coresponding to this component.
%
%     InitialConditions : this is the initial conditions for variables
%       associated with this component.
%
%     AbsTol : the absolute tolerances of the variables associated with
%       this  component. If AbsTol is not supplied for every solution
%       component it will be ignored for all components.
%
%     The initial conditions for the ODE solution and possibly the absolute
%     tolerances on all variables are assembled from the information in
%     this structure.
%
%     In addition, the field OutputFcn may be present. This contains a
%     function handle or string representing a function to be run on the
%     variables associated with the solution component after each
%     successful time step.
%
%     SolutionComponents can also contain a field named 'NestedSim' for the
%     purposes of setting up a multi-rate solution. If present, it contains
%     solution component information intended for a nested, higher time
%     step rate simulation (implemented using the ode.odesolver class),
%     running between the steps of the 'outer' or top level simulation. The
%     NestedSim sturcture is the same format as the top level
%     SolutionComponents structure and contains the solution component
%     information for the variables in the lower level simulation. The
%     NestedSim structure can also contain another NestedSim structure and
%     any number of levels are supported.
%
%    PostAssemblyFcn : function handle or string containing a function which
%     will be run after the solution components have been read and fully
%     assembled.
%
%    PostSimFcn : function handle or string containing a function which will
%     be run after the simulation has been completed by the ode solver.
%     resfun must take the T and Y matrices, as generated by the ode
%     solver, and the design and simoptions arguments in that order.
%     PostSimFcn can also be supplied with additional arguments by using
%     the 'ExtraPostSimFcnArgs' parameter-value pair. The extra arguments
%     must be placed in a cell array. It must return two arguments, one of
%     which is a results variable containing results of interest to the
%     user, the other of which overwrites the design variable.
%
%     The supplied function must have the calling syntax
%
%     [results, design] = htefunction(T, Y, design, simoptions, odearg1, odearg2, ..., resfunarg1, resfunarg1, ...);
%
%     Where odearg1, odearg2, ..., resfunarg1, resfunarg1, ... if supplied are the elements of the
%     two cell arrays, passed in using the Parameter-value pairs
%     ExtraEvalFcnArgs and ExtraPostSimFcnArgs respectively, e.g.
%
%     simulatemachine_AM ( design, simoptions, ...
%                          'ExtraEvalFcnArgs', {1, true}, ...
%                          'ExtraPostSimFcnArgs', {2, false} )
%
%    Solver : function handle or string specifying the ode solver to use,
%     if not supplied, for Matlab the default is 'ode15s', and for Octave
%     'ode2r'.
%
%    Split : (scalar integer) if this field is present in the structure
%     it indicates that the evaluation of the system of differential
%     equations should be split into manageable chunks, useful for
%     long-running simulations which use substantial memory. The value of
%     ODESim.Split is the desired initial number of chunks into which
%     evaluation will be split. If the system runs out of memory during
%     simulation, the number of blocks will be increased and simulation
%     reattempted this will be attempted at most 4 times. If ODESim.Split
%     is present, the field SplitPointFcn must also be supplied, documented
%     below.
%
%    SplitPointFcn : (string|function handle) if ODESim.Split is provided
%     this field must also be present which should contain a string or
%     function handle. This function will be called at each break in the
%     integration and must have the following syntax:
%
%     results = spfcn (flag, results, sol, design, simoptions)
%
%     For further information on creating a split point function, see the
%     help for 'odesplit.m'.
%
%    OutputFcn : Top level OutputFcn to be run after each successful time
%     step. If not supplied, the function odesimoutputfcns_AM is used. This
%     function looks for a SolutionComponents structure in
%     simoptions.ODESim and runs the output function (if present) for each
%     solution component with the appropriate inputs.
%
%    Events : Event function to run after every time step to determine if a
%     termination event has occured. See the help for the ode solvers (e.g.
%     ode45) to learn more about the event function.
%
%    Vectorized : true/false flag indicating if the ODE solution function is
%     vectorized
%
%    MaxStep : The maximum allowed time step size
%
%    InitialStep : A suggested initial time step size for the ode solution
%
%
% Output
%
%  score - scalar numeric value containing the score assigned to the design
%   determined according the supplied criteria and scoring functions in
%   simoptions.
%
%  design - the input design structure returned with any modifications made
%   by the performed simulations. The design structure will generally have
%   a number of fields added, containing the main results from the
%   evaluation.
%
%  simoptions - the input design structure returned with any modifications made
%   by the performed simulations. The modification can include the addition
%   of fields containing default options used which were not provided by
%   the user. The exact fields added are simulaiton dependant.
%
%  T - output time vector as produced by ode solver functions, e.g. ode45
%
%  Y - output solution vector as produced by ode solver functions, e.g.
%   ode45
%
%  results - the results as produced by the supplied function in
%   ODESim.PostSimFcn. Typically a structure containig fields which are the
%   outputs of various quantities at each time step in the simulation.
%
% See also: simulatemachine_AM
%

    simoptions = setfieldifabsent (simoptions, 'Evaluation', []);

    simoptions.Evaluation = designandevaloptions_RADIAL_SLOTTED(simoptions.Evaluation);

    % pre-screen the design to see if a full simulation is worth it
    [sdesign, ssimoptions] = screendesign_RADIAL_SLOTTED(design, simoptions);

    simoptions = setfieldifabsent(simoptions, 'ForceFullSim', false);
    simoptions = setfieldifabsent(simoptions, 'DoStructEval', false);

    check.isLogicalScalar (simoptions.ForceFullSim, true, 'ForceFullSim');
    check.isLogicalScalar (simoptions.DoStructEval, true, 'DoStructEval');

    % prefer to screen for desired EMF range, terminal voltage seems to be
    % more challenging for the GA to handle
    if isfield (ssimoptions, 'max_EMFPhaseRms')
        max_Voltage_check_value = ssimoptions.max_EMFPhaseRms;
    elseif isfield (ssimoptions, 'max_VoltageGenTerminalPhaseRms')
        max_Voltage_check_value = ssimoptions.max_VoltageGenTerminalPhaseRms;
    end

    if isfield (ssimoptions, 'min_EMFPhaseRms')
        min_Voltage_check_value = ssimoptions.min_EMFPhaseRms;
    elseif isfield (ssimoptions, 'min_VoltageGenTerminalPhaseRms')
        min_Voltage_check_value = ssimoptions.min_VoltageGenTerminalPhaseRms;
    end

    if ~simoptions.ForceFullSim && ...
         ( ...
            (sdesign.EMFPhaseRms > 2*max_Voltage_check_value) ...
            || (sdesign.EMFPhaseRms < 0.25*min_Voltage_check_value) ...
            || (sdesign.PowerLoadMean > 2*ssimoptions.max_PowerLoadMean) ...
            || (sdesign.PowerLoadMean < 0.5*ssimoptions.min_PowerLoadMean) ...
         )

        T = [];
        Y = [];
        results = [];

        % estimate the masses of the components
        sdesign = materialmasses_RADIAL_SLOTTED(sdesign, ssimoptions);

        % generate a score for the machine
        [prescore, sdesign, ssimoptions] = machinescore_RADIAL_SLOTTED(sdesign, ssimoptions);

        % make the score bigger to encourage getting into the full test zone
        score = prescore * 3;
        design = sdesign;
        simoptions = ssimoptions;

    else
        % run the simulations and return the results using the generic
        % radial flux evaluation function
        [design, simoptions, T, Y, results] = evaluatedesign_RADIAL(design, simoptions);

        if simoptions.DoStructEval
            % evaluate the design structurally
            [design, simoptions] = feval(simoptions.Evaluation.structevalfcn, design, simoptions);
        end

        % estimate the masses of the components
        design = materialmasses_RADIAL_SLOTTED(design, simoptions);

        % generate a score for the machine
        [score, design, simoptions] = machinescore_RADIAL_SLOTTED(design, simoptions);
    end

end


function [sdesign, ssimoptions] = screendesign_RADIAL_SLOTTED(design, simoptions)
% pre-screens a design to assess if whether to perform full assessment

    sdesign = design;
    ssimoptions = simoptions;

    if ~isfield(sdesign, 'CoreLoss')
        % CoreLoss will be the armature back iron data
        [sdesign.CoreLoss.fq, ...
         sdesign.CoreLoss.Bq, ...
         sdesign.CoreLoss.Pq ] = m36assheared26gagecorelossdata(false);

        sdesign.CoreLoss(2) = sdesign.CoreLoss(1);
    end

    % do some common design processing things, but skipping calculations of
    % coil properties
    ssimoptions.SkipCheckCoilProps = true;
    [sdesign, ssimoptions] = simfun_RADIAL(sdesign, ssimoptions);

    % we are going to perform a single FEA simulation of the design to
    % extract some basic info about it to make a simple evaluation of the
    % performance
    ssimoptions.MagFEASim = setfieldifabsent(ssimoptions.MagFEASim, 'ShoeGapRegionMeshSize', -1);
    ssimoptions.MagFEASim = setfieldifabsent(ssimoptions.MagFEASim, 'YokeRegionMeshSize', -1);
    ssimoptions.MagFEASim = setfieldifabsent(ssimoptions.MagFEASim, 'CoilRegionMeshSize', -1);

    rmcoilturns = false;
    if ~isfield(sdesign, 'CoilTurns')
        sdesign.CoilTurns = 1;
        rmcoilturns = true;
    end

    % Draw the sim at position 0
    firstslotcentre = design.thetas / 2;
    if sdesign.yd == 1
        coilspan = design.thetas;
    else
        coilspan = (design.yd-1) * design.thetas;
    end
    pos = (-design.thetap/2) + firstslotcentre + (coilspan / 2);

    if sdesign.pb == 1
        simpolepairs = 1;
    else
        simpolepairs = sdesign.pb/2;
    end

    if ~iseven (sdesign.pb) && (sdesign.pb*2 <= sdesign.Poles)
        % double the number of poes in the simulation
        simpolepairs = sdesign.pb;
    end

    % make sure there's at least 6 slots in the simulation. If not, as long
    % as there are enough slots in the whole machine to simulate another
    % pole pair, simulate another basic winding unit
    if ( ( (simpolepairs*2/sdesign.pb) * sdesign.Qsb ) < 6 ) ...
            && (simpolepairs*2 <= sdesign.Poles)

        simpolepairs = simpolepairs * 2;

    end

    [sdesign.FemmProblem, sdesign.RotorDrawingInfo, sdesign.StatorDrawingInfo] = ...
                        slottedfemmprob_radial (sdesign, ...
                            'NPolePairs', simpolepairs, ...
                            'NWindingLayers', sdesign.CoilLayers, ...
                            'Position', pos, ...
                            'MagnetRegionMeshSize', ssimoptions.MagFEASim.MagnetRegionMeshSize, ...
                            'BackIronRegionMeshSize', ssimoptions.MagFEASim.BackIronRegionMeshSize, ...
                            'RotorOuterRegionsMeshSize', ssimoptions.MagFEASim.OuterRegionsMeshSize, ...
                            'StatorOuterRegionsMeshSize', ssimoptions.MagFEASim.OuterRegionsMeshSize, ...
                            'AirGapMeshSize', ssimoptions.MagFEASim.AirGapMeshSize, ...
                            'ShoeGapRegionMeshSize', ssimoptions.MagFEASim.ShoeGapRegionMeshSize, ...
                            'YokeRegionMeshSize', ssimoptions.MagFEASim.YokeRegionMeshSize, ...
                            'CoilRegionMeshSize', ssimoptions.MagFEASim.CoilRegionMeshSize);

    if rmcoilturns
        sdesign = rmfield (sdesign, 'CoilTurns');
    end

    femfilename = [tempname, '_simfun_RADIAL_SLOTTED.fem'];

    % write the fem file to disk
    writefemmfile (femfilename, sdesign.FemmProblem);

    % analyse the problem
    try
        ansfilename = analyse_mfemm ( femfilename, ...
                                      ssimoptions.MagFEASim.UseFemm, ...
                                      ssimoptions.MagFEASim.QuietFemm );
    catch err
        if strncmp (err.message, 'Material properties have not been defined', 41)
            warning (err.message);
            [sdesign, ssimoptions] = badscore (sdesign, ssimoptions);
            return;
        else
            rethrow (err);
        end
    end

    solution = fpproc (ansfilename);
    solution.smoothon ();

    % get the cross-sectional area of the armature iron for
    % calcuation of material masses later
    solution.clearblock ();
    solution.groupselectblock (sdesign.FemmProblem.Groups.ArmatureBackIron);
    sdesign.ArmatureIronArea = (solution.blockintegral(5) / sdesign.StatorDrawingInfo.NDrawnSlots) * design.Qs;

    % get the cross-sectional area of the coil winding bundle
    sdesign.CoilArea = ...
        solution.blockintegral ( 5, ...
                                 sdesign.StatorDrawingInfo.CoilLabelLocations(1,1), ...
                                 sdesign.StatorDrawingInfo.CoilLabelLocations(1,2) );

    sdesign.FirstSlotCenter = 0;
    sdesign.MagFEASimPositions = 0;
    [slotPos, slotIntA] = slotintAdata_RADIAL_SLOTTED (sdesign, 1, solution);

    for ind = 1:design.CoilLayers
        % use the integral data to produce flux linkage values according to the
        % coil shape. We append the last slot again
        intAslm(ind) = slmengine ([slotPos; slotPos(end)+slotPos(2)-slotPos(1)], ...
                                  [slotIntA(:,ind); slotIntA(1,ind)], ...
                                  'EndCon', 'periodic', ...
                                  'knots', 2*numel (slotPos)+1, ...
                                  'Plot', 'off');
    end

    lambda = fluxlinkagefrmintAslm ( intAslm, ...
                            sdesign.yd*design.thetas/design.thetap, ...
                            linspace (0,4,100), ...
                            1, ... % use one coil turn we will scale later
                            sdesign.CoilArea, ...
                           'Skew', sdesign.MagnetSkew, ...
                           'NSkewPositions', sdesign.NSkewMagnetsPerPole );

    peakfl = max ( abs (lambda));

    % get the peak flux density in the armature back iron along
    % center line of a tooth
    NBpnts = 100;
    switch design.ArmatureType
        case 'external'
            [x, y] = pol2cart (repmat (sdesign.thetas, 1, NBpnts), ...
                               linspace (sdesign.Rai, sdesign.Ryo, NBpnts));
        case 'internal'
            [x, y] = pol2cart (repmat (sdesign.thetas, 1, NBpnts), ...
                               linspace (sdesign.Ryi, sdesign.Rao, NBpnts));
    end
    Bmag = magn (solution.getb (x, y));

    sdesign.ArmatureToothFluxDensityPeak = max (Bmag);

    sdesign.FluxDensityMagnitudeAirGapTheta = linspace (0, 2*sdesign.thetap, NBpnts);

    % now get peak flux density in the air gap
    [x, y] = pol2cart (sdesign.FluxDensityMagnitudeAirGapTheta, ...
                       repmat (design.Rgm, 1, NBpnts) );

    Bmag = magn (solution.getb (x, y));

    sdesign.FluxDensityMagnitudeAirGap = Bmag;

    sdesign.FluxDensityMagnitudeAirGapPeak = max (Bmag);

    % tidy up the fea files
    delete (femfilename); delete (ansfilename);

    sdesign = checkcoilprops_AM(sdesign);

    if rmcoilturns
       peakfl = peakfl * sdesign.CoilTurns;
    end

    omega = rpm2omega(ssimoptions.RPM);

    sdesign.EMFCoilPeak = peakemfest_ROTARY(abs(peakfl), omega, sdesign.Poles / 2);

    sdesign.EMFCoilRms = sdesign.EMFCoilPeak / sqrt(2);

    sdesign.EMFPhasePeak = sdesign.CoilsPerBranch * sdesign.EMFCoilPeak;

    sdesign.EMFPhaseRms = sdesign.EMFPhasePeak  / sqrt(2);

%     if sdesign.EMFPhaseRms < ssimoptions.min_EMFPhaseRms
%
%         min_coil_turns_factor = ssimoptions.min_EMFPhaseRms / sdesign.EMFPhaseRms;
%
%         sdesign = rmfield (sdesign, 'Dc');
%
%         sdesign.CoilTurns = max (10000, round (min_coil_turns_factor * ssdesign.CoilTurns));
%
%         sdesign = checkcoilprops_AM(sdesign);
%
%     elseif sdesign.EMFPhaseRms > ssimoptions.max_EMFPhaseRms
%
%         min_coil_turns_factor = ssimoptions.max_EMFPhaseRms / sdesign.EMFPhaseRms;
%
%         sdesign = rmfield (sdesign, 'Dc');
%
%         sdesign.CoilTurns = min(1, round (min_coil_turns_factor * ssdesign.CoilTurns));
%
%         sdesign = checkcoilprops_AM(sdesign);
%
%     end

    % now calculate coil resistance using the same function as would be
    % used in simfun_RADIAL_SLOTTED
    sdesign = coilresistance_RADIAL_SLOTTED (sdesign);

    sdesign.CoilInductance = 0;

    sdesign.psilookup = [0,1;0,0];

    [sdesign, ssimoptions] = finfun_RADIAL(sdesign, ssimoptions);

    sdesign.IPhasePeak = sdesign.EMFPhasePeak / (sdesign.PhaseResistance(1) + sdesign.LoadResistance(1));
    sdesign.ICoilPeak = sdesign.IPhasePeak / sdesign.Branches;

    sdesign.IPhaseRms = sdesign.IPhasePeak / sqrt(2);
    sdesign.ICoilRms = sdesign.IPhaseRms / sdesign.Branches;

    sdesign.VoltageGenTerminalPhaseRms = sdesign.EMFPhaseRms - (sdesign.IPhaseRms.*sdesign.PhaseResistance(1));

    sdesign.PowerLoadMean = sdesign.IPhaseRms.^2 * sdesign.LoadResistance * sdesign.Phases;

    sdesign.JCoilRms = sdesign.ICoilRms / sdesign.ConductorArea;

    sdesign.JCoilPeak = sdesign.ICoilPeak / sdesign.ConductorArea;

    sdesign.Efficiency = 0.9 * (sdesign.LoadResistance / (sdesign.CoilResistance + sdesign.LoadResistance));
    sdesign.TorqueRippleFactor = 0.2;
    sdesign.VoltagePercentTHD = 50;
    if isfield (ssimoptions, 'max_TemperaturePeak')
        sdesign.TemperaturePeak = ssimoptions.max_TemperaturePeak - 1;
    end
    sdesign.CoggingTorquePeak = 0;

end

function [sdesign, ssimoptions] = badscore (sdesign, ssimoptions)

	sdesign.JCoilRms = 2 * ssimoptions.max_JCoilRms;
    sdesign.EMFPhaseRms = 5 * ssimoptions.max_EMFPhaseRms;
    sdesign.PowerLoadMean = 2 * ssimoptions.max_PowerLoadMean;
    if isfield (ssimoptions, 'max_TemperaturePeak')
        sdesign.TemperaturePeak = 2 * ssimoptions.max_TemperaturePeak;
    end
    sdesign.TorqueRippleFactor = 2 * ssimoptions.max_TorqueRippleFactor;
    sdesign.VoltagePercentTHD = 2 * ssimoptions.max_VoltagePercentTHD;
    sdesign.CoggingTorquePeak = 2 * ssimoptions.max_CoggingTorquePeak;
    sdesign.Efficiency = 0.5;
    sdesign.ArmatureToothFluxDensityPeak = 2 * ssimoptions.max_ArmatureToothFluxDensityPeak;

    % now calculate coil resistance
    sdesign.MTL = rectcoilmtl( sdesign.ls, ...
                               sdesign.yd * sdesign.thetas * sdesign.Rcm, ...
                               mean([sdesign.thetacg, sdesign.thetacy] * sdesign.Rcm) );

    sdesign.CoilTurns = 1;
    sdesign.ArmatureIronAreaPerPole = 1;
    ssimoptions = setfieldifabsent(ssimoptions, 'basescorefcn', 'costscore_AM');

end
