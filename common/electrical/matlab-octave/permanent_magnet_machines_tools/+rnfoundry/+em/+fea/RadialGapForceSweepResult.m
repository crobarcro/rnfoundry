classdef RadialGapForceSweepResult
    %RADIALGAPFORCESWEEPRESULT Raw full-machine eccentric closing-force samples.
    % Displacements are field-assembly translations toward negative global x
    % in metres. ClosingForce is the absolute global-x force in newtons for
    % the complete full-machine, stack-length-scaled FEM problem.
    properties (SetAccess = private)
        Displacements
        ClosingForce
        Provenance
    end
    methods
        function obj = RadialGapForceSweepResult(displacements,force,provenance)
            if nargin ~= 3 || ~isnumeric(displacements) || ~isnumeric(force) ...
                    || ~isreal(displacements) || ~isreal(force) ...
                    || ~isvector(displacements) || ~isvector(force) ...
                    || isempty(displacements) || numel(displacements) ~= numel(force) ...
                    || any(~isfinite(displacements(:))) || any(~isfinite(force(:))) ...
                    || ~isstruct(provenance)
                error('rnfoundry:em:InvalidRadialGapForceSweepResult', ...
                    'Displacements and force must be aligned finite real vectors.');
            end
            obj.Displacements = displacements(:);
            obj.ClosingForce = force(:);
            obj.Provenance = provenance;
        end
    end
end
