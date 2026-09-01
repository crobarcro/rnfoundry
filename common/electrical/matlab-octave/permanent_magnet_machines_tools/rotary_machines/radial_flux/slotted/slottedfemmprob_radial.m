function [FemmProblem, rotorinfo, statorinfo] = slottedfemmprob_radial(design, varargin)
% creates a FemmProblem structure for a slotted radial flux permanent
% magnet machine
%
% Syntax
%
% [FemmProblem, coillabellocs] = slottedfemmprob_radial (design)
% [FemmProblem, coillabellocs] = slottedfemmprob_radial (..., 'Parameter', Value)
%
%
% Inputs
%
%  design - Structure containing the design specification. See the help for
%   completedesign_RADIAL_SLOTTED.m for a detailed discussion of how a
%   design can be specified.
%
%  Finer control over the drawing can be made using a number of optional
%  arguments supplied as parameter-value pairs, i.e. a string followed by
%  the desired value. The optional parameters are described below:
%
%   'DrawingType' - string describing the desired type of simulation
%     drawing. Currently there is only one option 'MagnetRotation', also
%     the default. With this option the magnets are drawn rotated to the
%     desired position. See the 'Position' parameter below for more
%     details.
%
%   'Position' - angular displacement of the rotor expressed.
%
%   'NBoundaryPositions' -
%
%   'CoilCurrent' = zeros (1,design.Phases)
%
%   'MagArrangement' = 'NN'
%
%   'PolarisationType' = 'constant'
%
%   'FemmProblem' - existing mfemm FemmProblem structure to which the
%     drawing will be added. If not supplied, a new FemmProblem is created.
%
%   'FractionalPolePosition' = angular displacement of the rotor expressed
%     as a fraction of one pole.
%
%   'RotorAnglePosition' = [];
%
%   'MagnetGroup' - Scalar integer representing the group number to be
%     assigned to the magnet regions
%
%   'MagnetSpaceGroup' - Scalar integer representing the group number to be
%     assigned to the regions between magnets
%
%   'RotorBackIronGroup' - Scalar integer representing the group number to
%     be assigned to the rotor back iron
%
%   'RotorOuterRegionGroup' - The group number(s) to be assigned to the
%     external regions beyond the rotor back iron outer bounday. If scalar,
%     the same group number is applied to all outer regions. If a vector,
%     it must be the same length as the number of outer regions, and is the
%     group number for each region working from the region closest to the
%     back iron outwards.
%
%   'CoilGroup' - Scalar integer representing the group number to
%     be assigned to all coil regions
%
%   'ArmatureBackIronGroup' = [];
%
%   'MagnetRegionMeshSize' = choosemesharea_mfemm(design.tm, (design.Rmm*design.thetam), 1/10);
%
%   'BackIronRegionMeshSize' = choosemesharea_mfemm(min(design.tbi), 2*(design.Rbm*design.thetap), 1/10);
%
%   'OuterRegionsMeshSize' = [choosemesharea_mfemm(design.tm, (design.Rbo*design.thetap), 1/5), -1];
%
%   'AirGapMeshSize' = choosemesharea_mfemm(design.g, (design.Rmm*design.thetap), 1/10);
%
%   'DrawOuterRegions' = true;
%
%   'DrawCoilInsulation' = true/false flag indicating whether to draw a
%     layer of coil insulation in the slot
%
%   'CoilInsRegionMeshSize' = -1;
%
%   'ShoeGapRegionMeshSize' = choosemesharea_mfemm(max(design.tsg, design.tsb), (design.Rmo*design.thetasg), 1/20);
%
%   'YokeRegionMeshSize' -
%
%   'CoilRegionMeshSize' -
%
%   'Tol' - drawing tolerance for gaps etc.
%
%   'SimType' - char array describing which type of simulation is to be
%     performed. Valid input are : 'Magnetics', and 'HeatFlow'.
%
%   'MaterialsLibrary' - string containing a path to an alternative
%     materials library to use for the simulation.
%
%   'NPolePairs' - number of pole pairs to be drawn in the simulation. The
%     number of slots will be calculated from this
%
%   'NWindingLayers' - legacy option to specify number of layers in the
%     coils, should be specified in design structure (which will also
%     override this option, even if it is specified).
%
%  'SplitSlot' - true/false flag. If there is only two winding layers, the
%     slot can be split into two in the circumferential direction rather
%     than the radial by setting this flag to true. Defaults to false. If
%     true coil label locations are provided in an anti-clockwise
%     direction.
%

    % First set up some default inputs
    Inputs.DrawingType = 'MagnetRotation';
    Inputs.NBoundaryPositions = 10;
    Inputs.BoundaryShift = 0;
    Inputs.NWindingLayers = nan;
    Inputs.CoilCurrent = zeros (1,design.Phases);
    Inputs.MagArrangement = 'NN';
    Inputs.PolarisationType = 'constant';
    if isfield (design, 'MagnetPolarisation') && ischar (design.MagnetPolarisation)
        Inputs.PolarisationType = design.MagnetPolarisation;
    end
    Inputs.FemmProblem = newproblem_mfemm ('planar', 'Depth', design.ls, 'MinAngle', 15);
    Inputs.Position = 0;
    Inputs.FractionalPolePosition = [];
    Inputs.RotorAnglePosition = [];
    Inputs.MagnetGroup = [];
    Inputs.MagnetSpaceGroup = [];
    Inputs.RotorBackIronGroup = [];
    Inputs.RotorOuterRegionGroup = [];
    Inputs.CoilGroup = 0;
    Inputs.ArmatureBackIronGroup = [];
    Inputs.MagnetRegionMeshSize = choosemesharea_mfemm (design.tm, (design.Rmm*design.thetam), 1/10);
    Inputs.BackIronRegionMeshSize = choosemesharea_mfemm (min(design.tbi), 2*(design.Rbm*design.thetap), 1/10);
    Inputs.RotorOuterRegionsMeshSize = [choosemesharea_mfemm(design.tm, (design.Rbo*design.thetap), 1/5), -1];
    Inputs.StatorOuterRegionsMeshSize = [];
    Inputs.StatorOuterRegionMaterials = {};
    Inputs.AirGapMeshSize = choosemesharea_mfemm (design.g, (design.Rmm*design.thetap), 1/10);
    Inputs.DrawOuterRegions = true;
    Inputs.StatorOuterRegionSize = [];
    Inputs.DrawCoilInsulation = false;
    Inputs.CoilInsRegionMeshSize = -1;
    Inputs.SplitSlot = false;

    if design.tsg > 1e-5
        if design.tsb > 1e-5
            Inputs.ShoeGapRegionMeshSize = ...
                choosemesharea_mfemm (max(design.tsg, design.tsb), (design.Rmo*design.thetasg), 1/20);
        else
            Inputs.ShoeGapRegionMeshSize = ...
                choosemesharea_mfemm (design.tsb, (design.Rmo*design.thetasg), 1/20);
        end
    else
        if design.tsb > 1e-5
            Inputs.ShoeGapRegionMeshSize = ...
                choosemesharea_mfemm (design.tsb, (design.Rmo*design.thetasg), 1/20);
        else
            Inputs.ShoeGapRegionMeshSize = -1;
        end
    end
    Inputs.YokeRegionMeshSize = mean( [choosemesharea_mfemm(design.ty, 2*(design.Rym*design.thetap), 1/10), ...
                                       choosemesharea_mfemm(design.tc(1), (design.Rcm*(design.thetas-mean(design.thetac))), 1/10)] );
    Inputs.CoilRegionMeshSize = choosemesharea_mfemm (design.tc(1), (design.Rcm*mean(design.thetac)));
    Inputs.Tol = 1e-5;
    Inputs.SimType = 'Magnetics';
    Inputs.MaterialsLibrary = '';
    Inputs.NPolePairs = 1;

    Inputs = parseoptions (Inputs, varargin);

	NSlots = Inputs.NPolePairs*2*design.Qs/design.Poles;

    if isnan(Inputs.NWindingLayers)
        if isfield (design, 'CoilLayers')
            Inputs.NWindingLayers = design.CoilLayers;
        else
            Inputs.NWindingLayers = 1;
            warning ('Number of winding layers not specified, using 1.');
        end
    end

    FemmProblem = Inputs.FemmProblem;

    if isempty (Inputs.ArmatureBackIronGroup) ...
            && ~isfield (FemmProblem.Groups, 'ArmatureBackIron')
        [FemmProblem, Inputs.ArmatureBackIronGroup] = addgroup_mfemm (FemmProblem, 'ArmatureBackIron');
    end

    if isempty (Inputs.MaterialsLibrary)
        if strncmpi (Inputs.SimType, 'Magnetics', 1)
            FemmProblem.ProbInfo.Domain = 'Magnetics';
            Inputs.MaterialsLibrary = fullfile (fileparts (which ('matstr2matstruct_mfemm')), '..', 'matlib.mat');
        elseif strncmpi (Inputs.SimType, 'HeatFlow', 1)
            FemmProblem.ProbInfo.Domain = 'HeatFlow';
            Inputs.MaterialsLibrary = fullfile (fileparts (which ('matstr2matstruct_mfemm')), '..', 'heatlib.mat');
        else
            error ('Unrecognised SimType');
        end
    end

    % Get the planar position from the position specification
    Inputs.Position = planarrotorpos ( design.thetap, ...
                                       Inputs.Position, ...
                                       Inputs.FractionalPolePosition, ...
                                       Inputs.RotorAnglePosition );

    % Convert the material names to materials structures from the materials
    % library, if this has not already been done.
    if strncmpi (Inputs.SimType, 'Magnetics', 1)

        [FemmProblem, matinds] = addmaterials_mfemm (FemmProblem, ...
            { design.MagFEASimMaterials.AirGap, ...
              design.MagFEASimMaterials.Magnet, ...
              design.MagFEASimMaterials.FieldBackIron, ...
              design.MagFEASimMaterials.ArmatureYoke, ...
              design.MagFEASimMaterials.ArmatureCoil }, ...
             'MaterialsLibrary', Inputs.MaterialsLibrary );

    elseif strncmpi (Inputs.SimType, 'HeatFlow', 1)

        [FemmProblem, matinds] = addmaterials_mfemm (FemmProblem, ...
            { design.HeatFEASimMaterials.AirGap, ...
              design.HeatFEASimMaterials.Magnet, ...
              design.HeatFEASimMaterials.FieldBackIron, ...
              design.HeatFEASimMaterials.ArmatureYoke, ...
              design.HeatFEASimMaterials.ArmatureCoil }, ...
             'MaterialsLibrary', Inputs.MaterialsLibrary );
    end

    GapMatInd = matinds(1);
    MagnetMatInd = matinds(2);
    BackIronMatInd = matinds(3);
    YokeMatInd = matinds(4);
    CoilMatInd = matinds(5);

    switch design.ArmatureType

        case 'external'
            % single inner facing stator
            drawnrotors = [false, true];
            rrotor = design.Rmo;
            drawnstatorsides = [1, 0];
            Rs = design.Rmo + design.g + design.tc(1) + design.tsb + design.ty/2;
            outerR = design.Ryo;
        case 'internal'
            % single outer facing stator
            drawnrotors = [true, false];
            rrotor = design.Rmi;
            drawnstatorsides = [0, 1];
            Rs = design.Rmi - design.g - design.tc(1) - design.tsb - design.ty/2;
            outerR = design.Rbo;
        case 'di'
            % double internal stator (mags on outside)
