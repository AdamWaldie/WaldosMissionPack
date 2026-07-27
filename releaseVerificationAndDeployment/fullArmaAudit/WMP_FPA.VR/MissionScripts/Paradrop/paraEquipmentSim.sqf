/*
This function run a para jump simulation on a given player. 

Arguments:
0: Player <OBJECT>
1: whether the advanced simulation (lost items) is enabled
Return Value:
None

Example:
["unit"] call Waldo_fnc_paraEquipmentSim;

Public: No
*/

params [
    ["_player", player],
    ["_advancedMode",false]
];

private _blacklist_headgear = ["H_Bandanna_gry","H_Bandanna_blu","H_Bandanna_cbr","H_Bandanna_khk_hs","H_Bandanna_khk","H_Bandanna_mcamo","H_Bandanna_sgg","H_Bandanna_sand","H_Bandanna_surfer","H_Bandanna_surfer_blk","H_Bandanna_surfer_grn","H_Bandanna_camo","rhssaf_bandana_digital","rhssaf_bandana_digital_desert","rhssaf_bandana_md2camo","rhssaf_bandana_oakleaf","rhssaf_bandana_smb","rhsgref_bcap_specter","rhs_beanie_green","H_Watchcap_blk","H_Watchcap_cbr","rhs_beanie","H_Watchcap_camo","H_Watchcap_khk","DAR_Beret_Blk","DAR_Beret_Mar","H_Beret_blk","H_Beret_gen_F","rhs_beret_mp1","rhs_beret_mp2","rhsgref_un_beret","rhs_beret_vdv2","rhs_beret_vdv3","rhs_beret_vdv1","rhs_beret_milp","H_Beret_02","H_Beret_Colonel","rhssaf_beret_para","rhssaf_beret_green","rhssaf_beret_black","rhssaf_beret_red","rhssaf_beret_blue_un","rhs_Booniehat_digi","rhs_Booniehat_flora","H_Booniehat_khk_hs","H_Booniehat_khk","H_Booniehat_mcamo","H_Booniehat_oli","H_Booniehat_tan","H_Booniehat_tna_F","H_Booniehat_dgtl","rhsgref_Booniehat_alpen","rhs_Booniehat_m81","rhs_booniehat2_marpatd","rhs_booniehat2_marpatwd","rhs_Booniehat_ocp","rhs_Booniehat_ucp","rhssaf_booniehat_digital","rhssaf_booniehat_md2camo","rhssaf_booniehat_woodland","H_Cap_grn_BI","H_Cap_blk","H_Cap_Black_IDAP_F","H_Cap_blu","H_Cap_blk_CMMG","H_Cap_grn","H_Cap_blk_ION","H_Cap_oli","H_Cap_oli_hs","H_Cap_Orange_IDAP_F","H_Cap_police","H_Cap_press","H_Cap_red","H_Cap_surfer","H_Cap_tan","H_Cap_khaki_specops_UK","H_Cap_usblack","H_Cap_tan_specops_US","H_Cap_White_IDAP_F","H_Cap_blk_Raven","H_Cap_brn_SPECOPS","DAR_Stetson","rhs_xmas_antlers","rhsgref_patrolcap_specter","rhs_fieldcap","rhs_fieldcap_digi","rhs_fieldcap_digi2","rhs_fieldcap_ml","rhs_fieldcap_khk","rhs_fieldcap_vsr","rhsgref_fieldcap_ttsko_digi","rhsgref_fieldcap_ttsko_forest","rhsgref_fieldcap_ttsko_mountain","rhsgref_fieldcap_ttsko_urban","H_Hat_blue","H_Hat_brown","H_Hat_camo","H_Hat_checker","H_Hat_grey","H_Hat_tan","DAR_JMCap_Blk","H_MilCap_blue","H_MilCap_gen_F","H_MilCap_ghex_F","H_MilCap_gry","H_MilCap_ocamo","H_MilCap_mcamo","H_MilCap_tna_F","H_MilCap_dgtl","rhsgref_hat_M1951","rhsusf_patrolcap_ocp","rhsusf_patrolcap_ucp","H_Hat_Safari_olive_F","H_Hat_Safari_sand_F","H_Shemag_olive","H_Shemag_olive_hs","H_ShemagOpen_tan","H_ShemagOpen_khk","H_StrawHat","H_StrawHat_dark","tf47_beret","rhs_8point_marpatd","rhs_8point_marpatwd"];
private _blacklist_glasses = ["G_Aviator","G_Spectacles","G_Sport_Red","G_Sport_Blackyellow","G_Sport_BlackWhite","G_Sport_Checkered","G_Sport_Blackred","G_Sport_Greenblack","G_Squares_Tinted","G_Squares","G_Spectacles_Tinted"];

