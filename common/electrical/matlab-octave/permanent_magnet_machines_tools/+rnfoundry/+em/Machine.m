classdef Machine
    %MACHINE Base value type for canonical electromagnetic machines.
    properties (SetAccess = private)
        PoleSpan
    end
    methods
        function obj = Machine(poleSpan)
            if nargin < 1
                poleSpan = NaN;
            end
            obj.PoleSpan = poleSpan;
        end
        function validate(obj)
            if ~(isscalar(obj.PoleSpan) && isfinite(obj.PoleSpan) && obj.PoleSpan > 0)
                error('rnfoundry:em:InvalidPoleSpan', 'PoleSpan must be a positive finite scalar.');
            end
        end
        function value = normalizedPosition(obj, position)
            value = position ./ obj.PoleSpan;
        end
        function s = toStruct(obj)
            s = struct('Schema', 'rnfoundry.em.Machine', ...
                       'SchemaVersion', 1, ...
                       'Type', class(obj), ...
                       'PoleSpan', obj.PoleSpan);
        end
    end
end
