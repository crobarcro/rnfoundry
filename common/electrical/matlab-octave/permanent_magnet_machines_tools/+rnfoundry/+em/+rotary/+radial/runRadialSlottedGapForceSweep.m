function result = runRadialSlottedGapForceSweep(machine,options)
%RUNRADIALSLOTTEDGAPFORCESWEEP Rebuilt-geometry femmsession force sweep.
if nargin < 2, options=struct(); end
options=rnfoundry.em.rotary.radial.resolveGapForceSweepOptions(machine,options);
[design,~]=rnfoundry.em.rotary.radial.prepareMagneticSweep(machine,struct());
d=options.Displacements; force=zeros(size(d));
for k=1:numel(d)
    problem=slottedfemmprob_radial(design,'DrawingType','Full');
    problem=translategroups_mfemm(problem, ...
        [problem.Groups.Magnet,problem.Groups.RotorBackIron],-d(k),0);
    analysis=rnfoundry.em.fea.XFemmSessionAnalysis(problem);
    cleanup=onCleanup(@() delete(analysis)); %#ok<NASGU>
    analysis.solve(); session=analysis.Session;
    session.clearblock();
    session.groupselectblock([problem.Groups.Magnet,problem.Groups.RotorBackIron]);
    force(k)=abs(session.blockintegral(18));
    delete(analysis); clear cleanup analysis
end
provenance=struct('Solver','xfemm.femmsession','Geometry','FullMachineRebuiltPerSample', ...
    'TranslationAxis','negative global x','ForceIntegral',18,'ForceScaling','full machine');
result=rnfoundry.em.fea.RadialGapForceSweepResult(d,force,provenance);
end
