# WaldosMissionPack
A package of mission scripts for new mission makers.

![alt text](https://github.com/AdamWaldie/WaldosMissionPack/blob/main/Pictures/loading.jpg?raw=true)

**If you find this mission pack inside a mission, please do not utilise it. Mission Makers like to customise the pack. Instead download the original from github: https://github.com/AdamWaldie/WaldosMissionPack/releases/latest**

# Background Information
- This project was created originally for the mission makers of the Rooster Teeth Gaming Discord, with the intent to provide them with the easiest possible method 
to utilise critical systems of arma 3.
- The majority of QOL & critical scripts can be utilised via the init.sqf, initServer.sqf, initPlayerlocal.sqf & description.ext files.
- Mission Pack Functions are defined in WaldoFunctions.sqf in MissionScripts Folder.
- For those seeking the more involved features of this pack, or greater control, each file is fully documented on its usage, its parameters and its purpose. 
- The pack has a large amount to discover and utilise, so have at it!

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


# QuickStart Guide
You can always find the most recent quickstart guide at this URL: https://github.com/AdamWaldie/WaldosMissionPack/wiki/Quickstart-Guide

# Other Information
- All files are provided with description on their utilisation and purpose.
- initPlayerLocal.sqf utilises CBA eventhandlers to provide respawn loadout saving/loading. You can choose whether to respawn with starting equipment, or what they died with in that file.
- Its recommended that you download Visual Studio Code & Its SQF plugins. Itll make any script reading in Arma 3 easier on you! 
    - Visual Studio Code: https://code.visualstudio.com/
    - SQF Language Extension: https://marketplace.visualstudio.com/items?itemName=vlad333000.sqf
    - SQF Debugger Extension: https://marketplace.visualstudio.com/items?itemName=billw2011.sqf-debugger

# Required Addons
- CBA_A3

# Supported Addons
- ACE 3
- ACRE 2 (You can disable this via missionParameters.sqf)
- TFAR (Inherrent support via 3Eden)
- Zeus Enhanced & Compat
- LAMBS Series of mods (Tutorial Mission Requires this, the pack can work without it)
- All unit mods compatable

# Tutorial Mission Addons
- ACE
- ACRE
- LAMBS_DANGER
- ZEN & Zen Ace compat
