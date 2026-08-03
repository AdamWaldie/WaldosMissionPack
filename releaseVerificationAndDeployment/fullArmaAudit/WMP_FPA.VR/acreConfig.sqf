/*
 * Author: WaldoTheWarfighter
 * Derives the full-audit ACRE configuration from the release root configuration, enabling three
 * deterministic Babel languages and partial multilingual player-variable overrides for live QA.
 *
 * Arguments: None.
 * Return Value: HASHMAP - audit-specific ACRE configuration consumed as mission acreConfig.sqf.
 *
 * Example: Copied to acreConfig.sqf by the full-audit generator and builder.
 * Current callers: build_full_arma_audit.py and generate_full_arma_audit_mission.py.
 */
private _config = call compile preprocessFileLineNumbers 'WMPPackSource\acreConfig.sqf';
private _babel = _config get 'babel';
_babel set ['enabled', true];
_babel set ['languages', [['en', 'English'], ['fr', 'French'], ['ru', 'Russian']]];
_babel set ['sideDefaults', [['WEST', ['en'], 'en'], ['EAST', ['ru'], 'ru'], ['GUER', ['fr'], 'fr'], ['CIV', ['fr'], 'fr']]];
_babel set ['unitOverrides', [
    [['VARIABLE', 'qa_player_1'], ['en', 'fr'], 'en'],
    [['VARIABLE', 'qa_player_2'], ['en', 'ru'], 'ru']
]];
_config
