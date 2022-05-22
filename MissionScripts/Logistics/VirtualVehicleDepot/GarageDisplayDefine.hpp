//- GUI Documenation: https://community.bistudio.com/wiki/Arma:_GUI_Configuration
//- Control Types:    https://community.bistudio.com/wiki/Arma:_GUI_Configuration#Control_Types
//- Control Styles:   https://community.bistudio.com/wiki/Arma:_GUI_Configuration#Control_Styles

//Eden Editor macros such as background colour and pixel grid
#include "\a3\3DEN\UI\macros.inc"
#include "\a3\3DEN\UI\macroexecs.inc"
//GRIDs
#include "\a3\ui_f\hpp\defineCommonGrids.inc"
#include "\A3\ui_f\hpp\defineCommonColors.inc"
//DIK Key Codes
#include "\a3\ui_f\hpp\definedikcodes.inc"
//Eden Editor IDDs and IDCs as well as control types, styles and macros
#include "\a3\3den\ui\resincl.inc"

#include "VVDIDC.inc"

#define SIZE_X  (((0.81 * 30 * GUI_GRID_W) min (safezoneW*0.5)) / (0.81 * GUI_GRID_W))
#define SIZE_Y  (((0.45 * 30 * GUI_GRID_H) min (safezoneH*0.45)) / (0.45 * GUI_GRID_H))
#define SettingGroupSize_X  (0.81 * (SIZE_X min SIZE_Y) * GUI_GRID_W)
#define SettingGroupSize_Y  (0.45 * (SIZE_X min SIZE_Y) * GUI_GRID_H)
#define PylonWidth  (GUI_GRID_W*5)
#define PylonHeight  (GUI_GRID_H*0.9)

#define SpawnGroupSize_X (GUI_GRID_W*9.5)

//Import Base Controls
import RscButton;
import RscButtonMenu;
import RscCheckBox;
import RscCombo;
import RscListBox;
import RscListNBox;
import RscControlsGroupNoScrollbars;
import RscPicture;
import RscPictureKeepAspect;
import RscProgress;
import RscText;
import RscEdit;
import RscXSliderH;
import ctrlButtonPictureKeepAspect;
import RscDisplayGarage;

class GarageLoadDisplay: RscDisplayGarage {
	idd = 8765;
	class controls: controls
	{
		class ArrowLeft: ArrowLeft {};
		class ArrowRight: ArrowRight {};
		class BackgroundLeft: BackgroundLeft {};
		class BackgroundRight: BackgroundRight {};
		class LineIcon: LineIcon {};
		class LineTabLeft: LineTabLeft {};
		class LineTabLeftSelected: LineTabLeftSelected {};
		class LineTabRight: LineTabRight {};
		class Tabs: Tabs {};
		class FrameLeft: FrameLeft {};
		class FrameRight: FrameRight {};
		class Load: Load {};
		class LoadCargo: LoadCargo {};
		class Message: Message {};
		class Space: Space {};
		class ControlBar: ControlBar {
			class controls: controls
			{
				class ButtonClose: ButtonClose {};
				class ButtonInterface: ButtonInterface {};
				class ButtonRandom: ButtonRandom {};
				class ButtonSave: ButtonSave {};
				class ButtonLoad: ButtonLoad {};
				class ButtonExport: ButtonExport {};
				class ButtonImport: ButtonImport {};
			};
		};
		class Info: Info { class controls: controls {}; };
		class Stats: Stats { class controls: controls {}; };
		class MouseBlock: MouseBlock {};
		class Template: Template {};
		class MessageBox: MessageBox {};
		class TabCar: TabCar {};
		class IconCar: IconCar {};
		class ListCar: ListCar {};
		class ListDisabledCar: ListDisabledCar {};
		class TabTank: TabTank {};
		class IconTank: IconTank {};
		class ListTank: ListTank {};
		class ListDisabledTank: ListDisabledTank {};
		class TabHelicopter: TabHelicopter {};
		class IconHelicopter: IconHelicopter {};
		class ListHelicopter: ListHelicopter {};
		class ListDisabledHelicopter: ListDisabledHelicopter {};
		class TabPlane: TabPlane {};
		class IconPlane: IconPlane {};
		class ListPlane: ListPlane {};
		class ListDisabledPlane: ListDisabledPlane {};
		class TabNaval: TabNaval {};
		class IconNaval: IconNaval {};
		class ListNaval: ListNaval {};
		class ListDisabledNaval: ListDisabledNaval {};
		class TabStatic: TabStatic {};
		class IconStatic: IconStatic {};
		class ListStatic: ListStatic {};
		class ListDisabledStatic: ListDisabledStatic {};
		class TabCrew: TabCrew {};
		class IconCrew: IconCrew {};
		class ListCrew: ListCrew {};
		class ListDisabledCrew: ListDisabledCrew {};
		class TabAnimationSources: TabAnimationSources {};
		class IconAnimationSources: IconAnimationSources {};
		class ListAnimationSources: ListAnimationSources {};
		class ListDisabledAnimationSources: ListDisabledAnimationSources {};
		class TabTextureSources: TabTextureSources {};
		class IconTextureSources: IconTextureSources {};
		class ListTextureSources: ListTextureSources {};
		class ListDisabledTextureSources: ListDisabledTextureSources {};

