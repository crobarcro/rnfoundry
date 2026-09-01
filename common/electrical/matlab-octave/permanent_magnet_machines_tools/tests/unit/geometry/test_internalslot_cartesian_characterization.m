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
