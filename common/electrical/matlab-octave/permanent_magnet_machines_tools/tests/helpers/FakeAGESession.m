classdef FakeAGESession < handle
    %FAKEAGESESSION Minimal cross-engine recorder for positioner unit tests.
    properties
        Names = {}
        InnerAngles = []
        OuterAngles = []
    end
    methods
        function setAGEPosition(obj,name,innerAngle,outerAngle)
            obj.Names{end+1}=name;
            obj.InnerAngles(end+1)=innerAngle;
            obj.OuterAngles(end+1)=outerAngle;
        end
    end
end
