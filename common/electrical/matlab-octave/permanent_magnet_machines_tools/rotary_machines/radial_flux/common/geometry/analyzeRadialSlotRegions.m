function geom=analyzeRadialSlotRegions(geom)
%ANALYZERADIALSLOTREGIONS Trace, validate, label, and integrate slot faces.
faces=traceFaces(geom.Nodes,geom.Edges);
labels=geom.CoilLabelLocations;
regions=repmat(struct('LabelIndex',0,'FaceIndex',0,'BoundaryEdgeIds',[], ...
    'BoundaryDirections',[],'Area',0,'IsClosed',false,'HalfEdgeCount',0),size(labels,1),1);
assigned=zeros(size(labels,1),1);
for k=1:size(labels,1)
    containing=[];
    for j=1:numel(faces)
        if faces(j).IsClosed && isfinite(faces(j).Area) && faces(j).Area>0 && ...
                inpolygon(labels(k,1),labels(k,2),faces(j).Polygon(:,1),faces(j).Polygon(:,2))
            containing(end+1)=j; %#ok<AGROW>
        end
    end
    if isempty(containing)
        error('rnfoundry:geometry:LabelOutsideFace','A coil label was not enclosed by a valid slot face.');
    end
    areas=[faces(containing).Area]; smallest=min(areas);
    selected=containing(abs(areas-smallest)<=max(1e-14*smallest,100*eps(smallest)));
    if numel(selected)~=1
        error('rnfoundry:geometry:AmbiguousLabelFace','A coil label resolved ambiguously to multiple physical faces.');
    end
    assigned(k)=selected;
    if any(assigned(1:k-1)==selected)
        error('rnfoundry:geometry:DuplicateLabelFace','Multiple coil labels resolved to the same physical face.');
    end
    f=faces(selected);
    regions(k)=struct('LabelIndex',k,'FaceIndex',selected, ...
        'BoundaryEdgeIds',f.EdgeIds,'BoundaryDirections',f.Directions, ...
        'Area',f.Area,'IsClosed',f.IsClosed,'HalfEdgeCount',f.HalfEdgeCount);
end
geom.Faces=faces; geom.CoilRegions=regions;
geom.LayerPackAreas=reshape([regions.Area],[],1);
geom.TotalPackArea=sum(geom.LayerPackAreas);
counts=zeros(numel(geom.Edges),1);
for k=1:numel(regions), counts(regions(k).BoundaryEdgeIds)=counts(regions(k).BoundaryEdgeIds)+1; end
geom.PartitionEdgeIds=find(counts>1)';
if isempty(geom.PartitionEdgeIds), geom.MinimumPartitionEdgeLength=Inf;
else, geom.MinimumPartitionEdgeLength=min([geom.Edges(geom.PartitionEdgeIds).Length]); end
end

function faces=traceFaces(nodes,edges)
ne=numel(edges); from=zeros(2*ne,1); to=from; eid=from; dir=from; ang=from;
for k=1:ne
    ids=edges(k).NodeIds;
    if numel(ids)~=2 || any(ids<1) || any(ids>size(nodes,1)) || ids(1)==ids(2)
        error('rnfoundry:geometry:MalformedEdge','Slot graph contains an invalid edge.');
    end
    if strcmp(edges(k).Type,'arc')
        p=nodes(ids,:); radii=sqrt(sum((p-edges(k).ArcCenter).^2,2)); tol=max(1e-12,1e-10*max(radii));
        if any(~isfinite(radii)) || abs(diff(radii))>tol
            error('rnfoundry:geometry:InvalidArcRadius','An arc has endpoints at different radii.');
        end
        if ~isfinite(edges(k).ArcAngle) || edges(k).ArcAngle==0 || ...
                ~isfinite(edges(k).Length) || edges(k).Length<=0
            error('rnfoundry:geometry:InvalidArc','An arc is zero or non-finite.');
        end
    end
    for s=1:2
        h=2*k-2+s; from(h)=ids(s); to(h)=ids(3-s); eid(h)=k; dir(h)=3-2*s;
        ang(h)=tangentAngle(nodes,edges(k),dir(h));
    end
end
outgoing=cell(size(nodes,1),1);
for h=1:2*ne, outgoing{from(h)}=[outgoing{from(h)},h]; end %#ok<AGROW>
used=false(2*ne,1);
faces=struct('EdgeIds',{},'Directions',{},'Area',{},'Polygon',{}, ...
             'IsClosed',{},'HalfEdgeCount',{});
for seed=1:2*ne
    if used(seed), continue; end
    hs=[]; h=seed;
    for step=1:2*ne+1
        if used(h), break; end
        used(h)=true; hs(end+1)=h; %#ok<AGROW>
        candidates=outgoing{to(h)}; twin=h+1; if mod(h,2)==0, twin=h-1; end
        delta=mod(ang(twin)-ang(candidates),2*pi); delta(delta<1e-12)=2*pi;
        [~,ix]=min(delta); h=candidates(ix);
    end
    if h~=seed
        error('rnfoundry:geometry:OpenFaceWalk','A face walk did not return to its starting half-edge.');
    end
    ids=eid(hs); ds=dir(hs); area=0; poly=[];
    for z=1:numel(ids)
        e=edges(ids(z)); ij=e.NodeIds; if ds(z)<0, ij=fliplr(ij); end
        p=nodes(ij,:);
        if strcmp(e.Type,'arc')
            da=e.ArcAngle*ds(z); c=e.ArcCenter; r=e.Radius;
            t0=atan2(p(1,2)-c(2),p(1,1)-c(1)); t1=t0+da;
            area=area+0.5*(r*r*da + r*c(1)*(sin(t1)-sin(t0)) ...
                                      - r*c(2)*(cos(t1)-cos(t0)));
            tt=t0+linspace(0,da,max(2,ceil(abs(da)/(pi/180))+1));
            pts=[c(1)+r*cos(tt(:)),c(2)+r*sin(tt(:))];
        else
            area=area+0.5*(p(1,1)*p(2,2)-p(2,1)*p(1,2)); pts=p;
        end
        poly=[poly;pts(1:end-1,:)]; %#ok<AGROW>
    end
    isClosed=true;
    poly=[poly;poly(1,:)];
    faces(end+1)=struct('EdgeIds',ids,'Directions',ds,'Area',area,'Polygon',poly, ...
        'IsClosed',isClosed,'HalfEdgeCount',numel(hs)); %#ok<AGROW>
end
end
function a=tangentAngle(nodes,e,d)
ij=e.NodeIds; if d<0, ij=fliplr(ij); end; p=nodes(ij,:);
if strcmp(e.Type,'arc')
    da=e.ArcAngle*d; radial=atan2(p(1,2)-e.ArcCenter(2),p(1,1)-e.ArcCenter(1)); a=radial+sign(da)*pi/2;
else
    a=atan2(p(2,2)-p(1,2),p(2,1)-p(1,1));
end
a=mod(a,2*pi);
end
