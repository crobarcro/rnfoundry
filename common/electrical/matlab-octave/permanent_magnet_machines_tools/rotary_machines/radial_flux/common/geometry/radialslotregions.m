function geom = radialslotregions(thetacoil, thetashoegap, ryoke, rcoil, ...
                                    rshoebase, rshoegap, roffset, side, varargin)
%RADIALSLOTREGIONS Pure geometry and exact areas for one radial coil slot.
%   GEOM reuses INTERNALSLOTNODELINKS and applies exactly the reflection,
%   radial offset and POL2CART mapping used by CURVEDSTATORHALF2DFEMMPROBLEM.
%   It has no FEMM or solver dependency.  Ordinary winding-layer boundaries
%   remain the legacy equal-local-area boundaries; changing their radial
%   placement is deliberately deferred to Issue #5B.
%
%   Curves sampled by INTERNALSLOTNODELINKS remain straight FEMM segments.
%   Only links in VERTLINKINDS become origin-centred circular arcs.  Region
%   area is evaluated exactly over those actual segment/arc primitives by
%   Green's theorem; curve sampling is used only to identify the face that
%   contains each authoritative coil label.

    in.NWindingLayers = 1;
    in.Tol = 1e-5;
    in.CoilBaseFraction = 0.05;
    in.ShoeCurveControlFrac = 0.5;
    in.SplitSlot = false;
    in.DrawCoilInsulation = false;
    in.CoilInsulationThickness = 0;
    in = parse_pv_pairs(in, varargin);
    if in.SplitSlot
        if in.NWindingLayers ~= 2
            error('If SplitSlot is true, NWindingLayers must be equal to 2');
        end
        layers = 1;
    else
        layers = in.NWindingLayers;
    end
    tins = 0;
    if in.DrawCoilInsulation, tins = in.CoilInsulationThickness; end
    [localNodes, links, info] = internalslotnodelinks( ...
        thetacoil, thetashoegap, ryoke/2, rcoil, rshoebase, rshoegap, ...
        layers, in.Tol, 'CoilBaseFraction', in.CoilBaseFraction, ...
        'InsulationThickness', tins, ...
        'ShoeCurveControlFrac', in.ShoeCurveControlFrac, ...
        'YScale', roffset + ryoke + rcoil/2, 'SplitX', in.SplitSlot);

    % Ordinary layers may add points to a straight local slot side.  After
    % radial mapping those points would bend the FEMM chord used by the
    % one-layer geometry.  Capture the authoritative one-layer perimeter so
    % newly-created divider endpoints can instead be attached to that fixed
    % physical chord.  The generic Cartesian generator remains unchanged.
    boundaryLocalNodes=localNodes; boundaryLinks=links; boundaryInfo=info;
    if layers > 1
        [boundaryLocalNodes,boundaryLinks,boundaryInfo]=internalslotnodelinks( ...
            thetacoil,thetashoegap,ryoke/2,rcoil,rshoebase,rshoegap,1,in.Tol, ...
            'CoilBaseFraction',in.CoilBaseFraction,'InsulationThickness',tins, ...
            'ShoeCurveControlFrac',in.ShoeCurveControlFrac, ...
            'YScale',roffset+ryoke+rcoil/2);
    end
    chordAttachments=findChordAttachments(localNodes,links,boundaryLocalNodes,boundaryLinks,in.Tol);

    localLabels = info.coillabelloc;
    localInsLabels = info.inslabelloc;
    localShoeLabels = info.shoegaplabelloc;
    if strcmp(side, 'i')
        localNodes(:,1) = -localNodes(:,1);
        boundaryLocalNodes(:,1) = -boundaryLocalNodes(:,1);
        localLabels(:,1) = -localLabels(:,1);
        if ~isempty(localInsLabels), localInsLabels(:,1)=-localInsLabels(:,1); end
        if ~isempty(localShoeLabels), localShoeLabels(:,1)=-localShoeLabels(:,1); end
        info.cornernodes = info.cornernodes([2 1 4 3]);
    elseif ~strcmp(side, 'o')
        error('side must be ''i'' or ''o''.');
    end
    localNodes(:,1) = localNodes(:,1) + roffset;
    boundaryLocalNodes(:,1) = boundaryLocalNodes(:,1) + roffset;
    localLabels(:,1) = localLabels(:,1) + roffset;
    if ~isempty(localInsLabels), localInsLabels(:,1)=localInsLabels(:,1)+roffset; end
    if ~isempty(localShoeLabels), localShoeLabels(:,1)=localShoeLabels(:,1)+roffset; end

    nodes = zeros(size(localNodes));
    [nodes(:,1),nodes(:,2)] = pol2cart(localNodes(:,2),localNodes(:,1));
    boundaryNodes=zeros(size(boundaryLocalNodes));
    [boundaryNodes(:,1),boundaryNodes(:,2)]=pol2cart(boundaryLocalNodes(:,2),boundaryLocalNodes(:,1));
    for k=1:size(chordAttachments,1)
        nid=chordAttachments(k,1); bid1=chordAttachments(k,2); bid2=chordAttachments(k,3);
        t=chordAttachments(k,4);
        nodes(nid,:)=boundaryNodes(bid1,:)+t*(boundaryNodes(bid2,:)-boundaryNodes(bid1,:));
    end
    labels = zeros(size(localLabels));
    [labels(:,1),labels(:,2)] = pol2cart(localLabels(:,2),localLabels(:,1));
    shoelabels = zeros(size(localShoeLabels));
    if ~isempty(localShoeLabels)
        [shoelabels(:,1),shoelabels(:,2)] = pol2cart(localShoeLabels(:,2),localShoeLabels(:,1));
    end
    inslabels = zeros(size(localInsLabels));
    if ~isempty(localInsLabels)
        [inslabels(:,1),inslabels(:,2)] = pol2cart(localInsLabels(:,2),localInsLabels(:,1));
    end

    nedge=size(links,1);
    edgeTemplate=struct('NodeIds',[0 0],'Type','segment','ArcAngle',0, ...
        'Length',0,'IsTooth',false,'IsInsulation',false);
    edges=repmat(edgeTemplate,nedge,1);
    for k=1:nedge
        ids=links(k,1:2)+1; p=nodes(ids,:);
        edges(k).NodeIds=ids;
        edges(k).IsTooth=any(info.toothlinkinds==k);
        edges(k).IsInsulation=any(info.inslinkinds==k);
        if any(info.vertlinkinds==k)
            edges(k).Type='arc';
            edges(k).ArcAngle=signedAngle(p(1,:),p(2,:));
            edges(k).Length=mean(sqrt(sum(p.^2,2)))*abs(edges(k).ArcAngle);
        else
            edges(k).Length=sqrt(sum((p(2,:)-p(1,:)).^2));
        end
    end

    faces=traceFaces(nodes,edges);
    regions=repmat(struct('LabelIndex',0,'BoundaryEdgeIds',[], ...
        'BoundaryDirections',[],'Area',0,'ClosureError',0),size(labels,1),1);
    for k=1:size(labels,1)
        found=0; bestArea=Inf;
        for j=1:numel(faces)
            if faces(j).Area>0 && faces(j).Area<bestArea && ...
                    inpolygon(labels(k,1),labels(k,2),faces(j).Polygon(:,1),faces(j).Polygon(:,2))
                found=j; bestArea=faces(j).Area;
            end
        end
        if found==0, error('rnfoundry:geometry:LabelOutsideFace','A coil label was not enclosed by the slot graph.'); end
        regions(k).LabelIndex=k;
        regions(k).BoundaryEdgeIds=faces(found).EdgeIds;
        regions(k).BoundaryDirections=faces(found).Directions;
        regions(k).Area=faces(found).Area;
        regions(k).ClosureError=faces(found).ClosureError;
    end
    geom=struct('Nodes',nodes,'LocalNodes',localNodes,'Links',links, ...
        'Edges',edges,'CoilLabelLocations',labels, ...
        'InsulationLabelLocations',inslabels,'ShoeGapLabelLocations',shoelabels,'CoilRegions',regions, ...
        'LayerPackAreas',reshape([regions.Area],[],1), ...
        'TotalPackArea',sum([regions.Area]),'SlotInfo',info, ...
        'MinimumNodeSeparation',minimumSeparation(nodes), ...
        'MinimumEdgeLength',min([edges.Length]), ...
        'BoundaryChordAttachments',chordAttachments, ...
        'AuthoritativeBoundaryNodes',boundaryNodes, ...
        'AuthoritativeBoundaryLinks',boundaryLinks, ...
        'AuthoritativeBoundaryArcLinkIndices',boundaryInfo.vertlinkinds);
