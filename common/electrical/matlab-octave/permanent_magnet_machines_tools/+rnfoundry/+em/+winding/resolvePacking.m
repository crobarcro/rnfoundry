function resolved = resolvePacking(spec, coilGeometry)
%RESOLVEPACKING Resolve legacy-compatible ordinary round-wire packing.
%   RESOLVED = resolvePacking(SPEC, COILGEOMETRY) accepts any supported pair
%   of equivalent diameter, turns and PackingFactor, plus strand count.
%   PackingFactor is legacy CoilFillFactor (insulated occupied-wire area),
%   while RESOLVED.CopperFillFactor reports actual copper area / PackArea.
%   Packing remains a winding/geometry relationship, not conductor state.
coilGeometry.validate();
area = coilGeometry.PackArea;
strandCount = getAlias(spec, {'StrandCount', 'NStrands'}, 1);
hasDiameter = hasAny(spec, {'EquivalentCopperDiameter', 'Dc'});
hasTurns = hasAny(spec, {'TurnsPerCoil', 'CoilTurns'});
hasPacking = hasAny(spec, {'PackingFactor', 'CoilFillFactor'});

if hasDiameter
    equivalentDiameter = getAlias(spec, {'EquivalentCopperDiameter', 'Dc'}, NaN);
elseif isfield(spec, 'StrandDiameter') || isfield(spec, 'WireStrandDiameter')
    strandDiameter = getAlias(spec, {'StrandDiameter', 'WireStrandDiameter'}, NaN);
    equivalentDiameter = strandDiameter .* sqrt(strandCount);
    hasDiameter = true;
end
if hasTurns
    turns = getAlias(spec, {'TurnsPerCoil', 'CoilTurns'}, NaN);
end
if hasPacking
    packingFactor = getAlias(spec, {'PackingFactor', 'CoilFillFactor'}, NaN);
end
if hasDiameter
    strandDiameter = equivalentDiameter ./ sqrt(strandCount);
end

if hasDiameter && hasPacking && ~hasTurns
    fullDiameter = rnfoundry.em.winding.insulatedWireDiameter(strandDiameter);
    strandTurns = round(area .* packingFactor ./ (pi .* (fullDiameter ./ 2).^2));
    turns = floor(strandTurns ./ strandCount);
elseif ~hasDiameter && hasTurns && hasPacking
    maxDiameter = sqrt(4 .* area .* packingFactor ./ (turns .* strandCount .* pi));
    strandDiameter = 0.99 .* maxDiameter;
    fullDiameter = rnfoundry.em.winding.insulatedWireDiameter(strandDiameter);
    while fullDiameter > maxDiameter
        strandDiameter = strandDiameter .* 0.99;
        fullDiameter = rnfoundry.em.winding.insulatedWireDiameter(strandDiameter);
    end
elseif hasDiameter && hasTurns && ~hasPacking
    fullDiameter = rnfoundry.em.winding.insulatedWireDiameter(strandDiameter);
    packingFactor = turns .* strandCount .* pi .* (fullDiameter ./ 2).^2 ./ area;
elseif ~(hasDiameter && hasTurns && hasPacking)
    error('rnfoundry:em:InsufficientPackingSpecification', ...
          'Packing requires two of equivalent diameter, turns, and packing factor.');
end

material = getAlias(spec, {'Material'}, struct());
insulation = getAlias(spec, {'Insulation'}, struct('Type', 'LegacyEnamelCorrelation'));
conductor = rnfoundry.em.winding.RoundWireConductor( ...
    material, strandCount, strandDiameter, insulation);
resolved = struct('TurnsPerCoil', turns, ...
                  'PackingFactor', packingFactor, ...
                  'Conductor', conductor, ...
                  'CopperFillFactor', turns .* conductor.CopperAreaPerTurn ./ area);
end
function tf = hasAny(s, names)
tf = false;
for k = 1:numel(names), tf = tf || isfield(s, names{k}); end
end
function value = getAlias(s, names, defaultValue)
value = defaultValue;
for k = 1:numel(names)
    if isfield(s, names{k}), value = s.(names{k}); return; end
end
end
