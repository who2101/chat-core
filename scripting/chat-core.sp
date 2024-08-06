#pragma semicolon 1
#pragma newdecls required

#include <chat-core>

char 
	Prefix[64],
	Prefix_CM[64],
	TextColor[64],
	TextColor_CM[64];

char 
	Tag[32][64],
	TagColor[32][64],
	TagColor_CM[32][64];

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_max)  {
	CreateNative("ChatCore_PrintToChat", Native_PrintToChat);
	CreateNative("ChatCore_PrintToChatAll", Native_PrintToChatAll);
	CreateNative("ChatCore_PrintToChatEx", Native_PrintToChatEx);
	CreateNative("ChatCore_PrintToChatAllEx", Native_PrintToChatAllEx);

	return APLRes_Success;
}

public void OnPluginStart() {
	LoadTags();
	LoadCfg();
	
	RegAdminCmd("cc_reload", CMD_RELOAD, ADMFLAG_GENERIC);
}

public Action CMD_RELOAD(int client, int args) {
	LoadTags();
	LoadCfg();
	
	return Plugin_Handled;
}

public int Native_PrintToChat(Handle hPlugin, int args) {
	int client = GetNativeCell(1);
	
	if(!client || !IsClientInGame(client))
		ThrowNativeError(0, "[ERROR] Native_PrintToChat: client is not found");
	
	char szMessage[1024], szFinalMsg[1024];
	GetNativeString(2, szMessage, sizeof(szMessage));

	FormatNativeString(0, 2, 3, 1024, _, szFinalMsg);
	SemiNative_PrintToChat(hPlugin, client, _, false, szFinalMsg);
	
	return 0;
}

public int Native_PrintToChatAll(Handle hPlugin, int args) {
	char szMessage[1024], szFinalMsg[1024];
	GetNativeString(1, szMessage, sizeof(szMessage));

	FormatNativeString(0, 1, 2, 1024, _, szFinalMsg);
	
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			SemiNative_PrintToChat(hPlugin, i, _, false, szFinalMsg);
			
	return 0;
}

public int Native_PrintToChatAllEx(Handle hPlugin, int args) {
	int author = GetNativeCell(1);
	
	if(!author || !IsClientInGame(author))
		ThrowNativeError(0, "[ERROR] Native_PrintToChatAllEx: author is not found");
	
	char szMessage[1024], szFinalMsg[1024];
	GetNativeString(2, szMessage, sizeof(szMessage));

	FormatNativeString(0, 3, 4, 1024, _, szFinalMsg);
	
	for(int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i))
			SemiNative_PrintToChat(hPlugin, i, author, true, szFinalMsg);
			
	return 0;
}

public int Native_PrintToChatEx(Handle hPlugin, int args) {
	int client = GetNativeCell(1);
	int author = GetNativeCell(2);

	if(!client || !IsClientInGame(client))
		ThrowNativeError(0, "[ERROR] Native_PrintToChatEx: client is not found");
		
	if(!author || !IsClientInGame(author))
		ThrowNativeError(0, "[ERROR] Native_PrintToChatEx: author is not found");


	char szMessage[1024], szFinalMsg[1024];
	GetNativeString(3, szMessage, sizeof(szMessage));

	FormatNativeString(0, 3, 4, 1024, _, szFinalMsg);

	SemiNative_PrintToChat(hPlugin, client, author, false, szFinalMsg);
	
	return 0;
}