%             drawnrotors = [true, true];
%             rrotor = [ design.Rmo, design.Rmo + 2* (design.g + design.tc(1) + design.ty/2) ];
%             drawnstatorsides = [1, 1];
%             Rs = design.Rmo(1) + design.g + design.tc(1) + design.ty/2;
            error('not yet supported');
        case 'do'
            % double outer/external stator (mags on inside)
            error('not yet supported');

        otherwise
            error('Unrecognised ArmatureType option.')

    end

    XShift = 0;
    YShift = 0;

    if numel (design.tc) > 1
        coilbasefrac = design.tc(2) / design.tc(1);
    else
        coilbasefrac = 0.05;
    end

    if isfield (design, 'ShoeCurveControlFrac')
        shoecurvefrac = design.ShoeCurveControlFrac;
    else
        shoecurvefrac = 0.5;
    end

    % define the block properties of the core region
    yokeBlockProps.BlockType = FemmProblem.Materials(YokeMatInd).Name;
    yokeBlockProps.MaxArea = Inputs.BackIronRegionMeshSize;
    yokeBlockProps.InCircuit = '';
    yokeBlockProps.InGroup = Inputs.ArmatureBackIronGroup;

    switch Inputs.DrawingType

        case 'MagnetRotation'

            % draw the radial rotor according to the spec in the design strucure
            [FemmProblem, rotorinfo] = radialfluxrotor2dfemmprob ( ...
                design.thetap, design.thetam, design.tm, design.tbi, drawnrotors, rrotor, ...
                'FemmProblem', FemmProblem, ...
                'MagArrangement', Inputs.MagArrangement, ...
                'PolarisationType', Inputs.PolarisationType, ...
                'MagnetMaterial', MagnetMatInd, ...
                'BackIronMaterial', BackIronMatInd, ...
                'OuterRegionsMaterial', GapMatInd, ... % ususally Air
                'MagnetSpaceMaterial', GapMatInd, ... % usually Air
                'MagnetGroup', Inputs.MagnetGroup, ...
                'MagnetSpaceGroup', Inputs.MagnetSpaceGroup, ...
                'BackIronGroup', Inputs.RotorBackIronGroup, ...
                'OuterRegionGroup', Inputs.RotorOuterRegionGroup, ...
                'MagnetRegionMeshSize', Inputs.MagnetRegionMeshSize, ...
                'BackIronRegionMeshSize', Inputs.BackIronRegionMeshSize, ...
                'OuterRegionsMeshSize', Inputs.RotorOuterRegionsMeshSize, ...
                'Position', Inputs.Position, ...
                'DrawOuterRegions', Inputs.DrawOuterRegions, ...
                'NPolePairs', Inputs.NPolePairs, ...
                'Tol', Inputs.Tol, ...
                'YShift', YShift );

            % draw the stator slots
            [FemmProblem, statorinfo] = radialfluxstator2dfemmprob ( ...
                design.Qs, design.Poles, Rs, design.thetap, design.thetac, ...
                design.thetasg, design.ty, design.tc(1), design.tsb, design.tsg, drawnstatorsides, ...
                'NWindingLayers', Inputs.NWindingLayers, ...
                'SplitSlot', Inputs.SplitSlot, ...
                'FemmProblem', FemmProblem, ...
                'ShoeGapMaterial', GapMatInd, ...
                'ShoeGapRegionMeshSize', Inputs.ShoeGapRegionMeshSize, ...
                ...'ArmatureIronGroup', Inputs.ArmatureBackIronGroup, ...
                'Tol', Inputs.Tol, ...
                'DrawCoilInsulation', Inputs.DrawCoilInsulation, ...
                'CoilInsulationThickness', design.CoilInsulationThickness, ...
                'CoilBaseFraction', coilbasefrac, ...
                'ShoeCurveControlFrac', shoecurvefrac, ...
                'NSlots', NSlots, ...
                'YShift', YShift );

