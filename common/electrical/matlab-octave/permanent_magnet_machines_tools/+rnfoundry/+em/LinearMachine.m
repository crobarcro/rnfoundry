classdef LinearMachine < rnfoundry.em.Machine
    %LINEARMACHINE Base value class for linear electromagnetic machines.
    %   PoleSpan is expressed in metres. This class adds no topology or
    %   workflow state; concrete physical machines use composition.
    methods
        function obj = LinearMachine(poleSpan)
            if nargin < 1
                poleSpan = NaN;
            end
            obj@rnfoundry.em.Machine(poleSpan);
        end
    end
end
