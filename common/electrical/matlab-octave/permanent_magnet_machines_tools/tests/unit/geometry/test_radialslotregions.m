function test_suite=test_radialslotregions()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_ordinary_radial_layers_have_fixed_external_boundary()
for side=['o','i']
    g1=fixture(side,1,false,false); g2=fixture(side,2,false,false); g3=fixtureMode(side,3,false,false,'legacy-local');
    assertScaleEqual(g2.TotalPackArea,g1.TotalPackArea);
    assertScaleEqual(g3.TotalPackArea,g1.TotalPackArea);
    assertBoundaryEqual(g1,g2); assertBoundaryEqual(g1,g3);
    assertEqual(numel(g2.CoilRegions),2); assertEqual(numel(g3.CoilRegions),3);
    assertTrue(~isempty(intersect(g2.CoilRegions(1).BoundaryEdgeIds, ...
                                  g2.CoilRegions(2).BoundaryEdgeIds)));
end
end
function test_legacy_partition_positions_remain_physically_unequal()
ge=fixtureMode('o',2,false,false,'legacy-local'); gi=fixtureMode('i',2,false,false,'legacy-local');
assertElementsAlmostEqual(ge.LayerPackAreas,[.001178404114275779;.001241968301635460],'absolute',3e-15);
assertElementsAlmostEqual(gi.LayerPackAreas,[.001069027610527237;.001003888643539117],'absolute',3e-15);
% The total perimeter is now fixed; equal physical-area placement is #5B.
assertTrue(abs(diff(ge.LayerPackAreas))>5e-5);
assertTrue(abs(diff(gi.LayerPackAreas))>5e-5);
end
function test_single_internal_external_and_insulation_invariance()
ge=fixture('o',1,false,false); gi=fixture('i',1,false,false);
assertElementsAlmostEqual(ge.TotalPackArea,.002420372415911237,'absolute',3e-15);
assertElementsAlmostEqual(gi.TotalPackArea,.002072916254066352,'absolute',3e-15);
for side=['o','i']
    g1=fixture(side,1,false,true); g2=fixture(side,2,false,true); g3=fixtureMode(side,3,false,true,'legacy-local');
    assertScaleEqual(g2.TotalPackArea,g1.TotalPackArea);
    assertScaleEqual(g3.TotalPackArea,g1.TotalPackArea);
    assertBoundaryEqual(g1,g2); assertBoundaryEqual(g1,g3);
end
assertElementsAlmostEqual(fixture('o',1,false,true).TotalPackArea,.002278073900072925,'absolute',3e-15);
assertElementsAlmostEqual(fixture('i',1,false,true).TotalPackArea,.001949103895770560,'absolute',3e-15);
end
function test_splitslot_is_physically_symmetric_and_keeps_single_perimeter()
g1=fixture('o',1,false,false); g=fixture('o',2,true,false);
assertEqual(numel(g.CoilRegions),2);
assertElementsAlmostEqual(g.LayerPackAreas(1),g.LayerPackAreas(2),'absolute',2e-15);
assertScaleEqual(g.TotalPackArea,g1.TotalPackArea);
end
function test_primitives_topology_features_and_determinism()
g=fixtureMode('o',3,false,false,'legacy-local'); h=fixtureMode('o',3,false,false,'legacy-local');
assertEqual(g.Nodes,h.Nodes); assertEqual(g.LayerPackAreas,h.LayerPackAreas);
assertTrue(all(isfinite(g.Nodes(:)))); assertTrue(g.MinimumNodeSeparation>0);
assertTrue(g.MinimumEdgeLength>1e-6); assertTrue(any(strcmp({g.Edges.Type},'arc')));
assertTrue(all([g.Edges.Length]>0)); assertTrue(all([g.CoilRegions.IsClosed])); assertTrue(all([g.CoilRegions.HalfEdgeCount]>=3));
assertElementsAlmostEqual(sum(g.LayerPackAreas),g.TotalPackArea,'absolute',1e-18);
assertEqual(size(g.BoundaryChordAttachments,1),4);
end
function test_near_tolerance_feature_measurement()
g=radialslotregions(.08,.08-2.01e-5,.02,.05,1.01e-5,1.01e-5,.5,'o','Tol',1e-5);
assertTrue(isfinite(g.MinimumNodeSeparation)); assertTrue(g.MinimumNodeSeparation>0);
assertTrue(isfinite(g.MinimumEdgeLength)); assertTrue(g.MinimumEdgeLength>0);
end
function assertBoundaryEqual(a,b)
assertElementsAlmostEqual(a.AuthoritativeBoundaryNodes,b.AuthoritativeBoundaryNodes,'absolute',2e-15);
assertEqual(a.AuthoritativeBoundaryLinks,b.AuthoritativeBoundaryLinks);
assertEqual(a.AuthoritativeBoundaryArcLinkIndices,b.AuthoritativeBoundaryArcLinkIndices);
end
function assertScaleEqual(a,b)
assertTrue(abs(a-b)<=max(2e-15,2e-12*max(abs([a b]))));
end
function g=fixture(side,layers,split,insulated)
g=fixtureMode(side,layers,split,insulated,'equal-physical-area');
end
function g=fixtureMode(side,layers,split,insulated,mode)
g=radialslotregions([.075 .095],.016,.024,.052,.009,.004,.48,side, ...
 'NWindingLayers',layers,'SplitSlot',split,'DrawCoilInsulation',insulated, ...
 'CoilInsulationThickness',.0006,'LayerPartitionMode',mode);