%             coillabellocs = [coillabellocs; statorinfo.CoilLabelLocations];

            % Complete the design using the common radial drawing function
            Inputs.AddAllCoilsToCircuits = true;
%             Inputs.StartSlot = lastslot;

            [FemmProblem, statorinfo] = stator_iron_boundary (FemmProblem, design, Inputs, statorinfo, Rs, XShift, YShift);

            [FemmProblem, statorinfo] = stator_outer_regions (FemmProblem, design, Inputs, statorinfo, Rs, GapMatInd, XShift, YShift);

            if abs(tau-(design.thetap * 2 * Inputs.NPolePairs)) > Inputs.Tol
                % create boundaries for the air gap

                % add segments with periodic boundaries on the outer parts
                [FemmProblem, ~, airgapboundname] = addboundaryprop_mfemm (FemmProblem, 'Radial Air Gap Periodic', 4);

                % bottom gap corner to bottom core corner
                [FemmProblem, commoninfo.BottomSegInds] = addsegments_mfemm (FemmProblem, ...
                                                   statorinfo.node_id_set_stator_inner(1), ...
                                                   rotorinfo.MagnetCornerIDs(1), ...
                                                   'BoundaryMarker', airgapboundname);

                % top gap corner to top core corner
                [FemmProblem, commoninfo.BottomSegInds(end+1)] = addsegments_mfemm (FemmProblem, ...
                                                   statorinfo.node_id_set_stator_inner(2), ...
                                                   rotorinfo.MagnetCornerIDs(2), ...
                                                   'BoundaryMarker', airgapboundname);

            end

            % add the air gap labels
            switch design.ArmatureType

                case 'external'

                    % Add block labels for the air gap
                    [labelloc(1),labelloc(2)]  = pol2cart (design.thetap, design.Rmo+design.g/2);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm ( labelloc(1,1), labelloc(1,2), ...
                                            'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                            'MaxArea', Inputs.AirGapMeshSize );

                    % add a block label for the yoke and teeth
                    [labelloc(1),labelloc(2)] = pol2cart (design.thetap, Rs);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                                                         yokeBlockProps);

                case 'internal'

                    % Add block labels for the air gap
                    [labelloc(1),labelloc(2)] = pol2cart (design.thetap, design.Rmi-design.g/2);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                            'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                            'MaxArea', Inputs.AirGapMeshSize);

                    % add a block label for the yoke and teeth
                    [labelloc(1),labelloc(2)] = pol2cart (design.thetap, Rs);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                                                         yokeBlockProps);

                otherwise
                    error('Unrecognised ArmatureType option.')

            end

        case 'SlidingMesh'

            % draws the rotor and stator separately and links them at the
            % air gap using appropriate boundaries which can be swapped to
            % create relative motion without remeshing
            YShift = 0;

            % draw the radial rotor according to the spec in the design strucure
            [FemmProblem, rotorinfo] = radialfluxrotor2dfemmprob ( ...
                design.thetap, design.thetam, design.tm, design.tbi, drawnrotors, rrotor, ...
                'FemmProblem', FemmProblem, ...
                'MagArrangement', Inputs.MagArrangement, ...
                'PolarisationType', Inputs.PolarisationType, ...
                'MagnetMaterial', MagnetMatInd, ...
                'BackIronMaterial', BackIronMatInd, ...
                'OuterRegionsMaterial', GapMatInd, ... % ususally Air
                'MagnetSpaceMaterial', GapMatInd, ... % usually Air
                'MagnetGroup', Inputs.MagnetGroup, ...
                'MagnetSpaceGroup', Inputs.MagnetSpaceGroup, ...
                'BackIronGroup', Inputs.RotorBackIronGroup, ...
                'OuterRegionGroup', Inputs.RotorOuterRegionGroup, ...
                'MagnetRegionMeshSize', Inputs.MagnetRegionMeshSize, ...
                'BackIronRegionMeshSize', Inputs.BackIronRegionMeshSize, ...
                'OuterRegionsMeshSize', Inputs.RotorOuterRegionsMeshSize, ...
                'Position', 0, ...
                'DrawOuterRegions', Inputs.DrawOuterRegions, ...
                'NPolePairs', Inputs.NPolePairs, ...
                'Tol', Inputs.Tol, ...
                'YShift', 0 );

            switch design.ArmatureType
                case 'external'
                    %YShift = design.Rmo + design.g + (design.Ryo + 2*design.tm + 10*design.tm) + 10*Inputs.Tol;
                    inner_angle = rad2deg (Inputs.Position);
                    outer_angle = 0;
                case 'internal'
                    %YShift = design.Ryo + design.g + (design.Rbo + sum (rotorinfo.OuterWrapperThickness(2:end))) + 10*Inputs.Tol;
                    inner_angle = 0;
                    outer_angle = rad2deg (Inputs.Position);
            end

            % draw the stator slots
            [FemmProblem, statorinfo] = radialfluxstator2dfemmprob ( ...
                design.Qs, design.Poles, Rs, design.thetap, design.thetac, ...
                design.thetasg, design.ty, design.tc(1), design.tsb, design.tsg, drawnstatorsides, ...
                'NWindingLayers', Inputs.NWindingLayers, ...
                'SplitSlot', Inputs.SplitSlot, ...
                'FemmProblem', FemmProblem, ...
                'ShoeGapMaterial', GapMatInd, ...
                'ShoeGapRegionMeshSize', Inputs.ShoeGapRegionMeshSize, ...
                ...'ArmatureIronGroup', Inputs.ArmatureBackIronGroup, ...
                'Tol', Inputs.Tol, ...
                'DrawCoilInsulation', Inputs.DrawCoilInsulation, ...
                'CoilInsulationThickness', design.CoilInsulationThickness, ...
                'CoilBaseFraction', coilbasefrac, ...
                'ShoeCurveControlFrac', shoecurvefrac, ...
                'NSlots', NSlots, ...
                'YShift', 0 );

            [FemmProblem, statorinfo] = stator_iron_boundary (FemmProblem, design, Inputs, statorinfo, Rs, 0, 0);

            [FemmProblem, statorinfo] = stator_outer_regions (FemmProblem, design, Inputs, statorinfo, Rs, GapMatInd, 0, 0);

            % A sliding air gap is one AGE boundary whose marker is applied
            % to every arc on both sides of the annular interface.  The arc
            % subdivisions control the interpolation resolution; they must
            % not be represented by separate AGE boundary properties.
            [FemmProblem, ~, gapboundname] = ...
                addboundaryprop_mfemm (FemmProblem, 'Radial Sliding Air Gap', 6, ...
                                       'InnerAngle', inner_angle, ...
                                       'OuterAngle', outer_angle);

            FemmProblem.AGEBoundNames = {gapboundname};

            switch design.ArmatureType

                case 'external'
                    % obtain appropriate locations for the nodes to be added for
                    % each gap boundary
                    [n1x, n1y] = pol2cart ( linspace (0, Inputs.NPolePairs*2*design.thetap, Inputs.NBoundaryPositions+1)', ...
                                            repmat (design.Rmo + design.g/3, Inputs.NBoundaryPositions+1, 1 ) ...
                                          );

                    [n2x, n2y] = pol2cart ( linspace (0, Inputs.NPolePairs*2*design.thetap, Inputs.NBoundaryPositions+1)', ...
                                            repmat (design.Rmo + 2*design.g/3, Inputs.NBoundaryPositions+1, 1 ) ...
                                          );
                case 'internal'
                    % obtain appropriate locations for the nodes to be added for
                    % each gap boundary
                    [n1x, n1y] = pol2cart ( linspace (0, Inputs.NPolePairs*2*design.thetap, Inputs.NBoundaryPositions+1)', ...
                                            repmat (design.Rmi - 2*design.g/3, Inputs.NBoundaryPositions+1, 1 ) ...
                                          );

                    [n2x, n2y] = pol2cart ( linspace (0, Inputs.NPolePairs*2*design.thetap, Inputs.NBoundaryPositions+1)', ...
                                            repmat (design.Rmi - design.g/3, Inputs.NBoundaryPositions+1, 1 ) ...
                                          );
            end
            % shift the nodes to create the boundary nodes for the
