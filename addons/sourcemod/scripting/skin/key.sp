void ProcessConfigFile(const char[] file)
{
    char sFileCFG[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, sFileCFG, sizeof(sFileCFG), file);

    if(!FileExists(sFileCFG))
    {
        LogError("Плагин не запущен! Не удалось найти файл %s", sFileCFG);
        SetFailState("Файл не был загружен %s", sFileCFG);
    }
    else if(!Key_Settings(sFileCFG))
    {
        LogError("[SM] Плагин не запущен! Не удалось выполнить синтаксический анализ %s", sFileCFG);
        SetFailState("Ошибка синтаксического анализа файла %s", sFileCFG);
    }
}

bool Key_Settings(const char[] file)
{
    SMCParser hParser = new SMCParser();
    char error[256];
    int line = 0, col = 0;

    listAll.Reset();
  
    hParser.OnEnterSection = Config_NewSection;
    hParser.OnLeaveSection = Config_EndSection;
    hParser.OnKeyValue = Config_KeyValue;
    hParser.OnEnd = Config_End;
    
    SMCError result = SMC_ParseFile(hParser, file, line, col);

    CloseHandle(hParser);

    if(result != SMCError_Okay)
    {
        SMC_GetErrorString(result, error, sizeof(error));
        LogError("%s on line %d, col %d of %s", error, line, col, file);
    }

    return (result == SMCError_Okay);
}

public SMCResult Config_NewSection(Handle parser, const char[] section, bool quotes)
{
    if(StrEqual(section, "List Models"))
    {
        return SMCParse_Continue;
    }
    Format(sSection, sizeof(sSection), section);

    return SMCParse_Continue;
}

public SMCResult Config_KeyValue(Handle parser, char[] key, char[] value, bool key_quotes, bool value_quotes)
{
    static char sName[512], sModel[512];

    if(StrEqual(key, "name", false))
    {
        Format(sName, sizeof(sName), value);
    }
    else if(StrEqual(key, "model", false))
    {
        Format(sModel, sizeof(sModel), value);
    }
    else if(StrEqual(key, "team", false))
    {
        if(StrEqual(value, "t", false))
        {
            listAll.id_t.PushString(sSection);
            listAll.name_t.PushString(sName);
            listAll.model_t.PushString(sModel);
        }
        else if(StrEqual(value, "ct", false))
        {
            listAll.id_ct.PushString(sSection);
            listAll.name_ct.PushString(sName);
            listAll.model_ct.PushString(sModel);
        }
    }

    return SMCParse_Continue;
}

public SMCResult Config_EndSection(Handle parser)
{
    return SMCParse_Continue;
}

public void Config_End(Handle parser, bool halted, bool failed)
{
    if(failed)
    {
        SetFailState("Plugin configuration error");
    }
}