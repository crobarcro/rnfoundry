function test_suite=test_radial_slot_region_area_external_insulated()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_external_insulated_all_faces_match_femm()
assertRadialSlotRegionAreaParity('external',true);
end
