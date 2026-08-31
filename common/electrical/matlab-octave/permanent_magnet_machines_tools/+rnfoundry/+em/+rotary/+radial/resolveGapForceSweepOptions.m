function options = resolveGapForceSweepOptions(machine,options)
%RESOLVEGAPFORCESWEEPOPTIONS Validate the single public sampling choice.
if nargin < 2 || isempty(options), options=struct(); end
if ~isa(machine,'rnfoundry.em.rotary.radial.SlottedPMMachine') || ~isstruct(options)
    error('rnfoundry:em:InvalidGapForceSweepOptions','Expected a slotted machine and options struct.');
end
names=fieldnames(options);
if any(~ismember(names,{'Displacements'}))
    error('rnfoundry:em:InvalidGapForceSweepOptions','Only Displacements is a public option.');
end
if ~isfield(options,'Displacements')
    options.Displacements=[linspace(0,0.9*machine.g,3),0.95*machine.g];
end
d=options.Displacements;
if ~isnumeric(d) || ~isreal(d) || ~isvector(d) || isempty(d) ...
        || any(~isfinite(d(:))) || any(d(:)<0) || any(d(:)>=machine.g)
    error('rnfoundry:em:InvalidGapForceSweepOptions', ...
        'Displacements must be a finite real vector in [0,g).');
end
options.Displacements=d(:);
end