end

function test_coordinate_frames_and_internal_external_mapping()
for side=['o','i']
    g=fixture(side,2,false,false);
    assertElementsAlmostEqual(g.Nodes(:,1),g.RadialNodes(:,1).*cos(g.RadialNodes(:,2)),'absolute',2e-15);
    assertElementsAlmostEqual(g.Nodes(:,2),g.RadialNodes(:,1).*sin(g.RadialNodes(:,2)),'absolute',2e-15);
    assertElementsAlmostEqual(g.CoilLabelLocations(:,1), ...
        g.RadialCoilLabelLocations(:,1).*cos(g.RadialCoilLabelLocations(:,2)),'absolute',2e-15);
    if side=='o'
        assertElementsAlmostEqual(g.MappedRadialNodes(:,1),g.LocalNodes(:,1)+.48,'absolute',2e-15);
    else
        assertElementsAlmostEqual(g.MappedRadialNodes(:,1),.48-g.LocalNodes(:,1),'absolute',2e-15);
    end
    assertEqual(g.SlotInfo.coillabelloc,g.CoilLabelLocations);
    assertEqual(g.LegacySlotInfo.coillabelloc,g.LegacyLocalCoilLabelLocations);
end
end
function test_divider_arcs_remain_valid_after_chord_attachment()
for side=['o','i']
    g=fixtureMode(side,3,false,false,'legacy-local');
    assertEqual(numel(g.PartitionEdgeIds),2);
    for id=g.PartitionEdgeIds
        e=g.Edges(id); p=g.Nodes(e.NodeIds,:); radii=sqrt(sum(p.^2,2));
        assertElementsAlmostEqual(radii(1),radii(2),'absolute',2e-15);
        assertTrue(strcmp(e.Type,'arc')); assertTrue(isfinite(e.ArcAngle));
        assertTrue(abs(e.ArcAngle)>1e-6); assertTrue(isfinite(e.Length)&&e.Length>1e-4);
    end
end
end
function test_every_arc_is_finite_nonzero_and_coradial()
for side=['o','i']
    g=fixtureMode(side,3,false,true,'legacy-local');
    for id=find(strcmp({g.Edges.Type},'arc'))
        e=g.Edges(id); p=g.Nodes(e.NodeIds,:); r=sqrt(sum((p-e.ArcCenter).^2,2));
        assertTrue(abs(diff(r))<=max(1e-12,1e-10*max(r)));
        assertTrue(isfinite(e.ArcAngle)&&e.ArcAngle~=0);
        assertTrue(isfinite(e.Length)&&e.Length>0);
    end
end
end
function test_invalid_arc_radius_fails_deterministically()
g=radialslotgeometry([.075 .095],.016,.024,.052,.009,.004,.48,'o','NWindingLayers',2);
id=find(strcmp({g.Edges.Type},'arc'),1); nid=g.Edges(id).NodeIds(1);
g.Nodes(nid,1)=g.Nodes(nid,1)+1e-3;
assertExceptionThrown(@() analyzeRadialSlotRegions(g), ...
    'rnfoundry:geometry:InvalidArcRadius');
