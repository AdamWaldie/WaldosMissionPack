/*
 * Author: WaldoTheWarfighter
 * Derives the full-audit ACRE configuration from the release root configuration. Managed test
 * radios use distinctive non-channel-1 assignments and named operational nets. Every supported
 * carried-radio profile has a paired squad inventory in the generated mission. Radio-specific nets
 * prove that unrelated radios no longer impose a shared channel capacity. It also enables the
 * configured deterministic Babel examples and partial multilingual overrides for this QA mission.
 *
 * Arguments: None.
 * Return Value: HASHMAP - audit-specific ACRE configuration consumed as MissionConfig\acreConfig.sqf.
 *
 * Example: Copied to MissionConfig\acreConfig.sqf by the full-audit generator and builder.
 * Current callers: build_full_arma_audit.py and generate_full_arma_audit_mission.py.
 */
private _config = call compile preprocessFileLineNumbers 'MissionConfig\releaseAcreConfig.sqf';
private _sides = _config get 'sides';
private _westIndex = _sides findIf {toUpper (_x select 0) == 'WEST'};
if (_westIndex >= 0) then {
    private _west = _sides select _westIndex;
    private _groups = _west select 3;
    private _groupIndex = _groups findIf {toUpper (_x select 0) == 'VIKING-1-1'};
    if (_groupIndex >= 0) then {
        (_groups select _groupIndex) set [3, [
            ['ACRE_PRC343', 1, [7, 13], 'LEFT'],
            ['ACRE_PRC343', 2, [12, 6], 'RIGHT'],
            ['ACRE_PRC152', 1, 'CAS2', 'RIGHT'],
            ['ACRE_PRC152', 2, 'CONVOY', 'LEFT'],
            ['ACRE_PRC148', 1, 'CFF1', 'BOTH'],
            ['ACRE_PRC117F', 1, 'AIR', 'BOTH'],
            ['ACRE_BF888S', 1, 'BF_LOCAL', 'RIGHT'],
            ['ACRE_SEM52SL', 1, 'SEM_LOCAL', 'LEFT'],
            ['ACRE_PRC77', 1, 'LEGACY', 'RIGHT'],
            ['ACRE_SEM70', 1, 'LEGACY', 'LEFT']
        ]];
    };
};
private _babel = _config get 'babel';
_babel set ['enabled', true];
_babel set ['languages', [['common', 'Common'], ['en', 'English'], ['ru', 'Russian'], ['fr', 'French'], ['ar', 'Arabic']]];
_babel set ['sideDefaults', [['WEST', ['common', 'en'], 'en'], ['EAST', ['common', 'ru'], 'ru'], ['GUER', ['common', 'fr'], 'fr'], ['CIV', ['common', 'ar'], 'ar']]];
_babel set ['unitOverrides', [
    [['VARIABLE', 'qa_player_1'], ['common', 'en', 'fr'], 'en'],
    [['VARIABLE', 'qa_player_2'], ['common', 'en', 'ru'], 'ru']
]];
_config
