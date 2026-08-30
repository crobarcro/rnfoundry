function test_suite=test_periodic_slm_evaluation()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end

function test_historical_call_forms_and_shape()
xfit=linspace(0,2,21); fit=slmengine(xfit,cos(pi*xfit), ...
    'EndCon','periodic','knots',12,'Plot','off');
row=[-0.3,0,0.7,2,2.4]; column=row.';
expected=periodicslmeval(row,fit,0,false);
assertElementsAlmostEqual(periodicslmeval(row,fit),expected,'absolute',1e-13);
assertElementsAlmostEqual(periodicslmeval(row,fit,0),expected,'absolute',1e-13);
assertElementsAlmostEqual(periodicslmeval(row,fit,0,true),expected,'absolute',1e-13);
assertElementsAlmostEqual(periodicslmeval(row,fit,[],[]),expected,'absolute',1e-13);
assertEqual(size(periodicslmeval(row,fit)),size(row));
assertEqual(size(periodicslmeval(column,fit)),size(column));
end

function test_nonzero_evaluation_mode()
xfit=linspace(0,2,21); fit=slmengine(xfit,sin(pi*xfit), ...
    'EndCon','periodic','knots',12,'Plot','off'); x=[0.1,0.8,2.1];
assertElementsAlmostEqual(periodicslmeval(x,fit,1), ...
    periodicslmeval(x,fit,1,false),'absolute',1e-13);
end
