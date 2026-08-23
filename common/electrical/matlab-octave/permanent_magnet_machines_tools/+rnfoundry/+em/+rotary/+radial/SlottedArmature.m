classdef SlottedArmature
    %SLOTTEDARMATURE Canonical radial slotted armature value object.
    %   Position is 'internal' or 'external'. Ra is the orientation-neutral
    %   air-gap-facing armature radius and maps to legacy Rao or Rai.
    %   Compact Ryi/Ryo/Rtsb/Rtsg notation denotes radial surfaces [m].
    %   tc is full coil-slot depth and tcb is its base section; Rcb is derived.
    properties (SetAccess = private)
        Position
        Ryi
        Ryo
        Rtsb
        Rtsg
        Ra
        tc
        tcb
        thetasg
        thetacg
        thetacy
        IronMaterial
        Winding
    end
    properties (Dependent)
        ty
        tsb
        tsg
        thetas
        Rym
        Rci
        Rco
        Rcm
        Rcb
        thetac
        tcbVtc
    end
    methods
        function obj = SlottedArmature(s)
            names = {'Position','Ryi','Ryo','Rtsb','Rtsg','Ra','tc','tcb', ...
                     'thetasg','thetacg','thetacy','IronMaterial','Winding'};
            for k = 1:numel(names)
                if ~isfield(s,names{k})
                    error('rnfoundry:em:MissingArmatureProperty','Missing armature property %s.',names{k});
                end
                obj.(names{k}) = s.(names{k});
            end
            obj.validate();
        end
        function value = get.ty(obj), value = obj.Ryo - obj.Ryi; end
        function value = get.tsb(obj)
            if strcmp(obj.Position,'external'), value = obj.Rtsb - obj.Ra;
            else, value = obj.Ra - obj.Rtsb; end
        end
        function value = get.tsg(obj), value = abs(obj.Rtsg - obj.Ra); end
        function value = get.thetas(obj), value = 2*pi ./ obj.Winding.SlotCount; end
        function value = get.Rym(obj), value = mean([obj.Ryi,obj.Ryo]); end
        function value = get.Rci(obj)
            if strcmp(obj.Position,'external'), value = obj.Rtsb;
            else, value = obj.Ryo; end
        end
        function value = get.Rco(obj)
            if strcmp(obj.Position,'external'), value = obj.Ryi;
            else, value = obj.Rtsb; end
        end
        function value = get.Rcm(obj), value = mean([obj.Rci,obj.Rco]); end
        function value = get.Rcb(obj)
            if strcmp(obj.Position,'external'), value = obj.Rco - obj.tcb;
            else, value = obj.Rci + obj.tcb; end
        end
        function value = get.thetac(obj), value = [obj.thetacg,obj.thetacy]; end
        function value = get.tcbVtc(obj), value = obj.tcb ./ obj.tc; end
        function validate(obj)
            if ~(strcmp(obj.Position,'internal') || strcmp(obj.Position,'external'))
                error('rnfoundry:em:InvalidPosition','Position must be internal or external.');
            end
            values = [obj.Ryi,obj.Ryo,obj.Rtsb,obj.Rtsg,obj.Ra,obj.tc,obj.tcb, ...
                      obj.thetasg,obj.thetacg,obj.thetacy];
            if any(~isfinite(values)) || any(values(1:6) <= 0) || obj.tcb < 0
                error('rnfoundry:em:InvalidArmatureGeometry','Armature geometry is not positive and finite.');
            end
            if ~(obj.Ryi < obj.Ryo) || obj.tcb > obj.tc
                error('rnfoundry:em:InvalidSlotGeometry','Yoke or tc/tcb geometry is invalid.');
            end
            if ~(obj.thetasg >= 0 && obj.thetasg < obj.thetacg ...
                    && obj.thetacg <= obj.thetas ...
                    && obj.thetacy > 0 && obj.thetacy <= obj.thetas)
                error('rnfoundry:em:InvalidSlotGeometry','Angular slot geometry is invalid.');
            end
            if strcmp(obj.Position,'external')
                ordered = obj.Ra < obj.Rtsb && obj.Rtsb < obj.Ryi ...
                    && obj.Rtsg >= obj.Ra && obj.Rtsg <= obj.Rtsb;
            else
                ordered = obj.Ryo < obj.Rtsb && obj.Rtsb < obj.Ra ...
                    && obj.Rtsg <= obj.Ra && obj.Rtsg >= obj.Rtsb;
            end
            if ~ordered
                error('rnfoundry:em:InvalidRadialOrder','Armature radial ordering is invalid.');
            end
            if abs(obj.tc - abs(obj.Rco-obj.Rci)) > 10*eps(max(obj.tc,1))
                error('rnfoundry:em:InconsistentGeometry','tc disagrees with the coil radii.');
            end
            obj.Winding.validate();
        end
        function s = toStruct(obj)
            s = struct('Schema','rnfoundry.em.rotary.radial.SlottedArmature', ...
                'SchemaVersion',1,'Type','SlottedArmature','Position',obj.Position, ...
                'Ryi',obj.Ryi,'Ryo',obj.Ryo,'Rtsb',obj.Rtsb,'Rtsg',obj.Rtsg, ...
                'Ra',obj.Ra,'tc',obj.tc,'tcb',obj.tcb,'thetasg',obj.thetasg, ...
                'thetacg',obj.thetacg,'thetacy',obj.thetacy, ...
                'IronMaterial',obj.IronMaterial,'Winding',obj.Winding.toStruct());
        end
    end
    methods (Static)
        function obj = fromStruct(s)
            rnfoundry.em.validateStructEnvelope( ...
                s, 'rnfoundry.em.rotary.radial.SlottedArmature', 'SlottedArmature');
            armatureStruct = s;
            armatureStruct.Winding = rnfoundry.em.winding.Winding.fromStruct(s.Winding);
            obj = rnfoundry.em.rotary.radial.SlottedArmature(armatureStruct);
        end
    end
end