		class ControlBarDummy: RscControlsGroupNoScrollbars
		{
			idc=IDC_GARAGEDISPLAY_CONTROLBARDUMMY;
			x="8 * 	((safezoneW - 1 * 			(			((safezoneW / safezoneH) min 1.2) / 40)) * 0.1) + 			(safezoneX)";
			y="23.5 * 			(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25) + 			(safezoneY + safezoneH - 			(			((safezoneW / safezoneH) min 1.2) / 1.2))";
			w="safezoneW";
			h="1 * 			(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
			class controls
			{
				class ButtonTry: RscButtonMenu
				{
					idc=-1;
					text="";
					x="0.5 * 			(			((safezoneW / safezoneH) min 1.2) / 40)";
					y="0 * 			(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
					w="((safezoneW - 1 * 			(			((safezoneW / safezoneH) min 1.2) / 40)) * 0.1) - 0.1 * 			(			((safezoneW / safezoneH) min 1.2) / 40)";
					h="1 * 			(			(			((safezoneW / safezoneH) min 1.2) / 1.2) / 25)";
				};
				class ButtonOK: ButtonTry
				{
					x="0.5 * 			(			((safezoneW / safezoneH) min 1.2) / 40) + 1 * 	((safezoneW - 1 * 			(			((safezoneW / safezoneH) min 1.2) / 40)) * 0.1)";
				};
			};
		};

		class GarageStatsGroup: RscControlsGroupNoScrollbars
		{
			idc = IDC_GARAGEDISPLAY_STATS_GROUP;
			x = safezoneX + ((safezoneW - SpawnGroupSize_X) / 2.0);
			y = safezoneY + safezoneH - GUI_GRID_H*7;
			w = SpawnGroupSize_X;
			h = GUI_GRID_H*5.2;
			class controls: controls
			{
				class GarageStatsBackground: RscPicture
				{
					idc = -1;
					colorBackground[] = {0,0,0,0.5};
					text = "#(argb,8,8,3)color(0.2,0.2,0.2,0.8)";
					x = 0;
					y = 0;
					w = SpawnGroupSize_X;
					h = GUI_GRID_H*2.3;
				};

				class GarageStatsModPicture: RscPictureKeepAspect
				{
					idc = IDC_GARAGEDISPLAY_STATS_MODPIC;
					colorBackground[] ={0,0,0,0.8};
					x = GUI_GRID_W*0.1;
					y = GUI_GRID_H*0.1;
					w = GUI_GRID_W*2.1;
					h = GUI_GRID_H*2.1;
				};

				class GarageStatsMaxSpeed: RscProgress
				{
					idc = IDC_GARAGEDISPLAY_STATS_MAXSPD;
					colorFrame[] = {0,0,0,0};
					colorBar[] = {1,1,1,1};
					x = GUI_GRID_W*2.3;
					y = GUI_GRID_H*0.1;
					w = SpawnGroupSize_X - (GUI_GRID_W * 2.45);
					h = GUI_GRID_H;
				};
				class GarageStatsMaxSpeedText: RscText
				{
					idc = -1;
					colorText[]={0,0,0,1};
					colorShadow[]={1,1,1,1};
					colorBackground[]={1,1,1,0.1};
					text = "$STR_A3_RSCDISPLAYGARAGE_STAT_MAX_SPEED";
					x = GUI_GRID_W*2.3;
					y = GUI_GRID_H*0.1;
					w = SpawnGroupSize_X - (GUI_GRID_W * 2.45);
					h = GUI_GRID_H;
					shadow = 0;
				};