%             n2x = n1x;
%             n2y = n1y + YShift;

            % add the nodes for the gap boundaries
            if abs(tau-(design.thetap * 2 * Inputs.NPolePairs)) > Inputs.Tol
                [FemmProblem, ~, n1nodeids] = addnodes_mfemm ( FemmProblem, n1x, n1y);
                [FemmProblem, ~, n2nodeids] = addnodes_mfemm ( FemmProblem, n2x, n2y);

                % add segments with periodic boundaries on the outer parts
                [FemmProblem, ~, rotorairgapboundname] = addboundaryprop_mfemm (FemmProblem, 'Radial Air Gap Periodic', 4);
                [FemmProblem, ~, statorairgapboundname] = addboundaryprop_mfemm (FemmProblem, 'Radial Air Gap Periodic', 4);

                % bottom gap corner to bottom rotor corner
                [FemmProblem, commoninfo.BottomSegInds] = addsegments_mfemm (FemmProblem, ...
                                                   n1nodeids(1), ...
                                                   rotorinfo.MagnetCornerIDs(1), ...
                                                   'BoundaryMarker', rotorairgapboundname);

                % top gap corner to top rotor corner
                [FemmProblem, commoninfo.BottomSegInds(end+1)] = addsegments_mfemm (FemmProblem, ...
                                                   n1nodeids(end), ...
                                                   rotorinfo.MagnetCornerIDs(2), ...
                                                   'BoundaryMarker', rotorairgapboundname);

                % bottom gap corner to bottom core corner
                [FemmProblem, commoninfo.BottomSegInds] = addsegments_mfemm (FemmProblem, ...
                                                   statorinfo.node_id_set_stator_inner(1), ...
                                                   n2nodeids(1), ...
                                                   'BoundaryMarker', statorairgapboundname);

                % top gap corner to top core corner
                [FemmProblem, commoninfo.BottomSegInds(end+1)] = addsegments_mfemm (FemmProblem, ...
                                                   statorinfo.node_id_set_stator_inner(2), ...
                                                   n2nodeids(end), ...
                                                   'BoundaryMarker', statorairgapboundname);


            else
                [FemmProblem, ~, n1nodeids] = addnodes_mfemm ( FemmProblem, n1x(1:end-1), n1y(1:end-1));
                [FemmProblem, ~, n2nodeids] = addnodes_mfemm ( FemmProblem, n2x(1:end-1), n2y(1:end-1));
                n1nodeids(end+1) = n1nodeids(1);
                n2nodeids(end+1) = n2nodeids(1);
            end

            gaparcangle = rad2deg (Inputs.NPolePairs*2*design.thetap/Inputs.NBoundaryPositions);
            maxgapsegdegrees = gaparcangle / 10;

            % create the segments for the gap boundaries
            for ind = 1:numel (n1x)-1

               % add a new gap boundary

               % add the gap segments
               FemmProblem = addarcsegments_mfemm ( FemmProblem, ...
                                                    n1nodeids(ind), ...
                                                    n1nodeids(ind+1), ...
                                                    gaparcangle, ...
                                                    'MaxSegDegrees', maxgapsegdegrees, ...
                                                    'BoundaryMarker', gapboundname );

               % add the gap segments
               FemmProblem = addarcsegments_mfemm ( FemmProblem, ...
                                                    n2nodeids(ind), ...
                                                    n2nodeids(ind+1), ...
                                                    gaparcangle, ...
                                                    'MaxSegDegrees', maxgapsegdegrees, ...
                                                    'BoundaryMarker', gapboundname );
            end


            % add the air gap labels
            switch design.ArmatureType

                case 'external'

                    % Add block labels for the air gap
                    [labelloc(1),labelloc(2)]  = pol2cart (design.thetap, design.Rmo + design.g/4);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm ( labelloc(1,1), labelloc(1,2), ...
                                            'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                            'MaxArea', Inputs.AirGapMeshSize );

                    [labelloc(1),labelloc(2)]  = pol2cart (design.thetap, design.Rmo + 3*design.g/4);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm ( labelloc(1,1), labelloc(1,2) + YShift, ...
                                            'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                            'MaxArea', Inputs.AirGapMeshSize );

                    % add a block label for the yoke and teeth
                    [labelloc(1),labelloc(2)] = pol2cart (design.thetap, Rs);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2) + YShift, ...
                                                                         yokeBlockProps);

                case 'internal'

                    % Add block labels for the air gap
                    [labelloc(1),labelloc(2)] = pol2cart (design.thetap, design.Rmi-design.g/4);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                            'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                            'MaxArea', Inputs.AirGapMeshSize);

                    [labelloc(1),labelloc(2)] = pol2cart (design.thetap, design.Rmi-3*design.g/4);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2) + YShift, ...
                                            'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
                                            'MaxArea', Inputs.AirGapMeshSize);

                    % add a block label for the yoke and teeth
                    [labelloc(1),labelloc(2)] = pol2cart (design.thetap, Rs);

                    FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                                                         yokeBlockProps);

                otherwise
                    error('Unrecognised ArmatureType option.')

            end


        case 'Full'

            % we're drawing everything and theefore ignoring some inputs
%             Inputs.NSlots = design.Qs;
            Inputs.NPolePairs = design.Poles / 2;
            Inputs.DrawingType = 'MagnetRotation';

            tempargs = struct2pvpairs (Inputs);

            [FemmProblem, rotorinfo, statorinfo] = slottedfemmprob_radial(design, tempargs{:});
            return;

        otherwise

            error ('Unrecognised simulation type, valid options are ''2PoleMagnetRotation'' and ''Full''');

    end

    if Inputs.DrawCoilInsulation
        FemmProblem = addcoilinsulationlabels (FemmProblem, design, Inputs, statorinfo.InsulationLabelLocations);
    end

    FemmProblem = addcircuitsandcoillabels (FemmProblem, design, Inputs, CoilMatInd, statorinfo.CoilLabelLocations);

    % copy over some drawing info
    rotorinfo.NDrawnPoles = 2 * Inputs.NPolePairs;
    statorinfo.NDrawnSlots = NSlots;

