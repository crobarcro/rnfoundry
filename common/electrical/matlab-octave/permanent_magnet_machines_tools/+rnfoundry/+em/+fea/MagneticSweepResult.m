classdef MagneticSweepResult
    %MAGNETICSWEEPRESULT Value-semantic raw magnetic FEA observations.
    properties (SetAccess = private)
        Positions
        CoggingTorque
        DirectFluxLinkage
        ToothFluxDensity
        SlotVectorPotential
        SlotFlux
        AirGapField
        CoilArea
        ArmatureIronArea
        PerPoleRadialForce
        Provenance
    end
    methods
        function obj = MagneticSweepResult(s)
            required = {'Positions','CoggingTorque','DirectFluxLinkage', ...
                'ToothFluxDensity','SlotVectorPotential','SlotFlux', ...
                'AirGapField','CoilArea','ArmatureIronArea', ...
                'PerPoleRadialForce','Provenance'};
            if nargin ~= 1 || ~isstruct(s) || ~all(isfield(s,required))
                error('rnfoundry:em:InvalidMagneticSweepResult', ...
                      'MagneticSweepResult requires all documented raw-result fields.');
            end
            n = numel(s.Positions);
            if n < 2 || any(~isfinite(s.Positions(:))) || ...
                    numel(s.CoggingTorque) ~= n || ...
                    numel(s.ToothFluxDensity) ~= n || ...
                    size(s.DirectFluxLinkage,1) ~= n || ...
                    size(s.AirGapField.Magnitude,1) ~= n
                error('rnfoundry:em:InvalidMagneticSweepResult', ...
                      'Raw observation dimensions must agree with Positions.');
            end
            for k = 1:numel(required), obj.(required{k}) = s.(required{k}); end
        end
    end
end
