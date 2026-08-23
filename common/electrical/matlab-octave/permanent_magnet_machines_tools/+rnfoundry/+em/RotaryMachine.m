classdef RotaryMachine < rnfoundry.em.Machine
    properties (Dependent)
        thetap
    end
    methods
        function obj = RotaryMachine(poleSpan), if nargin < 1, poleSpan = NaN; end; obj@rnfoundry.em.Machine(poleSpan); end
        function v = get.thetap(obj), v = obj.PoleSpan; end
        function f = electricalFrequency(obj, angularSpeed), f = angularSpeed ./ (2*pi/obj.PoleSpan); end
    end
end
