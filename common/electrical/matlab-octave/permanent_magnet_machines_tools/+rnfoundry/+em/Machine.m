classdef Machine
    %MACHINE Base value class for canonical electromagnetic machines.
    %   PoleSpan is the physical extent of one magnetic pole along the
    %   motion coordinate (metres for linear machines, radians for rotary
    %   machines). Stored state has private setters. Use versioned structs
    %   returned by toStruct for persistence rather than saved class objects.
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
