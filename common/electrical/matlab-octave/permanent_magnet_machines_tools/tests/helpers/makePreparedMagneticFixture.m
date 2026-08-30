function [machine,result]=makePreparedMagneticFixture(layerCount,skew,duplicatePositions)
%MAKEPREPAREDMAGNETICFIXTURE Representative deterministic raw 2A data.
machine=makeExternalSlottedMachine();
if nargin < 1, layerCount=2; end
if nargin < 2, skew=machine.Field.MagnetSkew; end
if nargin < 3, duplicatePositions=false; end
machine=setFixtureWinding(machine,layerCount,skew);
p=linspace(0,1,9).';
if duplicatePositions
    % Sweep increments and half-pole slot spacing create exact duplicates.
    slotBase=[-1,-0.5,0,0.5,1,1.5];
else
    slotBase=[-1,-0.57,-0.13,0.31,0.76,1.23];
end
slotPosition=bsxfun(@plus,p,slotBase);
n=numel(p); ns=numel(slotBase);
slotIntegral=zeros(n,ns,layerCount,1);
for k=1:layerCount
    x=slotPosition;
    slotIntegral(:,:,k,1)=1e-8*(1.1*cos(pi*x+0.37*k) ...
        +0.23*sin(2*pi*x-0.19*k)+0.07*cos(3*pi*x+0.11));
end
torque=0.7*sin(2*pi*p+0.2)+0.19*sin(4*pi*p-0.4)-0.08*cos(6*pi*p);
s=makeMagneticSweepData(n);
s.Positions=p; s.CoggingTorque=torque;
s.DirectFluxLinkage=repmat(50+7*p,1,3); % Deliberately unrelated diagnostic.
s.SlotVectorPotential=struct('Position',slotPosition,'Integral',slotIntegral);
s.CoilArea=1.7e-4; % Deliberately differs from canonical PackArea (Issue #5 seam).
s.Provenance=struct('Solver','fixture','NPositions',n, ...
    'PhaseCurrents',zeros(machine.Armature.Winding.PhaseCount,1));
result=rnfoundry.em.fea.MagneticSweepResult(s);
end

function machine=setFixtureWinding(machine,layerCount,skew)
ms=machine.toStruct(); ws=ms.Armature.Winding;
if layerCount==1
    ws.LayerCount=1; ws.CoilCount=18; ws.BasicCoilCount=3;
    ws.BasicPoleCount=2; ws.BasicWindingRepetitions=6; ws.BasicSlotCount=6;
    ws.qcn=1; ws.qcd=2;
    ws.Layout.Coils=reshape(mod(0:35,36)+1,6,6);
    ws.Layout.Phases=repmat([1;-1;2;-2;3;-3],6,1);
end
ms.Field.MagnetSkew=skew; ms.Armature.Winding=ws;
machine=rnfoundry.em.rotary.radial.SlottedPMMachine.fromStruct(ms);
end
