classdef SlottedArmature
    properties
        Position='external'; Ryi=NaN; Ryo=NaN; Rtsb=NaN; Rtsg=NaN; Ra=NaN
        tc=NaN; tcb=NaN; ty=NaN; tsb=NaN; tsg=NaN
        thetas=NaN; thetasg=NaN; thetacg=NaN; thetacy=NaN
        IronMaterial=struct(); Winding=[]
    end
    properties (Dependent)
        Rym; Rci; Rco; Rcm; Rcb; thetac; tcbVtc
    end
    methods
        function obj=SlottedArmature(s), if nargin>0, n=fieldnames(s); allowed={'Position','Ryi','Ryo','Rtsb','Rtsg','Ra','tc','tcb','ty','tsb','tsg','thetas','thetasg','thetacg','thetacy','IronMaterial','Winding'}; for k=1:numel(n), if any(strcmp(n{k},allowed)), obj.(n{k})=s.(n{k}); end; end; end; end
        function v=get.Rym(obj), v=mean([obj.Ryi obj.Ryo]); end
        function v=get.Rci(obj), if strcmp(obj.Position,'external'), v=obj.Rtsb; else, v=obj.Ryo; end; end
        function v=get.Rco(obj), if strcmp(obj.Position,'external'), v=obj.Ryi; else, v=obj.Rtsb; end; end
        function v=get.Rcm(obj), v=mean([obj.Rci obj.Rco]); end
        function v=get.Rcb(obj), if strcmp(obj.Position,'external'), v=obj.Rco-obj.tcb; else, v=obj.Rci+obj.tcb; end; end
        function v=get.thetac(obj), v=[obj.thetacg obj.thetacy]; end
        function v=get.tcbVtc(obj), v=obj.tcb/obj.tc; end
        function validate(obj)
            if ~any(strcmp(obj.Position,{'internal','external'})), error('rnfoundry:em:InvalidPosition','Position must be internal or external.'); end
            vals=[obj.Ryi obj.Ryo obj.Rtsb obj.Rtsg obj.Ra obj.tc obj.tcb obj.ty obj.tsb obj.tsg obj.thetas obj.thetasg obj.thetacg obj.thetacy];
            if any(~isfinite(vals))||any(vals<0)||any(vals([1:9 11:14])==0), error('rnfoundry:em:InvalidArmatureGeometry','Armature dimensions must be positive.'); end
            if ~(obj.Ryi<obj.Ryo) || obj.tcb>obj.tc || obj.thetasg>=obj.thetacg || obj.thetacg>obj.thetas || obj.thetacy>obj.thetas, error('rnfoundry:em:InvalidSlotGeometry','Slot geometry is inconsistent.'); end
            if strcmp(obj.Position,'external') && ~(obj.Ra<obj.Rtsb && obj.Rtsb<obj.Ryi), error('rnfoundry:em:InvalidRadialOrder','External armature radii are inconsistent.'); end
            if strcmp(obj.Position,'internal') && ~(obj.Ryo<obj.Rtsb && obj.Rtsb<obj.Ra), error('rnfoundry:em:InvalidRadialOrder','Internal armature radii are inconsistent.'); end
            obj.Winding.validate();
        end
        function s=toStruct(obj), s=struct('Type','SlottedArmature','Position',obj.Position,'Ryi',obj.Ryi,'Ryo',obj.Ryo,'Rtsb',obj.Rtsb,'Rtsg',obj.Rtsg,'Ra',obj.Ra,'tc',obj.tc,'tcb',obj.tcb,'ty',obj.ty,'tsb',obj.tsb,'tsg',obj.tsg,'thetas',obj.thetas,'thetasg',obj.thetasg,'thetacg',obj.thetacg,'thetacy',obj.thetacy,'IronMaterial',obj.IronMaterial,'Winding',obj.Winding.toStruct()); end
    end
end