end

function tbboundnames = getsegbounds (FemmProblem, tbboundseginds)

    % preallocate a cell array to hold the boundary names
    tbboundnames = cell (size (tbboundseginds));

    for ind = 1:numel (tbboundseginds)

        tbboundnames{ind} = FemmProblem.Segments(tbboundseginds(ind)).BoundaryMarker;

    end

end


function [FemmProblem, statorinfo] = stator_iron_boundary (FemmProblem, design, Inputs, statorinfo, Rs, XShift, YShift)

    elcount = elementcount_mfemm (FemmProblem);

    statorirongp = getgroupnumber_mfemm (FemmProblem, 'StatorIronOutline');

    edgenodes = [];

    switch design.ArmatureType

        case 'external'
            % single inner facing stator (magnets inside, stator outside)

            % create the nodes which will make up the outer region and
            % upper and lower enges of the stator
            [edgenodes(:,1), edgenodes(:,2)] = pol2cart ( ...
                                                         [ 0; ...
                                                           design.thetap * 2 * Inputs.NPolePairs; ...
                                                           0; ...
                                                           design.thetap * Inputs.NPolePairs; ...
                                                           design.thetap * 2 * Inputs.NPolePairs ...
                                                           ], ...
                                                         [ design.Rmo+design.g; ... % inner surface of stator, bottom corner
                                                           design.Rmo+design.g; ... % inner surface of stator, top corner
                                                           Rs + design.ty/2; ... % outer surface of stator, bottom node
                                                           Rs + design.ty/2; ... % outer surface of stator, middle node
                                                           Rs + design.ty/2; ... % outer surface of stator, top node
                                                           ] ...
                                                         );

            if abs(tau-(design.thetap * 2 * Inputs.NPolePairs)) > Inputs.Tol

                % add the nodes to the problem
                [FemmProblem, ~, nodeids] = addnodes_mfemm (FemmProblem, edgenodes(:,1), edgenodes(:,2));

                statorinfo.node_id_set_stator_inner = [nodeids(1), nodeids(2)];
                statorinfo.node_id_set_stator_outer = [nodeids(3), nodeids(4), nodeids(5)];
                statorinfo.node_id_pair_stator_bottom_edge = [nodeids(1), nodeids(3)];
                statorinfo.node_id_pair_stator_top_edge = [nodeids(2), nodeids(5)];

                % add  periodic boundary for the segments on the edges of the
                % stator
                [FemmProblem, ~, statorboundname] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Back Iron Periodic', 4);

                segprop = struct ('BoundaryMarker', statorboundname, 'InGroup', statorirongp);

                % bottom stator boundary edge segment
                [FemmProblem, statorinfo.BottomSegInds] = addsegments_mfemm (FemmProblem, ...
                                                                       statorinfo.node_id_pair_stator_bottom_edge(1), ...
                                                                       statorinfo.node_id_pair_stator_bottom_edge(2), ...
                                                                       segprop);
                % top stator boundary edge segment
                [FemmProblem, statorinfo.TopSegInds] = addsegments_mfemm (FemmProblem, ...
                                                                    statorinfo.node_id_pair_stator_top_edge(1), ...
                                                                    statorinfo.node_id_pair_stator_top_edge(2), ...
                                                                    segprop);

                % arc from bottom slot corner to sim periodic boundary edge at bottom
                FemmProblem = addarcsegments_mfemm (FemmProblem, statorinfo.node_id_set_stator_inner(1), statorinfo.OuterNodes(1), ...
                                                    rad2deg(((2*pi/design.Qs)-design.thetac(1))/2), ...
                                                    'InGroup', statorirongp);

                % arc from top slot corner to sim periodic boundary edge at bottom
                FemmProblem = addarcsegments_mfemm (FemmProblem, statorinfo.OuterNodes(4), statorinfo.node_id_set_stator_inner(2), ...
                                                    rad2deg(((2*pi/design.Qs)-design.thetac(1))/2), ...
                                                    'InGroup', statorirongp);
            else

                % add the nodes to the problem
                [FemmProblem, ~, nodeids] = addnodes_mfemm (FemmProblem, edgenodes([4,5],1), edgenodes([4,5],2));

                statorinfo.node_id_set_stator_outer = [nodeids(1), nodeids(2), nodeids(1)];
%                 statorinfo.node_id_set_stator_outer = [nodeids(3), nodeids(4), nodeids(3)];

                % arc from first slot bottom left corner to last slot top
                % left corner
                FemmProblem = addarcsegments_mfemm (FemmProblem, statorinfo.OuterNodes(4), statorinfo.OuterNodes(1), ...
                                                    rad2deg(((2*pi/design.Qs)-design.thetac(1))), ...
                                                    'InGroup', statorirongp);

            end

            % add arcs linking the outer segments
            FemmProblem = addarcsegments_mfemm (FemmProblem, ...
                                                statorinfo.node_id_set_stator_outer(1), ...
                                                statorinfo.node_id_set_stator_outer(2), ...
                                                rad2deg(design.thetap*Inputs.NPolePairs));

            % put the stator iron segment in the right group
            FemmProblem.ArcSegments(end).InGroup = statorirongp;

            FemmProblem = addarcsegments_mfemm (FemmProblem, ...
                                                statorinfo.node_id_set_stator_outer(2), ...
                                                statorinfo.node_id_set_stator_outer(3), ...
                                                rad2deg(design.thetap*Inputs.NPolePairs));

            % put the stator iron segment in the right group
            FemmProblem.ArcSegments(end).InGroup = statorirongp;

        case 'internal'
            % single outer facing stator (stator inside, magnets outside)

            % create the nodes which will make up the outer region and
            % upper and lower enges of the stator
            [edgenodes(:,1), edgenodes(:,2)] = pol2cart ( ...
                                                         [ 0; ...
                                                           design.thetap * 2 * Inputs.NPolePairs; ...
                                                           0; ...
                                                           design.thetap * Inputs.NPolePairs; ...
                                                           design.thetap * 2 * Inputs.NPolePairs ...
                                                           ], ...
                                                         [ design.Rmi-design.g; ... % outer surface of stator, bottom corner
                                                           design.Rmi-design.g; % outer surface of stator, top corner
                                                           Rs - design.ty/2; ... % inner surface of stator, bottom node
                                                           Rs - design.ty/2; ... % inner surface of stator, middle node
                                                           Rs - design.ty/2; % inner surface of stator, top node
                                                           ] ...
                                                         );

            if abs(tau-(design.thetap * 2 * Inputs.NPolePairs)) > Inputs.Tol

                % add the nodes to the problem
                [FemmProblem, ~, nodeids] = addnodes_mfemm (FemmProblem, edgenodes(:,1), edgenodes(:,2));

                statorinfo.node_id_set_stator_inner = [nodeids(1), nodeids(2)];
                statorinfo.node_id_set_stator_outer = [nodeids(3), nodeids(4), nodeids(5)];
                statorinfo.node_id_pair_stator_bottom_edge = [nodeids(3), nodeids(1)];
                statorinfo.node_id_pair_stator_top_edge = [nodeids(5), nodeids(2)];

                % add  periodic boundaries for the segments on the edges of
                % the stator
                [FemmProblem, ~, statorboundname] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Back Iron Periodic', 4);

                segprop = struct ('BoundaryMarker', statorboundname, 'InGroup', statorirongp);

                % bottom stator boundary edge segment
                [FemmProblem, statorinfo.BottomSegInds] = addsegments_mfemm (FemmProblem, ...
                                                                       statorinfo.node_id_pair_stator_bottom_edge(1), ...
                                                                       statorinfo.node_id_pair_stator_bottom_edge(2), ...
                                                                       segprop);
                % top stator boundary edge segment
                [FemmProblem, statorinfo.TopSegInds] = addsegments_mfemm (FemmProblem, ...
                                                                    statorinfo.node_id_pair_stator_top_edge(1), ...
                                                                    statorinfo.node_id_pair_stator_top_edge(2), ...
                                                                    segprop);

                % arc from bottom slot corner to sim periodic boundary edge at bottom
                FemmProblem = addarcsegments_mfemm (FemmProblem, ...
                                                    statorinfo.node_id_set_stator_inner(1), ...
                                                    statorinfo.OuterNodes(2), ...
                                                    rad2deg(((2*pi/design.Qs)-design.thetac(1))/2), ...
                                                    'InGroup', statorirongp);

                % arc from top slot corner to sim periodic boundary edge at bottom
                FemmProblem = addarcsegments_mfemm (FemmProblem, ...
                                                    statorinfo.OuterNodes(3), ...
                                                    statorinfo.node_id_set_stator_inner(2), ...
                                                    rad2deg(((2*pi/design.Qs)-design.thetac(1))/2), ...
                                                    'InGroup', statorirongp);

            else

                % add the nodes to the problem
                [FemmProblem, ~, nodeids] = addnodes_mfemm (FemmProblem, edgenodes(:,1), edgenodes(:,2));

