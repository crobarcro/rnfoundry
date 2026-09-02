function geom = radialslotgeometry(varargin)
%RADIALSLOTGEOMETRY Authoritative solver-free radial-slot construction.
%   Ordinary radial layers default to equal physical area.  The
%   'legacy-local' LayerPartitionMode retains the Issue-5A construction.
%   SplitSlot and single-layer constructions never use the depth solver.
opts=struct('NWindingLayers',1,'SplitSlot',false,'DrawCoilInsulation',false, ...
    'LayerPartitionMode','equal-physical-area','PartitionSnapTolerance',[], ...
    'MinimumPhysicalFeature',[],'PartitionAreaTolerance',5e-13, ...
    'PartitionMaxIterations',80);
for k=9:2:numel(varargin)
    if isfield(opts,varargin{k}), opts.(varargin{k})=varargin{k+1}; end
end
legacyArgs=varargin;
remove={'LayerPartitionMode','PartitionSnapTolerance','MinimumPhysicalFeature', ...
        'PartitionAreaTolerance','PartitionMaxIterations'};
for j=1:numel(remove)
    k=9;
    while k<=numel(legacyArgs)
        if strcmp(legacyArgs{k},remove{j}), legacyArgs(k:k+1)=[]; else, k=k+2; end
    end
end
geom=radialslotgeometrylegacy(legacyArgs{:});
geom.LegacyLocalNodes=geom.LocalNodes; geom.LegacyLocalCoilLabelLocations=geom.LocalCoilLabelLocations;
if opts.DrawCoilInsulation && opts.NWindingLayers>1 && ~opts.SplitSlot && strcmp(opts.LayerPartitionMode,'equal-physical-area')
    plain=varargin;
    for kk=9:2:numel(plain), if strcmp(plain{kk},'DrawCoilInsulation'), plain{kk+1}=false; end; end
    unins=radialslotgeometry(plain{:}); ua=radialslotknownareas(unins); ia=radialslotknownareas(geom);
    ur=sort([unins.Edges(ua.PartitionEdgeIds).Radius]); ids=ia.PartitionEdgeIds; ir=[geom.Edges(ids).Radius]; [~,io]=sort(ir);
    geom.PartitionEdgeIds=ids; geom.CoilRadialBounds=unins.CoilRadialBounds;
    for kk=1:numel(ids), [geom,ok]=candidateAtRadius(geom,ids(io(kk)),ur(kk)); if ~ok, error('rnfoundry:geometry:NoSafePartition','Insulation boundary cannot accept frozen divider.'); end; end
    final=radialslotknownareas(geom); diag=unins.PartitionDiagnostics; diag.AchievedRegionAreas=final.LayerPackAreas; diag.RelativeAreaImbalance=(max(final.LayerPackAreas)-min(final.LayerPackAreas))/mean(final.LayerPackAreas); diag.PartitionPositions=ur; geom.PartitionDiagnostics=diag; return;
end
if opts.SplitSlot
    mode='split-slot';
elseif opts.NWindingLayers==1
    mode='single-layer';
elseif strcmp(opts.LayerPartitionMode,'legacy-local')
    mode='legacy-local';
elseif strcmp(opts.LayerPartitionMode,'equal-physical-area') && opts.NWindingLayers==2
    [geom,diag]=equalRadialPartitions(geom,opts);
    geom.PartitionDiagnostics=diag;
    return;
elseif strcmp(opts.LayerPartitionMode,'equal-physical-area')
    error('rnfoundry:geometry:UnsupportedLayerCount','Equal physical area currently supports exactly two ordinary layers.');
else
    error('rnfoundry:geometry:InvalidPartitionMode', ...
          'LayerPartitionMode must be equal-physical-area or legacy-local.');
end
analyzed=radialslotknownareas(geom);
geom.PartitionDiagnostics=makeDiagnostics(mode,analyzed.LayerPackAreas,[],0,false,'',{});
end

function [geom,diag]=equalRadialPartitions(geom,opts)
% The topology is supplied by the Cartesian construction, but its divider
% radii are replaced using bounded bisection on exact line/arc face areas.
a=radialslotknownareas(geom); ids=a.PartitionEdgeIds; geom.PartitionEdgeIds=ids;
if numel(ids)~=numel(a.LayerPackAreas)-1
    error('rnfoundry:geometry:InvalidPartitionTopology','Expected one divider between adjacent radial layers.');