end
function test_topology_validation_is_nonvacuous()
g=radialslotgeometry([.075 .095],.016,.024,.052,.009,.004,.48,'o','NWindingLayers',2);
g.Edges(1).NodeIds=[1 1];
assertExceptionThrown(@() analyzeRadialSlotRegions(g),'rnfoundry:geometry:MalformedEdge');
g=radialslotgeometry([.075 .095],.016,.024,.052,.009,.004,.48,'o','NWindingLayers',2);
g.CoilLabelLocations(2,:)=g.CoilLabelLocations(1,:);
assertExceptionThrown(@() analyzeRadialSlotRegions(g),'rnfoundry:geometry:DuplicateLabelFace');
g=radialslotgeometry([.075 .095],.016,.024,.052,.009,.004,.48,'o','NWindingLayers',2);
g.Edges(60)=[];
assertExceptionThrown(@() analyzeRadialSlotRegions(g),'rnfoundry:geometry:LabelOutsideFace');
g=radialslotgeometry(.08,.02,.02,.05,0,0,.5,'o','NWindingLayers',2);
g.Edges(1).NodeIds(2)=1;
assertExceptionThrown(@() analyzeRadialSlotRegions(g),'rnfoundry:geometry:OpenFaceWalk');
end
function test_multilayer_feature_characterization()
% These fixtures exercise divider placement near the base/body and body/shoe
% portions and densely spaced legacy divisions. Values are physical metres.
cases={.05,3;.33,4;.70,4;.80,6};
expected=[1.01470569690398e-4,4.392e-3; ...
          1.02332278211974e-4,4.392e-3; ...
          1.079265488220787e-4,4.392e-3; ...
          1.154455680380752e-4,4.392e-3];
for k=1:size(cases,1)
    g=radialslotregions([.075 .095],.016,.024,.052,.009,.004,.48,'o', ...
        'NWindingLayers',cases{k,2},'LayerPartitionMode','legacy-local','CoilBaseFraction',cases{k,1});
    assertElementsAlmostEqual(g.MinimumStraightSegmentLength,expected(k,1),'absolute',5e-15);
    assertElementsAlmostEqual(g.MinimumArcLength,expected(k,2),'absolute',5e-15);
    assertTrue(g.MinimumPartitionBoundarySegmentLength>1e-3);
    assertTrue(g.MinimumPartitionEdgeLength>4e-2);
end
g=fixtureMode('o',3,false,true,'legacy-local');
assertTrue(g.MinimumPartitionBoundarySegmentLength>1e-2);
assertTrue(g.MinimumPartitionEdgeLength>4e-2);
end

function test_targeted_partition_transition_proximity()
% Tune the legacy area rule to leave a 42.7 um boundary piece at the
% base/body end of the authoritative body chord, in both orientations.
for side=['o','i']
    g=radialslotregions([.075 .095],.016,.024,.052,.009,.004,.48,side, ...
        'NWindingLayers',2,'LayerPartitionMode','legacy-local','CoilBaseFraction',.5256);
    assertEqual(g.BoundaryChordAttachments(:,2:3),[1 111;5 112]);
    assertTrue(g.MinimumPartitionBoundarySegmentLength>42e-6);
    assertTrue(g.MinimumPartitionBoundarySegmentLength<43e-6);
    assertTrue(g.MinimumNodeSeparation>42e-6);
end
% This curved-base partition is exactly the authoritative sampled node pair
% 81/106, not merely an unspecified coincident boundary node.
g=radialslotregions([.075 .095],.016,.024,.052,.009,.004,.48,'o', ...
    'NWindingLayers',2,'LayerPartitionMode','legacy-local','CoilBaseFraction',.80);
assertTrue(isempty(g.BoundaryChordAttachments));
assertEqual(g.Edges(g.PartitionEdgeIds).NodeIds,[81 106]);
assertPartitionEndpointsMatchBoundaryNodes(g,1e-14);
% Tune a large-shoe fixture to 34.2 um from the body/shoe chord endpoint;
% its second partition is explicitly the sampled shoe-node pair 14/39.
g=radialslotregions([.075 .095],.005,.024,.052,.046,.001,.48,'o', ...
    'NWindingLayers',3,'LayerPartitionMode','legacy-local','CoilBaseFraction',.02);
