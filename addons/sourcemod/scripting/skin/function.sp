//Берём список доступных id моделей для данной группы
stock void FetchGroupModelIDs(int client)
{
	list[client].Reset();

	char text[512];
	VIP_GetClientFeatureString(client, g_sFeatureSkin[0], text, sizeof(text));
	//PrintToChatAll("Вывод: [%s]", text);

	char sBuffer[32][32];

	int count = ExplodeString(text, ";", sBuffer, sizeof(sBuffer[]), sizeof(sBuffer[]));

	for(int i = 0; i < count; i++) if(sBuffer[i][0])
	{
		TrimString(sBuffer[i]);
		list[client].id.PushString(sBuffer[i]);
		//PrintToChatAll("Фильтр: [%s]", sBuffer[i]);
	}
}

//	Фильтруем весь список доступных моделей группы польователя
//  На основании доступных id узнаём именя и пути моделей
//  И распределяем их на Т и КТ
stock void AssignModelsToTeams(int client)
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

				list[client].id_t.PushString(sBuffer[1]);
				list[client].name_t.PushString(sBuffer[2]);
				list[client].model_t.PushString(sBuffer[3]);
			}
		}

		//Получаем скины для КТ
		for(int j = 0; j < listAll.id_ct.Length; j++)
		{
			//Узнаем id для сравнения
			list[client].id.GetString(i, sBuffer[0], sizeof(sBuffer[]));
			//Узначем с чем сравнивать
			listAll.id_ct.GetString(j, sBuffer[1], sizeof(sBuffer[]));

			if(!strcmp(sBuffer[0], sBuffer[1]))
			{
				//Узнаем имя
				listAll.name_ct.GetString(j, sBuffer[2], sizeof(sBuffer[]));
				//Узнаем модель
				listAll.model_ct.GetString(j, sBuffer[3], sizeof(sBuffer[]));

				list[client].id_ct.PushString(sBuffer[1]);
				list[client].name_ct.PushString(sBuffer[2]);
				list[client].model_ct.PushString(sBuffer[3]);
			}
		}
	}
}

stock void setDefaultSkin(int client, bool team_t = false, bool team_ct = false)
{
	char sBuffer[512];

    if(!team_t && !team_ct)
    {
        //Активируем включения моделей для нового пользователя
        skin[client].Reset();
    }
    
	
    //Устанавливаем самую первую модель для пользователя 
	if(!team_t && list[client].name_t.Length)
	{
		list[client].name_t.GetString(0, sBuffer, sizeof(sBuffer));
		skin[client].name_t = sBuffer;
		list[client].model_t.GetString(0, sBuffer, sizeof(sBuffer));
		skin[client].model_t = sBuffer;

		//LogToFile(sFile, "Установлен по стандарту скин для Т [%s]", sBuffer);
	}	

	if(!team_ct && list[client].name_ct.Length)
	{
		list[client].name_ct.GetString(0, sBuffer, sizeof(sBuffer));
		skin[client].name_ct = sBuffer;
		list[client].model_ct.GetString(0, sBuffer, sizeof(sBuffer));
		skin[client].model_ct = sBuffer;

		//LogToFile(sFile, "Установлен по стандарту скин для КТ [%s]", sBuffer);
	}
}

//  Проверка корректности установленных скинов
//  На тот случай, если скины были удалены с сервера
stock void correctionSkin(int client)
{
    bool success[2];
    char buffer[256];
    for(int i = 0; i < list[client].model_t.Length; i++)
    {
        if(success[0])
            break;

        list[client].model_t.GetString(i, buffer, sizeof(buffer));
        if(!strcmp(skin[client].model_t, buffer, true))
        {
            success[0] = true;
        }
    }

    for(int i = 0; i < list[client].model_ct.Length; i++)
    {
        if(success[1])
            break;

        list[client].model_ct.GetString(i, buffer, sizeof(buffer));
        if(!strcmp(skin[client].model_ct, buffer, true))
        {
            success[1] = true;
        }
    }

    if(success[0] && success[1])
    {
        return;
    }
    else if(!success[0] || !success[1])
    {
        setDefaultSkin(client, success[0], success[1]);
    }
}

void dataUpdate(int client)
{
	//  Берём список доступных id моделей для данной группы
	FetchGroupModelIDs(client);

	//	Фильтруем весь список доступных моделей группы польователя
	//  На основании доступных id узнаём именя и пути моделей
	//  И распределяем их на Т и КТ
	AssignModelsToTeams(client);
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
		SetEntityModel(client, skin[client].model_t);
	}
	else if(skin[client].enable_ct && team == 3 && skin[client].model_ct[0])
	{
		/* LogToFile(sFile, "Установка игроку КТ [%N] скина [%s]", client, skin[client].model_ct);
		PrintToChatAll("Установка игроку [%N] скина [%s]", client, skin[client].model_ct); */
		SetEntityModel(client, skin[client].model_ct);
	}
}

bool IsValideClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}