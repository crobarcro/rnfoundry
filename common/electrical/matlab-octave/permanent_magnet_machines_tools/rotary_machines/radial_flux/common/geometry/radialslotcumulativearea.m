function [area,loop]=radialslotcumulativearea(geom,dividerEdgeId,radialSide)
%RADIALSLOTCUMULATIVEAREA Integrate a known face adjacent to one divider.
% The ordinary two-layer construction has exactly one divider. Starting on
% that known edge, this follows only its requested adjacent boundary loop;
% it does not discover arbitrary faces or classify labels.
if nargin<3, radialSide='inner'; end
[a1,l1,r1]=adjacentLoop(geom,dividerEdgeId,1);
[a2,l2,r2]=adjacentLoop(geom,dividerEdgeId,-1);
if strcmp(radialSide,'inner')
    if r1<=r2, area=abs(a1); loop=l1; else, area=abs(a2); loop=l2; end
elseif strcmp(radialSide,'outer')
    if r1>=r2, area=abs(a1); loop=l1; else, area=abs(a2); loop=l2; end
else
    error('rnfoundry:geometry:InvalidRadialSide','radialSide must be inner or outer.');
end
end
function [area,loop,meanRadius]=adjacentLoop(g,eid,direction)
startFrom=edgeNode(g.Edges(eid),direction,1); currentEdge=eid; currentDirection=direction;
area=0; loopEdges=[]; loopDirections=[]; radii=[];
for step=1:(2*numel(g.Edges)+1)
    e=g.Edges(currentEdge); ids=e.NodeIds; if currentDirection<0, ids=fliplr(ids); end
    p=g.Nodes(ids,:); area=area+greenareaedge(p,e,currentDirection);
    loopEdges(end+1)=currentEdge; loopDirections(end+1)=currentDirection; %#ok<AGROW>
    radii(end+1)=mean(sqrt(sum(p.^2,2))); %#ok<AGROW>
    at=ids(2);
    if at==startFrom, loop=struct('EdgeIds',loopEdges,'Directions',loopDirections); meanRadius=mean(radii); return; end
    incident=find(arrayfun(@(x) any(x.NodeIds==at),g.Edges));
    candidates=[]; candidateDirections=[]; candidateAngles=[];
    incomingReverse=tangent(g.Nodes,e,-currentDirection);
    for k=incident(:)'
        if k==currentEdge, continue; end
        ce=g.Edges(k);
        if ce.NodeIds(1)==at, cd=1; else, cd=-1; end
        candidates(end+1)=k; candidateDirections(end+1)=cd; %#ok<AGROW>
        candidateAngles(end+1)=tangent(g.Nodes,ce,cd); %#ok<AGROW>
    end
    if isempty(candidates), error('rnfoundry:geometry:OpenKnownBoundary','Known divider boundary is open.'); end
    delta=mod(incomingReverse-candidateAngles,2*pi); delta(delta<1e-12)=2*pi;
    [~,pick]=min(delta); currentEdge=candidates(pick); currentDirection=candidateDirections(pick);
end
error('rnfoundry:geometry:OpenKnownBoundary','Known divider boundary did not close.');
end
function n=edgeNode(e,d,which)
ids=e.NodeIds; if d<0, ids=fliplr(ids); end; n=ids(which);
end
function a=tangent(nodes,e,d)
ids=e.NodeIds; if d<0, ids=fliplr(ids); end; p=nodes(ids,:);
if strcmp(e.Type,'arc')
 da=e.ArcAngle*d; radial=atan2(p(1,2)-e.ArcCenter(2),p(1,1)-e.ArcCenter(1)); a=radial+sign(da)*pi/2;
else, a=atan2(p(2,2)-p(1,2),p(2,1)-p(1,1)); end
a=mod(a,2*pi);
end
