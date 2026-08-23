function d = baseInput(position, layers, windingCase)
if nargin < 3, windingCase = 'integral'; end
d = struct('ArmatureType',position,'Phases',3,'CoilLayers',layers, ...
    'Poles',12,'qc',fr(1,1),'yd',4,'g',0.003,'ty',0.010, ...
    'tm',0.005,'tc',[0.020,0.012],'tsb',0.002,'tbi',0.010, ...
    'tsg',0.0006,'ls',0.400,'CoilTurns',25,'CoilFillFactor',0.70, ...
    'NStrands',4,'Branches',2,'CoilArea',2.5e-4, ...
    'CoilInsulationThickness',2e-4,'MagnetSkew',0.1,'NStages',2);
switch windingCase
    case 'tooth'
        d.yd = 1;
    case 'fractional'
        d.qc = fr(1,2);
        d.yd = 2;
    case 'qc_poles'
        % Already in this form.
    case 'qc_basic'
        d = rmfield(d,'Poles');
        d.NBasicWindings = 4;
    case 'Qc_poles'
        d.Qc = 36;
        d = rmfield(d,'qc');
end
if strcmp(position,'external'), d.Ryo=0.25; else, d.Rbo=0.25; end
% Angular dimensions depend on the slot count resulting from the winding.
if isfield(d,'Poles'), poles=d.Poles; else, poles=12; end
if isfield(d,'qc'), qc=double(d.qc); else, qc=d.Qc/(poles*d.Phases); end
qcCount=qc*d.Phases*poles; slots=qcCount*(2/layers); thetas=2*pi/slots;
d.thetam=0.8*(2*pi/poles); d.thetacg=0.7*thetas;
d.thetacy=0.9*thetas; d.thetasg=0.4*d.thetacg;
d.MagFEASimMaterials=struct('Magnet',struct('Name','magnet'), ...
    'FieldBackIron',struct('Name','field iron'), ...
    'ArmatureYoke',struct('Name','armature iron'), ...
    'ArmatureCoil',struct('Name','copper','Resistivity',1.9e-8));
end
