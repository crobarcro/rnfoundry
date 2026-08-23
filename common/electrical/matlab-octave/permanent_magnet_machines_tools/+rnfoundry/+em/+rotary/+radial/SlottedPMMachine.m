classdef SlottedPMMachine < rnfoundry.em.RotaryMachine
    properties (SetAccess = private)
        Field
        Armature
        ls
        NStages
    end
    properties (Dependent)
        g
        Rgm
        tausm
    end
    methods
        function obj = SlottedPMMachine(field, armature, ls, nStages)
            if nargin < 4, nStages = 1; end
            obj@rnfoundry.em.RotaryMachine(2*pi ./ armature.Winding.PoleCount);
            obj.Field = field;
            obj.Armature = armature;
            obj.ls = ls;
            obj.NStages = nStages;
            obj.validate();
        end
        function value = get.g(obj)
            if strcmp(obj.Armature.Position,'external')
                value = obj.Armature.Ra - obj.Field.Rmo;
            else
                value = obj.Field.Rmi - obj.Armature.Ra;
            end
        end
        function value = get.Rgm(obj)
            if strcmp(obj.Armature.Position,'external')
                value = obj.Field.Rmo + obj.g./2;
            else
                value = obj.Field.Rmi - obj.g./2;
            end
        end
        function value = get.tausm(obj)
            value = obj.Armature.thetas .* obj.Armature.Rcm;
        end
        function validate(obj)
            validate@rnfoundry.em.Machine(obj);
            obj.Field.validate();
            obj.Armature.validate();
            if ~(isscalar(obj.ls) && isfinite(obj.ls) && obj.ls > 0)
                error('rnfoundry:em:InvalidStackLength','ls must be a positive finite scalar.');
            end
            if ~(isscalar(obj.NStages) && obj.NStages >= 1 && obj.NStages == fix(obj.NStages))
                error('rnfoundry:em:InvalidStages','NStages must be a positive integer.');
            end
            if ~(obj.g > 0)
                error('rnfoundry:em:InvalidAirGap','Facing surfaces must define a positive air gap.');
            end
            if abs(obj.Armature.Winding.PoleCount .* obj.PoleSpan - 2*pi) > 20*eps
                error('rnfoundry:em:InvalidPoles','PoleCount and PoleSpan disagree.');
            end
            if abs(obj.Armature.thetas - 2*pi./obj.Armature.Winding.SlotCount) > 20*eps
                error('rnfoundry:em:InvalidSlots','SlotCount and thetas disagree.');
            end
            if obj.Field.thetam > obj.PoleSpan
                error('rnfoundry:em:InvalidMagnetAngle','thetam cannot exceed PoleSpan.');
            end
        end
        function s = toStruct(obj)
            s = struct('Schema','rnfoundry.em.SlottedPMMachine', ...
                'SchemaVersion',1,'Type','SlottedPMMachine', ...
                'PoleSpan',obj.PoleSpan,'ls',obj.ls,'NStages',obj.NStages, ...
                'Field',obj.Field.toStruct(),'Armature',obj.Armature.toStruct());
        end
        function d = toLegacyStruct(obj)
            a = obj.Armature; f = obj.Field; w = a.Winding; c = w.Conductor;
            d = struct();
            d.ArmatureType = a.Position; d.Poles = w.PoleCount; d.Phases = w.PhaseCount;
            d.CoilLayers = w.LayerCount; d.Qc = w.CoilCount; d.Qcb = w.BasicCoilCount;
            d.pb = w.BasicPoleCount; d.NBasicWindings = w.BasicWindingRepetitions;
            d.Qs = w.SlotCount; d.Qsb = w.BasicSlotCount; d.qcn = w.qcn; d.qcd = w.qcd;
            d.ypn = w.ypn; d.ypd = w.ypd; d.yp = w.yp; d.yd = w.CoilPitchSlots;
            d.qsp = w.SlotsPerPole; d.NCoilsPerPhase = w.CoilsPerPhase;
            d.Branches = w.ParallelBranches; d.CoilsPerBranch = w.CoilsPerBranch;
            d.WindingLayout = w.Layout;
            d.qc = w.qc;
            try, d.qc = fr(w.qcn,w.qcd); catch, end
            d.CoilTurns = w.TurnsPerCoil; d.CoilFillFactor = w.PackingFactor;
            d.NStrands = c.StrandCount; d.WireStrandDiameter = c.StrandDiameter;
            d.Dc = c.EquivalentCopperDiameter; d.ConductorArea = c.CopperAreaPerTurn;
            d.CoilArea = w.CoilGeometry.PackArea; d.MTL = w.MeanTurnLength;
            d.CoilResistance = w.ReferenceDCCoilResistance;
            d.CoilInsulationThickness = w.CoilGeometry.CoilInsulationThickness;
            d.Rmi=f.Rmi; d.Rmo=f.Rmo; d.Rbi=f.Rbi; d.Rbo=f.Rbo;
            d.Rmm=f.Rmm; d.Rbm=f.Rbm; d.thetam=f.thetam; d.MagnetSkew=f.MagnetSkew;
            d.Ryi=a.Ryi; d.Ryo=a.Ryo; d.Rym=a.Rym; d.Rtsb=a.Rtsb; d.Rtsg=a.Rtsg;
            d.Rci=a.Rci; d.Rco=a.Rco; d.Rcm=a.Rcm; d.Rcb=a.Rcb;
            d.tc=[a.tc,a.tcb]; d.tc2Vtc1=a.tcbVtc; d.ty=a.ty; d.tsb=a.tsb; d.tsg=a.tsg;
            if strcmp(a.Position,'external'), d.Rai=a.Ra; else, d.Rao=a.Ra; end
            d.thetas=a.thetas; d.thetasg=a.thetasg; d.thetacg=a.thetacg;
            d.thetacy=a.thetacy; d.thetac=a.thetac; d.thetap=obj.thetap;
            d.PoleWidth=obj.PoleSpan; d.g=obj.g; d.ls=obj.ls; d.Rgm=obj.Rgm;
            d.tausm=obj.tausm; d.NStages=obj.NStages; d.tm=f.MagnetThickness;
            d.tbi=f.BackIronThickness; d.thetamVthetap=f.thetam/obj.thetap;
            d.thetacgVthetas=a.thetacg/a.thetas; d.thetacyVthetas=a.thetacy/a.thetas;
            d.thetasgVthetacg=a.thetasg/a.thetacg; d.tsgVtsb=a.tsg/a.tsb;
            d.lsVtm=obj.ls/d.tm; d.RmiVRmo=f.Rmi/f.Rmo; d.RyiVRyo=a.Ryi/a.Ryo;
            if strcmp(a.Position,'external')
                d.RtsbVRyi=a.Rtsb/a.Ryi; d.RaiVRtsb=a.Ra/a.Rtsb;
                d.RmoVRai=f.Rmo/a.Ra; d.RbiVRmi=f.Rbi/f.Rmi; d.RcbVRyi=a.Rcb/a.Ryi;
            else
                d.RmoVRbo=f.Rmo/f.Rbo; d.RaoVRmi=a.Ra/f.Rmi;
                d.RtsbVRao=a.Rtsb/a.Ra; d.RyoVRtsb=a.Ryo/a.Rtsb;
                d.RcbVRtsb=a.Rcb/a.Rtsb;
            end
            d.MagFEASimMaterials = struct('Magnet',f.MagnetMaterial, ...
                'FieldBackIron',f.BackIronMaterial,'ArmatureYoke',a.IronMaterial, ...
                'ArmatureCoil',c.Material);
        end
    end
    methods (Static)
        function obj = fromRatios(d)
            obj = rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct( ...
                rnfoundry.em.rotary.radial.SlottedPMMachine.completeInput(d,'ratios'));
        end
        function obj = fromRadii(d)
            obj = rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct( ...
                rnfoundry.em.rotary.radial.SlottedPMMachine.completeInput(d,'radims'));
        end
        function obj = fromThicknesses(d)
            obj = rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct( ...
                rnfoundry.em.rotary.radial.SlottedPMMachine.completeInput(d,'tdims'));
        end
        function obj = fromLegacyStruct(d)
            required = {'Rcm','thetas','Qcb','WindingLayout'};
            if ~all(isfield(d,required))
                d = completedesign_RADIAL_SLOTTED(d,struct(),'firstcomplete');
            end
            d = rnfoundry.em.rotary.radial.SlottedPMMachine.defaults(d);
            if ~isfield(d,'CoilArea')
                error('rnfoundry:em:MissingPackArea', ...
                      'CoilArea/PackArea is required; it cannot be inferred exactly without slot-region integration.');
            end
            if ~isfield(d.WindingLayout,'Coils') || ~isfield(d.WindingLayout,'Phases') ...
                    || isempty(d.WindingLayout.Coils) || isempty(d.WindingLayout.Phases)
                error('rnfoundry:em:UnresolvedWindingLayout', ...
                      'A resolved WindingLayout.Coils and WindingLayout.Phases are required.');
            end
            packingSpec = struct('NStrands',d.NStrands, ...
                'Material',rnfoundry.em.rotary.radial.SlottedPMMachine.material(d,'ArmatureCoil'));
            names = {'Dc','CoilTurns','CoilFillFactor','WireStrandDiameter'};
            for k=1:numel(names), if isfield(d,names{k}), packingSpec.(names{k})=d.(names{k}); end; end
            pitchLength = d.yd*d.thetas*d.Rcm + d.thetas*d.Rcm/2;
            slotWidth = mean([d.thetacg,d.thetacy])*d.Rcm;
            geometry = rnfoundry.em.winding.RadialSlottedCoilGeometry( ...
                d.CoilArea,d.ls,pitchLength,slotWidth,2*d.ls,d.CoilInsulationThickness);
            packing = rnfoundry.em.winding.resolvePacking(packingSpec,geometry);
            ws = struct('PhaseCount',d.Phases,'PoleCount',d.Poles(1), ...
                'LayerCount',d.CoilLayers,'CoilCount',d.Qc,'BasicCoilCount',d.Qcb, ...
                'BasicPoleCount',d.pb,'BasicWindingRepetitions',d.NBasicWindings, ...
                'SlotCount',d.Qs,'BasicSlotCount',d.Qsb,'CoilPitchSlots',d.yd, ...
                'qcn',d.qcn,'qcd',d.qcd,'ypn',d.ypn,'ypd',d.ypd, ...
                'ParallelBranches',d.Branches,'Layout',d.WindingLayout, ...
                'TurnsPerCoil',packing.TurnsPerCoil,'PackingFactor',packing.PackingFactor, ...
                'Conductor',packing.Conductor,'CoilGeometry',geometry);
            winding = rnfoundry.em.winding.Winding(ws);
            tc = d.tc(1);
            if numel(d.tc)>1, tcb=d.tc(2); else, tcb=0.05*tc; end
            if strncmpi(d.ArmatureType,'external',1)
                position='external'; ra=d.Rai;
            else
                position='internal'; ra=d.Rao;
            end
            armature = rnfoundry.em.rotary.radial.SlottedArmature(struct( ...
                'Position',position,'Ryi',d.Ryi,'Ryo',d.Ryo,'Rtsb',d.Rtsb, ...
                'Rtsg',d.Rtsg,'Ra',ra,'tc',tc,'tcb',tcb,'thetasg',d.thetasg, ...
                'thetacg',d.thetacg,'thetacy',d.thetacy, ...
                'IronMaterial',rnfoundry.em.rotary.radial.SlottedPMMachine.material(d,'ArmatureYoke'), ...
                'Winding',winding));
            field = rnfoundry.em.rotary.radial.RadialPMField(struct( ...
                'Rmi',d.Rmi,'Rmo',d.Rmo,'Rbi',d.Rbi,'Rbo',d.Rbo, ...
                'thetam',d.thetam,'MagnetSkew',d.MagnetSkew, ...
                'MagnetMaterial',rnfoundry.em.rotary.radial.SlottedPMMachine.material(d,'Magnet'), ...
                'BackIronMaterial',rnfoundry.em.rotary.radial.SlottedPMMachine.material(d,'FieldBackIron')));
            obj = rnfoundry.em.rotary.radial.SlottedPMMachine(field,armature,d.ls,d.NStages);
        end
        function obj = fromStruct(s)
            if ~isfield(s,'Schema') || ~strcmp(s.Schema,'rnfoundry.em.SlottedPMMachine') ...
                    || ~isfield(s,'SchemaVersion') || s.SchemaVersion~=1 ...
                    || ~isfield(s,'Type') || ~strcmp(s.Type,'SlottedPMMachine')
                error('rnfoundry:em:UnsupportedSchema','Unsupported machine schema.');
            end
            field = rnfoundry.em.rotary.radial.RadialPMField(s.Field);
            armatureStruct = s.Armature;
            armatureStruct.Winding = rnfoundry.em.winding.Winding.fromStruct(s.Armature.Winding);
            armature = rnfoundry.em.rotary.radial.SlottedArmature(armatureStruct);
            obj = rnfoundry.em.rotary.radial.SlottedPMMachine(field,armature,s.ls,s.NStages);
            if ~isfield(s,'PoleSpan') || abs(s.PoleSpan-obj.PoleSpan)>20*eps
                error('rnfoundry:em:InvalidPoles','Serialized PoleSpan disagrees with winding PoleCount.');
            end
        end
    end
    methods (Static, Access=private)
        function d = defaults(d)
            defaults = {'MagnetSkew',0;'CoilLayers',1;'CoilInsulationThickness',0; ...
                        'NStrands',1;'NStages',1;'Branches',1};
            for k=1:size(defaults,1), if ~isfield(d,defaults{k,1}), d.(defaults{k,1})=defaults{k,2}; end; end
            if isfield(d,'NCoilsPerPhase') && ~isfield(d,'CoilsPerBranch')
                d.CoilsPerBranch=d.NCoilsPerPhase/d.Branches;
            end
        end
        function value = material(d,name)
            value=struct();
            if isfield(d,'MagFEASimMaterials') && isfield(d.MagFEASimMaterials,name)
                value=d.MagFEASimMaterials.(name);
            end
        end
        function d = completeInput(d,mode)
            try
                d=completedesign_RADIAL_SLOTTED(d,struct(),mode);
                return;
            catch err
                missingMex=~isempty(strfind(err.message,'mexmPhaseWL'));
                numericQc=~isempty(strfind(err.message, 'must be an object of the ''fr'''));
                if ~(missingMex || numericQc), rethrow(err); end
            end
            d=rnfoundry.em.rotary.radial.SlottedPMMachine.completeWinding(d);
            external=strncmpi(d.ArmatureType,'external',1);
            if strcmp(mode,'ratios')
                if external
                    d.Ryi=d.RyiVRyo*d.Ryo; d.Rtsb=d.RtsbVRyi*d.Ryi;
                    d.Rai=d.RaiVRtsb*d.Rtsb; d.Rmo=d.RmoVRai*d.Rai;
                    d.Rmi=d.RmiVRmo*d.Rmo; d.Rbi=d.RbiVRmi*d.Rmi;
                else
                    d.Rmo=d.RmoVRbo*d.Rbo; d.Rmi=d.RmiVRmo*d.Rmo;
                    d.Rao=d.RaoVRmi*d.Rmi; d.Rtsb=d.RtsbVRao*d.Rao;
                    d.Ryo=d.RyoVRtsb*d.Rtsb; d.Ryi=d.RyiVRyo*d.Ryo;
                end
                d.thetam=d.thetamVthetap*d.thetap;
                d.thetacg=d.thetacgVthetas*d.thetas;
                d.thetacy=d.thetacyVthetas*d.thetas;
                d.thetasg=d.thetasgVthetacg*d.thetacg;
                if external, d.tsb=d.Rtsb-d.Rai; else, d.tsb=d.Rao-d.Rtsb; end
                d.tsg=d.tsgVtsb*d.tsb;
            elseif strcmp(mode,'tdims')
                if external
                    d.Ryi=d.Ryo-d.ty; d.Rtsb=d.Ryi-d.tc(1); d.Rai=d.Rtsb-d.tsb;
                    d.Rmo=d.Rai-d.g; d.Rmi=d.Rmo-d.tm; d.Rbi=d.Rmi-d.tbi;
                else
                    d.Rmo=d.Rbo-d.tbi; d.Rmi=d.Rmo-d.tm; d.Rao=d.Rmi-d.g;
                    d.Rtsb=d.Rao-d.tsb; d.Ryo=d.Rtsb-d.tc(1); d.Ryi=d.Ryo-d.ty;
                end
            end
            if external
                d.ty=d.Ryo-d.Ryi; d.tsb=d.Rtsb-d.Rai; d.g=d.Rai-d.Rmo;
                d.tm=d.Rmo-d.Rmi; d.tbi=d.Rmi-d.Rbi; d.Rco=d.Ryi;
                d.Rci=d.Rtsb; d.Rbo=d.Rmi; d.Rtsg=d.Rai+d.tsg;
            else
                d.ty=d.Ryo-d.Ryi; d.tsb=d.Rao-d.Rtsb; d.g=d.Rmi-d.Rao;
                d.tm=d.Rmo-d.Rmi; d.tbi=d.Rbo-d.Rmo; d.Rco=d.Rtsb;
                d.Rci=d.Ryo; d.Rbi=d.Rmo; d.Rtsg=d.Rao-d.tsg;
            end
            d.tc(1)=d.Rco-d.Rci;
            if isfield(d,'Rcb')
                if external, d.tc(2)=d.Rco-d.Rcb; else, d.tc(2)=d.Rcb-d.Rci; end
            elseif numel(d.tc)>1
                if external, d.Rcb=d.Rco-d.tc(2); else, d.Rcb=d.Rci+d.tc(2); end
            end
            if strcmp(mode,'ratios'), d.ls=d.lsVtm*d.tm; end
            d.Rmm=mean([d.Rmi,d.Rmo]); d.Rcm=mean([d.Rci,d.Rco]);
            d.Rbm=mean([d.Rbi,d.Rbo]); d.Rym=mean([d.Ryi,d.Ryo]);
            d.thetac=[d.thetacg,d.thetacy];
            if external, d.Rgm=d.Rmo+d.g/2; else, d.Rgm=d.Rmi-d.g/2; end
            d.tausm=d.thetas*d.Rcm;
        end
        function d = completeWinding(d)
            d=rnfoundry.em.rotary.radial.SlottedPMMachine.defaults(d);
            if all(isfield(d,{'Qc','Phases','Poles'})) && ~isfield(d,'qc')
                d.qc=d.Qc/(d.Poles(1)*d.Phases);
            end
            hasBasic=all(isfield(d,{'qc','Phases','NBasicWindings'}));
            hasPoles=all(isfield(d,{'qc','Phases','Poles'}));
            if ~(hasBasic || hasPoles)
                error('rnfoundry:em:InvalidWindingSpecification','Invalid minimum winding specification.');
            end
            qc=double(d.qc); [d.Qcb,d.pb]=rat(qc*d.Phases);
            if ~isfield(d,'Poles')
                if d.pb==1 && mod(d.NBasicWindings,2)~=0
                    d.NBasicWindings=d.NBasicWindings+1;
                end
                d.Qc=d.Qcb*d.NBasicWindings; d.Poles=d.pb*d.NBasicWindings;
            else
                d.Qc=round(qc*d.Phases*d.Poles(1));
                d.NBasicWindings=d.Poles(1)/d.pb;
            end
            if d.pb>d.Poles(1)
                error('rnfoundry:em:InvalidWindingSpecification','Basic winding poles exceed total poles.');
            end
            if d.CoilLayers==2, d.Qs=d.Qc; d.Qsb=d.Qcb;
            elseif d.CoilLayers==1, d.Qs=2*d.Qc; d.Qsb=2*d.Qcb;
            else, error('rnfoundry:em:InvalidLayers','Only one or two winding layers are supported.'); end
            [d.qcn,d.qcd]=rat(qc); [d.ypn,d.ypd]=rat(d.Qs/d.Poles(1)); d.yp=d.Qs/d.Poles(1);
            if ~isfield(d,'yd')
                if d.ypd==1, d.yd=d.ypn;
                else, error('rnfoundry:em:MissingCoilPitch','yd is required for fractional-slot windings.'); end
            end
            d.NCoilsPerPhase=d.Qc/d.Phases; d.qsp=d.Qs/d.Poles(1);
            d.thetap=2*pi/d.Poles(1); d.thetas=2*pi/d.Qs; d.PoleWidth=d.thetap;
            if ~isfield(d,'WindingLayout') || isempty(d.WindingLayout)
                try
                    [coils,phases]=windinglayout(d.Phases,d.Qs,d.Poles(1),d.CoilLayers==1);
                    d.WindingLayout=struct('Coils',coils,'Phases',phases);
                catch err
                    error('rnfoundry:em:WindingLayoutUnavailable', ...
                          'Winding layout could not be generated: %s',err.message);
                end
            end
        end
    end
end
