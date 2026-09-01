function test_suite=test_radialslotregions()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_ordinary_radial_layers_characterize_current_defect()
ge=fixture('o',2,false,false); gi=fixture('i',2,false,false);
assertElementsAlmostEqual(ge.LayerPackAreas,[.00118162323131247;.00124487281136070],'absolute',3e-15);
assertElementsAlmostEqual(gi.LayerPackAreas,[.00106589191747663;.00100091004220922],'absolute',3e-15);
% The local algorithm targets equal Cartesian area, but the radial Jacobian
% makes the actual physical regions unequal.  This is not a future target.
assertTrue(abs(diff(ge.LayerPackAreas))>5e-5);
assertTrue(abs(diff(gi.LayerPackAreas))>5e-5);
end
function test_single_internal_external_and_insulation()
ge=fixture('o',1,false,false); gi=fixture('i',1,false,false);
assertElementsAlmostEqual(ge.LayerPackAreas,.00242037241591124,'absolute',3e-15);
assertElementsAlmostEqual(gi.LayerPackAreas,.00207291625406635,'absolute',3e-15);
gins=fixture('o',2,false,true);
assertElementsAlmostEqual(gins.LayerPackAreas,[.00115510244548085;.00114416165987411],'absolute',3e-15);
assertTrue(sum(gins.LayerPackAreas)<ge.TotalPackArea);
end
function test_splitslot_is_physically_symmetric()
g=fixture('o',2,true,false);
assertEqual(numel(g.CoilRegions),2);
assertElementsAlmostEqual(g.LayerPackAreas(1),g.LayerPackAreas(2),'absolute',2e-15);
assertElementsAlmostEqual(g.TotalPackArea,2*.00121018620795562,'absolute',4e-15);
end
function test_primitives_topology_features_and_determinism()
g=fixture('o',2,false,false); h=fixture('o',2,false,false);
assertEqual(g.Nodes,h.Nodes); assertEqual(g.LayerPackAreas,h.LayerPackAreas);
assertTrue(all(isfinite(g.Nodes(:)))); assertTrue(g.MinimumNodeSeparation>0);
assertTrue(g.MinimumEdgeLength>0); assertTrue(any(strcmp({g.Edges.Type},'arc')));
assertTrue(all([g.Edges.Length]>0)); assertTrue(all([g.CoilRegions.ClosureError]<1e-14));
assertElementsAlmostEqual(sum(g.LayerPackAreas),g.TotalPackArea,'absolute',1e-18);
for k=1:numel(g.CoilRegions), assertTrue(g.CoilRegions(k).Area>0); end
end
function test_near_tolerance_feature_measurement()
g=radialslotregions(.08,.08-2.01e-5,.02,.05,1.01e-5,1.01e-5,.5,'o','Tol',1e-5);
assertTrue(isfinite(g.MinimumNodeSeparation)); assertTrue(g.MinimumNodeSeparation>0);
assertTrue(isfinite(g.MinimumEdgeLength)); assertTrue(g.MinimumEdgeLength>0);
end
function g=fixture(side,layers,split,insulated)
g=radialslotregions([.075 .095],.016,.024,.052,.009,.004,.48,side, ...
 'NWindingLayers',layers,'SplitSlot',split,'DrawCoilInsulation',insulated, ...
 'CoilInsulationThickness',.0006);
end
