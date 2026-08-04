function [ RawTorque, ...
           BxCoreLossData, ...
           ByCoreLossData, ...
           ArmatureToothFluxDensity, ...
           FemmDirectFluxLinkage, ...
           AslotPos, ...
           slotIntA, ...
           BslotPos, ...
           slotIntB, ...
           design, ...
           session ] = feasim_RADIAL_SLOTTED (design, simoptions, theta, varargin)
% performs a single finite element simulation of a slotted radial flux
% machine and returns raw data
%
% Syntax
%
% [ RawTorque, ...
%   BxCoreLossData, ...
%   ByCoreLossData, ...
%   ArmatureToothFluxDensity, ...
%   FemmDirectFluxLinkage, ...
%   AslotPos, ...
%   slotIntA, ...
%   BslotPos, ...
%   slotIntB, ...
%   design ] = feasim_RADIAL_SLOTTED (design, simoptions, theta, 'Parameter', value)
%
% Inputs
%
%  design - slotted radial flux design matrix
%
%  simoptions - simulation parameters structure
%
%  theta -


    Inputs.IsInitialisation = false;
    Inputs.GatherIronLossData = true;
    Inputs.GatherVectorPotentialData = true;
    Inputs.PhaseCurrents = zeros (design.Phases, 1);
    Inputs.NPolePairs = max(1, ceil (design.pb/2));
    Inputs.RotationMethod = 'MagnetRedraw';
    Inputs.FemFileName = [tempname, '_simfun_RADIAL_SLOTTED.fem'];
    Inputs.FemmSession = [];
    Inputs.SolveMethod = 'xfemm_legacy';

    Inputs = parse_pv_pairs (Inputs, varargin);


    if nargin == 0
        RawTorque = {@slotintAdata, @slotintBdata, @corelosssetup };
    end

    % initialise all outputs to empty matrices as we don't fill some
    % depending on input options
    BxCoreLossData = [];
    ByCoreLossData = [];
    ArmatureToothFluxDensity = [];
    FemmDirectFluxLinkage = [];
    AslotPos = [];
    slotIntA = [];
    BslotPos = [];
    slotIntB = [];

    femfilename = Inputs.FemFileName;

    switch Inputs.RotationMethod

        case 'MagnetRedraw'
            DrawingType = 'MagnetRotation';
%            use_existing_mesh = false;
            KeepMesh = false;
            sliding_mesh = false;

        case 'SlidingMesh'
            DrawingType = 'SlidingMesh';
