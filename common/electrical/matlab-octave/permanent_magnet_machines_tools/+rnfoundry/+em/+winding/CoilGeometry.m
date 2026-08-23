classdef CoilGeometry
    properties (SetAccess = private)
        PackArea
        MeanTurnLength
        ActiveSegmentLengths
    end
    methods
        function obj = CoilGeometry(packArea, meanTurnLength, activeSegmentLengths)
            if nargin < 1, packArea = NaN; end
            if nargin < 2, meanTurnLength = NaN; end
            if nargin < 3, activeSegmentLengths = []; end
            obj.PackArea = packArea;
            obj.MeanTurnLength = meanTurnLength;
            obj.ActiveSegmentLengths = activeSegmentLengths;
        end
        function validate(obj)
            if ~(isscalar(obj.PackArea) && isfinite(obj.PackArea) && obj.PackArea > 0)
                error('rnfoundry:em:InvalidPackArea', 'PackArea must be a positive finite scalar.');
            end
            if ~(isscalar(obj.MeanTurnLength) && isfinite(obj.MeanTurnLength) && obj.MeanTurnLength > 0)
                error('rnfoundry:em:InvalidMTL', 'MeanTurnLength must be a positive finite scalar.');
            end
            if any(~isfinite(obj.ActiveSegmentLengths(:))) || any(obj.ActiveSegmentLengths(:) < 0)
                error('rnfoundry:em:InvalidActiveLength', 'Active segment lengths must be finite and non-negative.');
            end
        end
    end
end
