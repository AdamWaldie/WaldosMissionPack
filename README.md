# WaldosMissionPack
A package of mission scripts for new mission makers.

![alt text](https://github.com/AdamWaldie/WaldosMissionPack/blob/main/Pictures/loading.jpg?raw=true)

**If you find this mission pack inside a mission, please do not utilise it. Mission Makers like to customise the pack. Instead download the original from github: https://github.com/AdamWaldie/WaldosMissionPack/releases/latest**

This project was created originally for the mission makers of the Rooster Teeth Gaming Discord, with the intent to provide them with the easiest possible method 
to utilise critical systems of arma 3.

To this end, the majority of QOL & critical scripts can be utilised via the init.sqf, initServer.sqf, initPlayerlocal.sqf & description.ext files.

Functions are defined in WaldoFunctions.sqf in MissionScripts Folder.


Unless you are wanting to use specific features such as: creating starter crates, autolimited arsenals or Mobile Headquarters systems amoung other scripts, you need not venture further than the root mission directory, or using one of the compositions provided.

For those seeking knowledge or greater control, each file is fully documented on its usage, its parameters and its purpose. The pack has a large amount to discover and utilise.

# Required Steps To Enable Scripts
1. Download the most recent Waldos Mission Pack.
2. Copy everything from that folder into your mission
3. Ensure that the mission.sqm is unbinarized (attributes --> General --> under Misc --> uncheck the "binarize the scenario file" box)
4. Fill out the relevant information in the description.ext
5. Comment out / replace the MHQ related calls in the init.sqf and initServer.sqf
6. IF YOU ARE USING ACE 3:
   - Disable ACE 3 Respawn in server & mission addon settings.
7. IF YOU ARE USING ACRE2:
   - Player Groups MUST be given a Callsign in Eden & have their Callsign & radio frequiencies assigned in missionParameters.sqf.
8. Waldo's AI tweaks can be set via the missionParameters.sqf file.
9. Remove the UnitInsignias Folder if you arent planning to use them.
10. Remove/alter differing setup scripts in init.sqf & initServer.sqf as required and labelled.
11. The compositions may also prove helpful in gaining base functionality more expediently.

# Other Information
- All files are provided with description on their utilisation, their parameters and how you can use them.
- initPlayerLocal.sqf utilises CBA eventhandlers to provide respawn loadout saving/loading. You can choose whether to respawn with starting equipment, or what they died with in that file.

# Pack Features
- Loadout saving and respawn system
- Automatic ACRE2 Radio setup and respawn handling - based on mission makers specification in init.sqf
- Custom loadout & logistics system which scrapes the kits of all playable characters on a particular side to fulfil base logistical needs - such as starter crates and supply crates, WITHOUT YOU HAVING TO LIFT A FINGER! (Dependant on the loadouts being edited ACE or Vanilla arsenal in the editor, and the disabling of scenario binarization)
- Vehicle unflippin actions
- Simple AI convoy script expanded and enhanced from Tovas original.
- Teleportation Script
- Endex & Safestart Scripts
- Custom Zeus Enhanced modules for in-game access to the logistics system and ENDEX scripts.
- HALO & Static Line Jump Scripts with equipment & weapon loss simulation.
- Extensively documented files to learn how it works, and make use of this pack!
- Mission Pack Compositions to hasten the learning and mission building process

# Required Addons
- CBA_A3
- Tutorial Mission:
   - ACE
   - ACRE
   - LAMBS_DANGER
   - ZEN & Zen Ace compat

# Supported Addons
- ACE 3
- ACRE 2 (You can disable this via missionParameters.sqf)
- TFAR (Inherrent support via 3Eden)
- Zeus Enhanced & Compat
- LAMBS Series of mods (Tutorial Mission Requires this, the pack can work without it)
- All unit mods compatable