%            use_existing_mesh = false;
            KeepMesh = true;
            sliding_mesh = true;

        otherwise

            error('Unrecognised RotationMethod: %s', Inputs.RotationMethod);

    end

    angle_position = theta + design.FirstSlotCenter;

    switch Inputs.SolveMethod

        case 'xfemm_legacy'

            % Draw the sim, i.e by creating the FemmProblem structure
            [design.FemmProblem, design.RotorDrawingInfo, design.StatorDrawingInfo] = ...
                        slottedfemmprob_radial (design, ...
                            'NPolePairs', Inputs.NPolePairs, ...
                            'NWindingLayers', design.CoilLayers, ...
                            'SplitSlot', (design.CoilLayers == 2) && (design.yd == 1), ...
                            'Position', angle_position, ...
                            'MagnetRegionMeshSize', simoptions.MagFEASim.MagnetRegionMeshSize, ...
                            'BackIronRegionMeshSize', simoptions.MagFEASim.BackIronRegionMeshSize, ...
                            'StatorOuterRegionsMeshSize', simoptions.MagFEASim.OuterRegionsMeshSize, ...
                            'RotorOuterRegionsMeshSize', simoptions.MagFEASim.OuterRegionsMeshSize, ...
                            'AirGapMeshSize', simoptions.MagFEASim.AirGapMeshSize, ...
                            'ShoeGapRegionMeshSize', simoptions.MagFEASim.ShoeGapRegionMeshSize, ...
                            'YokeRegionMeshSize', simoptions.MagFEASim.YokeRegionMeshSize, ...
                            'CoilRegionMeshSize', simoptions.MagFEASim.CoilRegionMeshSize, ...
                            'CoilCurrent', Inputs.PhaseCurrents, ...
                            'DrawingType', DrawingType);

            % write the fem file to disk
            writefemmfile (femfilename, design.FemmProblem);

            % analyse the problem
            ansfilename = analyse_mfemm (femfilename, ...
                                         'UseFemm', simoptions.MagFEASim.UseFemm, ...
                                         'Quiet', simoptions.MagFEASim.QuietFemm, ...
                                         'KeepMesh', KeepMesh);


            session = fpproc (ansfilename);

            delete (ansfilename);

        case 'femmsession'

            if isempty(Inputs.FemmSession)

                % Draw the sim, i.e by creating the FemmProblem structure
                [design.FemmProblem, design.RotorDrawingInfo, design.StatorDrawingInfo] = ...
                        slottedfemmprob_radial (design, ...
                            'NPolePairs', Inputs.NPolePairs, ...
                            'NWindingLayers', design.CoilLayers, ...
                            'SplitSlot', (design.CoilLayers == 2) && (design.yd == 1), ...
                            'Position', angle_position, ...
                            'MagnetRegionMeshSize', simoptions.MagFEASim.MagnetRegionMeshSize, ...
                            'BackIronRegionMeshSize', simoptions.MagFEASim.BackIronRegionMeshSize, ...
                            'StatorOuterRegionsMeshSize', simoptions.MagFEASim.OuterRegionsMeshSize, ...
                            'RotorOuterRegionsMeshSize', simoptions.MagFEASim.OuterRegionsMeshSize, ...
                            'AirGapMeshSize', simoptions.MagFEASim.AirGapMeshSize, ...
                            'ShoeGapRegionMeshSize', simoptions.MagFEASim.ShoeGapRegionMeshSize, ...
                            'YokeRegionMeshSize', simoptions.MagFEASim.YokeRegionMeshSize, ...
                            'CoilRegionMeshSize', simoptions.MagFEASim.CoilRegionMeshSize, ...
                            'CoilCurrent', Inputs.PhaseCurrents, ...
                            'DrawingType', DrawingType);

                % write the fem file to disk
                writefemmfile (femfilename, design.FemmProblem);

                session = xfemm.femmsession(femfilename);

            elseif isa(Inputs.FemmSession, 'xfemm.femmsession')

                % we're re-using an existing analysis session
                session = Inputs.FemmSession;

            else

                error('FemmSession was not empty and of type %s', type(Inputs.FemmSession));

            end

            if sliding_mesh

                switch design.ArmatureType

                    case 'external'
                        %YShift = design.Rmo + design.g + (design.Ryo + 2*design.tm + 10*design.tm) + 10*Inputs.Tol;
                        inner_angle = rad2deg (angle_position);
                        outer_angle = 0;
                    case 'internal'
                        %YShift = design.Ryo + design.g + (design.Rbo + sum (rotorinfo.OuterWrapperThickness(2:end))) + 10*Inputs.Tol;
                        inner_angle = 0;
                        outer_angle = rad2deg (angle_position);
                end

                for ind = 1:numel(design.FemmProblem.AGEBoundNames)
                    % should just need to change the ait gap angle
                    session.setAGEPosition(design.FemmProblem.AGEBoundNames{ind}, inner_angle, outer_angle);
                end

            end

            for ind = 1:numel(Inputs.PhaseCurrents)

                cname = num2str(ind);

                session.setCircuit(cname, 'current', Inputs.PhaseCurrents(ind));

            end

            session.solve();

    end

    % activate field smoothing so values are interpolated across
    % mesh elements
    session.smoothon ();

    if Inputs.IsInitialisation
        % is an initialisation run, do things we only need to do once

        design = corelosssetup (design, simoptions, design.MagFEASimPositions, session);

        % get the forces
        session.clearblock();
        session.groupselectblock( [ design.FemmProblem.Groups.Magnet, ...
                                    design.FemmProblem.Groups.RotorBackIron ]);

        % determine a unit vector pointing in the direction normal to the air
        % gap half way between the Poles for the purpose of extracting the
        % air-gap closing forces
        [gvector(1), gvector(2)] = pol2cart (design.RotorDrawingInfo.NDrawnPoles * design.thetap / 2,1);
        gvector = unit (gvector);

        design.PerPoleAirGapClosingForce = dot ( [ session.blockintegral(18)/design.RotorDrawingInfo.NDrawnPoles, ...
                                                   session.blockintegral(19)/design.RotorDrawingInfo.NDrawnPoles ], ...
                                                 gvector );

        % get the cross-sectional area of the armature iron for
        % calcuation of material masses later
        session.clearblock();
        session.groupselectblock (design.FemmProblem.Groups.ArmatureBackIron);
        design.ArmatureIronArea = (session.blockintegral(5) / design.StatorDrawingInfo.NDrawnSlots) * design.Qs;

        % get the cross-sectional area of the coil winding bundle
        design.CoilArea = session.blockintegral ( 5, design.StatorDrawingInfo.CoilLabelLocations(1,1), design.StatorDrawingInfo.CoilLabelLocations(1,2) );


    end

    % get the peak flux density in the armature back iron along
    % center line of a tooth
    NBpnts = 100;
    if strcmpi (design.ArmatureType, 'external')
        [x, y] = pol2cart (repmat (design.thetas, 1, NBpnts), linspace (design.Rai, design.Ryo, NBpnts));
    elseif strcmpi (design.ArmatureType, 'internal')
        [x, y] = pol2cart (repmat (design.thetas, 1, NBpnts), linspace (design.Ryi, design.Rao, NBpnts));
    end
    Bmag = magn (session.getb (x, y));

    ArmatureToothFluxDensity = max (Bmag);

    design.FluxDensityMagnitudeAirGapTheta = linspace (0, 2*design.thetap, NBpnts);

    % now get peak flux density in the air gap
    [x, y] = pol2cart (design.FluxDensityMagnitudeAirGapTheta, ...
                       repmat (design.Rgm, 1, NBpnts) );

    Bmag = magn (session.getb (x, y));

    design.FluxDensityMagnitudeAirGap = Bmag;

    design.FluxDensityMagnitudeAirGapPeak = max (Bmag);

    if numel(design.FemmProblem.Circuits) > 0
        FemmDirectFluxLinkage = zeros (1,numel(design.FemmProblem.Circuits));
        for ind = 1:numel(design.FemmProblem.Circuits)
             temp = session.getcircuitprops ( design.FemmProblem.Circuits(ind).Name );
             FemmDirectFluxLinkage(ind) = temp(3);
        end
    else
        FemmDirectFluxLinkage = nan;
    end

    % get the per-coil flux linkage regardless of number of poles drawn
    FemmDirectFluxLinkage = FemmDirectFluxLinkage / double(design.qc * Inputs.NPolePairs * 2);

    if Inputs.GatherIronLossData

        for ii = 1:numel(design.CoreLoss)

            p = session.getpointvalues ( design.CoreLoss(ii).meshx(:), ...
                                          design.CoreLoss(ii).meshy(:) );

            ByCoreLossData{ii} = reshape (p(2,:)', size (design.CoreLoss(ii).meshx));
            BxCoreLossData{ii} = reshape (p(3,:)', size (design.CoreLoss(ii).meshx));

        end

    end

    % get the cogging forces
    session.clearblock ();
    session.groupselectblock( [ design.FemmProblem.Groups.Magnet, ...
                                 design.FemmProblem.Groups.RotorBackIron ]);

%                 design.coggingforce(i) = dot([session.blockintegral(18)/2, session.blockintegral(19)/2], ...
%                                              coggingvector);
%
%                 design.coggingforce(i) = design.coggingforce(i) * design.Poles(1);

%                if simoptions.getintermagflux
%                    design.InterMagFlux = getintermagflux (design, session);
%                end

    % get the torque, this will include the cogging torque, and will in fact
    % be only the cogging torque if the coils currents are zero
    RawTorque = design.Poles(1) * (session.blockintegral (22) / (2*Inputs.NPolePairs));

    if Inputs.GatherVectorPotentialData

        % get the integral of the vector potential in a slot, if two
        % layers get both layers
        [AslotPos, slotIntA] = slotintAdata_RADIAL_SLOTTED (design, theta, session);

        [BslotPos, slotIntB] = slotintBdata(design, theta, session);

    end

    if exist(femfilename, 'file') == 2
        delete(femfilename);
    end

    if strcmp(Inputs.SolveMethod, 'xfemm_legacy')
        session = [];
    end

end


function [slotPos, slotIntB] = slotintBdata (design, theta, session)

    % extract the flux integral data from all the slots at the given
    % positions of the magnet relative to coil
    if design.CoilLayers == 1

        slotypos = design.StatorDrawingInfo.CoilLabelLocations(1:(size(design.StatorDrawingInfo.CoilLabelLocations,1)),2);
        slotxpos = design.StatorDrawingInfo.CoilLabelLocations(1:(size(design.StatorDrawingInfo.CoilLabelLocations,1)),1);

        for i = 1:numel (slotypos)
            % x and y directed flux in slot on left hand side
            session.clearblock ();
            session.selectblock (slotxpos(i,1), slotypos(i));
            slotIntB(i,1,1) = session.blockintegral (8);
            slotIntB(i,2,1) = session.blockintegral (9);
        end

    elseif design.CoilLayers == 2

        slotypos = [design.StatorDrawingInfo.CoilLabelLocations(1:2:(size(design.StatorDrawingInfo.CoilLabelLocations,1)),2), ...
                    design.StatorDrawingInfo.CoilLabelLocations((1:2:(size(design.StatorDrawingInfo.CoilLabelLocations,1)))+1,2)];
        slotxpos = [design.StatorDrawingInfo.CoilLabelLocations(1:2:(size(design.StatorDrawingInfo.CoilLabelLocations,1)),1), ...
                    design.StatorDrawingInfo.CoilLabelLocations((1:2:(size(design.StatorDrawingInfo.CoilLabelLocations,1)))+1,1)];

        for i = 1:size(slotypos,1)

            % x and y directed flux in slot on left hand side outer
            % (leftmost) layer
            session.clearblock ();
            session.selectblock(slotxpos(i,1), slotypos(i,1));
            slotIntB(i,1,1) = session.blockintegral (8);
            slotIntB(i,2,1) = session.blockintegral (9);

            % x and y directed flux in slot on left hand side inner
            % (rightmost) layer
            session.clearblock ();
            session.selectblock (slotxpos(i,2), slotypos(i,2));
            slotIntB(i,3,1) = session.blockintegral (8);
            slotIntB(i,4,1) = session.blockintegral (9);

        end

    end

    % store the relative coil/slot positions, we use -ve slotypos as the
    % direction of sampling is the opposite of the direction of the fea
    % drawing, so choosing a slot in the +ve y direction is the same as
    % the magnets being in the opposite direction
    [thetaslotypos, ~] = cart2pol (slotxpos(:,1), slotypos(:,1));
    slotPos = (-thetaslotypos./design.thetap) + design.FirstSlotCenter + theta./design.thetap;

%     % sort the data in ascending position order
%     [design.intBdata.slotPos, idx] = sort (design.intBdata.slotPos);
%     design.intBdata.slotIntB = design.intBdata.slotIntB(idx,:,:);

end

function design = corelosssetup (design, simoptions, feapos, session)

    groups = design.FemmProblem.Groups.ArmatureBackIron;

    if simoptions.DoBackIronCoreLoss
        groups = [groups, design.FemmProblem.Groups.BackIron];
    end

    if numel (design.CoreLoss) ~= numel (groups)
        error ('RENEWNET:corelosssetup:badgroups', ...
            'The number of specified groups does not match the number of CoreLoss structures.');
    end

    design = corelosssetup_SLOTTED (design, feapos, groups, design.ls, session);

end

function design = corelosssetup_SLOTTED (design, feapos, groups, volscalefac, session)

    % get the number of positions
    npos = numel (feapos);

    if isa(session, 'fpproc')
        % it's an xfemm fpproc object

        for gpind = 1:numel (groups)

            % get the volume of each element under consideration
            design.CoreLoss(gpind).dV = session.getgroupareas (groups(gpind)) .* volscalefac;

            % get the location we will use to estimate the flux in the element
            temp = session.getgroupcentroids (groups(gpind));
            design.CoreLoss(gpind).meshx = temp(:,1);
            design.CoreLoss(gpind).meshy = temp(:,2);

            % The values along the first dimension (down the columns) of the
            % arrays will contain values sampled in the x-direction in the fea
            % simulation. In this case values along the dimension hbi, or ht in
            % the case of the teeth. The values along the second dimension are
            % the values sampled at each value xRVWp. The values along the
            % third dimension of the arrays will contain values which are
            % sampled from the y direction of the fea simulation, in this case
            % along the dimension taupm, or tsb and tc in the case of the
            % teeth.
            design.CoreLoss(gpind).Bx = zeros( [size(design.CoreLoss(gpind).meshx,1), ...
                                                npos, ...
                                                size(design.CoreLoss(gpind).meshx,2) ]);

            design.CoreLoss(gpind).By = zeros( [size(design.CoreLoss(gpind).meshx,1), ...
                                                npos, ...
                                                size(design.CoreLoss(gpind).meshx,2)]);

            design.CoreLoss(gpind).Bz = zeros( [size(design.CoreLoss(gpind).meshx,1), ...
                                                npos, ...
                                                size(design.CoreLoss(gpind).meshx,2)]);

            % add xstep which is the size of the steps in xRVWp
            % denormalised. This is later used to find the value of dB/dx
            % (or dB/dtheta) at each position
            design.CoreLoss(gpind).xstep = (feapos(2) - feapos(1)) * design.PoleWidth;

        end

    else
        error ('RENEWNET:corelosssetup_SLOTTED:nousefemm', 'FEMM not currently supported for core loss calculation, use xfemm.')
    end

end
