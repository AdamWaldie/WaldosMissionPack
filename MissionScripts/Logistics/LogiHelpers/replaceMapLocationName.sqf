/*
    Script to replace a map location name based on a nearby game logic object and specify the new location's type.


    To use this, place down a logic module with a variable name, then execute this script in init.sqf


    Usage: [locationLogic, "New Location Name", "LocationType"] call Waldo_fnc_Waldo_fnc_ReplaceMapLocationName;

    Parameters:
    0: OBJECT - The variable name of the game logic object used as a reference point.
    1: STRING - The new name for the location.
    2: STRING - The type of the new location (e.g., "NameCity", "NameVillage", "NameCityCapital").

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
    private _nearestLocation = nearestLocation [_position, ""];

    if (!isNull _nearestLocation) then {
        // Create a new, editable location at the same place with the specified type
        private _editableLocation = createLocation [_nearestLocation];
        _editableLocation setText _newName;
        _editableLocation setType _locationType;
        
        // Log success message
        diag_log format ["Location near %1 renamed to '%2' with type %3", _logicObject, _newName, _locationType];
    } else {
        diag_log format ["No nearby location found near %1 to replace with name '%2'", _logicObject, _newName];
    };
} else {
    diag_log format ["Game logic object named '%1' not found.", _logicObject];
};
