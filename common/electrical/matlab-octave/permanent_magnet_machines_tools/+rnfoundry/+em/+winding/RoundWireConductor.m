classdef RoundWireConductor
    properties (SetAccess = private)
        Material
        StrandCount
        StrandDiameter
        Insulation
    end
    properties (Dependent)
        CopperAreaPerStrand
        CopperAreaPerTurn
        EquivalentCopperDiameter
        InsulatedStrandDiameter
        OccupiedAreaPerTurn
    end
    methods
        function obj = RoundWireConductor(material, strandCount, strandDiameter, insulation)
            if nargin < 1, material = struct(); end
            if nargin < 2, strandCount = 1; end
            if nargin < 3, strandDiameter = NaN; end
            if nargin < 4, insulation = struct('Type', 'LegacyEnamelCorrelation'); end
            obj.Material = material;
            obj.StrandCount = strandCount;
            obj.StrandDiameter = strandDiameter;
            obj.Insulation = insulation;
            obj.validate();
        end
        function value = get.CopperAreaPerStrand(obj)
            value = pi .* (obj.StrandDiameter ./ 2).^2;
        end
        function value = get.CopperAreaPerTurn(obj)
            value = obj.StrandCount .* obj.CopperAreaPerStrand;
        end
        function value = get.EquivalentCopperDiameter(obj)
            value = obj.StrandDiameter .* sqrt(obj.StrandCount);
        end
        function value = get.InsulatedStrandDiameter(obj)
            value = rnfoundry.em.winding.insulatedWireDiameter(obj.StrandDiameter);
        end
        function value = get.OccupiedAreaPerTurn(obj)
            value = obj.StrandCount .* pi .* (obj.InsulatedStrandDiameter ./ 2).^2;
        end
        function validate(obj)
            if ~(isscalar(obj.StrandCount) && isfinite(obj.StrandCount) ...
                    && obj.StrandCount >= 1 && obj.StrandCount == fix(obj.StrandCount))
                error('rnfoundry:em:InvalidStrandCount', 'StrandCount must be a positive integer.');
            end
            if ~(isscalar(obj.StrandDiameter) && isfinite(obj.StrandDiameter) && obj.StrandDiameter > 0)
                error('rnfoundry:em:InvalidStrandDiameter', 'StrandDiameter must be positive.');
            end
        end
        function resistance = dcResistancePerLength(obj, resistivity)
            if nargin < 2
                resistivity = obj.resistivity();
            end
            resistance = resistivity ./ obj.CopperAreaPerTurn;
        end
        function value = resistivity(obj)
            value = 1.7e-8;
            if isstruct(obj.Material) && isfield(obj.Material, 'Resistivity')
                value = obj.Material.Resistivity;
            elseif isnumeric(obj.Material) && isscalar(obj.Material)
                value = obj.Material;
            end
        end
        function s = toStruct(obj)
            s = struct('Schema', 'rnfoundry.em.winding.Conductor', ...
                       'SchemaVersion', 1, 'Type', 'RoundWireConductor', ...
                       'Material', obj.Material, 'StrandCount', obj.StrandCount, ...
                       'StrandDiameter', obj.StrandDiameter, 'Insulation', obj.Insulation);
        end
    end
    methods (Static)
        function obj = fromStruct(s)
            if ~isfield(s, 'Type') || ~strcmp(s.Type, 'RoundWireConductor')
                error('rnfoundry:em:UnsupportedType', 'Unsupported conductor type.');
            end
            obj = rnfoundry.em.winding.RoundWireConductor( ...
                s.Material, s.StrandCount, s.StrandDiameter, s.Insulation);
        end
    end
end
