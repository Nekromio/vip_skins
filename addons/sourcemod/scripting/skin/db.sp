void Custom_SQLite()
{
	KeyValues hKv = new KeyValues("");
	hKv.SetString("driver", "sqlite");
	hKv.SetString("host", "localhost");
	hKv.SetString("database", "vip_skins");
	hKv.SetString("user", "root");
	hKv.SetString("pass", "");
	
	char sError[255];
	hDatabase = SQL_ConnectCustom(hKv, sError, sizeof(sError), true);

	if(sError[0])
	{
		SetFailState("Ошибка подключения к локальной базе SQLite: %s", sError);
	}
	hKv.Close();

	First_ConnectionSQLite();
}

void First_ConnectionSQLite()
{
	SQL_LockDatabase(hDatabase);
	char sQuery[1024];
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS `vip_skins` (\
		`id` INTEGER PRIMARY KEY,\
		`steam_id` VARCHAR(32),\
		`skin_name_t` VARCHAR(512),\
		`skin_name_ct` VARCHAR(512),\
		`skin_model_t` VARCHAR(512),\
		`skin_model_ct` VARCHAR(512),\
		`skin_enable_t` INTEGER(1),\
		`skin_enable_ct` INTEGER(1),\
		`skin_enable_all` INTEGER(1))");

	hDatabase.Query(First_ConnectionSQLite_Callback, sQuery);

	SQL_UnlockDatabase(hDatabase);
	hDatabase.SetCharset("utf8");
}

public void First_ConnectionSQLite_Callback(Database hDb, DBResultSet results, const char[] sError, any iUserID)
{
	if (hDb == null || sError[0])
	{
		SetFailState("Ошибка подключения к базе: %s", sError);
		return;
	}
}

public void ConnectClient_Callback(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("ConnectClient_Callback: %s", sError);
		return;
	}
	
	int client = GetClientOfUserId(iUserID);
	if(client)
	{
		if(hResults.FetchRow())
		{
			char sResult[512], sValue[512];
			hResults.FetchString(0, sResult, sizeof(sResult));

			for(int i = 0; i < 6; i++)
			{
				hResults.FetchString(i, sResult, sizeof(sResult));
				Format(sValue, sizeof(sValue), sResult, sValue);
				switch(i)
				{
					case 0: skin[client].name_t = sValue;
					case 1: skin[client].name_ct = sValue;
					case 2: skin[client].model_t = sValue;
					case 3: skin[client].model_ct = sValue;
					case 4: skin[client].enable_t = view_as<bool>(StringToInt(sValue));
					case 5: skin[client].enable_ct = view_as<bool>(StringToInt(sValue));
					case 6: skin[client].enable = view_as<bool>(StringToInt(sValue));
				}
			}

			//Обновляем данные о моделях
			dataUpdate(client);

			//Проверяем актуальность установленных моделей
			correctionSkin(client);
		}
		else
		{
			//Обновляем данные о моделях
			dataUpdate(client);
			//Устанавливаем саму первую модель и активируем
			setDefaultSkin(client);

			char sQuery[512], sSteam[32];
			GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
			FormatEx(sQuery, sizeof(sQuery), "INSERT INTO `vip_skins` (`steam_id`, `skin_name_t`, `skin_name_ct`, `skin_model_t`, `skin_model_ct`, `skin_enable_t`, `skin_enable_ct`, `skin_enable_all`)\
			VALUES ( '%s', '%s', '%s', '%s', '%s', '%d', '%d', '%d');",
			sSteam, skin[client].name_t, skin[client].name_ct, skin[client].model_t, skin[client].model_ct,
			skin[client].enable_t, skin[client].enable_ct, skin[client].enable);

			hDatabase.Query(ClietnAddDB_Callback, sQuery, GetClientUserId(client));
		}
	}
}

public void ClietnAddDB_Callback(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("ClietnAddDB_Callback: %s", sError); //
		return; //
	}
}

void SaveSettings(int client)
{
	char sQuery[512], sSteam[32];
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));

	FormatEx(sQuery, sizeof(sQuery), "UPDATE `vip_skins` SET \
	`skin_name_t` = '%s', `skin_name_ct` = '%s', `skin_model_t` = '%s', `skin_model_ct` = '%s', `skin_enable_t` = '%d', `skin_enable_ct` = '%d', `skin_enable_all` = '%d'	WHERE `steam_id` = '%s';",
	skin[client].name_t, skin[client].name_ct, skin[client].model_t, skin[client].model_ct, skin[client].enable_t, skin[client].enable_ct, skin[client].enable, sSteam);
	hDatabase.Query(SaveSettings_Callback, sQuery);

	skin[client].Reset();
}

public void SaveSettings_Callback(Database hDatabaseLocal, DBResultSet hResults, const char[] sError, any iUserID)
{
	if(sError[0])
	{
		LogError("SaveSettings_Callback: %s", sError); //
		return; //
	}
}

void QueryConnect(int client)
{
	char sQuery[512], sSteam[32];
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam), true);
	FormatEx(sQuery, sizeof(sQuery), "SELECT `skin_name_t`, `skin_name_ct`, `skin_model_t`, `skin_model_ct`,\
	`skin_enable_t`, `skin_enable_ct` FROM `vip_skins` WHERE `steam_id` = '%s'", sSteam);
	hDatabase.Query(ConnectClient_Callback, sQuery, GetClientUserId(client));
}