classdef RadialSlottedCoilGeometry < rnfoundry.em.winding.CoilGeometry
    %RADIALSLOTTEDCOILGEOMETRY Exact usable areas for every coil-side region.
    properties (SetAccess = private)
        ls
        PitchLength
        SlotWidth
        CoilInsulationThickness
        LayerPackAreas
        TotalPackArea
    end
    methods
        function obj = RadialSlottedCoilGeometry(layerAreas,ls,pitchLength,slotWidth,activeLengths,insulationThickness)
            if nargin<5, activeLengths=[]; end
            if nargin<6, insulationThickness=0; end
            layerAreas=layerAreas(:);
            meanTurnLength=rnfoundry.em.winding.rectCoilMTL(ls,pitchLength,slotWidth);
            obj@rnfoundry.em.winding.CoilGeometry(min(layerAreas),meanTurnLength,activeLengths);
            obj.LayerPackAreas=layerAreas; obj.TotalPackArea=sum(layerAreas);
            obj.ls=ls; obj.PitchLength=pitchLength; obj.SlotWidth=slotWidth;
            obj.CoilInsulationThickness=insulationThickness; obj.validate();
        end
        function validate(obj)
            validate@rnfoundry.em.winding.CoilGeometry(obj);
            v=[obj.ls,obj.PitchLength,obj.SlotWidth,obj.CoilInsulationThickness];
            if any(~isfinite(v))||any(v(1:3)<=0)||v(4)<0||isempty(obj.LayerPackAreas)||any(~isfinite(obj.LayerPackAreas))||any(obj.LayerPackAreas<=0)
                error('rnfoundry:em:InvalidCoilGeometry','Radial coil geometry is invalid.');
            end
            tol=1e-12*max(1,obj.TotalPackArea);
            if abs(obj.PackArea-min(obj.LayerPackAreas))>tol||abs(obj.TotalPackArea-sum(obj.LayerPackAreas))>tol
                error('rnfoundry:em:InconsistentPackArea','PackArea/TotalPackArea disagree with LayerPackAreas.');
            end
        end
        function s=toStruct(obj)
            s=struct('Schema','rnfoundry.em.winding.CoilGeometry','SchemaVersion',2, ...
             'Type','RadialSlottedCoilGeometry','PackArea',obj.PackArea, ...
             'LayerPackAreas',obj.LayerPackAreas,'TotalPackArea',obj.TotalPackArea, ...
             'ls',obj.ls,'PitchLength',obj.PitchLength,'SlotWidth',obj.SlotWidth, ...
             'ActiveSegmentLengths',obj.ActiveSegmentLengths, ...
             'CoilInsulationThickness',obj.CoilInsulationThickness);
        end
    end
    methods (Static)
        function obj=fromStruct(s)
            rnfoundry.em.validateStructEnvelope(s,'rnfoundry.em.winding.CoilGeometry','RadialSlottedCoilGeometry');
            if isfield(s,'LayerPackAreas'), areas=s.LayerPackAreas; else, areas=s.PackArea; end
            if isfield(s,'PackArea')&&abs(s.PackArea-min(areas))>1e-12*max(1,abs(s.PackArea)), error('rnfoundry:em:InconsistentPackArea','Serialized PackArea disagrees with LayerPackAreas.'); end
            if isfield(s,'TotalPackArea')&&abs(s.TotalPackArea-sum(areas))>1e-12*max(1,abs(s.TotalPackArea)), error('rnfoundry:em:InconsistentPackArea','Serialized TotalPackArea disagrees with LayerPackAreas.'); end
            obj=rnfoundry.em.winding.RadialSlottedCoilGeometry(areas,s.ls,s.PitchLength,s.SlotWidth,s.ActiveSegmentLengths,s.CoilInsulationThickness);
        end
    end
end
