# AutoFortifySetup Function

## Description

This script is designed to dynamically grab all objects synchronized to a game logic in Arma 3, add them to a side's fortify menu, and price them dynamically based on their volume & mass. The log scalars help keep the extremes (mostly) in step with everything else.

## Usage

To use this script in your Arma 3 mission:

1. Make sure your player(s) have a fortify tool in their inventory.
2. Place a game logic down and paste into its init the function call as noted below - alter it to fit your requirements.
3. Synchronize to the game logic any objects or static weapons that you wish to be constructible in fortify. (Note: Vehicles other than static weapons are not supported due to concerning behavior.)
4. If you require more than one side to use fortify, repeat the above steps in entirety and ensure the function call has the correct side in each.
5. Run the game.

## Parameters

The function takes the following parameters:

- `_target`: The object variable name you want this to apply to (The game logic)
- `_side`: The side that the crate will populate the fortify list to. Each setup is single use as the objects and logic are destroyed afterward. Options: West, East, Independent, Civilian
- `_budget`: User defined starting budget for the side, this can then be added to later on using the ACE_Fortify budget script.

### Example

```sqf
[this, west, 6000] call Waldo_fnc_AutoFortifySetup;
```


## Budget updates

ACE Fortify Budget Function can be used to update the given sides budget.

 Arguments:
  0: Side <SIDE>
  1: Change <NUMBER> (default: 0)
  2: Display hint <BOOL> (default: true)

 Return Value:
  None

 Example:
```sqf
  [west, -250, false] call ace_fortify_fnc_updateBudget
```

## Zeus Budget Module

I have also created a ZEN module which allows you to do this via Zeus during the mission if desired. You can find out how it works on the [Waldos Mission Pack Zeus Modules](https://github.com/AdamWaldie/WaldosMissionPack/wiki/Waldos-Mission-Pack-Zeus-Modules) page.
