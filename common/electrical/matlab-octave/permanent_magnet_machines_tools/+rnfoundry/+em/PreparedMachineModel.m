classdef PreparedMachineModel
    %PREPAREDMACHINEMODEL Immutable-by-interface numerical preparation boundary.
    properties (SetAccess = private)
        Machine
        Magnetic
        Circuit
        Losses
        GapForce
        MassProperties
        Diagnostics
    end
    methods
        function obj = PreparedMachineModel(machine,magnetic,gapForce)
            if nargin < 3, gapForce = []; end
            if ~isa(machine,'rnfoundry.em.Machine') ...
                    || ~isa(magnetic,'rnfoundry.em.PreparedMagneticModel')
                error('rnfoundry:em:InvalidPreparedMachineModel', ...
                    'A canonical machine and prepared magnetic section are required.');
            end
            if ~isempty(gapForce) && ~isa(gapForce,'rnfoundry.em.RadialGapForceModel')
                error('rnfoundry:em:InvalidPreparedMachineModel','GapForce has an invalid type.');
            end
            obj.Machine=machine; obj.Magnetic=magnetic;
            obj.Circuit=[]; obj.Losses=[]; obj.GapForce=gapForce;
            obj.MassProperties=[]; obj.Diagnostics=[];
        end
        function result = withGapForce(obj,gapForce)
            result = rnfoundry.em.PreparedMachineModel(obj.Machine,obj.Magnetic,gapForce);
        end
    end
end
