classdef Machine
    %MACHINE Base value type for canonical electromagnetic machines.
    properties
        PoleSpan = NaN
    end
    methods
        function obj = Machine(poleSpan)
            if nargin > 0, obj.PoleSpan = poleSpan; end
        end
        function validate(obj)
            if ~(isscalar(obj.PoleSpan) && isfinite(obj.PoleSpan) && obj.PoleSpan > 0)
                error('rnfoundry:em:InvalidPoleSpan', 'PoleSpan must be positive.');
            end
        end
        function x = normalizedPosition(obj, q), x = q ./ obj.PoleSpan; end
        function s = toStruct(obj)
            s = struct('SchemaVersion', 1, 'Type', class(obj), 'PoleSpan', obj.PoleSpan);
        end
    end
end
