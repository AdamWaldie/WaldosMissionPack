_Associated Files: MissionScripts\MissionInit\ACRE2\BabelActivation.sqf_

Description: 
The script activates the Babel system in Arma 3 with Advanced Combat Radio Environment 2 (ACRE2). It sets up the languages spoken by different sides and defines the languages spoken by interpreters. It adds all the necessary languages to the ACRE2 Babel system, assigns them to the respective units based on the side they belong to, and creates a diary record with a list of languages spoken in the area, highlighting the ones the player can speak.

Interpreters can speak all languages.

Arguments:
_languages - An array of sub-arrays. Each sub-array contains a side (West, East, Independent, Civilian) and the languages they speak as strings. 
_interpreters - An array of units that are interpreters. These units can speak all languages.

Returns:
N/A. The script operates by side effect, creating diary records and setting up the ACRE2 Babel system.

Example:
[
    [
        [West, "English","French"],
        [East, "Chinese"],
        [independent, "Altian"],
        [civilian, "Altian"]
    ],
    [unit, unit2]
] call Waldo_fnc_BabelActivation;


## Setup

In the init.sqf you should uncomment the Waldo_fnc_BabelActivation function call.

It is broken into two arrays:
1. A 2d array which contains up to 4 sides and their associated spoken languages.
2. A list of variable names which relate to units in the game. These individuals are interpreters.

If you do not require Babel, comment out this section by surrounding it with /* and */.

If you do not require any interpreters, you can remove the section list as shown below:
![](https://i.imgur.com/IKIHu9s.png)

If you do require interpreters you can add the variable names of units in the second array. The below example makes every player an interpreter.
![](https://i.imgur.com/Qkf3S5a.png)

## Output.

Sides will be correctly setup with the Babel system, and a piece of documentation will be generated dynamically based on the languages used, and whether the player can speak it.

If the player is an interpreter based on the above example, they will see this:
![](https://i.imgur.com/uekMEWK.jpg)

If the player is not an interpreter, and BLUFOR, based on the above example, they will see this:
![](https://i.imgur.com/RpLDJJN.png)