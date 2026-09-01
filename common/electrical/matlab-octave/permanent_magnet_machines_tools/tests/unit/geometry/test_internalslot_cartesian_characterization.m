function test_suite=test_internalslot_cartesian_characterization()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_representative_legacy_topologies_are_frozen()
fixtures={ ...
 {'single',.08,.02,.02,.05,.01,.005,1,112,113,1,5.41665,12444,.0021337428}; ...
 {'double',[.075 .095],.016,.012,.052,.009,.004,2,114,116,2,4.71303983451005,13119,.00234116124267206}; ...
 {'noshoe',.08,0,.02,.05,0,0,3,60,62,3,1.49748592,3770,.0019832816}; ...
 {'sharp',.08,0,.02,.05,.01,0,2,110,111,2,5.33373204,12206,.0022498448}};
for k=1:numel(fixtures)
 c=fixtures{k}; [n,l,i]=internalslotnodelinks(c{2:8},1e-5);
 assertEqual(size(n,1),c{9}); assertEqual(size(l,1),c{10});
 assertEqual(size(i.coillabelloc,1),c{11});
 assertElementsAlmostEqual(sum(n(:)),c{12},'absolute',2e-13);
 assertEqual(sum(l(:)),c{13}); assertElementsAlmostEqual(i.totalarea,c{14},'absolute',2e-15);
 assertTrue(all(isfinite(n(:)))); assertTrue(all(i.windingarea>0));
end
end
function test_splitx_and_repeated_calls_are_deterministic()
args={.08,.02,.02,.05,.01,.005,1,1e-5,'SplitX',true};
[n1,l1,i1]=internalslotnodelinks(args{:}); [n2,l2,i2]=internalslotnodelinks(args{:});
assertEqual(n1,n2); assertEqual(l1,l2); assertEqual(i1.coillabelloc,i2.coillabelloc);
assertEqual(size(n1,1),112); assertEqual(size(l1,1),114); assertEqual(size(i1.coillabelloc,1),2);
assertElementsAlmostEqual(i1.coillabelloc(1,1),i1.coillabelloc(2,1),'absolute',1e-15);
end
function test_tolerance_guards_remain_active()
assertExceptionThrown(@() internalslotnodelinks(.08,0,.02,4.9e-5,0,0,1,1e-5),'');
[n,~,~]=internalslotnodelinks(.08,.08-1.5e-5,.02,.05,0.9e-5,0,1,1e-5);
assertTrue(all(isfinite(n(:))));
end
function test_order_sensitive_geometry_and_topology_fingerprints()
fixtures={ ...
 {.08,.02,.02,.05,.01,.005,1,{},188.693575,1646274,[4 5 1 0],[1 2 57 58 59],463262,0}; ...
 {[.075 .095],.016,.012,.052,.009,.004,2,{},148.7664924309101,1756419,[4 5 1 0],[1 2 57 58 59 114],489238,0}; ...
 {.08,.02,.02,.05,.01,.005,1,{'SplitX',true},188.693575,1661297,[4 5 1 0],[1 2 57 58 59],463481,0}; ...
 {.08,0,.02,.05,0,0,3,{},27.76813101333333,270503,[1 1 0 0],[1 2 57 60],70710,0}; ...
 {.08,0,.02,.05,.01,0,2,{},184.64745838,1565775,[3 4 1 0],[1 54 109],450169,0}; ...
 {[.075 .095],.016,.012,.052,.009,.004,2,{'InsulationThickness',.0006},654.8251179991557,10079619,[136 5 1 113],[1 2 57 58 59 134 135 204],473336,745424}};
for k=1:numel(fixtures)
 f=fixtures{k}; [n,l,i]=internalslotnodelinks(f{1:7},1e-5,f{8}{:});
 assertElementsAlmostEqual(weighted(n),f{9},'absolute',2e-12); assertEqual(weighted(l),f{10});
 assertEqual(i.cornernodes,f{11}); assertEqual(i.vertlinkinds,f{12});
 assertEqual(weighted(i.toothlinkinds),f{13}); assertEqual(weighted(i.inslinkinds),f{14});
 assertTrue(all(isfinite(i.coillabelloc(:))));
 if ~isempty(i.inslabelloc), assertTrue(all(isfinite(i.inslabelloc(:)))); end
 if ~isempty(i.shoegaplabelloc), assertTrue(all(isfinite(i.shoegaplabelloc(:)))); end
end
end
function v=weighted(x)
x=x(:); v=x'*(1:numel(x))';
end
