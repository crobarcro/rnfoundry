classdef RotaryMachine < rnfoundry.em.Machine
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
