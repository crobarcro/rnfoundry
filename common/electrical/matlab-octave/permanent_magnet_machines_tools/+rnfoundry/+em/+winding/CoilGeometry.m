classdef CoilGeometry
    properties
        PackArea = NaN
        MeanTurnLength = NaN
        ActiveSegmentLengths = []
    end
    methods
        function obj=CoilGeometry(area,mtl,active)
            if nargin>0, obj.PackArea=area; end; if nargin>1, obj.MeanTurnLength=mtl; end; if nargin>2, obj.ActiveSegmentLengths=active; end
        end
        function validate(obj)
            if ~(isscalar(obj.PackArea)&&isfinite(obj.PackArea)&&obj.PackArea>0), error('rnfoundry:em:InvalidPackArea','PackArea must be positive.'); end
            if ~(isscalar(obj.MeanTurnLength)&&isfinite(obj.MeanTurnLength)&&obj.MeanTurnLength>0), error('rnfoundry:em:InvalidMTL','MeanTurnLength must be positive.'); end
            if any(obj.ActiveSegmentLengths<0), error('rnfoundry:em:InvalidActiveLength','Active lengths cannot be negative.'); end
        end
    end
end
