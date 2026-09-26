/*
 * Author: WaldoTheWarfighter
 * Purpose: Attach every object synchronized to the nearest Game Logic to one parent while
 * keeping each child's authored relative position. This is a manual Eden layout helper.
 * Locality/authority: intended for the parent object's Eden Init on each machine. There is no
 * server authority check or owner dispatch; test movable vehicles in multiplayer.
 * Repeat/JIP: no registration, action, or explicit state replay. Eden Init repeats for joining
 * clients; dynamically spawned parents need their own setup path.
 * Arguments:
 * 0: parent <OBJECT> (required) - existing vehicle or other world object.
 * Return Value: Nothing useful; the function iterates the synchronized objects.
 * Current callers: mission-maker Eden parent Init fields and manual compositions.
 * Example: [this] call Waldo_fnc_MassAttachRelative;
 * Result: the nearest Logic's synchronized children are attached at their Eden offsets.
 */

params["_targetObject"];

// Finds all synced Objects. Hides the model and attaches the object to vehicle.
_syncLogic = nearestObject [_targetObject, "Logic"]; 
_AttachingLayerContents = synchronizedObjects _syncLogic;

// Attach Relative Position to MHQ vehicle & hide globally
{
    call{0 = [_x, _targetObject, true] call BIS_fnc_attachToRelative;};
} forEach _AttachingLayerContents;
