function run_milestone1a_tests()
%RUN_MILESTONE1A_TESTS Octave/MATLAB construction and legacy-kernel parity.
cases={fixture('external',2,1,1,4),fixture('internal',2,1,1,4),fixture('external',2,1,1,1),fixture('external',1,1,1,4),fixture('external',2,1,2,2)};
for k=1:numel(cases)
    d=cases{k}; m=rnfoundry.em.rotary.radial.SlottedPMMachine.fromLegacyStruct(d); out=m.toLegacyStruct();
    near(out.g,d.g); near(out.Rcm,d.Rcm); near(out.thetap,d.thetap); assert(numel(out.tc)==2); near(out.tc,d.tc);
    near(out.MTL,rectcoilmtl(d.ls,d.yd*d.thetas*d.Rcm+d.thetas*d.Rcm/2,mean(d.thetac)*d.Rcm));
    near(out.CoilResistance,wireresistancedc('round',out.Dc,out.MTL*out.CoilTurns));
    near(m.Armature.Winding.CopperVolume,m.Armature.Winding.TotalTurnPathLength*out.ConductorArea);
    m2=rnfoundry.em.rotary.radial.SlottedPMMachine.fromStruct(m.toStruct()); near(m2.g,m.g);
end
cg=rnfoundry.em.winding.CoilGeometry(1e-4,1,[]);
comparepacking(struct('Dc',1e-3,'CoilFillFactor',0.6,'NStrands',1),cg);
comparepacking(struct('CoilTurns',20,'CoilFillFactor',0.6,'NStrands',1),cg);
comparepacking(struct('Dc',1e-3,'CoilTurns',20,'NStrands',1),cg);
comparepacking(struct('CoilTurns',20,'CoilFillFactor',0.6,'NStrands',4),cg);
for n=[1 7], for d=[0.4e-3 2e-3], near(equivDcfromstranded(stranddiameter(d,n),n),d); near(rnfoundry.em.winding.insulatedWireDiameter(d),conductord2wired(d)); end; end
x=cases{1}; raw=rmfield(x,{'Ryi','Rtsb','Rai','Rmo','Rmi','Rbi','Rbo','Rtsg','Rco','Rci','Rcb','Rmm','Rcm','Rbm','Rym','Rgm','tausm','Qcb','pb','NBasicWindings','Qs','Qsb','qcn','qcd','ypn','ypd','yp','qsp','NCoilsPerPhase','WindingLayout','thetap','thetas','thetac','CoilArea'}); rnfoundry.em.rotary.radial.SlottedPMMachine.fromThicknesses(raw);
fprintf('Milestone 1A tests passed.\n');
end
function comparepacking(s,cg)
s.CoilArea=cg.PackArea; legacy=checkcoilprops_AM(s); modern=rnfoundry.em.winding.resolvePacking(s,cg);
near(modern.TurnsPerCoil,legacy.CoilTurns); near(modern.Conductor.EquivalentCopperDiameter,legacy.Dc); near(modern.PackingFactor,legacy.CoilFillFactor);
end
function d=fixture(pos,layers,qcn,qcd,yd)
ph=3; poles=12; qc=qcn/qcd; Qc=qc*ph*poles; Qs=Qc*(2/layers); [Qcb,pb]=rat(qc*ph); [ypn,ypd]=rat(Qs/poles); ths=2*pi/Qs;
d=struct('ArmatureType',pos,'Poles',poles,'Phases',ph,'CoilLayers',layers,'Qc',Qc,'qc',qc,'Qcb',Qcb,'pb',pb,'NBasicWindings',poles/pb,'Qs',Qs,'Qsb',Qs/(poles/pb),'qcn',qcn,'qcd',qcd,'ypn',ypn,'ypd',ypd,'yp',Qs/poles,'yd',yd,'qsp',Qs/poles,'NCoilsPerPhase',Qc/ph,'WindingLayout',struct(),'Branches',1,'CoilTurns',25,'CoilFillFactor',0.7,'NStrands',4,'MagnetSkew',0,'NStages',1);
d.thetap=2*pi/poles; d.thetas=ths; d.thetam=.8*d.thetap; d.thetacg=.7*ths; d.thetacy=.9*ths; d.thetac=[d.thetacg d.thetacy]; d.thetasg=.4*d.thetacg; d.g=.003; d.ty=.01; d.tm=.005; d.tc=[.02 .012]; d.tsb=.002; d.tsg=.0006; d.tbi=.01; d.ls=.4;
if strcmp(pos,'external')
 d.Ryo=.25; d.Ryi=d.Ryo-d.ty; d.Rtsb=d.Ryi-d.tc(1); d.Rai=d.Rtsb-d.tsb; d.Rmo=d.Rai-d.g; d.Rmi=d.Rmo-d.tm; d.Rbi=d.Rmi-d.tbi; d.Rbo=d.Rmi; d.Rtsg=d.Rai+d.tsg; d.Rco=d.Ryi; d.Rci=d.Rtsb; d.Rcb=d.Rco-d.tc(2);
else
 d.Rbo=.25; d.Rmo=d.Rbo-d.tbi; d.Rmi=d.Rmo-d.tm; d.Rao=d.Rmi-d.g; d.Rtsb=d.Rao-d.tsb; d.Ryo=d.Rtsb-d.tc(1); d.Ryi=d.Ryo-d.ty; d.Rbi=d.Rmo; d.Rtsg=d.Rao-d.tsg; d.Rco=d.Rtsb; d.Rci=d.Ryo; d.Rcb=d.Rci+d.tc(2);
end
d.Rmm=mean([d.Rmi d.Rmo]); d.Rcm=mean([d.Rci d.Rco]); d.Rbm=mean([d.Rbi d.Rbo]); d.Rym=mean([d.Ryi d.Ryo]); d.Rgm=d.Rmm; d.tausm=d.thetas*d.Rcm; d.CoilArea=d.tc(1)*mean(d.thetac)*d.Rcm/layers;
end
function near(a,b), assert(all(abs(a(:)-b(:)) <= 5e-12*max(1,max(abs(b(:)))))); end
