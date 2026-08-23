classdef RadialSlottedCoilGeometry < rnfoundry.em.winding.CoilGeometry
    properties (SetAccess = private)
        ls
        PitchLength
        SlotWidth
        CoilInsulationThickness
    end
    methods
        function obj = RadialSlottedCoilGeometry(packArea, ls, pitchLength, slotWidth, activeLengths, insulationThickness)
            if nargin < 5, activeLengths = []; end
            if nargin < 6, insulationThickness = 0; end
            meanTurnLength = rnfoundry.em.winding.rectCoilMTL(ls, pitchLength, slotWidth);
            obj@rnfoundry.em.winding.CoilGeometry(packArea, meanTurnLength, activeLengths);
            obj.ls = ls;
            obj.PitchLength = pitchLength;
            obj.SlotWidth = slotWidth;
            obj.CoilInsulationThickness = insulationThickness;
            obj.validate();
        end
        function validate(obj)
            validate@rnfoundry.em.winding.CoilGeometry(obj);
            values = [obj.ls, obj.PitchLength, obj.SlotWidth, obj.CoilInsulationThickness];
            if any(~isfinite(values)) || any(values(1:3) <= 0) || obj.CoilInsulationThickness < 0
                error('rnfoundry:em:InvalidCoilGeometry', 'Radial coil geometry is invalid.');
            end
        end
        function s = toStruct(obj)
            s = struct('Schema', 'rnfoundry.em.winding.CoilGeometry', ...
                       'SchemaVersion', 1, 'Type', 'RadialSlottedCoilGeometry', ...
                       'PackArea', obj.PackArea, 'ls', obj.ls, ...
                       'PitchLength', obj.PitchLength, 'SlotWidth', obj.SlotWidth, ...
                       'ActiveSegmentLengths', obj.ActiveSegmentLengths, ...
                       'CoilInsulationThickness', obj.CoilInsulationThickness);
        end
    end
    methods (Static)
        function obj = fromStruct(s)
            if ~isfield(s, 'Type') || ~strcmp(s.Type, 'RadialSlottedCoilGeometry')
                error('rnfoundry:em:UnsupportedType', 'Unsupported coil geometry type.');
            end
            obj = rnfoundry.em.winding.RadialSlottedCoilGeometry( ...
                s.PackArea, s.ls, s.PitchLength, s.SlotWidth, ...
                s.ActiveSegmentLengths, s.CoilInsulationThickness);
        end
    end
end
