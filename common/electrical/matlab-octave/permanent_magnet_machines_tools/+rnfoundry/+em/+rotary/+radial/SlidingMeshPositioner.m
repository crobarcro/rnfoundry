classdef SlidingMeshPositioner
    %SLIDINGMESHPOSITIONER Radial AGE positioning policy (angles in radians).
    properties (SetAccess = private)
        ArmaturePosition
        BoundaryNames
    end
    methods
        function obj = SlidingMeshPositioner(armaturePosition, boundaryNames)
            if ~(strcmp(armaturePosition,'external') || strcmp(armaturePosition,'internal'))
                error('rnfoundry:em:InvalidArmaturePosition', ...
                      'Armature position must be internal or external.');
            end
            if ~iscell(boundaryNames) || isempty(boundaryNames)
                error('rnfoundry:em:InvalidAGEBoundaries','AGE boundary names must be a nonempty cell array.');
            end
            obj.ArmaturePosition = armaturePosition;
            obj.BoundaryNames = boundaryNames;
        end
        function [innerAngle, outerAngle] = angles(obj, position)
            degrees = position .* (180 ./ pi);
            if strcmp(obj.ArmaturePosition,'external')
                innerAngle = degrees; outerAngle = 0;
            else
                innerAngle = 0; outerAngle = degrees;
            end
        end
        function apply(obj, session, position)
            [innerAngle,outerAngle] = obj.angles(position);
            for k = 1:numel(obj.BoundaryNames)
                session.setAGEPosition(obj.BoundaryNames{k},innerAngle,outerAngle);
            end
        end
    end
end
