classdef RotaryMachine < rnfoundry.em.Machine
    %ROTARYMACHINE Base value class for rotary electromagnetic machines.
    %   PoleSpan and the dependent engineering alias thetap are mechanical
    %   radians per magnetic pole. electricalFrequency accepts rad/s.
    properties (Dependent)
        thetap
    end
    methods
        function obj = RotaryMachine(poleSpan)
            if nargin < 1
                poleSpan = NaN;
            end
            obj@rnfoundry.em.Machine(poleSpan);
        end
        function value = get.thetap(obj)
            value = obj.PoleSpan;
        end
        function frequency = electricalFrequency(obj, angularSpeed)
            frequency = angularSpeed ./ (2 .* obj.PoleSpan);
        end
    end
end
