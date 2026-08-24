function test_design_space_simoptions()
%TEST_DESIGN_SPACE_SIMOPTIONS Preserve observable field-presence semantics.
c=[.32;.8;.2;.1;.5;.002;.1;2;.8;.7;.6;.4;.05;5.2;.025;.7];
sim=struct('PreventStrandDiameterGreaterThanSlotOpening',false);
[~,~,modern,legacy]=rnfoundry.em.test.assertCandidateLegacyParity(c, ...
    struct('ArmatureType','internal'),sim);
assert(~isfield(modern,'MaxStrandDiameter'));
assert(~isfield(legacy,'MaxStrandDiameter'));
assert(modern.MinStrandDiameter==legacy.MinStrandDiameter);
assert(modern.PreventStrandDiameterGreaterThanSlotOpening== ...
       legacy.PreventStrandDiameterGreaterThanSlotOpening);

sim.MaxStrandDiameter=.7e-3;
[~,~,modern,legacy]=rnfoundry.em.test.assertCandidateLegacyParity(c, ...
    struct('ArmatureType','internal'),sim);
assert(isfield(modern,'MaxStrandDiameter') && isfield(legacy,'MaxStrandDiameter'));
assert(modern.MaxStrandDiameter==legacy.MaxStrandDiameter);

% Freeze CoilTurns' exact Ac == available-area quirk (NStrands remains NaN).
maxDiameter=.7e-3;
fullDiameter=rnfoundry.em.winding.insulatedWireDiameter(maxDiameter);
[~,probe]=rnfoundry.em.test.assertCandidateLegacyParity(c, ...
    struct('ArmatureType','internal'),struct('MaxStrandDiameter',maxDiameter));
c(15)=pi*fullDiameter^2/(4*probe.Hc*probe.Wc*probe.CoilFillFactor);
[modernDesign,legacyDesign]=rnfoundry.em.test.assertCandidateLegacyParity(c, ...
    struct('ArmatureType','internal'),struct('MaxStrandDiameter',maxDiameter));
assert(isnan(legacyDesign.NStrands) && isnan(modernDesign.NStrands));
assert(isnan(legacyDesign.Dc) && isnan(modernDesign.Dc));
end