				class GarageStatsArmor: GarageStatsMaxSpeed
				{
					idc = IDC_GARAGEDISPLAY_STATS_ARMOR;
					y = GUI_GRID_H*1.2;
				};
				class GarageStatsArmorText: GarageStatsMaxSpeedText
				{
					text = "$STR_UI_ABAR";
					y = GUI_GRID_H*1.2;
				};

				class GarageSpawnButton: RscButton
				{
					idc = IDC_GARAGEDISPLAY_SPAWNBUTTON;
					font = "PuristaMedium";
					text = "SPAWN";
					tooltip = "Ready?";
					colorBackground[] = {0,0,0,0.5};
					x = 0;
					y = GUI_GRID_H*2.5;
					w = SpawnGroupSize_X;
					h = GUI_GRID_H*1.5;
					onButtonClick = " \
						_display = uiNamespace getVariable 'Garage_Display_Loadout'; \
						missionNameSpace setVariable ['Garage_Spawn_Flag' ,true]; \
						_display closeDisplay 1; \
					";
				};

				class GarageSpawnType: RscCombo
				{
					idc = -1;
					font = "PuristaMedium";
					text = "Pylons settings";
					tooltip = "Spawn Type";
					x = 0;
					y = GUI_GRID_H*4.2;
					w = SpawnGroupSize_X;
					h = GUI_GRID_H;
					onLBSelChanged = "missionNamespace setVariable ['Garage_SpawnType', _this select 1];";
					onLoad = "(_this select 0) lbSetCurSel (missionNamespace getVariable ['Garage_SpawnType', 0]);";
					class Items
					{
						class OnlySpawn { text = "Only Spawn"; default = 1; };
						class Getin { text = "Get in"; };
						class Flying { text = "Flying"; };
					};
				};
			};
		};
	};
};

class GarageSettingGroup: RscControlsGroupNoScrollbars
{
	idc = IDC_GARAGEDISPLAY_SETTINGGROUP;
	x = (safezoneX + safezoneW) - SettingGroupSize_X - (0.6*GUI_GRID_W);
	y = (safezoneY + safezoneH) - SettingGroupSize_Y - (1.8*GUI_GRID_H);
	w = SettingGroupSize_X;
	h = SettingGroupSize_Y;
	class controls: controls
	{
		class GarageSettingBackground: RscPicture
		{
			idc = -1;
			colorBackground[] = {0,0,0,0.5};
			text = "#(argb,8,8,3)color(0.2,0.2,0.2,0.8)";
			x = 0;
			y = 0;
			w = SettingGroupSize_X;
			h = SettingGroupSize_Y;
		};

		class GaragePylonGroup: RscControlsGroupNoScrollbars
		{
			idc = IDC_GARAGEDISPLAY_PYLON_GROUP;
			x = 0;
			y = 0;
			w = SettingGroupSize_X;
			h = SettingGroupSize_Y;
			class controls: controls
			{
				class GaragePylonText: RscText
				{
					idc = -1;
					font = "RobotoCondensedLight";
					text = "Pylons settings";
					x = 0;
					y = 0;
					w = SettingGroupSize_X;
					h = SettingGroupSize_Y * 0.07;
				};

				class GaragePylonToggle: RscButton
				{
					idc = IDC_GARAGEDISPLAY_PYLON_TOGGLE;
					font = "RobotoCondensedLight";
					text = "Option";
					tooltip = "Change display";
					x = SettingGroupSize_X*0.815;
					y = 0;
					w = SettingGroupSize_X*0.185;
					h = GUI_GRID_H;
					onButtonClick = "_this call sel_toggle_setting";
				};

				class GaragePylonUIPicture: RscPictureKeepAspect
				{
					idc = IDC_GARAGEDISPLAY_PYLON_UIPIC;
					x = 0;
					y = SettingGroupSize_Y * 0.07;
					w = SettingGroupSize_X * 0.921;
					h = SettingGroupSize_Y * 0.907;
				};

				class GaragePylonPreset: RscCombo
				{
					idc = IDC_GARAGEDISPLAY_PYLON_PRESET;
					colorBackground[] ={0,0,0,0.8};
					font = "RobotoCondensedLight";
					tooltip = "Select Preset";
					x = SettingGroupSize_X*0.03;
					y = SettingGroupSize_Y*0.086;
					w = PylonWidth;
					h = PylonHeight;
					class Items
					{
						class Custom { text = "Custom"; default = 1; };
					};
				};

