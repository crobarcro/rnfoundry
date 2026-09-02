function test_suite=test_radial_slot_region_area_parity()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_external_uninsulated_all_faces_match_femm()
assertRadialSlotRegionAreaParity('external',false);
end
