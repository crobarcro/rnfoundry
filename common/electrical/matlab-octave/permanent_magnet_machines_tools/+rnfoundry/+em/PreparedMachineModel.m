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
        function obj = PreparedMachineModel(machine,magnetic)
            if ~isa(machine,'rnfoundry.em.Machine') ...
                    || ~isa(magnetic,'rnfoundry.em.PreparedMagneticModel')
                error('rnfoundry:em:InvalidPreparedMachineModel', ...
                    'A canonical machine and prepared magnetic section are required.');
            end
            obj.Machine=machine; obj.Magnetic=magnetic;
            obj.Circuit=[]; obj.Losses=[]; obj.GapForce=[];
            obj.MassProperties=[]; obj.Diagnostics=[];
        end
    end
end
