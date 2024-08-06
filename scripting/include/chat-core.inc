#if defined _chat_core_included
  #endinput
#endif
#define _chat_core_included

#include <clientmod>
#include <clientmod/multicolors>

native void ChatCore_PrintToChat(int client, const char[] message, any ...);
native void ChatCore_PrintToChatAll(const char[] message, any ...);
native void ChatCore_PrintToChatEx(int client, int author, const char[] message, any ...);
native void ChatCore_PrintToChatAllEx(int author, const char[] message, any ...);