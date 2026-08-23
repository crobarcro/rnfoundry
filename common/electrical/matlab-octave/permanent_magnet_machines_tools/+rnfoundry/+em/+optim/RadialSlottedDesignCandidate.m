classdef RadialSlottedDesignCandidate
    %RADIALSLOTTEDDESIGNCANDIDATE Mutable-in-construction optimisation value.
    %   A candidate retains independent g, ratios, normalized variables and
    %   the legacy Hc/Wc conductor-sizing envelope.  It can therefore be
    %   infeasible after decode.  repair returns a new candidate whose Data
    %   contains the deterministic repaired design.  Canonical machines are
    %   created only by RadialSlottedDesignSpace.build.
    properties (SetAccess = private)
        Chromosome
        Data
        IsRepaired
        Compatibility
    end
    methods
        function obj = RadialSlottedDesignCandidate(chromosome, data, repaired, compatibility)
            if nargin == 0, return; end
            obj.Chromosome = chromosome(:);
            obj.Data = data;
            obj.IsRepaired = repaired;
            if nargin < 4, compatibility = struct(); end
            obj.Compatibility = compatibility;
        end
        function value = toLegacyStruct(obj)
            value = obj.Data;
        end
    end
end
