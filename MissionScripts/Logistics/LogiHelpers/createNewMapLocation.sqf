/*
 * Author: WaldoTheWarfighter
 * Intended to create a named map location at a game logic's position.
 * WARNING: This legacy helper is not safe for a live mission. It calls setType on an undefined
 * `_editableLocation` rather than the created location and lacks a server/repeat guard. The
 * example below documents the intended arguments; do not run it until the helper is repaired.
 * Locality and authority: Currently unguarded on whichever machine calls it. A repeat call
 * can create another location and does not provide a controlled JIP state replay.
 * Arguments: 0: placed game logic <OBJECT>; 1: new name <STRING>;
 *   2: CfgLocationTypes type <STRING> (for example "NameVillage").
 * Return Value: No supported success value in the current implementation.
 * Current callers: None in the pack; legacy mission-maker helper only.
 * Example: [myLocationLogic, "New Village", "NameVillage"] call Waldo_fnc_CreateMapLocationName;
 * Result: Intended to create a location, but currently unsafe and not supported for use.

     Below is a list of common location types you might use in scripting and mission design, as derived from the Arma 3 documentation NOT ALL OF THESE WILL WORK:
    
    Airport (on Tanoa only. Tanoan airports have their own location type. On Altis and Stratis, airports are NameLocal)
    Area
    BorderCrossing
    CityCenter
    CivilDefense
    CulturalProperty
    DangerousForces
    Flag
    FlatArea
    FlatAreaCity
    FlatAreaCitySmall
    Hill
    HistoricalSite
    Invisible
    Mount
    Name
    NameCity
    NameCityCapital
    NameLocal (will return names like Airport)
    NameMarine
    NameVillage
    RockArea
    SafetyZone
    Strategic
    StrongpointArea
    VegetationBroadleaf
    VegetationFir
    VegetationPalm
    VegetationVineyard
    ViewPoint
    b_air
    b_antiair
    b_armor
    b_art
    b_hq
    b_inf
    b_installation
    b_maint
    b_mech_inf
    b_med
    b_mortar
    b_motor_inf
    b_naval
    b_plane
    b_recon
    b_service
    b_support
    b_uav
    b_unknown
    c_air
    c_car
    c_plane
    c_ship
    c_unknown
    fakeTown
    group_0
    group_1
    group_10
    group_11
    group_2
    group_3
    group_4
    group_5
    group_6
    group_7
    group_8
    group_9
    n_air
    n_antiair
    n_armor
    n_art
    n_hq
    n_inf
    n_installation
    n_maint
    n_mech_inf
    n_med
    n_mortar
    n_motor_inf
    n_naval
    n_plane
    n_recon
    n_service
    n_support
    n_uav
    n_unknown
    o_air
    o_antiair
    o_armor
    o_art
    o_hq
    o_inf
    o_installation
    o_maint
    o_mech_inf
    o_med
    o_mortar
    o_motor_inf
    o_naval
    o_plane
    o_recon
    o_service
    o_support
    o_uav
    o_unknown
    respawn_air
    respawn_armor
    respawn_inf
    respawn_motor
    respawn_naval
    respawn_para
    respawn_plane
    respawn_unknown
    u_installation

*/

params ["_logicObject", "_newName", "_locationType"];

// Ensure the specified location type is valid and exists
if (isNil {configFile >> "CfgLocationTypes" >> _locationType}) then {
    diag_log format ["Specified location type '%1' does not exist in CfgLocationTypes.", _locationType];
    // Exit the script if the location type is not valid
};

// Ensure the game logic object exists
if (!isNull _logicObject) then {
    private _position = getPos _logicObject;

    // Create a new location at the given position with the specified type
    private _newLocation = createLocation [_position];
    _newLocation setText _newName;
    _editableLocation setType _locationType;
    
    // Optionally, adjust the size of the location if needed
    // _newLocation setRectangular [sizeX, sizeY, angle];

    // Log success message
    diag_log format ["New location created at %1 named '%2' with type %3", _position, _newName, _locationType];
} else {
    diag_log format ["Game logic object not found."];
};