%                 statorinfo.node_id_set_stator_outer = [nodeids(1), nodeids(4)];
                statorinfo.node_id_set_stator_inner = [nodeids(3), nodeids(4), nodeids(3)];
%                 statorinfo.node_id_pair_stator_bottom_edge = [nodeids(1), nodeids(2)];
%                 statorinfo.node_id_pair_stator_top_edge = [nodeids(4), nodeids(3)];

                % arc from first slot bottom left corner to last slot top
                % left corner
                FemmProblem = addarcsegments_mfemm (FemmProblem, statorinfo.OuterNodes(4), statorinfo.OuterNodes(1), ...
                                                    rad2deg(((2*pi/design.Qs)-design.thetac(1))), ...
                                                    'InGroup', statorirongp);

            end

            % add arcs linking the outer segments
            FemmProblem = addarcsegments_mfemm (FemmProblem, ...
                                                statorinfo.node_id_set_stator_outer(1), ...
                                                statorinfo.node_id_set_stator_outer(2), ...
                                                rad2deg(design.thetap*Inputs.NPolePairs));

            % put the stator iron segment in the right group
            FemmProblem.ArcSegments(end).InGroup = statorirongp;

            FemmProblem = addarcsegments_mfemm (FemmProblem, ...
                                                statorinfo.node_id_set_stator_outer(2), ...
                                                statorinfo.node_id_set_stator_outer(3), ...
                                                rad2deg(design.thetap*Inputs.NPolePairs));

            % put the stator iron segment in the right group
            FemmProblem.ArcSegments(end).InGroup = statorirongp;



        case 'di'
            % double internal stator (mags on outside)
%             drawnrotors = [true, true];
%             rrotor = [ design.Rmo, design.Rmo + 2* (design.g + design.tc + design.ty/2) ];
%             drawnstatorsides = [1, 1];
%             Rs = design.Rmo(1) + design.g + design.tc + design.ty/2;
            error('not yet supported');
        case 'do'
            % double outer/external stator (mags on inside)
            error('not yet supported');

        otherwise
            error('Unrecognised ArmatureType option.')

    end

    FemmProblem = translatenewelements_mfemm (FemmProblem, elcount, XShift, YShift);

end


function [FemmProblem, statorinfo] = stator_outer_regions (FemmProblem, design, Inputs, statorinfo, Rs, GapMatInd, XShift, YShift)

    elcount = elementcount_mfemm (FemmProblem);

    edgenodes = [];

    switch design.ArmatureType

        case 'external'
            % single inner facing stator (magnets inside, stator outside)

            % the sizes of the stator outer air regions
            if isempty (Inputs.StatorOuterRegionSize)
                Inputs.StatorOuterRegionSize = [2*design.tm, 10*design.tm];
            end
            if isempty (Inputs.StatorOuterRegionsMeshSize)
                Inputs.StatorOuterRegionsMeshSize = [ choosemesharea_mfemm(design.tm, (Rs*design.thetap), 1/5), ...
                                                      repmat(-1,1,numel(Inputs.StatorOuterRegionSize)-1) ];
            end
            assert (samesize (Inputs.StatorOuterRegionSize, Inputs.StatorOuterRegionsMeshSize), ...
                'RENEWNET:slottedfemmproblem_radial:nstatormeshsizes', ...
                'Number of supplied stator outer region mesh sizes does not match number of outer region sizes.');

            if isempty (Inputs.StatorOuterRegionMaterials)
                % FemmProblem.Materials(GapMatInd).Name
                Inputs.StatorOuterRegionMaterials = repmat ({FemmProblem.Materials(GapMatInd).Name}, 1, numel(Inputs.StatorOuterRegionSize));
            end
            assert (samesize (Inputs.StatorOuterRegionSize, Inputs.StatorOuterRegionMaterials), ...
                'RENEWNET:slottedfemmproblem_radial:nstatormaterials', ...
                'Number of supplied stator outer region material names does not match number of outer region sizes.');

            statorinfo.touterregion = Inputs.StatorOuterRegionSize;

            % calculate the radial positions of the outer region boundaries
            statorinfo.routerregion = cumsum ([Rs + design.ty/2, statorinfo.touterregion]);

            % get a suitable tolerance to determine if we are making a full
            % circle or not
            FullCircleAngleTol = Inputs.Tol / statorinfo.routerregion(1);

            sectionangle = design.thetap * 2 * Inputs.NPolePairs;

            statorinfo.node_id_sets_stator_outer_region = statorinfo.node_id_set_stator_outer;

            for ind = 1:numel (statorinfo.touterregion)

                if (sectionangle < tau()) && ((tau()-sectionangle) > FullCircleAngleTol)
                    % there is not a full circle, so we will be making
                    % boundaries at the top and bottom. Test above is
                    % checking angle and tolerance based on actual
                    % distance, not angle

                    [edgenodes(:,1), edgenodes(:,2)] = ...
                        pol2cart ( [ 0; design.thetap * Inputs.NPolePairs; design.thetap * 2 * Inputs.NPolePairs; ], ...
                                     repmat (statorinfo.routerregion(ind+1), [3,1] ) );

                    % add the appropriate nodes to the problem
                    [FemmProblem, ~, nodeids] = addnodes_mfemm (FemmProblem, edgenodes(:,1), edgenodes(:,2));

                    statorinfo.node_id_sets_stator_outer_region = [statorinfo.node_id_sets_stator_outer_region;
                                                                   nodeids];

%                     statorinfo.node_id_set_stator_outer_region_2 = [nodeids(4), nodeids(5), nodeids(6)];

                    % add segments with periodic boundaries on the outer parts
                    [FemmProblem, ~, boundname] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Outer Periodic', 4);
