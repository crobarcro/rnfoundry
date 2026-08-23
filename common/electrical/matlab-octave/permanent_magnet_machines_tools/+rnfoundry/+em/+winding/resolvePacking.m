function resolved = resolvePacking(spec, coilGeometry)
%RESOLVEPACKING Pure legacy-compatible round-wire packing resolution.
area=coilGeometry.PackArea;
if isfield(spec,'StrandCount'), nstrands=spec.StrandCount; elseif isfield(spec,'NStrands'), nstrands=spec.NStrands; else, nstrands=1; end
hasD=isfield(spec,'EquivalentCopperDiameter')||isfield(spec,'Dc'); hasT=isfield(spec,'TurnsPerCoil')||isfield(spec,'CoilTurns'); hasF=isfield(spec,'PackingFactor')||isfield(spec,'CoilFillFactor');
if isfield(spec,'EquivalentCopperDiameter'), dc=spec.EquivalentCopperDiameter; elseif isfield(spec,'Dc'), dc=spec.Dc; end
if isfield(spec,'TurnsPerCoil'), turns=spec.TurnsPerCoil; elseif isfield(spec,'CoilTurns'), turns=spec.CoilTurns; end
if isfield(spec,'PackingFactor'), pf=spec.PackingFactor; elseif isfield(spec,'CoilFillFactor'), pf=spec.CoilFillFactor; end
if ~hasD && isfield(spec,'StrandDiameter'), strand=spec.StrandDiameter; dc=strand*sqrt(nstrands); hasD=true; end
if hasD, strand=dc/sqrt(nstrands); end
if hasD && hasF && ~hasT
    full=rnfoundry.em.winding.insulatedWireDiameter(strand); raw=area*pf/(pi*(full/2)^2); turns=floor(round(raw)/nstrands);
elseif ~hasD && hasT && hasF
    maxd=sqrt(4*area*pf/(turns*nstrands*pi)); strand=0.99*maxd; full=rnfoundry.em.winding.insulatedWireDiameter(strand);
    while full>maxd, strand=strand*0.99; full=rnfoundry.em.winding.insulatedWireDiameter(strand); end
    dc=strand*sqrt(nstrands);
elseif hasD && hasT && ~hasF
    full=rnfoundry.em.winding.insulatedWireDiameter(strand); pf=turns*nstrands*pi*(full/2)^2/area;
elseif ~(hasD&&hasT&&hasF)
    error('rnfoundry:em:InsufficientPackingSpecification','Packing requires two of diameter, turns and packing factor.');
end
conductor=rnfoundry.em.winding.RoundWireConductor(getfielddefault(spec,'Material',struct()),nstrands,strand,getfielddefault(spec,'Insulation',struct()));
resolved=struct('TurnsPerCoil',turns,'PackingFactor',pf,'Conductor',conductor,'CopperFillFactor',turns*conductor.CopperAreaPerTurn/area);
end
function v=getfielddefault(s,n,d), if isfield(s,n), v=s.(n); else, v=d; end; end
