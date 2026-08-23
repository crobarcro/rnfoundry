classdef RadialSlottedCoilGeometry < rnfoundry.em.winding.CoilGeometry
    properties
        ls = NaN
        PitchLength = NaN
        SlotWidth = NaN
    end
    methods
        function obj=RadialSlottedCoilGeometry(area,ls,pitchLength,slotWidth,active)
            if nargin<5, active=[]; end
            if nargin==0, area=NaN; ls=NaN; pitchLength=NaN; slotWidth=NaN; end
            extra=0;
            if isfinite(pitchLength), extra=0; end
            mtl=rnfoundry.em.winding.rectCoilMTL(ls,pitchLength,slotWidth);
            obj@rnfoundry.em.winding.CoilGeometry(area,mtl,active);
            obj.ls=ls; obj.PitchLength=pitchLength; obj.SlotWidth=slotWidth;
        end
        function s=toStruct(obj), s=struct('Type','RadialSlottedCoilGeometry','PackArea',obj.PackArea,'ls',obj.ls,'PitchLength',obj.PitchLength,'SlotWidth',obj.SlotWidth,'ActiveSegmentLengths',obj.ActiveSegmentLengths); end
    end
    methods (Static)
        function obj=fromStruct(s), obj=rnfoundry.em.winding.RadialSlottedCoilGeometry(s.PackArea,s.ls,s.PitchLength,s.SlotWidth,s.ActiveSegmentLengths); end
    end
end