				class GaragePylonMirror: RscCheckBox
				{
					idc = IDC_GARAGEDISPLAY_PYLON_MIRROR;
					font = "RobotoCondensedLight";
					tooltip = "Mirroring";
					x = SettingGroupSize_X*0.815;
					y = SettingGroupSize_Y*0.086;
					w = GUI_GRID_W;
					h = GUI_GRID_H;
				};

				class GaragePylonMirrorText: RscText
				{
					idc = -1;
					font = "RobotoCondensedLight";
					text = "Mirror";
					x = SettingGroupSize_X*0.815+PylonHeight;
					y = SettingGroupSize_Y*0.086;
					w = PylonWidth;
					h = PylonHeight;
				};
			};
		};

		class GarageOptionGroup: RscControlsGroupNoScrollbars
		{
			idc = IDC_GARAGEDISPLAY_OPTION_GROUP;
			x = 0;
			y = 0;
			w = SettingGroupSize_X;
			h = SettingGroupSize_Y;
			class controls: controls
			{
				class GarageOptionText: RscText
				{
					idc = -1;
					font = "RobotoCondensedLight";
					text = "Option settings";
					x = 0;
					y = 0;
					w = SettingGroupSize_X;
					h = SettingGroupSize_Y * 0.07;
				};

				class GarageOptionToggle: RscButton
				{
					idc = IDC_GARAGEDISPLAY_OPTION_TOGGLE;
					font = "RobotoCondensedLight";
					text = "Pylons";
					tooltip = "Change display";
					x = SettingGroupSize_X*0.815;
					y = 0;
					w = SettingGroupSize_X*0.185;
					h = GUI_GRID_H;
					onButtonClick = "_this call sel_toggle_setting";
				};

				class GarageDamageText: RscText
				{
					idc = -1;
					font = "RobotoCondensedLight";
					text = "Damage";
					style = ST_CENTER;
					sizeEx = PylonHeight*1.5;
					x = 0;
					y = SettingGroupSize_Y*0.086;
					w = SettingGroupSize_X*0.5;
					h = PylonHeight*2;
				};

				class GarageDamageListBackground: RscPicture
				{
					idc = -1;
					colorBackground[] = {0,0,0,0.3};
					text = "#(argb,8,8,3)color(0,0,0,0.3)";
					x = SettingGroupSize_X*0.03;
					y = SettingGroupSize_Y*0.23;
					w = SettingGroupSize_X*0.44;
					h = SettingGroupSize_Y*0.57;
				};

				class GarageDamageListArrowLeft: RscButton
				{
					idc = IDC_GARAGEDISPLAY_DAMAGE_LISTARROW_LEFT;
					text = "-";
					x = -1;
					y = -1;
					w = PylonHeight;
					h = PylonHeight;
					onButtonClick = "_this call sel_damage_arrow;";
				};

				class GarageDamageListArrowRight: GarageDamageListArrowLeft
				{
					idc = IDC_GARAGEDISPLAY_DAMAGE_LISTARROW_RIGHT;
					text = "+";
					onButtonClick = "_this call sel_damage_arrow;";
				};

				class GarageDamageList: RscListNBox
				{
					idc = IDC_GARAGEDISPLAY_DAMAGE_LIST;
					font = "RobotoCondensedLight";
					idcLeft = 1881;
					idcRight = 1882;
					columns[] = {0.07, 0.63};
					drawSideArrows = 1;
					disableOverflow = 1;
					sizeEx = PylonHeight;
					x = SettingGroupSize_X*0.03;
					y = SettingGroupSize_Y*0.23;
					w = SettingGroupSize_X*0.44;
					h = SettingGroupSize_Y*0.57;
					colorBackground[] = {0,0,0,0.3};
					colorSelectBackground[] = {1,1,1,0.5};
					colorSelectBackground2[] = {1,1,1,0.5};
					colorSelect[] = {1,1,1,1};
					colorSelect2[] = {1,1,1,1};
				};

				class GarageDamageDelayText: RscText
				{
					idc = -1;
					font = "RobotoCondensedLight";
					text = "DelaySec. [min,max] :";
					style = ST_LEFT;
					sizeEx = PylonHeight;
					x = SettingGroupSize_X*0.029;
					y = SettingGroupSize_Y*0.82;
					w = SettingGroupSize_X*0.23;
					h = PylonHeight;
				};

