classdef RadialPMField
    %RADIALPMFIELD Canonical radial permanent-magnet field component.
    %   Rmi/Rmo are inner/outer magnet radii [m]; Rbi/Rbo describe the
    %   adjoining back iron. Materials are owned by this value object.
    %   Rmm, Rbm and component thicknesses are dependent queries.
    properties (SetAccess = private)
        Rmi
        Rmo
        Rbi
        Rbo
        thetam
        MagnetSkew
        MagnetPolarisation
        MagnetMaterial
        BackIronMaterial
    end
    properties (Dependent)
        Rmm
        Rbm
        MagnetThickness
        BackIronThickness
    end
    methods
        function obj = RadialPMField(s)
            if ~isfield(s,'MagnetPolarisation')
                s.MagnetPolarisation='constant';
            end
            names = {'Rmi','Rmo','Rbi','Rbo','thetam','MagnetSkew', ...
                     'MagnetPolarisation','MagnetMaterial','BackIronMaterial'};
            for k = 1:numel(names)
                if ~isfield(s,names{k})
                    error('rnfoundry:em:MissingFieldProperty','Missing field property %s.',names{k});
                end
                obj.(names{k}) = s.(names{k});
            end
            obj.validate();
        end
        function value = get.Rmm(obj)
            value = mean([obj.Rmi,obj.Rmo]);
        end
        function value = get.Rbm(obj)
            value = mean([obj.Rbi,obj.Rbo]);
        end
        function value = get.MagnetThickness(obj)
            value = obj.Rmo - obj.Rmi;
        end
        function value = get.BackIronThickness(obj)
            value = abs(obj.Rbo - obj.Rbi);
        end
        function validate(obj)
            radii = [obj.Rbi,obj.Rmi,obj.Rmo,obj.Rbo];
            if any(~isfinite(radii)) || any(radii <= 0)
                error('rnfoundry:em:InvalidFieldRadii','All field radii must be positive and finite.');
            end
            tolerance = 100 .* eps(max(radii));
            internalBackIron = obj.Rbi < obj.Rbo ...
                && abs(obj.Rbo - obj.Rmi) <= tolerance;
            externalBackIron = abs(obj.Rbi - obj.Rmo) <= tolerance ...
                && obj.Rmo < obj.Rbo;
            if ~(obj.Rmi < obj.Rmo) || ~(internalBackIron || externalBackIron)
                error('rnfoundry:em:InvalidFieldRadii','Magnet and back-iron radial ordering is invalid.');
            end
            if ~(obj.MagnetThickness > 0 && obj.BackIronThickness > 0)
                error('rnfoundry:em:InvalidFieldThickness','Magnet and back-iron thickness must be positive.');
            end
            if ~(isscalar(obj.thetam) && isfinite(obj.thetam) && obj.thetam > 0)
                error('rnfoundry:em:InvalidMagnetAngle','thetam must be positive and finite.');
            end
            if ~(isscalar(obj.MagnetSkew) && isfinite(obj.MagnetSkew) ...
                    && obj.MagnetSkew >= 0 && obj.MagnetSkew <= 1)
                error('rnfoundry:em:InvalidMagnetSkew','MagnetSkew must be in [0, 1].');
            end
            if ~ischar(obj.MagnetPolarisation) ...
                    || ~any(strcmpi(obj.MagnetPolarisation,{'constant','radial'}))
                error('rnfoundry:em:InvalidMagnetPolarisation', ...
                    'MagnetPolarisation must be constant or radial.');
            end
        end
        function s = toStruct(obj)
            s = struct('Schema','rnfoundry.em.rotary.radial.RadialPMField', ...
                'SchemaVersion',1,'Type','RadialPMField','Rmi',obj.Rmi,'Rmo',obj.Rmo, ...
                'Rbi',obj.Rbi,'Rbo',obj.Rbo,'thetam',obj.thetam, ...
                'MagnetSkew',obj.MagnetSkew, ...
                'MagnetPolarisation',obj.MagnetPolarisation, ...
                'MagnetMaterial',obj.MagnetMaterial, ...
                'BackIronMaterial',obj.BackIronMaterial);
        end
    end
    methods (Static)
        function obj = fromStruct(s)
            rnfoundry.em.validateStructEnvelope( ...
                s, 'rnfoundry.em.rotary.radial.RadialPMField', 'RadialPMField');
            obj = rnfoundry.em.rotary.radial.RadialPMField(s);
        end
    end
end