assertTrue(g.MinimumPartitionBoundarySegmentLength>34e-6);
assertTrue(g.MinimumPartitionBoundarySegmentLength<35e-6);
assertEqual(g.BoundaryChordAttachments(end,2:3),[5 112]);
% A separate large-shoe fixture identifies the authoritative sampled shoe
% node pair 14/39 exactly.
g=radialslotregions([.075 .095],.005,.024,.052,.08,.001,.48,'o', ...
    'NWindingLayers',3,'LayerPartitionMode','legacy-local','CoilBaseFraction',.02);
assertEqual(g.Edges(g.PartitionEdgeIds(2)).NodeIds,[14 39]);
% An insulated eight-layer fixture approaches its known insulation-side
% chord endpoints 176/192 within 2.5 um without snapping.
g=radialslotregions([.075 .095],.016,.024,.052,.009,.004,.48,'o', ...
    'NWindingLayers',8,'LayerPartitionMode','legacy-local','CoilBaseFraction',.504,'DrawCoilInsulation',true, ...
    'CoilInsulationThickness',.0006);
assertTrue(any(all(g.BoundaryChordAttachments(:,2:3)==[114 176],2)));
assertTrue(any(all(g.BoundaryChordAttachments(:,2:3)==[137 192],2)));
assertTrue(g.MinimumPartitionBoundarySegmentLength>2e-6);
assertTrue(g.MinimumPartitionBoundarySegmentLength<3e-6);
assertTrue(g.MinimumNodeSeparation>2e-6 && g.MinimumNodeSeparation<3e-6);
assertTrue(g.MinimumStraightSegmentLength>2e-6 && g.MinimumStraightSegmentLength<3e-6);
assertTrue(g.MinimumArcLength>4e-3); assertTrue(g.MinimumPartitionEdgeLength>3.9e-2);
% A valid shallow 16-layer slot provides sub-millimetre neighbouring
% ordinary dividers; the legacy generator rejects still denser variants.
g=radialslotregions([.075 .095],.016,.024,.010,.004,.001,.48,'o', ...
    'NWindingLayers',16,'LayerPartitionMode','legacy-local','CoilBaseFraction',.05);
r=zeros(numel(g.PartitionEdgeIds),1);
for k=1:numel(r), p=g.Nodes(g.Edges(g.PartitionEdgeIds(k)).NodeIds,:); r(k)=mean(sqrt(sum(p.^2,2))); end
assertTrue(min(diff(sort(r)))>0.67e-3 && min(diff(sort(r)))<0.68e-3);
end
function assertPartitionEndpointsMatchBoundaryNodes(g,tol)
for id=g.PartitionEdgeIds
    p=g.Nodes(g.Edges(id).NodeIds,:);
    for k=1:2
        d=sqrt(sum((g.AuthoritativeBoundaryNodes-p(k,:)).^2,2));
        assertTrue(min(d)<tol);
    end
end
end

function test_equal_area_adjustment_diagnostics_are_real()
args={[.075 .095],.016,.024,.052,.009,.004,.48,'o', ...
    'NWindingLayers',2,'MinimumPhysicalFeature',2e-6,'PartitionSnapTolerance',.1};
g=radialslotregions(args{:}); h=radialslotregions(args{:});
assertTrue(g.PartitionDiagnostics.Adjusted);
assertTrue(~isempty(g.PartitionDiagnostics.AdjustmentReason));
assertTrue(~isempty(g.PartitionDiagnostics.SnappedFeature));
assertTrue(isfinite(g.PartitionDiagnostics.RelativeAreaImbalance));
assertTrue(g.PartitionDiagnostics.RelativeAreaImbalance<2e-4);
assertTrue(g.MinimumNodeSeparation>=2e-6);
assertEqual(g.Nodes,h.Nodes); assertEqual(g.PartitionDiagnostics,h.PartitionDiagnostics);
end

function test_equal_area_higher_layers_fail_explicitly()
assertExceptionThrown(@() radialslotgeometry([.075 .095],.016,.024,.052,.009,.004,.48,'o', ...
    'NWindingLayers',3),'rnfoundry:geometry:UnsupportedLayerCount');
end
