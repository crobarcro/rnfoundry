function geom = radialslotgeometry(thetacoil, thetashoegap, ryoke, rcoil, ...
                                    rshoebase, rshoegap, roffset, side, varargin)
%RADIALSLOTGEOMETRY Authoritative solver-free radial slot drawing geometry.
%   GEOM reuses INTERNALSLOTNODELINKS and applies exactly the reflection,
%   radial offset and POL2CART mapping used by CURVEDSTATORHALF2DFEMMPROBLEM.
%   This layer constructs nodes, primitives, and transformed labels only; it
%   deliberately performs no face tracing or region classification. Ordinary
%   layer positions retain the legacy rule pending Issue #5B.

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
    legacyInfo=info; rawLocalNodes=localNodes;

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
    rawLocalLabels=localLabels; rawLocalInsLabels=localInsLabels; rawLocalShoeLabels=localShoeLabels;
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
    mappedRadialNodes=localNodes; radialLabels=localLabels;
    radialInsLabels=localInsLabels; radialShoeLabels=localShoeLabels;

    nodes = zeros(size(localNodes));
    [nodes(:,1),nodes(:,2)] = pol2cart(mappedRadialNodes(:,2),mappedRadialNodes(:,1));
    boundaryNodes=zeros(size(boundaryLocalNodes));
    [boundaryNodes(:,1),boundaryNodes(:,2)]=pol2cart(boundaryLocalNodes(:,2),boundaryLocalNodes(:,1));
    for k=1:size(chordAttachments,1)
        nid=chordAttachments(k,1); bid1=chordAttachments(k,2); bid2=chordAttachments(k,3);
        t=chordAttachments(k,4);
        nodes(nid,:)=boundaryNodes(bid1,:)+t*(boundaryNodes(bid2,:)-boundaryNodes(bid1,:));
    end
    radialNodes=zeros(size(nodes));
    [radialNodes(:,2),radialNodes(:,1)]=cart2pol(nodes(:,1),nodes(:,2));
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
        'ArcCenter',[NaN NaN],'Radius',NaN,'Length',0,'IsTooth',false,'IsInsulation',false);
    edges=repmat(edgeTemplate,nedge,1);
    for k=1:nedge
        ids=links(k,1:2)+1; p=nodes(ids,:);
        edges(k).NodeIds=ids;
        edges(k).IsTooth=any(info.toothlinkinds==k);
        edges(k).IsInsulation=any(info.inslinkinds==k);
        if any(info.vertlinkinds==k)
            edges(k).Type='arc';
            edges(k).ArcAngle=signedAngle(p(1,:),p(2,:));
            if ~isfinite(edges(k).ArcAngle) || edges(k).ArcAngle==0
                error('rnfoundry:geometry:InvalidArc','A radial slot arc has a zero or non-finite sweep.');
            end
            chord=p(2,:)-p(1,:); chordLength=norm(chord);
            leftNormal=[-chord(2),chord(1)]/chordLength;
            edges(k).ArcCenter=(p(1,:)+p(2,:))/2 + ...
                leftNormal*chordLength/(2*tan(edges(k).ArcAngle/2));
            radii=sqrt(sum((p-edges(k).ArcCenter).^2,2));
            radiusTol=max(1e-12,1e-10*max(radii));
            if any(~isfinite(radii)) || abs(diff(radii))>radiusTol
                error('rnfoundry:geometry:InvalidArcRadius', ...
                      'Arc %d endpoints differ in radius by %.16g.',k,abs(diff(radii)));
            end
            edges(k).Radius=radii(1);
            edges(k).Length=edges(k).Radius*abs(edges(k).ArcAngle);
            if ~isfinite(edges(k).Length) || edges(k).Length==0
                error('rnfoundry:geometry:InvalidArc','A radial slot arc has zero or non-finite length.');
            end
        else
            edges(k).Length=sqrt(sum((p(2,:)-p(1,:)).^2));
        end
    end

    lengths=[edges.Length]; lineLengths=lengths(strcmp({edges.Type},'segment'));
    minPartitionBoundaryLength=minimumAttachmentSpacing(chordAttachments,boundaryNodes);
    arcLengths=lengths(strcmp({edges.Type},'arc'));
    info.coillabelloc=labels; info.inslabelloc=inslabels; info.shoegaplabelloc=shoelabels;
    geom=struct('LocalNodes',rawLocalNodes,'MappedRadialNodes',mappedRadialNodes, ...
        'RadialNodes',radialNodes,'Nodes',nodes, ...
        'Links',links,'Edges',edges, ...
        'LocalCoilLabelLocations',rawLocalLabels,'RadialCoilLabelLocations',radialLabels, ...
        'CoilLabelLocations',labels, ...
        'LocalInsulationLabelLocations',rawLocalInsLabels, ...
        'RadialInsulationLabelLocations',radialInsLabels,'InsulationLabelLocations',inslabels, ...
        'LocalShoeGapLabelLocations',rawLocalShoeLabels, ...
        'RadialShoeGapLabelLocations',radialShoeLabels,'ShoeGapLabelLocations',shoelabels, ...
        'LegacySlotInfo',legacyInfo,'SlotInfo',info, ...
        'MinimumNodeSeparation',minimumSeparation(nodes),'MinimumEdgeLength',min(lengths), ...
        'MinimumStraightSegmentLength',minimumOrInf(lineLengths), ...
        'MinimumArcLength',minimumOrInf(arcLengths), ...
        'MinimumPartitionBoundarySegmentLength',minPartitionBoundaryLength, ...
        'BoundaryChordAttachments',chordAttachments, ...
        'AuthoritativeBoundaryNodes',boundaryNodes,'AuthoritativeBoundaryLinks',boundaryLinks, ...
        'AuthoritativeBoundaryArcLinkIndices',boundaryInfo.vertlinkinds);
end

function v=minimumAttachmentSpacing(a,bnodes)
    v=Inf;
    if isempty(a), return; end
    pairs=unique(a(:,2:3),'rows');
    for k=1:size(pairs,1)
        same=a(:,2)==pairs(k,1) & a(:,3)==pairs(k,2);
        t=sort([0;a(same,4);1]);
        chord=norm(bnodes(pairs(k,2),:)-bnodes(pairs(k,1),:));
        v=min(v,min(diff(t))*chord);
    end
end

function v=minimumOrInf(values)
    if isempty(values), v=Inf; else, v=min(values); end
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