void SemiNative_PrintToChat(Handle hPlugin, int client, int author = 0, bool Ex, const char[] message, any ...) {
	char szBuffer[1024];
	char szFinalMsg[1024], szFinalMsg_CM[1024];

	Format(szBuffer, sizeof(szBuffer), "%s", message);
	VFormat(szFinalMsg, sizeof(szFinalMsg), szBuffer, 6);
	
	if(client == 0) {
		PrintToServer("%s", szFinalMsg);
		
		return;
	}
	
	if(!client || !IsClientInGame(client))
		ThrowNativeError(0, "[ERROR] SemiNative_PrintToChat: client is not found");
    
	if(strlen(szFinalMsg) <= 0)
		ThrowError("[ERROR] Native_PrintToChat: message has zero symbols");
	
	SetGlobalTransTarget(client);
	
	char szPlugin[128];
	GetPluginFilename(hPlugin, szPlugin, sizeof(szPlugin));
	ReplaceString(szPlugin, sizeof(szPlugin), "/", "_");

	KeyValues kv = new KeyValues("Plugins");
	
	char buffer[128];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/chat_core/plugins.cfg");
	
	if(!kv.ImportFromFile(buffer))
		ThrowError("[ERROR] SemiNative_PrintToChat: config %s is not exists", buffer);

	kv.Rewind();

	MC_RemoveTags(szFinalMsg, 1024);
	MC_RemoveTags(szFinalMsg_CM, 1024);

	strcopy(szFinalMsg_CM, sizeof(szFinalMsg_CM), szFinalMsg);

	for(int i; i < 32; i++) if(Tag[i][0] != 0) {
		ReplaceString(szFinalMsg, sizeof(szFinalMsg), Tag[i], TagColor[i], false);
		ReplaceString(szFinalMsg_CM, sizeof(szFinalMsg_CM), Tag[i], TagColor_CM[i], false);
	}

	if(kv.JumpToKey(szPlugin)) {
		char szPrefix[2][64], szTextColor[2][32]; // OLD - 0 | CLIENTMOD - 1

		kv.GetString("old_prefix", szPrefix[0], sizeof(szPrefix[]));
		kv.GetString("old_textcolor", szTextColor[0], sizeof(szTextColor[]));
		kv.GetString("clientmod_prefix", szPrefix[1], sizeof(szPrefix[]));
		kv.GetString("clientmod_textcolor", szTextColor[1], sizeof(szTextColor[]));

		if(!Ex) {
			C_PrintToChat(client, "%s %s%s", szPrefix[0], szTextColor[0], szFinalMsg);
			CM_PrintBigSayText(client, "%s %s%s", szPrefix[1], szTextColor[1], szFinalMsg_CM);
		} else {
			C_PrintToChatEx(client, author, "%s %s%s", szPrefix[0], szTextColor[0], szFinalMsg);
			MC_PrintToChatEx(client, author, "%s %s%s", szPrefix[1], szTextColor[1], szFinalMsg_CM);
		}

		delete kv;
		return;
	}

	delete kv;

	if(!Ex) {
		C_PrintToChat(client, "%s %s%s", Prefix, TextColor, szFinalMsg);
		CM_PrintBigSayText(client, "%s %s%s", Prefix_CM, TextColor_CM, szFinalMsg_CM);
	} else {
		C_PrintToChatEx(client, author, "%s %s%s", Prefix, TextColor, szFinalMsg);
		MC_PrintToChatEx(client, author, "%s %s%s", Prefix_CM, TextColor_CM, szFinalMsg_CM);
	}
}

void LoadCfg() {
	KeyValues kv = new KeyValues("Settings");

	char buffer[128];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/chat_core/default.cfg");

	if(!kv.ImportFromFile(buffer)) SetFailState("[ERROR] LoadCfg: config %s is not exists", buffer);

	kv.Rewind();

	kv.GetString("old_prefix", Prefix, sizeof(Prefix));
	kv.GetString("clientmod_prefix", Prefix_CM, sizeof(Prefix_CM));
	kv.GetString("old_textcolor", TextColor, sizeof(TextColor));
	kv.GetString("clientmod_textcolor", TextColor_CM, sizeof(TextColor_CM));

	delete kv;
}

void LoadTags() {
	KeyValues kv = new KeyValues("Tags");

	char buffer[128];
	BuildPath(Path_SM, buffer, sizeof(buffer), "configs/chat_core/tags.cfg");

	if(!kv.ImportFromFile(buffer)) ThrowError("LoadTags: config %s is not exists", buffer);

	if(!kv.GotoFirstSubKey()) ThrowError("LoadTags: cant goto first subkey");

	kv.Rewind();

	int i;

	if(kv.GotoFirstSubKey()) {
		do {
			kv.GetSectionName(Tag[i], sizeof(Tag[]));
	
			kv.GetString("old_color", TagColor[i], sizeof(TagColor[]));
			kv.GetString("clientmod_color", TagColor_CM[i], sizeof(TagColor_CM[]));
			
			i++;
		} while (kv.GotoNextKey());
	}

	delete kv;
}