end
rall=sqrt(sum(geom.AuthoritativeBoundaryNodes.^2,2)); scale=max(rall);
feature=opts.MinimumPhysicalFeature; if isempty(feature), feature=max(2e-6,1e-6*scale); end
snap=opts.PartitionSnapTolerance; if isempty(snap), snap=2*feature; end
% Region labels establish cumulative radial ordering independently for internal/external slots.
labelr=sqrt(sum(geom.CoilLabelLocations.^2,2)); [labelr,ord]=sort(labelr);
if numel(labelr)>1, gap=median(diff(labelr)); else, gap=max(rall)-min(rall); end
geom.CoilRadialBounds=[labelr(1)-gap/2,labelr(end)+gap/2];
total=sum(a.LayerPackAreas); targets=(1:numel(ids))'*total/(numel(ids)+1);
positions=zeros(numel(ids),1); idealPositions=zeros(numel(ids),1); iterations=zeros(numel(ids),1); adjusted=false; reasons={}; snapped={};
partitionR=zeros(numel(ids),1);
for q=1:numel(ids), partitionR(q)=mean(sqrt(sum(geom.Nodes(geom.Edges(ids(q)).NodeIds,:).^2,2))); end
[partitionR,edgeOrder]=sort(partitionR);
for q=1:numel(ids)
    edgeId=ids(edgeOrder(q)); target=targets(q);
    edgeNodes=geom.Edges(edgeId).NodeIds; ranges=zeros(2,2);
    for zz=1:2
        rr=find(geom.BoundaryChordAttachments(:,1)==edgeNodes(zz),1);
        if isempty(rr), error('rnfoundry:geometry:NoSafePartition','Divider endpoint is an existing feature and cannot be moved safely.'); end
        pp=geom.AuthoritativeBoundaryNodes(geom.BoundaryChordAttachments(rr,2:3),:);
        radii=sqrt(sum(pp.^2,2)); ranges(zz,:)=[min(radii),max(radii)];
    end
    lo=max(ranges(:,1))+feature; hi=min(ranges(:,2))-feature;
    if q>1, lo=max(lo,positions(q-1)+feature); end
    if q<numel(ids), hi=min(hi,partitionR(q+1)-feature); end
    safeLo=lo; safeHi=hi;
    [glo,oklo]=candidateAtRadius(geom,edgeId,lo); [ghi,okhi]=candidateAtRadius(geom,edgeId,hi);
    if ~(oklo&&okhi), error('rnfoundry:geometry:NoSafePartition','No valid divider bracket exists.'); end
    flo=cumulativeArea(glo,ord,q)-target; fhi=cumulativeArea(ghi,ord,q)-target;
    if flo*fhi>0, error('rnfoundry:geometry:NonMonotonicPartition','Physical cumulative area does not bracket its target.'); end
    for it=1:opts.PartitionMaxIterations
        mid=(lo+hi)/2; [gm,ok]=candidateAtRadius(geom,edgeId,mid);
        if ~ok, error('rnfoundry:geometry:NoSafePartition','A divider could not intersect both authoritative sides.'); end
        fm=cumulativeArea(gm,ord,q)-target;
        if abs(fm)<=opts.PartitionAreaTolerance*total, break; end
        if flo*fm<=0, hi=mid; fhi=fm; else, lo=mid; flo=fm; end %#ok<NASGU>
    end
    idealPositions(q)=mid;
    clearance=partitionClearance(gm,edgeId);
    if clearance<feature || clearance<snap
        steps=feature*[1 2 4 8 16]; candidates=reshape([mid-steps;mid+steps],1,[]); best=[]; besterr=Inf; bestpos=NaN;
        for cc=1:numel(candidates)
            if candidates(cc)<=safeLo || candidates(cc)>=safeHi, continue; end
            [gc,ok]=candidateAtRadius(geom,edgeId,candidates(cc));
            if ok && partitionClearance(gc,edgeId)>=feature
                err=abs(cumulativeArea(gc,ord,q)-target);
                if err<besterr, best=gc; besterr=err; bestpos=candidates(cc); end
            end
        end
        if isempty(best), error('rnfoundry:geometry:NoSafePartition','No topology-safe divider placement exists in the valid bracket.'); end
        gm=best; mid=bestpos; adjusted=true;
        reasons{end+1}='ideal divider was inside the physical feature-clearance band'; %#ok<AGROW>
        snapped{end+1}='nearest safe chord location'; %#ok<AGROW>
    end
    positions(q)=mid; iterations(q)=it; geom=gm;
end
final=radialslotknownareas(geom); achieved=final.LayerPackAreas;
diag=makeDiagnostics('equal-physical-area',achieved,targets,iterations,adjusted,strjoin(reasons,'; '),snapped);
diag.IdealPartitionPositions=idealPositions; diag.PartitionPositions=positions; diag.MinimumNodeSeparation=geom.MinimumNodeSeparation;
diag.MinimumStraightEdgeLength=geom.MinimumStraightSegmentLength;
diag.MinimumArcLength=geom.MinimumArcLength; diag.MinimumDividerSpacing=minimumDiff(positions);
end
function value=cumulativeArea(g,ord,q)
a=radialslotknownareas(g); value=sum(a.LayerPackAreas(ord(1:q)));
end
function value=partitionClearance(g,eid)
value=Inf; ids=g.Edges(eid).NodeIds;
for zz=1:2
 row=find(g.BoundaryChordAttachments(:,1)==ids(zz),1);
 if isempty(row), value=0; return; end
 pair=g.BoundaryChordAttachments(row,2:3); p=g.AuthoritativeBoundaryNodes(pair,:);
 value=min(value,min(sqrt(sum((p-g.Nodes(ids(zz),:)).^2,2))));