end

function attachments=findChordAttachments(nodes,links,bnodes,blinks,tol)
    attachments=zeros(0,4); scale=max(1,max(abs(bnodes(:)))); matchtol=max(100*eps(scale),tol*1e-7);
    nodeMap=zeros(size(nodes,1),1);
    for i=1:size(nodes,1)
        [d,j]=min(sqrt(sum((bnodes-nodes(i,:)).^2,2)));
        if d<=matchtol, nodeMap(i)=j; end
    end
    unmatched=find(nodeMap==0)'; resolved=false(size(unmatched));
    for ui=1:numel(unmatched)
        i=unmatched(ui); pending=i; visited=[]; boundaryNeighbours=[];
        while ~isempty(pending)
            q=pending(1); pending(1)=[];
            if any(visited==q), continue; end
            visited(end+1)=q; %#ok<AGROW>
            incident=find(links(:,1)==q-1 | links(:,2)==q-1);
            for k=incident'
                pair=links(k,1:2)+1; neighbour=pair(pair~=q);
                if nodeMap(neighbour)>0
                    boundaryNeighbours(end+1)=neighbour; %#ok<AGROW>
                elseif nodes(neighbour,2)*nodes(i,2)>0
                    pending(end+1)=neighbour; %#ok<AGROW>
                end
            end
        end
        mapped=unique(nodeMap(boundaryNeighbours)); mapped(mapped==0)=[];
        if numel(mapped)~=2, continue; end
        edge=find((blinks(:,1)==mapped(1)-1 & blinks(:,2)==mapped(2)-1) | ...
                  (blinks(:,1)==mapped(2)-1 & blinks(:,2)==mapped(1)-1),1);
        if isempty(edge), continue; end
        ids=blinks(edge,1:2)+1; a=bnodes(ids(1),:); v=bnodes(ids(2),:)-a;
        t=sum((nodes(i,:)-a).*v)/sum(v.^2);
        if ~(t>0 && t<1), continue; end
        attachments(end+1,:)=[i ids t]; resolved(ui)=true; %#ok<AGROW>
    end
    if ~all(resolved)
        error('rnfoundry:geometry:UnattachedPartition', ...
              'A radial layer-divider endpoint could not be attached to the fixed slot boundary.');
    end
