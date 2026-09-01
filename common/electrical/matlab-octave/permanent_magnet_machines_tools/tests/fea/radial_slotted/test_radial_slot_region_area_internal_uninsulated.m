function test_suite=test_radial_slot_region_area_internal_uninsulated()
try, test_functions=localfunctions(); catch, end %#ok<NASGU>
initTestSuite;
end
function test_internal_uninsulated_all_faces_match_femm()
assertRadialSlotRegionAreaParity('internal',false);
end
