#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>
#include <sdktools_stringtables>
#include <vip_core>
#include <smartdm>

Database
	hDatabase;

ConVar
	cvEnable,
	cvDelayTime;

Handle
	hTimerSetSkin[MAXPLAYERS+1];

char
	sFile[512],
	sSection[512],
	g_sFeatureSkin[][] = {"Skin_List", "Skin_Menu"};

enum struct Settings
{
	char name_t[512];
	char name_ct[512];
	char model_t[512];
	char model_ct[512];
	bool enable_t;
	bool enable_ct;
	bool enable;

	void Reset()
	{
		this.name_t = "";
		this.name_ct = "";
		this.model_t = "";
		this.model_ct = "";
		this.enable_t = true;
		this.enable_ct = true;
		this.enable = true;
	}
}

Settings skin[MAXPLAYERS+1];

enum struct ModelsAll
{
	ArrayList id_t;
	ArrayList id_ct;
	ArrayList name_t;
	ArrayList name_ct;
	ArrayList model_t;
	ArrayList model_ct;

	void Ads()
	{
		this.id_t = new ArrayList(ByteCountToCells(512));
		this.id_ct = new ArrayList(ByteCountToCells(512));
		this.name_t = new ArrayList(ByteCountToCells(512));
		this.name_ct = new ArrayList(ByteCountToCells(512));
		this.model_t = new ArrayList(ByteCountToCells(512));
		this.model_ct = new ArrayList(ByteCountToCells(512));
	}

	void Reset()
	{
		this.id_t.Clear();
		this.id_ct.Clear();
		this.name_t.Clear();
		this.name_ct.Clear();
		this.model_t.Clear();
		this.model_ct.Clear();
	}

	void Destroy()
	{
		delete this.id_t;
		delete this.id_ct;
		delete this.name_t;
		delete this.name_ct;
		delete this.model_t;
		delete this.model_ct;
	}

	void ProcessModelArray(ArrayList array)
	{
		char sBuffer[512];
	
		for (int i = 0; i < array.Length; i++)
		{
			array.GetString(i, sBuffer, sizeof(sBuffer));
			if (sBuffer[0])
			{
				// LogToFile(sFile, "Кеш [%d] модели [%s]", sizeof(sBuffer), sBuffer);
				PrecacheModel(sBuffer);
				Downloader_AddFileToDownloadsTable(sBuffer);
			}
		}
	}

	void Download()
	{
		this.ProcessModelArray(this.model_t);
		this.ProcessModelArray(this.model_ct);
	}
}

ModelsAll listAll;

enum struct Models
{
	ArrayList id;
	ArrayList id_t;
	ArrayList id_ct;
	
	ArrayList name_t;
	ArrayList name_ct;
	
	ArrayList model_t;
	ArrayList model_ct;

	void Ads()
	{
		this.id = new ArrayList(ByteCountToCells(512));
		this.id_t = new ArrayList(ByteCountToCells(512));
		this.id_ct = new ArrayList(ByteCountToCells(512));
		this.name_t = new ArrayList(ByteCountToCells(512));
		this.name_ct = new ArrayList(ByteCountToCells(512));
		this.model_t = new ArrayList(ByteCountToCells(512));
		this.model_ct = new ArrayList(ByteCountToCells(512));
	}

	void Reset()
	{
		this.id.Clear();
		this.id_t.Clear();
		this.id_ct.Clear();
		this.name_t.Clear();
		this.name_ct.Clear();
		this.model_t.Clear();
		this.model_ct.Clear();
	}

	void Destroy()
	{
		delete this.id;
		delete this.id_t;
		delete this.id_ct;
		delete this.name_t;
		delete this.name_ct;
		delete this.model_t;
		delete this.model_ct;
	}
}

Models list[MAXPLAYERS+1];

#define path "data/vip/modules/skins.ini"

#include "skin/menu.sp"
#include "skin/db.sp"
#include "skin/key.sp"
#include "skin/function.sp"

public Plugin myinfo = 
{
	name = "[ViP Core] Player Skins",
	author = "Nek.'a 2x2 | ggwp.site",
	description = "Player Skins",
	version = "1.0.0 104",
	url = "https://ggwp.site/"
};

