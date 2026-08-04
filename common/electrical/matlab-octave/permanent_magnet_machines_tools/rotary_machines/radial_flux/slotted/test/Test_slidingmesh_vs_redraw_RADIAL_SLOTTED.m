function report = Test_slidingmesh_vs_redraw_RADIAL_SLOTTED (nPositions)
%TEST_SLIDINGMESH_VS_REDRAW_RADIAL_SLOTTED Compare static rotation methods.
%
% This is the static magnetic part of the radial-machine tutorial.  It does
% not fit the complete machine model or run an ODE simulation.  The test
% compares the gauge-invariant winding flux-linkage waveform and tooth flux
% density obtained by reusing one AGE mesh with results obtained by drawing
% and meshing the rotor again at every position.

    if nargin < 1
        nPositions = 3;
    end

    tic;
    sliding = run_static_case ('SlidingMesh', nPositions);
    toc;
    tic;
    redraw = run_static_case ('MagnetRedraw', nPositions);
    toc;

    report.fluxLinkage = compare_signal (...
        redraw.fluxLinkage, sliding.fluxLinkage, 0.01, 1e-5);
    report.armatureToothFluxDensity = compare_signal (...
        redraw.armatureToothFluxDensity, ...
        sliding.armatureToothFluxDensity, 0.02, 1e-4);
    report.passed = report.fluxLinkage.passed ...
                    && report.armatureToothFluxDensity.passed;

    fprintf ('Sliding mesh versus redraw static radial-machine test:\n');
    fprintf ('  winding flux linkage: max |delta| = %.6g, limit = %.6g\n', ...
             report.fluxLinkage.maxAbsoluteError, ...
             report.fluxLinkage.limit);
    fprintf ('  tooth flux density:   max |delta| = %.6g, limit = %.6g\n', ...
             report.armatureToothFluxDensity.maxAbsoluteError, ...
             report.armatureToothFluxDensity.limit);

    assert (report.passed, ...
            'RENEWNET:TestSlidingMesh:StaticResultsDiffer', ...
            'Sliding-mesh and redraw static results exceeded tolerance.');
end


function results = run_static_case (rotationMethod, nPositions)
    design = example_design ();
    simoptions = struct ();
    design = completedesign_RADIAL_SLOTTED (design, simoptions);
    design.Rgm = mean ([design.Rmo, design.Rai]);

    simoptions.GetVariableGapForce = false;
    simoptions.SkipInductanceFEA = true;
    simoptions.NMagFEAPositions = nPositions;
    simoptions.MagFEASim.SolveMethod = 'femmsession';
    simoptions.MagFEASim.RotationMethod = rotationMethod;
    simoptions.MagFEASim.UseParFor = false;
    simoptions.MagFEASim.UseFemm = false;
    simoptions.MagFEASim.QuietFemm = true;

    [design, ~] = simfun_RADIAL_SLOTTED (design, simoptions);
    if strcmpi (rotationMethod, 'SlidingMesh')
        assert_age_construction (design.FemmProblem);
    end
    results.fluxLinkage = winding_flux_linkage (design);
    results.armatureToothFluxDensity = design.ArmatureToothFluxDensity;
end


function assert_age_construction (problem)
    ageIndices = find ([problem.BoundaryProps.BdryType] == 6 ...
                       | [problem.BoundaryProps.BdryType] == 7);
    assert (numel (ageIndices) == 1, ...
            'RENEWNET:TestSlidingMesh:AGECount', ...
            'The complete annular interface must use exactly one AGE property.');
    ageName = problem.BoundaryProps(ageIndices).Name;
    ageArcIndices = find (strcmp ({problem.ArcSegments.BoundaryMarker}, ageName));
    assert (numel (ageArcIndices) >= 2 ...
            && all ([problem.ArcSegments(ageArcIndices).MaxSegDegrees] > 0), ...
            'RENEWNET:TestSlidingMesh:AGEArcs', ...
            'Both AGE sides must use the shared property and degree segmentation.');
    assert (isequal (problem.AGEBoundNames, {ageName}), ...
            'RENEWNET:TestSlidingMesh:AGEName', ...
            'The reusable-session AGE name does not identify the shared boundary.');