private _nvgRandom = random [1, 4, 10];
private _hatRandom = random [1, 4, 10];
private _glaRandom = random [1, 4, 10];

switch _advancedMode do {
    case (false): { // Basic
        if ((hmd _player != "") && (_nvgRandom > 4)) then {
            private _baseHmd = hmd _player;
            _player unassignItem _baseHmd;
            [["You almost lost"], [getText (configfile >> "CfgWeapons" >> _baseHmd >> "picture"), 2], ["during your jump, it is in your inventory"]] call CBA_fnc_notify;
        };
        //if (EGVAR(Settings,jumpSimulationHat) && ((headgear _player in _blacklist_headgear) && (_hatRandom > 3))) then {
        if ((_hatRandom > 3) && ((headgear _player in _blacklist_headgear))) then {
            private _baseHeadgear = headgear _player;
            _player unassignItem _baseHeadgear;
            [["You almost lost"], [getText (configfile >> "CfgWeapons" >> _baseHeadgear >> "picture"), 2], ["during your jump, it is in your inventory"]] call CBA_fnc_notify;

        };
        //if (EGVAR(Settings,jumpSimulationGlasses) && ((goggles _player in _blacklist_glasses) && (_glaRandom > 2))) then { OLD - Unrestricted removal of glass slot
        if ((_glaRandom > 2) && ((goggles _player in _blacklist_glasses))) then {
            private _baseGoggles = goggles _player;
            _player unassignItem _baseGoggles;
            [["You almost lost"], [getText (configfile >> "CfgGlasses" >> _baseGoggles >> "picture"), 2], ["during your jump, it is in your inventory"]] call CBA_fnc_notify;
        };
    };
    case (true): { // Advanced

        if ((hmd _player != "") && (_nvgRandom > 4)) then {
            private _advHmd = hmd _player;
            _player unlinkItem _advHmd;
            [["You lost"], [getText (configfile >> "CfgWeapons" >> _advHmd >> "picture"), 2], ["during your jump"]] call CBA_fnc_notify;
        };
        //if (EGVAR(Settings,jumpSimulationHat) && ((headgear _player in _blacklist_headgear) && (_hatRandom > 3))) then {
        if ((_hatRandom > 3) && ((headgear _player in _blacklist_headgear))) then {
            private _advHeadgear = headgear _player;
            _player unlinkItem _advHeadgear;
            [["You lost"], [getText (configfile >> "CfgWeapons" >> _advHeadgear >> "picture"), 2], ["during your jump"]] call CBA_fnc_notify;
        };
        //if (EGVAR(Settings,jumpSimulationGlasses) && ((goggles _player in _blacklist_glasses) && (_glaRandom > 2))) then {
        if ((_glaRandom > 2) && ((goggles _player in _blacklist_glasses))) then {
            private _advGoggles = goggles _player;
            _player unlinkItem _advGoggles;
            [["You lost"], [getText (configfile >> "CfgGlasses" >> _advGoggles >> "picture"), 2], ["during your jump"]] call CBA_fnc_notify;
        };
    };
    default {};
};