%                     [FemmProblem, ~, region2boundname] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Outer Periodic', 4);

                    segprops = struct ('BoundaryMarker', boundname, 'InGroup', 0);

                    % bottom seg
                    [FemmProblem, statorinfo.BottomSegInds(ind)] ...
                        = addsegments_mfemm ( FemmProblem, ...
                                              statorinfo.node_id_sets_stator_outer_region(ind,1), ...
                                              statorinfo.node_id_sets_stator_outer_region(ind+1,1), ...
                                              segprops );
                    % top seg
                    [FemmProblem, statorinfo.TopSegInds(ind)] ...
                        = addsegments_mfemm ( FemmProblem, ...
                                              statorinfo.node_id_sets_stator_outer_region(ind,3), ...
                                              statorinfo.node_id_sets_stator_outer_region(ind+1,3), ...
                                              segprops );

                elseif (sectionangle > tau()) && ((sectionangle - tau()) > FullCircleAngleTol)
                    error ('RENEWNET:slottedfemmprob_radial:toomanypoles', ...
                        'You are attempting to draw too many poles, angle is greater than a complete circle.')
                else
                    % there is a full circle, so we'll be linking up the top
                    % and bottom to itelf
                    [edgenodes(:,1), edgenodes(:,2)] = ...
                        pol2cart ( [ 0; design.thetap * Inputs.NPolePairs; ], ...
                                     repmat (statorinfo.routerregion(ind+1), [2,1] ) );

                    % add the nodes to the problem
                    [FemmProblem, ~, nodeids] = addnodes_mfemm (FemmProblem, edgenodes(:,1), edgenodes(:,2));

                    statorinfo.node_id_sets_stator_outer_region ...
                        = [statorinfo.node_id_sets_stator_outer_region;
                           nodeids(1), nodeids(2), nodeids(1)];

%                     statorinfo.node_id_set_stator_outer_region_2 = [nodeids(3), nodeids(4), nodeids(3)];

                end

                % add arcs linking the outer segments
                FemmProblem = addarcsegments_mfemm (FemmProblem, ...
                                                   [ statorinfo.node_id_sets_stator_outer_region(ind+1,1), ...
                                                     statorinfo.node_id_sets_stator_outer_region(ind+1,2), ...
                                                     ], ...
                                                   [ statorinfo.node_id_sets_stator_outer_region(ind+1,2), ...
                                                     statorinfo.node_id_sets_stator_outer_region(ind+1,3), ...
                                                     ], ...
                                                   rad2deg(repmat(design.thetap*Inputs.NPolePairs,1,2)));

                % Add block labels for the outer air region
                [labelloc(1),labelloc(2)] = pol2cart (design.thetap * Inputs.NPolePairs, mean(statorinfo.routerregion(ind:ind+1)));


                FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                        'BlockType', Inputs.StatorOuterRegionMaterials{ind}, ...
                                        'MaxArea', Inputs.StatorOuterRegionsMeshSize(ind));
%
%                 [labelloc(1),labelloc(2)]  = pol2cart(design.thetap * Inputs.NPolePairs, Rs + design.ty/2 + statorinfo.touterregion(1) + statorinfo.touterregion(2)/2);
%
%                 FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
%                                         'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
%                                         'MaxArea', Inputs.OuterRegionsMeshSize(2));

            end

        case 'internal'
            % single outer facing stator (stator inside, magnets outside)

            % the sizes of the stator outer air regions
            if isempty (Inputs.StatorOuterRegionSize)
                Inputs.StatorOuterRegionSize = [0.8, 0.5];
            end
            % check if sizes are sensible
            if any (Inputs.StatorOuterRegionSize >= 1.0 | Inputs.StatorOuterRegionSize <= 0.0)
                error ('RENEWNET:slottedfemmproblem_radial:outersizes', ...
                       ['For an internal armature outer region sizes are ', ...
                        'specified as a fraction of the inner yoke radius ', ...
                        'and must lie in the reion 0 <= x <= 1'] );
            end
            % Check if stator outer region sizes are monotonically
            % decreasing. Keep this validation local so constructing the
            % legacy FEA oracle does not depend on an optional check package.
            assert ( all (diff (Inputs.StatorOuterRegionSize) < 0), ...
                'RENEWNET:slottedfemmproblem_radial:increasestatorouterregions', ...
                'StatorOuterRegionSize should be a monatonically decreasing vector (i.e. each value smaller than the previous).');

            % convert fractions to actual sizes
            Inputs.StatorOuterRegionSize = Inputs.StatorOuterRegionSize .* design.Ryi;

            if isempty (Inputs.StatorOuterRegionsMeshSize)
                Inputs.StatorOuterRegionsMeshSize = [ choosemesharea_mfemm(design.tm, (Rs*design.thetap), 1/5), ...
                                                      repmat(-1,1,numel(Inputs.StatorOuterRegionSize)-1) ];
            end
            assert (samesize (Inputs.StatorOuterRegionSize, Inputs.StatorOuterRegionsMeshSize), ...
                'RENEWNET:slottedfemmproblem_radial:nstatormeshsizes', ...
                'Number of supplied stator outer region mesh sizes does not match number of outer region sizes.');

            if isempty (Inputs.StatorOuterRegionMaterials)
                % FemmProblem.Materials(GapMatInd).Name
                Inputs.StatorOuterRegionMaterials = repmat ({FemmProblem.Materials(GapMatInd).Name}, 1, numel(Inputs.StatorOuterRegionSize));
            end
            assert (samesize (Inputs.StatorOuterRegionSize, Inputs.StatorOuterRegionMaterials), ...
                'RENEWNET:slottedfemmproblem_radial:nstatormaterials', ...
                'Number of supplied stator outer region material names does not match number of outer region sizes.');

            % calculate the radial positions of the outer region boundaries
            statorinfo.routerregion = [Rs - design.ty/2, Inputs.StatorOuterRegionSize];

            % calculate the thicknesses of the outer region boundaries
            statorinfo.touterregion = statorinfo.routerregion(1:end-1) - statorinfo.routerregion(2:end);

            % get a suitable tolerance to determine if we are making a full
            % circle or not
            FullCircleAngleTol = Inputs.Tol / statorinfo.routerregion(1);

            sectionangle = design.thetap * 2 * Inputs.NPolePairs;

            statorinfo.node_id_sets_stator_outer_region = statorinfo.node_id_set_stator_outer;

            for ind = 1:numel (statorinfo.touterregion)

                if (sectionangle < tau()) && ((tau()-sectionangle) > FullCircleAngleTol)
                    % there is not a full circle, so we will be making
                    % boundaries at the top and bottom. Test above is
                    % checking angle and tolerance based on actual
                    % distance, not angle

                    [edgenodes(:,1), edgenodes(:,2)] = ...
                        pol2cart ( [ 0; design.thetap * Inputs.NPolePairs; design.thetap * 2 * Inputs.NPolePairs; ], ...
                                     repmat (statorinfo.routerregion(ind+1), [3,1] ) );

                    % add the appropriate nodes to the problem
                    [FemmProblem, ~, nodeids] = addnodes_mfemm (FemmProblem, edgenodes(:,1), edgenodes(:,2));

                    statorinfo.node_id_sets_stator_outer_region = [statorinfo.node_id_sets_stator_outer_region;
                                                                   nodeids];

