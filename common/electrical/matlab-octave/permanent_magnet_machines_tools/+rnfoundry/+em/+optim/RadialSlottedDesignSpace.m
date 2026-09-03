classdef RadialSlottedDesignSpace
    %RADIALSLOTTEDDESIGNSPACE Legacy-parity radial-slotted design space.
    %   C = decode(CHROM), [C,INFO] = repair(C), and M = build(C,BUILDDATA)
    %   deliberately separate infeasible optimisation state from canonical
    %   physical state. Repair independently reproduces the deterministic
    %   legacy ordering; chrom2design_RADIAL_SLOTTED is only a test oracle.
    %   build has no FEA responsibility; exact pack area comes from geometry.
    properties (SetAccess = private)
        Options
        SimOptions
    end
    methods
        function obj = RadialSlottedDesignSpace(options, simoptions)
            defaults = struct('Phases',3,'qc',1,'yd',4, ...
                'UseResistanceRatio',true,'RlVRp',10,'LoadResistance',1, ...
                'tc2Vtc1',0.1,'CoilFillFactor',0.65,'NStrands',1, ...
                'BranchFac',0,'ArmatureType','internal','CoilLayers',2, ...
                'Max_tc',0.2,'Min_tc',[],'Max_tsb',0.2,'Max_tm',0.05, ...
                'Max_ls',4,'Max_tsbVtc1',0.9,'Min_g',0.5e-3);
            if nargin < 1, options = struct(); end
            if nargin < 2, simoptions = struct(); end
            names = fieldnames(options);
            known = fieldnames(defaults);
            for k=1:numel(names)
                if ~any(strcmp(names{k},known))
                    error('rnfoundry:em:UnknownDesignOption','Unknown design-space option %s.',names{k});
                end
                defaults.(names{k})=options.(names{k});
            end
            obj.validateOptions(defaults);
            if ~isfield(simoptions,'MinStrandDiameter'), simoptions.MinStrandDiameter=0.5e-3; end
            if ~isfield(simoptions,'PreventStrandDiameterGreaterThanSlotOpening')
                simoptions.PreventStrandDiameterGreaterThanSlotOpening=true;
            end
            obj.Options=defaults; obj.SimOptions=simoptions;
        end
        function candidate = decode(obj, chrom)
            if ~isnumeric(chrom) || ~(numel(chrom)==16 || numel(chrom)==17)
                error('rnfoundry:em:InvalidChromosome','Chromosome must contain 16 or 17 numeric elements.');
            end
            c=chrom(:); o=obj.Options;
            d=struct('ArmatureType',o.ArmatureType,'Phases',max(1,round(o.Phases)), ...
                'qc',o.qc,'yd',o.yd,'CoilLayers',o.CoilLayers, ...
                'CoilFillFactor',o.CoilFillFactor,'NStrands',o.NStrands);
            if o.UseResistanceRatio, d.RlVRp=o.RlVRp; else, d.LoadResistance=o.LoadResistance; end
            if strcmp(o.ArmatureType,'external'), d.Ryo=c(1); else, d.Rbo=c(1); end
            d.tyVtm=c(2); d.tcVMax_tc=c(3); d.tsbVMax_tsb=c(4); d.tsgVtsb=c(5);
            d.g=c(6); d.tmVMax_tm=c(7); d.tbiVtm=c(8); d.thetamVthetap=c(9);
            d.thetacgVthetas=c(10); d.thetacyVthetas=c(11); d.thetasgVthetacg=c(12);
            d.lsVMax_ls=c(13); d.NBasicWindings=round(c(14)); d.DcAreaFac=c(15); d.BranchFac=c(16);
            if numel(c)>16, d.MagnetSkew=c(17); end
            d.ls=c(13)*o.Max_ls; d.tc=c(3)*o.Max_tc; d.tm=max(c(7)*o.Max_tm,1e-3);
            d.tsb=c(4)*o.Max_tsb; d.tbi=max(c(8)*d.tm,1e-3); d.ty=max(c(2)*d.tm,1e-3);
            compatibility=struct('SimOptions',obj.SimOptions);
            candidate=rnfoundry.em.optim.RadialSlottedDesignCandidate.fromFlat( ...
                c,d,false,compatibility);
        end
        function [candidate, info] = repair(obj, candidate)
            if candidate.IsRepaired
                info=struct('Applied',{{}}); return;
            end
            d=candidate.toLegacyStruct();
            [d,s]=rnfoundry.em.optim.repairRadialSlottedCandidate( ...
                d,obj.Options,obj.SimOptions);
            compat=struct('SimOptions',s);
            if isfield(d,'RlVRp'), compat.RlVRp=d.RlVRp; end
            if isfield(d,'LoadResistance'), compat.LoadResistance=d.LoadResistance; end
            candidate=rnfoundry.em.optim.RadialSlottedDesignCandidate.fromFlat( ...
                candidate.Chromosome,d,true,compat);
            % Repair logging is intentionally omitted until every branch can
            % record at execution time without perturbing the parity kernel.
            info=struct('Applied',{{}});
        end
        function machine = build(obj,candidate,buildData)
            if ~candidate.IsRepaired, error('rnfoundry:em:UnrepairedCandidate','Repair candidate before build.'); end
            if nargin<3, buildData=struct(); end
            d=candidate.toLegacyStruct();
            % Legacy PackArea/CoilArea inputs are accepted but are diagnostic only;
            % authoritative canonical areas are always derived geometrically.
            names=fieldnames(buildData);
            allowed={'PackArea','CoilArea','CoilInsulationThickness', ...
                'WindingLayout','MagFEASimMaterials','CoilTurns'};
            for k=1:numel(names)
                if ~any(strcmp(names{k},allowed))
                    error('rnfoundry:em:UnsupportedBuildData','Unsupported buildData field %s.',names{k});
                end
                if ~any(strcmp(names{k},{'PackArea','CoilArea'})), d.(names{k})=buildData.(names{k}); end
            end
            machine=rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(d);
        end
        function [machine,candidate,info] = decodeRepairBuild(obj,chrom,buildData)
            candidate=obj.decode(chrom); [candidate,info]=obj.repair(candidate); machine=obj.build(candidate,buildData);
        end
    end
    methods (Access=private)
        function validateOptions(obj,o) %#ok<INUSD>
            if ~ischar(o.ArmatureType) || ~any(strcmp(o.ArmatureType,{'internal','external'}))
                error('rnfoundry:em:InvalidArmatureType','ArmatureType must be internal or external.');
            end
            if ~(o.CoilLayers==1 || o.CoilLayers==2)
                error('rnfoundry:em:InvalidLayers','CoilLayers must be one or two.');
            end
            positive={'Max_tc','Max_tsb','Max_tm','Max_ls','Max_tsbVtc1','tc2Vtc1'};
            for k=1:numel(positive)
                value=o.(positive{k});
                if ~(isscalar(value)&&isfinite(value)&&value>0)
                    error('rnfoundry:em:InvalidDesignOption','%s must be positive and finite.',positive{k});
                end
            end
            if ~(isscalar(o.Min_g)&&isfinite(o.Min_g)&&o.Min_g>=0)
                error('rnfoundry:em:InvalidDesignOption','Min_g must be finite and nonnegative.');
            end
            if ~(isscalar(o.NStrands)&&isfinite(o.NStrands)&&o.NStrands>=1&&o.NStrands==fix(o.NStrands))
                error('rnfoundry:em:InvalidDesignOption','NStrands must be a positive integer.');
            end
        end
    end
end
