classdef RadialSlottedDesignCandidate
    %RADIALSLOTTEDDESIGNCANDIDATE Radial-slotted optimisation value object.
    %   Variables contains independent chromosome variables and construction
    %   ratios. Geometry, Winding and ConductorSizing contain progressively
    %   resolved candidate-stage state. A decoded candidate may be infeasible;
    %   a repaired candidate is consistent enough to build a canonical machine.
    %   Candidate-only g, Hc/Wc, limits and normalized variables never become
    %   canonical machine state. toLegacyStruct constructs a regression view;
    %   that flat view is not the authoritative representation.
    properties (SetAccess = private)
        Chromosome
        Variables
        Geometry
        Winding
        ConductorSizing
        IsRepaired
        Compatibility
    end
    methods
        function obj = RadialSlottedDesignCandidate(chromosome, variables, ...
                geometry, winding, conductorSizing, repaired, compatibility)
            if nargin == 0, return; end
            obj.Chromosome = chromosome(:);
            obj.Variables = variables;
            obj.Geometry = geometry;
            obj.Winding = winding;
            obj.ConductorSizing = conductorSizing;
            obj.IsRepaired = repaired;
            obj.Compatibility = compatibility;
        end
        function value = toLegacyStruct(obj)
            value = mergeStructs(obj.Variables, obj.Geometry, obj.Winding, ...
                                 obj.ConductorSizing);
        end
    end
    methods (Static)
        function obj = fromFlat(chromosome, flat, repaired, compatibility)
            variableNames = {'ArmatureType','RlVRp','LoadResistance','tyVtm', ...
                'tcVMax_tc','tsbVMax_tsb','tmVMax_tm','tbiVtm','lsVMax_ls', ...
                'DcAreaFac','BranchFac'};
            windingNames = {'Phases','qc','yd','CoilLayers','NBasicWindings', ...
                'Qcb','pb','Qc','Qs','Qsb','WindingLayout','qcn','qcd','yp', ...
                'ypn','ypd','NCoilsPerPhase','qsp','Poles','thetap','thetas'};
            conductorNames = {'CoilFillFactor','NStrands','Hc','Wc','Dc', ...
                'WireStrandDiameter','Branches','CoilsPerBranch','LgVLc'};
            variables = takeFields(flat, variableNames);
            winding = takeFields(flat, windingNames);
            conductor = takeFields(flat, conductorNames);
            geometry = removeFields(flat, [variableNames,windingNames,conductorNames]);
            obj = rnfoundry.em.optim.RadialSlottedDesignCandidate(chromosome, ...
                variables, geometry, winding, conductor, repaired, compatibility);
        end
    end
end
function out = takeFields(source, names)
out = struct();
for k=1:numel(names)
    if isfield(source,names{k}), out.(names{k})=source.(names{k}); end
end
end
function out = removeFields(source,names)
out=source;
for k=1:numel(names)
    if isfield(out,names{k}), out=rmfield(out,names{k}); end
end
end
function out = mergeStructs(varargin)
out=struct();
for j=1:nargin
    names=fieldnames(varargin{j});
    for k=1:numel(names), out.(names{k})=varargin{j}.(names{k}); end
end
end
