void CreatMenu_Base(int client)
{

	if(!IsValideClient(client))
		return;
		
	//SkinStatus(client);
	
	dataUpdate(client);

	Menu hMenu = new Menu(Menu_Base);

	hMenu.SetTitle("Меню Скинов");

	char sItem[512];
	
	FormatEx(sItem, sizeof(sItem), "Модель за Т [%s]", skin[client].enable_t == true ? "√" : "×");
	hMenu.AddItem("item1", sItem);

	FormatEx(sItem, sizeof(sItem), "Выбрать скин за Т ? [%s]", skin[client].name_t[0] ? skin[client].name_t : "×");
	hMenu.AddItem("item2", sItem);

	FormatEx(sItem, sizeof(sItem), "Модель за CТ [%s]", skin[client].enable_ct == true ? "√" : "×");
	hMenu.AddItem("item3", sItem);

	FormatEx(sItem, sizeof(sItem), "Выбрать скин за КТ ? [%s]", skin[client].name_ct[0] ? skin[client].name_ct : "×");
	hMenu.AddItem("item4", sItem);

	hMenu.AddItem("item5", "Назад");
	//hMenu.ExitBackButton = true;

	DisplayMenu(hMenu, client, 50);
}

public int Menu_Base(Menu hMenu, MenuAction action, int client, int iItem)
{
    switch(action)
    {
		case MenuAction_End:
        {
            delete hMenu;
        }
		case MenuAction_Select:
        {
			if(!IsValideClient(client))
				return 0;

            switch(iItem)
    		{
				case 0:
				{
					if(skin[client].enable_t)
					{
						skin[client].enable_t = false;
					}
					else
					{
						skin[client].enable_t = true;
					}
					CreatMenu_Base(client);
				}
				case 1:
				{
					CreatMenu_ShowSkin_T(client);
				}
				case 2:
				{
					if(skin[client].enable_ct)
					{
						skin[client].enable_ct = false;
					}
					else
					{
						skin[client].enable_ct = true;
					}
					CreatMenu_Base(client);
				}
				case 3:
				{
					CreatMenu_ShowSkin_CT(client);
				}
				case 4:
				{
					ClientCommand(client, "vip");
				}
			}
        }
	}
	return 0;
}

void CreatMenu_ShowSkin_T(int client)
{
	if(!list[client].name_t.Length)
	{
		PrintToChat(client, "Список скинов Т пуст!");
		CreatMenu_Base(client);
		return;
	}	

	Menu hMenu = new Menu(Menu_Select_T);
	hMenu.SetTitle("Выбрать скин за T");

	char sBuffer[512];

	for(int i = 0; i < list[client].name_t.Length; i++)
	{
		list[client].name_t.GetString(i, sBuffer, sizeof(sBuffer));
		hMenu.AddItem("item1", sBuffer);
	}

	hMenu.ExitBackButton = true;

	hMenu.Display(client, 20);
}

public int Menu_Select_T(Menu hMenu, MenuAction action, int client, int iItem)
{
    switch(action)
    {
		case MenuAction_End:
        {
            delete hMenu;
        }
		case MenuAction_Select:
        {
			char sBuffer[512];

			list[client].name_t.GetString(iItem, sBuffer, sizeof(sBuffer));
			skin[client].name_t = sBuffer;

			list[client].model_t.GetString(iItem, sBuffer, sizeof(sBuffer));
			skin[client].model_t = sBuffer;

			SetModel(client);

			CreatMenu_Base(client);
        }
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
            	CreatMenu_Base(client);
        	}
   		}
	}
	return 0;
}

void CreatMenu_ShowSkin_CT(int client)
{
	if(!list[client].name_ct.Length)
	{
		PrintToChat(client, "Список скинов CТ пуст!");
		CreatMenu_Base(client);
		return;
	}

	Menu hMenu = new Menu(Menu_Select_CT);
	hMenu.SetTitle("Выбрать скин за CT");

	char sBuffer[512];
	for(int i = 0; i < list[client].name_ct.Length; i++)
	{
		list[client].name_ct.GetString(i, sBuffer, sizeof(sBuffer));
		hMenu.AddItem("item1", sBuffer);
	}

	hMenu.ExitBackButton = true;

	hMenu.Display(client, 20);
}

public int Menu_Select_CT(Menu hMenu, MenuAction action, int client, int iItem)
{
    switch(action)
    {
		case MenuAction_End:
        {
            delete hMenu;
        }
		case MenuAction_Select:
        {
			char sBuffer[512];

			list[client].name_ct.GetString(iItem, sBuffer, sizeof(sBuffer));
			skin[client].name_ct = sBuffer;

			list[client].model_ct.GetString(iItem, sBuffer, sizeof(sBuffer));
			skin[client].model_ct = sBuffer;

			SetModel(client);

			CreatMenu_Base(client);
        }
		case MenuAction_Cancel:
		{
			if(iItem == MenuCancel_ExitBack)
			{
            	CreatMenu_Base(client);
        	}
   		}
	}
	return 0;
}