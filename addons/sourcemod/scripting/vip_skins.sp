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
	sSection[512];

static const char g_sFeatureSkin[][] = {"Skin_List", "Skin_Menu"};

enum
{
	team_t,
	team_ct
}

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
		this.enable_t = false;
		this.enable_ct = false;
		this.enable = false;
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

public Plugin myinfo = 
{
	name = "[ViP Core] Player Skins",
	author = "Nek.'a 2x2 | ggwp.site",
	description = "Player Skins",
	version = "1.0.0 102",
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
		return Plugin_Continue;

	//Проверку на випа
	CreatMenu_Base(client);

	DefaultSkin(client);

	return Plugin_Handled;
}

public void OnClientPostAdminCheck(int client)
{
	if(!cvEnable.BoolValue || !IsFakeClient(client))
	{
		if(!VIP_IsClientVIP(client) || !VIP_IsClientFeatureUse(client, g_sFeatureSkin[0]))
			return;

		char sQuery[512], sSteam[32];
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam), true);
		FormatEx(sQuery, sizeof(sQuery), "SELECT `skin_name_t`, `skin_name_ct`, `skin_model_t`, `skin_model_ct`,\
		`skin_enable_t`, `skin_enable_ct` FROM `vip_skin` WHERE `steam_id` = '%s'", sSteam);
		hDatabase.Query(ConnectClient_Callback, sQuery, GetClientUserId(client));
	}
}

public void OnClientDisconnect(int client)
{
	delete hTimerSetSkin[client];
	SaveSettings(client);
	ResetClientSettings(client);
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

stock void ResetClientSettings(int client)
{
	list[client].Reset();
}

//Наполняем список моделей данной группы пользователя
stock void GetListModels(int client)
{
	ResetClientSettings(client);

	char text[512];
	VIP_GetClientFeatureString(client, g_sFeatureSkin[0], text, sizeof(text));
	//PrintToChatAll("Вывод: [%s]", text);

	char sBuffer[32][32];

	int count = ExplodeString(text, ";", sBuffer, sizeof(sBuffer[]), sizeof(sBuffer[]));

	for(int i = 0; i < count; i++) if(sBuffer[i][0])
	{
		TrimString(sBuffer[i]);
		list[client].id.PushString(sBuffer[i]);
		PrintToChatAll("Фильтр: [%s]", sBuffer[i]);
	}

	getGroupSkin(client);
}

//	Фильтруем весь список доступных моделей группы польователя
//	На доступ т и кт
stock void getGroupSkin(int client)
{
	char sBuffer[4][512];
	for(int i = 0; i < list[client].id.Length; i++)
	{
		//Получаем скины для Т
		for(int j = 0; j < listAll.id_t.Length; j++)
		{
			//Узнаем id для сравнения
			list[client].id.GetString(i, sBuffer[0], sizeof(sBuffer[]));

			//Узначем id с каким сравнивать
			listAll.id_t.GetString(j, sBuffer[1], sizeof(sBuffer[]));

			if(!strcmp(sBuffer[0], sBuffer[1]))
			{
				//Узнаем имя
				listAll.name_t.GetString(j, sBuffer[2], sizeof(sBuffer[]));

				//Узнаем модель
				listAll.model_t.GetString(j, sBuffer[3], sizeof(sBuffer[]));
				
				//PrintToChatAll("Сравнение |Т| найдено [%s] -> [%s]", sBuffer[0], sBuffer[1]);
				//PrintToChatAll("А именно: \nИмя [%s] \nПуть [%s]", sBuffer[2], sBuffer[3]);

				list[client].id_t.PushString(sBuffer[1]);
				list[client].name_t.PushString(sBuffer[2]);
				list[client].model_t.PushString(sBuffer[3]);
			}

			//Узначем с чем сравнивать
			listAll.id_ct.GetString(j, sBuffer[1], sizeof(sBuffer[]));

			if(!strcmp(sBuffer[0], sBuffer[1]))
			{
				//Узнаем имя
				listAll.name_ct.GetString(j, sBuffer[2], sizeof(sBuffer[]));

				//Узнаем модель
				listAll.model_ct.GetString(j, sBuffer[3], sizeof(sBuffer[]));
				
				//PrintToChatAll("Сравнение |Т| найдено [%s] -> [%s]", sBuffer[0], sBuffer[1]);
				//PrintToChatAll("А именно: \nИмя [%s] \nПуть [%s]", sBuffer[2], sBuffer[3]);

				list[client].id_ct.PushString(sBuffer[1]);
				list[client].name_ct.PushString(sBuffer[2]);
				list[client].model_ct.PushString(sBuffer[3]);
			}
		}
	}
}

stock void SetModel(int client)
{
	if(!client || IsFakeClient(client))
		return;

	int team = GetClientTeam(client);

	if(skin[client].enable_t && team == 2 && skin[client].model_t[0])
	{
		/* LogToFile(sFile, "Установка игроку Т [%N] скина [%s]", client, skin[client].model_t);
		PrintToChatAll("Установка игроку [%N] скина [%s]", client, skin[client].model_t); */
		if(IsModelPrecached(skin[client].model_t))
		{
			SetEntityModel(client, skin[client].model_t);
		}
		/* else
		{
			PrecacheModel(skin[client].model_t);
			SetEntityModel(client, skin[client].model_t);
		} */
		
	}
	else if(skin[client].enable_ct && team == 3 && skin[client].model_ct[0])
	{
		/* LogToFile(sFile, "Установка игроку КТ [%N] скина [%s]", client, skin[client].model_ct);
		PrintToChatAll("Установка игроку [%N] скина [%s]", client, skin[client].model_ct); */
		if(IsModelPrecached(skin[client].model_ct))
		{
			SetEntityModel(client, skin[client].model_ct);
		}
		/* else
		{
			PrecacheModel(skin[client].model_ct);
			SetEntityModel(client, skin[client].model_ct);
		} */
	}
}

bool IsValideClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}