%                     statorinfo.node_id_set_stator_outer_region_2 = [nodeids(4), nodeids(5), nodeids(6)];

                    % add segments with periodic boundaries on the outer parts
                    [FemmProblem, ~, boundname] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Outer Periodic', 4);
%                     [FemmProblem, ~, region2boundname] = addboundaryprop_mfemm (FemmProblem, 'Radial Stator Outer Periodic', 4);

                    segprops = struct ('BoundaryMarker', boundname, 'InGroup', 0);

                    % bottom seg
                    [FemmProblem, statorinfo.BottomSegInds(ind)] ...
                        = addsegments_mfemm ( FemmProblem, ...
                                              statorinfo.node_id_sets_stator_outer_region(ind,1), ...
                                              statorinfo.node_id_sets_stator_outer_region(ind+1,1), ...
                                              segprops );
                    % top seg
                    [FemmProblem, statorinfo.TopSegInds(ind)] ...
                        = addsegments_mfemm ( FemmProblem, ...
                                              statorinfo.node_id_sets_stator_outer_region(ind,3), ...
                                              statorinfo.node_id_sets_stator_outer_region(ind+1,3), ...
                                              segprops );

                elseif (sectionangle > tau()) && ((sectionangle - tau()) > FullCircleAngleTol)
                    error ('RENEWNET:slottedfemmprob_radial:toomanypoles', ...
                        'You are attempting to draw too many poles, angle is greater than a complete circle.')
                else
                    % there is a full circle, so we'll be linking up the top
                    % and bottom to itelf
                    [edgenodes(:,1), edgenodes(:,2)] = ...
                        pol2cart ( [ 0; design.thetap * Inputs.NPolePairs; ], ...
                                     repmat (statorinfo.routerregion(ind+1), [2,1] ) );

                    % add the nodes to the problem
                    [FemmProblem, ~, nodeids] = addnodes_mfemm (FemmProblem, edgenodes(:,1), edgenodes(:,2));

                    statorinfo.node_id_sets_stator_outer_region ...
                        = [statorinfo.node_id_sets_stator_outer_region;
                           nodeids(1), nodeids(2), nodeids(1)];

%                     statorinfo.node_id_set_stator_outer_region_2 = [nodeids(3), nodeids(4), nodeids(3)];

                end

                % add arcs linking the outer segments
                FemmProblem = addarcsegments_mfemm (FemmProblem, ...
                                                   [ statorinfo.node_id_sets_stator_outer_region(ind+1,1), ...
                                                     statorinfo.node_id_sets_stator_outer_region(ind+1,2), ...
                                                     ], ...
                                                   [ statorinfo.node_id_sets_stator_outer_region(ind+1,2), ...
                                                     statorinfo.node_id_sets_stator_outer_region(ind+1,3), ...
                                                     ], ...
                                                   rad2deg(repmat(design.thetap*Inputs.NPolePairs,1,2)));

                % Add block labels for the outer air region
                [labelloc(1),labelloc(2)] = pol2cart (design.thetap * Inputs.NPolePairs, ...
                                                      statorinfo.routerregion(ind) - statorinfo.touterregion(ind)/2);


                FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
                                        'BlockType', Inputs.StatorOuterRegionMaterials{ind}, ...
                                        'MaxArea', Inputs.StatorOuterRegionsMeshSize(ind));
%
%                 [labelloc(1),labelloc(2)]  = pol2cart(design.thetap * Inputs.NPolePairs, Rs + design.ty/2 + statorinfo.touterregion(1) + statorinfo.touterregion(2)/2);
%
%                 FemmProblem.BlockLabels(end+1) = newblocklabel_mfemm (labelloc(1,1), labelloc(1,2), ...
%                                         'BlockType', FemmProblem.Materials(GapMatInd).Name, ...
%                                         'MaxArea', Inputs.OuterRegionsMeshSize(2));

            end

        case 'di'
            % double internal stator (mags on outside)
%             drawnrotors = [true, true];
%             rrotor = [ design.Rmo, design.Rmo + 2* (design.g + design.tc + design.ty/2) ];
%             drawnstatorsides = [1, 1];
%             Rs = design.Rmo(1) + design.g + design.tc + design.ty/2;
            error('not yet supported');
        case 'do'
            % double outer/external stator (mags on inside)
            error('not yet supported');

        otherwise
            error('Unrecognised ArmatureType option.')

    end

    % move the new nodes and labels
    FemmProblem = translatenewelements_mfemm (FemmProblem, elcount, XShift, YShift);

end


function FemmProblem = addcoilinsulationlabels (FemmProblem, design, Inputs, inslabellocs)

   if strncmpi (Inputs.SimType, 'm', 1)
       [FemmProblem, matinds] = addmaterials_mfemm (FemmProblem, ...
                                                    {design.MagFEASimMaterials.CoilInsulation}, ...
                                                    'MaterialsLibrary', Inputs.MaterialsLibrary);
   elseif strncmpi (Inputs.SimType, 'h', 1)
       [FemmProblem, matinds] = addmaterials_mfemm (FemmProblem, ...
                                                    {design.HeatFEASimMaterials.CoilInsulation}, ...
                                                    'MaterialsLibrary', Inputs.MaterialsLibrary );
   end

    % add the coil insulation block labels
    coilinsBlockProps.BlockType = FemmProblem.Materials(matinds).Name;
    coilinsBlockProps.MaxArea = Inputs.CoilInsRegionMeshSize;
    coilinsBlockProps.InCircuit = '';
    coilinsBlockProps.InGroup = Inputs.CoilGroup;

    % add insulation labels if requested

    for indi = 1:size (inslabellocs)
        FemmProblem = addblocklabel_mfemm( FemmProblem, ...
                                           inslabellocs(indi,1), ...
                                           inslabellocs(indi,2), ...
                                           coilinsBlockProps );
    end



end


function FemmProblem = addcircuitsandcoillabels (FemmProblem, design, Inputs, coilmatind, coillabellocs)

    NSlots = Inputs.NPolePairs*2*design.Qs/design.Poles;

    % add circuits for each winding phase
    for i = 1:design.Phases
        cname = num2str(i);
        if ~hascircuit_mfemm (FemmProblem, cname)
            FemmProblem = addcircuit_mfemm (FemmProblem, cname);
        end
        FemmProblem = setcircuitcurrent (FemmProblem, cname, Inputs.CoilCurrent(i));
    end

    coilBlockProps.BlockType = FemmProblem.Materials(coilmatind).Name;
    coilBlockProps.MaxArea = Inputs.CoilRegionMeshSize;
    coilBlockProps.InCircuit = '';
    coilBlockProps.InGroup = Inputs.CoilGroup;

    % draw the positive part of the coil circuit
    coilBlockProps.Turns = design.CoilTurns;

    % add block labels for the coils
    row = 1;
    for slotn = 1:NSlots

        for layern = 1:Inputs.NWindingLayers

            coilBlockProps.InCircuit = num2str(abs(design.WindingLayout.Phases(slotn,layern)));
            coilBlockProps.Turns = design.CoilTurns * sign (design.WindingLayout.Phases(slotn,layern));

            FemmProblem = addblocklabel_mfemm( FemmProblem, ...
                                               coillabellocs(row,1), ...
                                               coillabellocs(row,2), ...
                                               coilBlockProps);

            row = row + 1;

        end

    end

end
