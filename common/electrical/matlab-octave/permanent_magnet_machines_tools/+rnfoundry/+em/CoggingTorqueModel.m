classdef CoggingTorqueModel
    %COGGINGTORQUEMODEL Periodic cogging torque versus normalized position.
    %   Position is normalized in pole spans.  The public fit has period two.
    properties (SetAccess = private)
        Fit
        Peak
    end
    methods
        function obj = CoggingTorqueModel(fit, peak)
            if nargin ~= 2 || ~isstruct(fit) || isempty(fit) ...
                    || ~isfield(fit,'period') || abs(fit.period-2) > 100*eps ...
                    || ~(isscalar(peak) && isfinite(peak))
                error('rnfoundry:em:InvalidCoggingTorqueModel', ...
                    'A nonempty periodic two-pole SLM fit and finite peak are required.');
            end
            obj.Fit=fit; obj.Peak=peak;
        end
        function value = evaluate(obj, position)
            if ~isnumeric(position) || any(~isfinite(position(:)))
                error('rnfoundry:em:InvalidModelPosition','position must be finite numeric data.');
            end
            value=periodicslmeval(position,obj.Fit,0,false);
        end
    end
end
