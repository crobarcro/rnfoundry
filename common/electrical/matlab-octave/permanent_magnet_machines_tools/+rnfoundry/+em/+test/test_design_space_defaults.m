function test_design_space_defaults()
%TEST_DESIGN_SPACE_DEFAULTS Freeze public Milestone 1B defaults.
s=rnfoundry.em.optim.RadialSlottedDesignSpace(); o=s.Options;
assert(o.Phases==3 && o.yd==4 && o.Max_tc==.2 && o.Min_g==.5e-3);
assert(o.CoilLayers==2 && o.NStrands==1 && o.tc2Vtc1==.1);
assert(s.SimOptions.MinStrandDiameter==.5e-3);
end
