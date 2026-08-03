/*
 * Author: WaldoTheWarfighter
 * Derives the full-audit ACRE configuration from the release root configuration, enabling three
 * deterministic Babel languages and partial multilingual player-variable overrides for live QA.
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
    private _groups = (_sides select _westIndex) select 3;
    private _groupIndex = _groups findIf {toUpper (_x select 0) == 'VIKING-1-1'};
    if (_groupIndex >= 0) then {
        (_groups select _groupIndex) set [3, [
            ['ACRE_PRC343', 1, [1, 1], 'LEFT'],
            ['ACRE_PRC343', 2, [1, 2], 'RIGHT'],
            ['ACRE_PRC152', 1, 'PLT1', 'RIGHT'],
            ['ACRE_PRC152', 2, 'AIRGND', 'LEFT']
        ]];
    };
};
private _babel = _config get 'babel';
_babel set ['enabled', true];
_babel set ['languages', [['en', 'English'], ['fr', 'French'], ['ru', 'Russian']]];
_babel set ['sideDefaults', [['WEST', ['en'], 'en'], ['EAST', ['ru'], 'ru'], ['GUER', ['fr'], 'fr'], ['CIV', ['fr'], 'fr']]];
_babel set ['unitOverrides', [
    [['VARIABLE', 'qa_player_1'], ['en', 'fr'], 'en'],
    [['VARIABLE', 'qa_player_2'], ['en', 'ru'], 'ru']
]];
_config
