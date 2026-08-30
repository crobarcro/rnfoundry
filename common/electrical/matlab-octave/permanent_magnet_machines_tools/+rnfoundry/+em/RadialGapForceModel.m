classdef RadialGapForceModel
    %RADIALGAPFORCEMODEL Legacy quadratic full-machine closing-force fit.
    properties (SetAccess = private)
        Polynomial
        CharacterizationDomain
    end
    methods
        function obj = RadialGapForceModel(polynomial,domain)
            if nargin ~= 2 || ~isstruct(polynomial) ...
                    || ~isfield(polynomial,'Coefficients') ...
                    || ~isnumeric(polynomial.Coefficients) ...
                    || ~isreal(polynomial.Coefficients) ...
                    || any(~isfinite(polynomial.Coefficients(:))) ...
                    || ~isnumeric(domain) ...
                    || ~isreal(domain) || numel(domain) ~= 2 ...
                    || any(~isfinite(domain(:))) || domain(2) < domain(1)
                error('rnfoundry:em:InvalidRadialGapForceModel','Invalid polynomial or domain.');
            end
            obj.Polynomial = polynomial;
            obj.CharacterizationDomain = domain(:).';
        end
        function force = evaluate(obj,radialDisplacement)
            % Input is negative-x eccentric field displacement [m]; output is
            % legacy positive full-machine closing-force magnitude [N].
            if ~isnumeric(radialDisplacement) || ~isreal(radialDisplacement) ...
                    || any(~isfinite(radialDisplacement(:)))
                error('rnfoundry:em:InvalidRadialDisplacement', ...
                    'Radial displacement must contain finite real numbers.');
            end
            originalSize = size(radialDisplacement);
            force = polyvaln(obj.Polynomial,radialDisplacement(:));
            force = reshape(force,originalSize); % legacy polynomial extrapolation is intentional
        end
    end
end