public void OnPluginStart()
{
	cvEnable = CreateConVar("sm_vip_skin_enable", "1", "Включить/Выключить плагин", _, true, _, true, 1.0);

	cvDelayTime = CreateConVar("sm_vip_skin_enable", "0.1", "Через сколько секунд будет установлена модель", _, true, _, true, 60.0);

	for(int i = 0; i <= MaxClients; i++)
	{
		list[i].Ads();
	}

	listAll.Ads();
	
	RegConsoleCmd("sm_skin", Cmd_Skin, "Вызов меню скинов");

	Custom_SQLite();

	BuildPath(Path_SM, sFile, sizeof(sFile), "logs/vip_skin.log");

	ProcessConfigFile(path);

	AutoExecConfig(true, "Skins", "vip");

	if(VIP_IsVIPLoaded()) VIP_OnVIPLoaded();
}

public void OnMapStart()
{
	listAll.Download();
}

public void OnPluginEnd()
{
	if(!CanTestFeatures() || GetFeatureStatus(FeatureType_Native, "VIP_UnregisterFeature") != FeatureStatus_Available)
	{
    	return;
	}
  
	if(VIP_IsValidFeature(g_sFeatureSkin[0]))
		VIP_UnregisterFeature(g_sFeatureSkin[0]);

	if(VIP_IsValidFeature(g_sFeatureSkin[1]))
		VIP_UnregisterFeature(g_sFeatureSkin[1]);
}

public void VIP_OnVIPLoaded()
{
	VIP_RegisterFeature(g_sFeatureSkin[0], STRING, _, OnToggleItem);
	VIP_RegisterFeature(g_sFeatureSkin[1], _, SELECTABLE, OnItemSelect, _, OnItemDraw);
}

public bool OnItemSelect(int client, const char[] sFeatureName)
{
	CreatMenu_Base(client);

	return false;
}

public int OnItemDraw(int iClient, const char[] sFeatureName, int iStyle)
{
	switch(VIP_GetClientFeatureStatus(iClient, g_sFeatureSkin[0]))
	{
		case ENABLED: return ITEMDRAW_DEFAULT;
		case DISABLED: return ITEMDRAW_DISABLED;
		case NO_ACCESS: return ITEMDRAW_RAWLINE;
	}

	return iStyle;
}

public Action OnToggleItem(int client, const char[] sFeatureName, VIP_ToggleState OldStatus, VIP_ToggleState &NewStatus)
{
	if(NewStatus == ENABLED)
	{
		skin[client].enable = true;
	}
	else
	{
		skin[client].enable = false;
	}

	return Plugin_Continue;
}

Action Cmd_Skin(int client, any args)
{
	if(!cvEnable.BoolValue || !client || IsFakeClient(client))
		return Plugin_Continue;

	if(!VIP_IsClientVIP(client) || !VIP_IsClientFeatureUse(client, g_sFeatureSkin[0]))
		return Plugin_Handled;

	CreatMenu_Base(client);

	return Plugin_Handled;
}

public void VIP_OnVIPClientAdded(int client, int admin)
{
	//LogToFile(sFile, "Игроком [%N] получен ViP | Статус функции [%d]", client, VIP_IsClientFeatureUse(client, g_sFeatureSkin[0]));

	QueryConnect(client);
}

public void OnClientPostAdminCheck(int client)
{
	if(!cvEnable.BoolValue || IsFakeClient(client))
		return;

	QueryConnect(client);
}

public void OnClientDisconnect(int client)
{
	delete hTimerSetSkin[client];
	SaveSettings(client);
}

public void VIP_OnPlayerSpawn(int client, int iTeam, bool bIsVIP)
{
	if(!bIsVIP)
		return;
	
	if(skin[client].enable)
	{
		hTimerSetSkin[client] = CreateTimer(cvDelayTime.FloatValue, Timer_SetSkin, GetClientUserId(client));
	}
}

Action Timer_SetSkin(Handle hTimer, int UserId)
{
	int client = GetClientOfUserId(UserId);

	hTimerSetSkin[client] = null;

	SetModel(client);

	return Plugin_Continue;
}