end

function a=signedAngle(p,q)
    a=atan2(p(1)*q(2)-p(2)*q(1),p(1)*q(1)+p(2)*q(2));
end
function d=minimumSeparation(n)
    d=Inf;
    for i=1:size(n,1)-1
        v=n(i+1:end,:)-n(i,:); d=min(d,min(sqrt(sum(v.^2,2))));
    end
end
function faces=traceFaces(nodes,edges)
    ne=numel(edges); from=zeros(2*ne,1); to=from; eid=from; dir=from; ang=from;
    for k=1:ne
        ids=edges(k).NodeIds;
        for s=1:2
            h=2*k-2+s; from(h)=ids(s); to(h)=ids(3-s); eid(h)=k; dir(h)=3-2*s;
            ang(h)=tangentAngle(nodes,edges(k),dir(h),true);
        end
    end
    outgoing=cell(size(nodes,1),1);
    for h=1:2*ne, outgoing{from(h)}=[outgoing{from(h)},h]; end %#ok<AGROW>
    used=false(2*ne,1); faces=struct('EdgeIds',{},'Directions',{},'Area',{},'Polygon',{},'ClosureError',{});
    for seed=1:2*ne
        if used(seed), continue; end
        hs=[]; h=seed;
        while ~used(h)
            used(h)=true; hs(end+1)=h; %#ok<AGROW>
            candidates=outgoing{to(h)}; twin=h+1; if mod(h,2)==0, twin=h-1; end
            reverse=ang(twin);
            ca=ang(candidates); delta=mod(reverse-ca,2*pi); delta(delta<1e-12)=2*pi;
            [~,ix]=min(delta); h=candidates(ix);
        end
        if h~=seed, continue; end
        ids=eid(hs); ds=dir(hs); area=0; poly=[];
        for z=1:numel(ids)
            e=edges(ids(z)); ij=e.NodeIds; if ds(z)<0, ij=fliplr(ij); end
            p=nodes(ij,:);
            if strcmp(e.Type,'arc')
                da=e.ArcAngle*ds(z); r=mean(sqrt(sum(p.^2,2))); area=area+0.5*r*r*da;
                t0=atan2(p(1,2),p(1,1)); tt=t0+linspace(0,da,max(2,ceil(abs(da)/(pi/180))+1));
                pts=[r*cos(tt(:)),r*sin(tt(:))];
            else
                area=area+0.5*(p(1,1)*p(2,2)-p(2,1)*p(1,2)); pts=p;
            end
            poly=[poly;pts(1:end-1,:)]; %#ok<AGROW>
        end
        poly=[poly;poly(1,:)];
        f=struct('EdgeIds',ids,'Directions',ds,'Area',area,'Polygon',poly, ...
            'ClosureError',norm(poly(end,:)-poly(1,:)));
        faces(end+1)=f; %#ok<AGROW>
    end
end
function a=tangentAngle(nodes,e,d,atStart)
    ij=e.NodeIds; if d<0, ij=fliplr(ij); end
    p=nodes(ij,:);
    if strcmp(e.Type,'arc')
        da=e.ArcAngle*d; radial=atan2(p(1,2),p(1,1)); a=radial+sign(da)*pi/2;
    else
        a=atan2(p(2,2)-p(1,2),p(2,1)-p(1,1));
    end
    if ~atStart, a=a+pi; end %#ok<UNRCH>
    a=mod(a,2*pi);
end