end


function design = example_design ()
    design.Poles = 12;
    design.Phases = 3;
    design.CoilLayers = 2;
    design.Qc = design.Phases * design.Poles;
    design.qc = fr (design.Qc, design.Poles * design.Phases);
    design.yd = 4;
    design.CoilFillFactor = 0.6;
    design.CoilTurns = 200;
    design.Branches = 1;

    design.Ryo = 95e-3;
    design.tm = 6.3e-3;
    design.tbi = 29.9523e-3;
    design.ty = 17.4e-3;
    design.tc = [16.4960e-3, 2.1995e-3];
    design.tsb = 2.604e-3;
    design.tsg = 1.7364e-3;
    design.g = 2e-3;
    design.thetam = (2*pi / design.Poles) * 0.667;
    design.thetacg = 84.7661e-3;
    design.thetacy = 93.0181e-3;
    design.thetasg = 38.6622e-3;
    design.ls = 88.9e-3;

    design.ArmatureType = 'external';
    design.MagnetPolarisation = 'radial';
    design.MagFEASimMaterials.AirGap = 'Air';
    design.MagFEASimMaterials.Magnet = 'NdFeB 40 MGOe';
    design.MagFEASimMaterials.FieldBackIron = '1117 Steel';
    design.MagFEASimMaterials.ArmatureYoke = ...
        design.MagFEASimMaterials.FieldBackIron;
    design.MagFEASimMaterials.ArmatureCoil = '36 AWG';
end


function fluxLinkage = winding_flux_linkage (design)
% This is the flux-linkage part of finfun_RADIAL_SLOTTED, kept local so the
% test stops before its material calculations and ODE preparation.
    [slotPos, order] = sort (design.intAdata.slotPos);
    slotIntA = design.intAdata.slotIntA(order,:,:);
    [slotPos, uniqueIndices] = unique (slotPos);
    slotIntA = slotIntA(uniqueIndices,:,:);

    pos = slotPos(slotPos <= slotPos(1) + 2);
    intA = slotIntA(slotPos <= slotPos(1) + 2,1:2,1);
    if pos(end) < slotPos(1) + 2
        pos(end+1) = slotPos(1) + 2;
        intA(end+1,:) = interp1 (slotPos, slotIntA(:,1:2,1), pos(end));
    end

    intAslm(1) = slmengine (pos, intA(:,1), ...
                           'EndCon', 'periodic', ...
                           'knots', ceil (numel (pos) / 2), ...
                           'Plot', 'off');
    intAslm(2) = slmengine (pos, intA(:,2), ...
                           'EndCon', 'periodic', ...
                           'knots', ceil (numel (pos) / 2), ...
                           'Plot', 'off');

    coilPitch = design.thetas * design.yd / design.thetap;
    searchPositions = linspace (0, 1, 1000);
    searchFlux = fluxlinkagefrmintAslm (intAslm, coilPitch, ...
        searchPositions, design.CoilTurns, design.CoilArea, ...
        'Skew', design.MagnetSkew, ...
        'NSkewPositions', design.NSkewMagnetsPerPole);
    [~, peakIndex] = max (abs (searchFlux));

    fluxLinkage = fluxlinkagefrmintAslm (intAslm, coilPitch, ...
        linspace (0, 2, 200), design.CoilTurns, design.CoilArea, ...
        'Skew', design.MagnetSkew, ...
        'NSkewPositions', design.NSkewMagnetsPerPole, ...
        'Offset', searchPositions(peakIndex(1)));
end


function comparison = compare_signal (reference, candidate, ...
                                      relativeTolerance, absoluteTolerance)
    assert (isequal (size (reference), size (candidate)), ...
            'RENEWNET:TestSlidingMesh:ResultSize', ...
            'Static result arrays have different sizes.');
    comparison.maxAbsoluteError = max (abs (candidate(:) - reference(:)));
    comparison.scale = max ([abs(reference(:)); abs(candidate(:))]);
    comparison.limit = absoluteTolerance ...
                       + relativeTolerance * comparison.scale;
    comparison.passed = comparison.maxAbsoluteError <= comparison.limit;
end