				class GarageDamageDelayMin: RscEdit
				{
					idc = IDC_GARAGEDISPLAY_DAMAGE_DELAY_MIN;
					font = "RobotoCondensedLight";
					text = "0";
					autocomplete = "";
					linespacing = 1;
					maxChars = 4;
					style = ST_RIGHT + ST_FRAME;
					sizeEx = PylonHeight;
					x = SettingGroupSize_X*0.28;
					y = SettingGroupSize_Y*0.82;
					w = SettingGroupSize_X*0.08;
					h = PylonHeight;
					onKeyUp = "(_this select 0) call sel_damage_delay";
				};

				class GarageDamageDelayMax: RscEdit
				{
					idc = IDC_GARAGEDISPLAY_DAMAGE_DELAY_MAX;
					font = "RobotoCondensedLight";
					text = "0";
					autocomplete = "";
					linespacing = 1;
					maxChars = 4;
					style = ST_RIGHT + ST_FRAME;
					sizeEx = PylonHeight;
					x = SettingGroupSize_X*0.38;
					y = SettingGroupSize_Y*0.82;
					w = SettingGroupSize_X*0.08;
					h = PylonHeight;
					onKeyUp = "(_this select 0) call sel_damage_delay";
				};

				class GarageDamageReset: RscButton
				{
					idc = -1;
					font = "RobotoCondensedLight";
					text = "Reset All Damage";
					x = SettingGroupSize_X*0.125;
					y = SettingGroupSize_Y*0.9;
					w = SettingGroupSize_X*0.25;
					h = GUI_GRID_H;
					onButtonClick = "call sel_damage_reset;";
				};

				class GarageInsigniaText: RscText
				{
					idc = -1;
					font = "RobotoCondensedLight";
					text = "Insignia";
					style = ST_CENTER;
					sizeEx = PylonHeight*1.5;
					x = SettingGroupSize_X*0.5;
					y = SettingGroupSize_Y*0.086;
					w = SettingGroupSize_X*0.5;
					h = PylonHeight*2;
				};

				class GarageInsigniaPointText: RscText
				{
					idc = -1;
					font = "RobotoCondensedLight";
					text = "Point:";
					style = ST_CENTER;
					x = SettingGroupSize_X*0.52;
					y = SettingGroupSize_Y*0.21;
					w = SettingGroupSize_X*0.18;
					h = PylonHeight;
				};

				class GarageInsigniaTexText: RscText
				{
					idc = -1;
					font = "RobotoCondensedLight";
					text = "Tex:";
					style = ST_CENTER;
					x = SettingGroupSize_X*0.72;
					y = SettingGroupSize_Y*0.21;
					w = SettingGroupSize_X*0.25;
					h = PylonHeight;
				};

				class GarageInsigniaPoint: RscListBox
				{
					idc = IDC_GARAGEDISPLAY_INSIGNIA_POINT;
					font = "RobotoCondensedLight";
					x = SettingGroupSize_X*0.52;
					y = SettingGroupSize_Y*0.28;
					w = SettingGroupSize_X*0.18;
					h = SettingGroupSize_Y*0.58;
				};

				class GarageInsigniaTex: RscListBox
				{
					idc = IDC_GARAGEDISPLAY_INSIGNIA_TEX;
					font = "RobotoCondensedLight";
					x = SettingGroupSize_X*0.72;
					y = SettingGroupSize_Y*0.28;
					w = SettingGroupSize_X*0.25;
					h = SettingGroupSize_Y*0.58;
				};

				class GarageInsigniaReset: RscButton
				{
					idc = -1;
					font = "RobotoCondensedLight";
					text = "Reset All Insignia";
					x = SettingGroupSize_X*0.625;
					y = SettingGroupSize_Y*0.9;
					w = SettingGroupSize_X*0.25;
					h = GUI_GRID_H;
					onButtonClick = "call sel_insignia_reset;";
				};
			};
		};
	};
};

class GaragePylons: RscCombo
{
	idc = -1;
	colorBackground[] = {0,0,0,0.8};
	font = "RobotoCondensedLight";
	w = PylonWidth;
	h = PylonHeight;
};

class GaragePylonTurrets: ctrlButtonPictureKeepAspect
{
	idc = -1;
	colorBackground[] = {0,0,0,0.8};
	font = "RobotoCondensedLight";
	w = PylonHeight;
	h = PylonHeight;
};
