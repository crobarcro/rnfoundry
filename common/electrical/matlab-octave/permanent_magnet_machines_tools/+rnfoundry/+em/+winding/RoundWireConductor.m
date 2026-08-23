classdef RoundWireConductor
    properties
        Material = struct()
        StrandCount = 1
        StrandDiameter = NaN
        Insulation = struct()
    end
    properties (Dependent)
        CopperAreaPerStrand
        CopperAreaPerTurn
        EquivalentCopperDiameter
        InsulatedStrandDiameter
        OccupiedAreaPerTurn
    end
    methods
        function obj = RoundWireConductor(material, count, diameter, insulation)
            if nargin > 0, obj.Material = material; end
            if nargin > 1, obj.StrandCount = count; end
            if nargin > 2, obj.StrandDiameter = diameter; end
            if nargin > 3, obj.Insulation = insulation; end
            if nargin > 0, obj.validate(); end
        end
        function v=get.CopperAreaPerStrand(obj), v=pi*(obj.StrandDiameter/2)^2; end
        function v=get.CopperAreaPerTurn(obj), v=obj.StrandCount*obj.CopperAreaPerStrand; end
        function v=get.EquivalentCopperDiameter(obj), v=obj.StrandDiameter*sqrt(obj.StrandCount); end
        function v=get.InsulatedStrandDiameter(obj), v=rnfoundry.em.winding.insulatedWireDiameter(obj.StrandDiameter); end
        function v=get.OccupiedAreaPerTurn(obj), v=obj.StrandCount*pi*(obj.InsulatedStrandDiameter/2)^2; end
        function validate(obj)
            if ~(isscalar(obj.StrandCount) && obj.StrandCount >= 1 && obj.StrandCount == fix(obj.StrandCount)), error('rnfoundry:em:InvalidStrandCount','StrandCount must be a positive integer.'); end
            if ~(isscalar(obj.StrandDiameter) && isfinite(obj.StrandDiameter) && obj.StrandDiameter > 0), error('rnfoundry:em:InvalidStrandDiameter','StrandDiameter must be positive.'); end
        end
        function r=dcResistancePerLength(obj, resistivity), if nargin<2, resistivity=obj.resistivity(); end; r=resistivity/obj.CopperAreaPerTurn; end
        function rho=resistivity(obj)
            rho=1.7e-8;
            if isstruct(obj.Material) && isfield(obj.Material,'Resistivity'), rho=obj.Material.Resistivity; elseif isnumeric(obj.Material) && isscalar(obj.Material), rho=obj.Material; end
        end
        function s=toStruct(obj), s=struct('Type','RoundWireConductor','Material',obj.Material,'StrandCount',obj.StrandCount,'StrandDiameter',obj.StrandDiameter,'Insulation',obj.Insulation); end
    end
    methods (Static)
        function obj=fromStruct(s), obj=rnfoundry.em.winding.RoundWireConductor(s.Material,s.StrandCount,s.StrandDiameter,s.Insulation); end
    end
end
