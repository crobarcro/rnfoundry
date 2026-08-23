classdef RadialSlottedDesignSpace
    %RADIALSLOTTEDDESIGNSPACE Legacy-parity radial-slotted design space.
    %   C = decode(CHROM), [C,INFO] = repair(C), and M = build(C,BUILDDATA)
    %   deliberately separate infeasible optimisation state from canonical
    %   physical state. Repair follows chrom2design_RADIAL_SLOTTED ordering.
    %   build has no FEA responsibility and requires BUILDDATA.PackArea (or
    %   CoilArea); Hc*Wc is never used as canonical coil pack area.
    properties (SetAccess = private)
        Options
        SimOptions
    end
    methods
        function obj = RadialSlottedDesignSpace(options, simoptions)
            defaults = struct('Phases',3,'qc',fr(3,3),'yd',4, ...
                'UseResistanceRatio',true,'RlVRp',10,'LoadResistance',1, ...
                'tc2Vtc1',0.1,'CoilFillFactor',0.65,'NStrands',1, ...
                'BranchFac',0,'ArmatureType','internal','CoilLayers',2, ...
                'Max_tc',0.2,'Min_tc',[],'Max_tsb',0.2,'Max_tm',0.05, ...
                'Max_ls',4,'Max_tsbVtc1',0.9,'Min_g',0.5e-3);
            if nargin < 1, options = struct(); end
            if nargin < 2, simoptions = struct(); end
            names = fieldnames(options);
            for k=1:numel(names), defaults.(names{k})=options.(names{k}); end
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
            candidate=rnfoundry.em.optim.RadialSlottedDesignCandidate(c,d,false,struct());
        end
        function [candidate, info] = repair(obj, candidate)
            if candidate.IsRepaired
                info=struct('Applied',{{}}); return;
            end
            args=obj.optionArguments();
            [d,s]=chrom2design_RADIAL_SLOTTED(obj.SimOptions,candidate.Chromosome,args{:});
            applied=obj.diagnostics(candidate.Data,d,s);
            compat=struct('SimOptions',s);
            if isfield(d,'RlVRp'), compat.RlVRp=d.RlVRp; end
            if isfield(d,'LoadResistance'), compat.LoadResistance=d.LoadResistance; end
            candidate=rnfoundry.em.optim.RadialSlottedDesignCandidate(candidate.Chromosome,d,true,compat);
            info=struct('Applied',{applied});
        end
        function machine = build(obj,candidate,buildData)
            if ~candidate.IsRepaired, error('rnfoundry:em:UnrepairedCandidate','Repair candidate before build.'); end
            if nargin<3, buildData=struct(); end
            d=candidate.toLegacyStruct();
            if isfield(buildData,'PackArea'), d.CoilArea=buildData.PackArea;
            elseif isfield(buildData,'CoilArea'), d.CoilArea=buildData.CoilArea;
            else, error('rnfoundry:em:MissingPackArea','buildData.PackArea or CoilArea is required.'); end
            names=fieldnames(buildData);
            for k=1:numel(names)
                if ~strcmp(names{k},'PackArea'), d.(names{k})=buildData.(names{k}); end
            end
            if ~isfield(d,'CoilTurns'), d.CoilTurns=1; end
            machine=rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(d);
        end
        function [machine,candidate,info] = decodeRepairBuild(obj,chrom,buildData)
            candidate=obj.decode(chrom); [candidate,info]=obj.repair(candidate); machine=obj.build(candidate,buildData);
        end
    end
    methods (Access=private)
        function args=optionArguments(obj)
            n=fieldnames(obj.Options); args=cell(1,2*numel(n));
            for k=1:numel(n), args{2*k-1}=n{k}; args{2*k}=obj.Options.(n{k}); end
        end
        function a=diagnostics(obj,b,d,s)
            a={};
            if b.tmVMax_tm*obj.Options.Max_tm<1e-3, a{end+1}='MinimumMagnetThickness'; end
            if b.tbiVtm*b.tm<1e-3, a{end+1}='MinimumBackIronThickness'; end
            if b.tyVtm*b.tm<1e-3, a{end+1}='MinimumYokeThickness'; end
            if (strcmp(b.ArmatureType,'external') && isfield(d,'Rbi') && d.Rbi>=1e-4 && b.Ryo-b.ty-b.tc-b.tsb-b.g-b.tm-b.tbi<1e-4) || ...
               (strcmp(b.ArmatureType,'internal') && isfield(d,'Ryi') && d.Ryi>=1e-4 && b.Rbo-b.tbi-b.tm-b.g-b.tsb-b.tc-b.ty<1e-4)
                a{end+1}='OriginClearanceShift';
            end
            if b.tsb>obj.Options.Max_tsbVtc1*b.tc, a{end+1}='MaximumShoeBase'; end
            if b.tc>obj.Options.Max_tc, a{end+1}='MaximumCoilHeight'; end
            if d.g> b.g, a{end+1}='MinimumAirGap'; end
            if isfield(s,'MaxStrandDiameter'), a{end+1}='SlotOpeningWireClearance'; end
            if d.WireStrandDiameter<=s.MinStrandDiameter, a{end+1}='MinimumStrandDiameter'; end
            a{end+1}='FinalRatioRecompletion'; a{end+1}='ConductorSizing'; a{end+1}='BranchConfiguration';
        end
    end
end
