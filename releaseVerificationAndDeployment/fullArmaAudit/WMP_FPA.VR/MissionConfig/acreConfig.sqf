/*
 * Author: WaldoTheWarfighter
 * Derives the full-audit ACRE configuration from the release root configuration. Managed test
 * radios use distinctive non-channel-1 assignments and named operational nets. Every playable
 * audit soldier carries one PRC-343, one PRC-152 and one PRC-148, so the same example can be
 * verified from any slot. It also enables the configured deterministic Babel examples and partial
 * multilingual overrides for this QA mission.
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
    private _groupIndex = _groups findIf {toUpper (_x select 0) == 'VIKING 2-3'};
    if (_groupIndex >= 0) then {
        (_groups select _groupIndex) set [1, [
            ['ACRE_PRC343', 1, [7, 13], 'LEFT'],
            ['ACRE_PRC152', 1, 'CAS2', 'RIGHT'],
            ['ACRE_PRC148', 1, 'CFF1', 'BOTH']
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
