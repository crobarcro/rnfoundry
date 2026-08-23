classdef LinearMachine < rnfoundry.em.Machine
    methods
        function obj = LinearMachine(poleSpan), if nargin < 1, poleSpan = NaN; end; obj@rnfoundry.em.Machine(poleSpan); end
    end
end
