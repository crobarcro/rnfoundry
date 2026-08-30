classdef PreparedMagneticModel
    %PREPAREDMAGNETICMODEL Fitted magnetic section of a prepared machine.
    properties (SetAccess = private)
        FluxLinkageModel
        CoggingTorqueModel
    end
    methods
        function obj = PreparedMagneticModel(fluxModel,coggingModel)
            if ~isa(fluxModel,'rnfoundry.em.FluxLinkageModel') ...
                    || ~isa(coggingModel,'rnfoundry.em.CoggingTorqueModel')
                error('rnfoundry:em:InvalidPreparedMagneticModel', ...
                    'Both fitted magnetic model value objects are required.');
            end
            obj.FluxLinkageModel=fluxModel;
            obj.CoggingTorqueModel=coggingModel;
        end
    end
end