end
value=min(value,g.Edges(eid).Length);
end
function [g,ok]=candidateAtRadius(g,eid,r)
ids=g.Edges(eid).NodeIds; ok=true;
for z=1:2
    n=ids(z); row=find(g.BoundaryChordAttachments(:,1)==n,1);
    if isempty(row), ok=false; return; end
    pair=g.BoundaryChordAttachments(row,2:3); p=g.AuthoritativeBoundaryNodes(pair,:);
    v=p(2,:)-p(1,:); rrts=roots([dot(v,v),2*dot(p(1,:),v),dot(p(1,:),p(1,:))-r*r]);
    rrts=rrts(abs(imag(rrts))<1e-12); rrts=real(rrts); rrts=rrts(rrts>0 & rrts<1);
    if isempty(rrts), ok=false; return; end
    t=rrts(1); g.Nodes(n,:)=p(1,:)+t*v; g.BoundaryChordAttachments(row,4)=t;
end
g=refreshGeometry(g,eid); g=relabelRegions(g); g=synchronizeCoordinates(g);
end
function g=relabelRegions(g)
pr=[g.Edges(g.PartitionEdgeIds).Radius];
if isempty(pr), return; end
lr=sqrt(sum(g.CoilLabelLocations.^2,2)); [~,oo]=sort(lr); br=[g.CoilRadialBounds(1),sort(pr),g.CoilRadialBounds(2)];
for kk=1:numel(oo), ang=atan2(g.CoilLabelLocations(oo(kk),2),g.CoilLabelLocations(oo(kk),1)); rad=mean(br(kk:kk+1)); g.CoilLabelLocations(oo(kk),:)=[rad*cos(ang),rad*sin(ang)]; end
g.SlotInfo.coillabelloc=g.CoilLabelLocations;
end

function g=synchronizeCoordinates(g)
% Keep every current Cartesian/polar/local representation coherent while
% retaining explicitly named frozen legacy-local coordinates.
oldR=g.MappedRadialNodes(:,1); oldLocal=g.LocalNodes(:,1);
[theta,radius]=cart2pol(g.Nodes(:,1),g.Nodes(:,2));
signMap=1; c=corrcoef(oldR,oldLocal); if numel(c)>=4 && c(1,2)<0, signMap=-1; end
g.LocalNodes(:,1)=oldLocal+signMap*(radius-oldR); g.LocalNodes(:,2)=theta;
g.RadialNodes=[radius,theta]; g.MappedRadialNodes=g.RadialNodes;
oldLR=sqrt(sum(g.RadialCoilLabelLocations.^2,2)); oldLL=g.LocalCoilLabelLocations(:,1);
[lt,lr]=cart2pol(g.CoilLabelLocations(:,1),g.CoilLabelLocations(:,2));
g.LocalCoilLabelLocations(:,1)=oldLL+signMap*(lr-oldLR);
g.LocalCoilLabelLocations(:,2)=lt; g.RadialCoilLabelLocations=[lr,lt];
g.SlotInfo.coillabelloc=g.CoilLabelLocations;
end
function g=refreshGeometry(g,dividerId)
for k=1:numel(g.Edges)
 p=g.Nodes(g.Edges(k).NodeIds,:);
 if strcmp(g.Edges(k).Type,'arc')
  if k==dividerId
   da=signedAngle(p(1,:),p(2,:)); g.Edges(k).ArcAngle=da; g.Edges(k).ArcCenter=[0 0];
   g.Edges(k).Radius=mean(sqrt(sum(p.^2,2)));
  end
  g.Edges(k).Length=abs(g.Edges(k).ArcAngle)*g.Edges(k).Radius;
 else, g.Edges(k).Length=norm(diff(p)); end
end
g.MinimumNodeSeparation=minsep(g.Nodes); ll=[g.Edges.Length];
g.MinimumEdgeLength=min(ll); g.MinimumStraightSegmentLength=minOrInf(ll(strcmp({g.Edges.Type},'segment')));
g.MinimumArcLength=minOrInf(ll(strcmp({g.Edges.Type},'arc')));
end
function d=makeDiagnostics(mode,areas,targets,it,adjusted,reason,snapped)
d=struct('PartitionMode',mode,'TargetRegionAreas',targets,'AchievedRegionAreas',areas, ...
 'RelativeAreaImbalance',(max(areas)-min(areas))/mean(areas),'IdealPartitionPositions',[],'PartitionPositions',[], ...
 'Iterations',it,'Adjusted',adjusted,'AdjustmentReason',reason,'SnappedFeature',{snapped}, ...
 'MinimumNodeSeparation',NaN,'MinimumStraightEdgeLength',NaN,'MinimumArcLength',NaN,'MinimumDividerSpacing',Inf);
end
function a=signedAngle(p,q), a=atan2(p(1)*q(2)-p(2)*q(1),p(1)*q(1)+p(2)*q(2)); end
function d=minsep(n), d=Inf; for i=1:size(n,1)-1, d=min(d,min(sqrt(sum((n(i+1:end,:)-n(i,:)).^2,2)))); end; end
function v=minOrInf(x), if isempty(x), v=Inf; else, v=min(x); end; end
function v=minimumDiff(x), if numel(x)<2, v=Inf; else, v=min(diff(sort(x))); end; end
