classdef RadialPMField
    properties
        Rmi=NaN; Rmo=NaN; Rbi=NaN; Rbo=NaN
        thetam=NaN; MagnetSkew=0; MagnetMaterial=struct(); BackIronMaterial=struct()
    end
    properties (Dependent)
        Rmm; Rbm; MagnetThickness
    end
    methods
        function obj=RadialPMField(s), if nargin>0, n=fieldnames(s); allowed={'Rmi','Rmo','Rbi','Rbo','thetam','MagnetSkew','MagnetMaterial','BackIronMaterial'}; for k=1:numel(n), if any(strcmp(n{k},allowed)), obj.(n{k})=s.(n{k}); end; end; end; end
        function v=get.Rmm(obj), v=mean([obj.Rmi obj.Rmo]); end
        function v=get.Rbm(obj), v=mean([obj.Rbi obj.Rbo]); end
        function v=get.MagnetThickness(obj), v=obj.Rmo-obj.Rmi; end
        function validate(obj)
            if any(~isfinite([obj.Rbi obj.Rmi obj.Rmo obj.Rbo]))||~(obj.Rmi<obj.Rmo), error('rnfoundry:em:InvalidFieldRadii','Field radii are invalid.'); end
            if ~(obj.Rbi==obj.Rmo || obj.Rbo==obj.Rmi), error('rnfoundry:em:InvalidBackIron','Back iron must meet one magnet surface.'); end
            if ~(obj.thetam>0), error('rnfoundry:em:InvalidMagnetAngle','thetam must be positive.'); end
        end
        function s=toStruct(obj), s=struct('Type','RadialPMField','Rmi',obj.Rmi,'Rmo',obj.Rmo,'Rbi',obj.Rbi,'Rbo',obj.Rbo,'thetam',obj.thetam,'MagnetSkew',obj.MagnetSkew,'MagnetMaterial',obj.MagnetMaterial,'BackIronMaterial',obj.BackIronMaterial); end
    end
end
