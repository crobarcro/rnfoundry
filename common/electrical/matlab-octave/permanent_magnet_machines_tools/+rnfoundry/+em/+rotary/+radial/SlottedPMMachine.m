classdef SlottedPMMachine < rnfoundry.em.RotaryMachine
    properties
        Field=[]; Armature=[]; ls=NaN; NStages=1
    end
    properties (Dependent)
        g; Rgm; tausm
    end
    methods
        function obj=SlottedPMMachine(field,armature,ls)
            if nargin==0, obj@rnfoundry.em.RotaryMachine(); return; end
            obj@rnfoundry.em.RotaryMachine(2*pi/armature.Winding.PoleCount);
            obj.Field=field; obj.Armature=armature; obj.ls=ls; obj.validate();
        end
        function v=get.g(obj), if strcmp(obj.Armature.Position,'external'), v=obj.Armature.Ra-obj.Field.Rmo; else, v=obj.Field.Rmi-obj.Armature.Ra; end; end
        function v=get.Rgm(obj), if strcmp(obj.Armature.Position,'external'), v=obj.Field.Rmo+obj.g/2; else, v=obj.Field.Rmi-obj.g/2; end; end
        function v=get.tausm(obj), v=obj.Armature.thetas*obj.Armature.Rcm; end
        function validate(obj)
            validate@rnfoundry.em.Machine(obj); obj.Field.validate(); obj.Armature.validate();
            if ~(isscalar(obj.ls)&&isfinite(obj.ls)&&obj.ls>0), error('rnfoundry:em:InvalidStackLength','ls must be positive.'); end
            if ~(obj.g>0), error('rnfoundry:em:InvalidAirGap','Facing surfaces must define a positive air gap.'); end
            if obj.Armature.Winding.PoleCount*obj.PoleSpan~=2*pi, error('rnfoundry:em:InvalidPoles','Pole count and PoleSpan disagree.'); end
        end
        function s=toStruct(obj), s=struct('Schema','rnfoundry.em.SlottedPMMachine','SchemaVersion',1,'Type','SlottedPMMachine','ls',obj.ls,'NStages',obj.NStages,'Field',obj.Field.toStruct(),'Armature',obj.Armature.toStruct()); end
        function d=toLegacyStruct(obj)
            a=obj.Armature; f=obj.Field; w=a.Winding; c=w.Conductor;
            d=struct('ArmatureType',a.Position,'Poles',w.PoleCount,'Phases',w.PhaseCount,'CoilLayers',w.LayerCount,'Qc',w.CoilCount,'Qcb',w.BasicCoilCount,'pb',w.BasicPoleCount,'NBasicWindings',w.BasicWindingRepetitions,'Qs',w.SlotCount,'Qsb',w.BasicSlotCount,'qcn',w.qcn,'qcd',w.qcd,'ypn',w.ypn,'ypd',w.ypd,'yp',w.yp,'yd',w.CoilPitchSlots,'qsp',w.SlotsPerPole,'NCoilsPerPhase',w.CoilsPerPhase,'Branches',w.ParallelBranches,'CoilsPerBranch',w.CoilsPerBranch,'WindingLayout',w.Layout,'CoilTurns',w.TurnsPerCoil,'CoilFillFactor',w.PackingFactor,'NStrands',c.StrandCount,'WireStrandDiameter',c.StrandDiameter,'Dc',c.EquivalentCopperDiameter,'ConductorArea',c.CopperAreaPerTurn,'CoilArea',w.CoilGeometry.PackArea,'MTL',w.MeanTurnLength,'CoilResistance',w.ReferenceDCCoilResistance);
            d.qc=w.qc; try, d.qc=fr(w.qcn,w.qcd); catch, end
            d.Rmi=f.Rmi; d.Rmo=f.Rmo; d.Rbi=f.Rbi; d.Rbo=f.Rbo; d.Rmm=f.Rmm; d.Rbm=f.Rbm; d.thetam=f.thetam; d.MagnetSkew=f.MagnetSkew;
            d.Ryi=a.Ryi; d.Ryo=a.Ryo; d.Rym=a.Rym; d.Rtsb=a.Rtsb; d.Rtsg=a.Rtsg; d.Rci=a.Rci; d.Rco=a.Rco; d.Rcm=a.Rcm; d.Rcb=a.Rcb; d.tc=[a.tc a.tcb]; d.tc2Vtc1=a.tcbVtc; d.ty=a.ty; d.tsb=a.tsb; d.tsg=a.tsg;
            if strcmp(a.Position,'external'), d.Rai=a.Ra; else, d.Rao=a.Ra; end
            d.thetas=a.thetas; d.thetasg=a.thetasg; d.thetacg=a.thetacg; d.thetacy=a.thetacy; d.thetac=a.thetac; d.thetap=obj.thetap; d.PoleWidth=obj.PoleSpan; d.g=obj.g; d.ls=obj.ls; d.Rgm=obj.Rgm; d.tausm=obj.tausm; d.NStages=obj.NStages;
            d.tm=f.Rmo-f.Rmi; d.tbi=abs(f.Rbo-f.Rbi); d.thetamVthetap=f.thetam/obj.thetap; d.thetacgVthetas=a.thetacg/a.thetas; d.thetacyVthetas=a.thetacy/a.thetas; d.thetasgVthetacg=a.thetasg/a.thetacg; d.tsgVtsb=a.tsg/a.tsb; d.lsVtm=obj.ls/d.tm; d.RmiVRmo=f.Rmi/f.Rmo; d.RyiVRyo=a.Ryi/a.Ryo;
            if strcmp(a.Position,'external'), d.RtsbVRyi=a.Rtsb/a.Ryi; d.RaiVRtsb=a.Ra/a.Rtsb; d.RmoVRai=f.Rmo/a.Ra; d.RbiVRmi=f.Rbi/f.Rmi; d.RcbVRyi=a.Rcb/a.Ryi; else, d.RmoVRbo=f.Rmo/f.Rbo; d.RaoVRmi=a.Ra/f.Rmi; d.RtsbVRao=a.Rtsb/a.Ra; d.RyoVRtsb=a.Ryo/a.Rtsb; d.RcbVRtsb=a.Rcb/a.Rtsb; end
            d.MagFEASimMaterials=struct('Magnet',f.MagnetMaterial,'FieldBackIron',f.BackIronMaterial,'ArmatureYoke',a.IronMaterial,'ArmatureCoil',c.Material);
        end
    end
    methods (Static)
        function obj=fromLegacyStruct(d)
            if ~isfield(d,'Rcm') || ~isfield(d,'thetas') || ~isfield(d,'Qcb'), d=completedesign_RADIAL_SLOTTED(d,struct(),'firstcomplete'); end
            d=rnfoundry.em.rotary.radial.SlottedPMMachine.defaults(d);
            if ~isfield(d,'CoilArea'), d.CoilArea=abs(d.tc(1))*mean([d.thetacg d.thetacy])*d.Rcm/d.CoilLayers; end
            ps=struct('NStrands',d.NStrands,'Material',rnfoundry.em.rotary.radial.SlottedPMMachine.material(d,'ArmatureCoil'));
            copy={'Dc','CoilTurns','CoilFillFactor','WireStrandDiameter'}; for k=1:numel(copy), if isfield(d,copy{k}), ps.(copy{k})=d.(copy{k}); end; end
            geom=rnfoundry.em.winding.RadialSlottedCoilGeometry(d.CoilArea,d.ls,d.yd*d.thetas*d.Rcm+d.thetas*d.Rcm/2,mean([d.thetacg d.thetacy])*d.Rcm,2*d.ls);
            p=rnfoundry.em.winding.resolvePacking(ps,geom);
            ws=struct('PhaseCount',d.Phases,'PoleCount',d.Poles(1),'LayerCount',d.CoilLayers,'CoilCount',d.Qc,'BasicCoilCount',d.Qcb,'BasicPoleCount',d.pb,'BasicWindingRepetitions',d.NBasicWindings,'SlotCount',d.Qs,'BasicSlotCount',d.Qsb,'CoilPitchSlots',d.yd,'qcn',d.qcn,'qcd',d.qcd,'ypn',d.ypn,'ypd',d.ypd,'ParallelBranches',d.Branches,'Layout',d.WindingLayout,'TurnsPerCoil',p.TurnsPerCoil,'PackingFactor',p.PackingFactor,'Conductor',p.Conductor,'CoilGeometry',geom);
            w=rnfoundry.em.winding.Winding(ws); tc=d.tc(1); if numel(d.tc)>1, tcb=d.tc(2); else, tcb=tc; end
            if strncmpi(d.ArmatureType,'e',1), pos='external'; ra=d.Rai; else, pos='internal'; ra=d.Rao; end
            as=struct('Position',pos,'Ryi',d.Ryi,'Ryo',d.Ryo,'Rtsb',d.Rtsb,'Rtsg',d.Rtsg,'Ra',ra,'tc',tc,'tcb',tcb,'ty',d.ty,'tsb',d.tsb,'tsg',d.tsg,'thetas',d.thetas,'thetasg',d.thetasg,'thetacg',d.thetacg,'thetacy',d.thetacy,'IronMaterial',rnfoundry.em.rotary.radial.SlottedPMMachine.material(d,'ArmatureYoke'),'Winding',w);
            fs=struct('Rmi',d.Rmi,'Rmo',d.Rmo,'Rbi',d.Rbi,'Rbo',d.Rbo,'thetam',d.thetam,'MagnetSkew',d.MagnetSkew,'MagnetMaterial',rnfoundry.em.rotary.radial.SlottedPMMachine.material(d,'Magnet'),'BackIronMaterial',rnfoundry.em.rotary.radial.SlottedPMMachine.material(d,'FieldBackIron'));
            obj=rnfoundry.em.rotary.radial.SlottedPMMachine(rnfoundry.em.rotary.radial.RadialPMField(fs),rnfoundry.em.rotary.radial.SlottedArmature(as),d.ls); obj.NStages=d.NStages;
        end
        function obj=fromRatios(d), d=rnfoundry.em.rotary.radial.SlottedPMMachine.completeInput(d,'ratios'); obj=rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(d); end
        function obj=fromRadii(d), d=rnfoundry.em.rotary.radial.SlottedPMMachine.completeInput(d,'radims'); obj=rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(d); end
        function obj=fromThicknesses(d), d=rnfoundry.em.rotary.radial.SlottedPMMachine.completeInput(d,'tdims'); obj=rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(d); end
        function obj=fromStruct(s)
            if ~isfield(s,'SchemaVersion')||s.SchemaVersion~=1||~strcmp(s.Type,'SlottedPMMachine'), error('rnfoundry:em:UnsupportedSchema','Unsupported machine schema.'); end
            f=rnfoundry.em.rotary.radial.RadialPMField(s.Field); a=s.Armature; a.Winding=rnfoundry.em.winding.Winding.fromStruct(a.Winding); arm=rnfoundry.em.rotary.radial.SlottedArmature(a); obj=rnfoundry.em.rotary.radial.SlottedPMMachine(f,arm,s.ls); obj.NStages=s.NStages;
        end
    end
    methods (Static, Access=private)
        function d=defaults(d)
            vals={'MagnetSkew',0;'CoilLayers',1;'NStrands',1;'NStages',1;'Branches',1;'CoilInsulationThickness',0}; for k=1:size(vals,1), if ~isfield(d,vals{k,1}), d.(vals{k,1})=vals{k,2}; end; end
            if ~isfield(d,'WindingLayout'), d.WindingLayout=struct(); end
            if ~isfield(d,'qcn') && isfield(d,'qc'), [d.qcn,d.qcd]=rat(double(d.qc)); end
            if ~isfield(d,'ypn') && isfield(d,'Qs'), [d.ypn,d.ypd]=rat(d.Qs/d.Poles(1)); end
            if ~isfield(d,'Qsb') && isfield(d,'Qs') && isfield(d,'NBasicWindings'), d.Qsb=d.Qs/d.NBasicWindings; end
        end
        function v=material(d,n), v=struct(); if isfield(d,'MagFEASimMaterials')&&isfield(d.MagFEASimMaterials,n), v=d.MagFEASimMaterials.(n); end; end
        function d=completeInput(d,mode)
            % Use the legacy completion when its optional winding-layout MEX is available.
            try, d=completedesign_RADIAL_SLOTTED(d,struct(),mode); return; catch err
                if isempty(strfind(err.message,'mexmPhaseWL')) && isempty(strfind(err.message,"must be an object of the 'fr'")), rethrow(err); end
            end
            d=rnfoundry.em.rotary.radial.SlottedPMMachine.defaults(d);
            if ~isfield(d,'qc'), d.qc=d.Qc/(d.Poles(1)*d.Phases); end; qc=double(d.qc);
            [d.Qcb,d.pb]=rat(qc*d.Phases); if ~isfield(d,'Poles'), d.Poles=d.pb*d.NBasicWindings; end
            d.Qc=round(qc*d.Phases*d.Poles(1)); d.NBasicWindings=d.Poles(1)/d.pb;
            if d.CoilLayers==2, d.Qs=d.Qc; d.Qsb=d.Qcb; else, d.Qs=2*d.Qc; d.Qsb=2*d.Qcb; end
            [d.qcn,d.qcd]=rat(qc); [d.ypn,d.ypd]=rat(d.Qs/d.Poles(1)); d.yp=d.Qs/d.Poles(1);
            if ~isfield(d,'yd'), if d.ypd==1, d.yd=d.ypn; else, error('rnfoundry:em:MissingCoilPitch','yd is required for fractional-slot windings.'); end; end
            d.NCoilsPerPhase=d.Qc/d.Phases; d.qsp=d.Qs/d.Poles(1); d.WindingLayout=struct(); d.thetap=2*pi/d.Poles(1); d.thetas=2*pi/d.Qs; d.PoleWidth=d.thetap;
            ext=strncmpi(d.ArmatureType,'external',1);
            if strcmp(mode,'ratios')
                if ext
                    d.Ryi=d.RyiVRyo*d.Ryo; d.Rtsb=d.RtsbVRyi*d.Ryi; d.Rai=d.RaiVRtsb*d.Rtsb; d.Rmo=d.RmoVRai*d.Rai; d.Rmi=d.RmiVRmo*d.Rmo; d.Rbi=d.RbiVRmi*d.Rmi;
                else
                    d.Rmo=d.RmoVRbo*d.Rbo; d.Rmi=d.RmiVRmo*d.Rmo; d.Rao=d.RaoVRmi*d.Rmi; d.Rtsb=d.RtsbVRao*d.Rao; d.Ryo=d.RyoVRtsb*d.Rtsb; d.Ryi=d.RyiVRyo*d.Ryo;
                end
                d.thetam=d.thetamVthetap*d.thetap; d.thetacg=d.thetacgVthetas*d.thetas; d.thetacy=d.thetacyVthetas*d.thetas; d.thetasg=d.thetasgVthetacg*d.thetacg;
                if ext, d.tsb=d.Rtsb-d.Rai; else, d.tsb=d.Rao-d.Rtsb; end; d.tsg=d.tsgVtsb*d.tsb;
            elseif strcmp(mode,'tdims')
                if ext
                    d.Ryi=d.Ryo-d.ty; d.Rtsb=d.Ryi-d.tc(1); d.Rai=d.Rtsb-d.tsb; d.Rmo=d.Rai-d.g; d.Rmi=d.Rmo-d.tm; d.Rbi=d.Rmi-d.tbi;
                else
                    d.Rmo=d.Rbo-d.tbi; d.Rmi=d.Rmo-d.tm; d.Rao=d.Rmi-d.g; d.Rtsb=d.Rao-d.tsb; d.Ryo=d.Rtsb-d.tc(1); d.Ryi=d.Ryo-d.ty;
                end
            end
            if ext
                d.ty=d.Ryo-d.Ryi; d.tsb=d.Rtsb-d.Rai; d.g=d.Rai-d.Rmo; d.tm=d.Rmo-d.Rmi; d.tbi=d.Rmi-d.Rbi; d.Rco=d.Ryi; d.Rci=d.Rtsb; d.Rbo=d.Rmi; d.Rtsg=d.Rai+d.tsg; if numel(d.tc)>1,d.Rcb=d.Rco-d.tc(2);end
            else
                d.ty=d.Ryo-d.Ryi; d.tsb=d.Rao-d.Rtsb; d.g=d.Rmi-d.Rao; d.tm=d.Rmo-d.Rmi; d.tbi=d.Rbo-d.Rmo; d.Rco=d.Rtsb; d.Rci=d.Ryo; d.Rbi=d.Rmo; d.Rtsg=d.Rao-d.tsg; if numel(d.tc)>1,d.Rcb=d.Rci+d.tc(2);end
            end
            d.tc(1)=d.Rco-d.Rci; if ~isfield(d,'Rcb'), d.Rcb=mean([d.Rci d.Rco]); d.tc(2)=abs(d.Rco-d.Rcb); elseif numel(d.tc)<2, if ext,d.tc(2)=d.Rco-d.Rcb;else,d.tc(2)=d.Rcb-d.Rci;end; end
            d.Rmm=mean([d.Rmi d.Rmo]); d.Rcm=mean([d.Rci d.Rco]); d.Rbm=mean([d.Rbi d.Rbo]); d.Rym=mean([d.Ryi d.Ryo]); d.thetac=[d.thetacg d.thetacy]; if ext,d.Rgm=d.Rmo+d.g/2;else,d.Rgm=d.Rmi-d.g/2;end; d.tausm=d.thetas*d.Rcm;
        end
    end
end
