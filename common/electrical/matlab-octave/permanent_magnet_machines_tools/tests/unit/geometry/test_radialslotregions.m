function test_suite=test_radialslotregions()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_ordinary_radial_layers_have_fixed_external_boundary()
for side=['o','i']
    g1=fixture(side,1,false,false); g2=fixture(side,2,false,false); g3=fixture(side,3,false,false);
    assertScaleEqual(g2.TotalPackArea,g1.TotalPackArea);
    assertScaleEqual(g3.TotalPackArea,g1.TotalPackArea);
    assertBoundaryEqual(g1,g2); assertBoundaryEqual(g1,g3);
    assertEqual(numel(g2.CoilRegions),2); assertEqual(numel(g3.CoilRegions),3);
    assertTrue(~isempty(intersect(g2.CoilRegions(1).BoundaryEdgeIds, ...
                                  g2.CoilRegions(2).BoundaryEdgeIds)));
end
end
function test_legacy_partition_positions_remain_physically_unequal()
ge=fixture('o',2,false,false); gi=fixture('i',2,false,false);
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
    g1=fixture(side,1,false,true); g2=fixture(side,2,false,true); g3=fixture(side,3,false,true);
    assertScaleEqual(g2.TotalPackArea,g1.TotalPackArea);
    assertScaleEqual(g3.TotalPackArea,g1.TotalPackArea);
    assertBoundaryEqual(g1,g2); assertBoundaryEqual(g1,g3);
end
assertElementsAlmostEqual(fixture('o',1,false,true).TotalPackArea,.002278073917524149,'absolute',3e-15);
assertElementsAlmostEqual(fixture('i',1,false,true).TotalPackArea,.001949103878319334,'absolute',3e-15);
end
function test_splitslot_is_physically_symmetric_and_keeps_single_perimeter()
g1=fixture('o',1,false,false); g=fixture('o',2,true,false);
assertEqual(numel(g.CoilRegions),2);
assertElementsAlmostEqual(g.LayerPackAreas(1),g.LayerPackAreas(2),'absolute',2e-15);
assertScaleEqual(g.TotalPackArea,g1.TotalPackArea);
end
function test_primitives_topology_features_and_determinism()
g=fixture('o',3,false,false); h=fixture('o',3,false,false);
assertEqual(g.Nodes,h.Nodes); assertEqual(g.LayerPackAreas,h.LayerPackAreas);
assertTrue(all(isfinite(g.Nodes(:)))); assertTrue(g.MinimumNodeSeparation>0);
assertTrue(g.MinimumEdgeLength>1e-6); assertTrue(any(strcmp({g.Edges.Type},'arc')));
assertTrue(all([g.Edges.Length]>0)); assertTrue(all([g.CoilRegions.BoundaryClosureError]<1e-14));
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
g=radialslotregions([.075 .095],.016,.024,.052,.009,.004,.48,side, ...
 'NWindingLayers',layers,'SplitSlot',split,'DrawCoilInsulation',insulated, ...
 'CoilInsulationThickness',.0006);
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
    assertEqual(g.LegacySlotInfo.coillabelloc,g.LocalCoilLabelLocations);
end
end
function test_divider_arcs_remain_valid_after_chord_attachment()
for side=['o','i']
    g=fixture(side,3,false,false);
    assertEqual(numel(g.PartitionEdgeIds),2);
    for id=g.PartitionEdgeIds
        e=g.Edges(id); p=g.Nodes(e.NodeIds,:); radii=sqrt(sum(p.^2,2));
        assertElementsAlmostEqual(radii(1),radii(2),'absolute',2e-15);
        assertTrue(strcmp(e.Type,'arc')); assertTrue(isfinite(e.ArcAngle));
        assertTrue(abs(e.ArcAngle)>1e-6); assertTrue(isfinite(e.Length)&&e.Length>1e-4);
    end
end
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
        'NWindingLayers',cases{k,2},'CoilBaseFraction',cases{k,1});
    assertElementsAlmostEqual(g.MinimumStraightSegmentLength,expected(k,1),'absolute',5e-15);
    assertElementsAlmostEqual(g.MinimumArcLength,expected(k,2),'absolute',5e-15);
    assertTrue(g.MinimumPartitionBoundarySegmentLength>1e-3);
    assertTrue(g.MinimumPartitionEdgeLength>4e-2);
end
g=fixture('o',3,false,true);
assertTrue(g.MinimumPartitionBoundarySegmentLength>1e-2);
assertTrue(g.MinimumPartitionEdgeLength>4e-2);
end
