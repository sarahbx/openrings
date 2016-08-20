// =icomm.lsl
// internal communications handler
//
//    Open Source 'Stargate' Ring Platform
//    Copyright 2008-2009 (C) CB Radek (Sarah Bennert)
//    http://xhub.com
//
//    This program is free software: you can redistribute it and/or modify
//    it under the terms of the GNU General Public License as published by
//    the Free Software Foundation, either version 3 of the License, or
//    (at your option) any later version.
//
//    This program is distributed in the hope that it will be useful,
//    but WITHOUT ANY WARRANTY; without even the implied warranty of
//    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//    GNU General Public License for more details.
//
//    You should have received a copy of the GNU General Public License
//    along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
////////////////////////////////////////////////////////////////////////////////////////////////
//
//    PLEASE READ THE README FILE
//
////////////////////////////////////////////////////////////////////////////////////////////////

integer debug = 0;

// list containing script names. the index of each script name will be the link channel they listen to.
list icommChannels = [];

// list containing commands and their associated script names.
list commandList = [];

// any script that needs to communicate internally needs to get an icomm channel to be addressed on.
linkChannelRequest(string scriptName)
{
  integer index = llListFindList(icommChannels, [ scriptName ]);
  if (index == -1)
  {
      icommChannels += [ scriptName ];
      index = llListFindList(icommChannels, [ scriptName ]);
      if (debug) llOwnerSay(scriptName + " comm link active.");
      llMessageLinked(LINK_THIS, -1, scriptName, (key)((string)index));
      llMessageLinked(LINK_THIS, index, "LIST_COMMANDS", "");
  }
  else
  {
      if (debug) llOwnerSay(scriptName + " comm link active.");
      llMessageLinked(LINK_THIS, -1, scriptName, (key)((string)index));
      llMessageLinked(LINK_THIS, index, "LIST_COMMANDS", "");
  }
}

// use this function to send messages to a specific script in this prim.
sendLinkedMessage(string command, string data)
{
  string destination = getScriptName(command);
  if (destination != "")
  {
    llMessageLinked(LINK_THIS, llListFindList(icommChannels, [ destination ]), command, (key)data);
  }
  else
  {
    llOwnerSay("ERROR: Unable to resolve '" + command + "' to a script. Querying scripts...");
    sendBroadcastMessage("COMMAND_LIST_QUERY", command);
  }
}

// use this function to send messages to all listening scripts in this prim.
sendBroadcastMessage(string command, string data)
{
  llMessageLinked(LINK_THIS, -1, command, (key)data);
}

integer processCommandList(string data)
{
  string tempString = "";
  list tempList = [];
  integer i;
  integer j;
  
  if (debug)  llOwnerSay("DEBUG:=icomm.lsl:processCommandList() " + data);
  
  tempString = llStringTrim(data, STRING_TRIM);
  if (tempString != "")
  {
    tempList = llParseString2List(tempString, [" "], []);
    if (llGetListLength(tempList) > 1)
    {
      i = llListFindList(commandList, llList2List(tempList, 0, 0));
      if (i != -1) // if the script already exists in the list, reset it's command list
      {
        for (j=i+1; i != -1 && j < llGetListLength(tempList); j+=1)
        {
          if (llSubStringIndex(llList2String(tempList, j), "=") == 0)
          {
            commandList = (commandList=[]) + llListReplaceList(commandList, tempList, i, j-1);
            i = -1;
          }
        }
        if (i != -1)
        {
            commandList = (commandList=[]) + llListReplaceList(commandList, tempList, i, -1);
        }
      }
      else
      {
        for (i=0; i < llGetListLength(tempList); i++)
        {
          if (llListFindList(commandList, llList2List(tempList, i, i)) != -1)
          {
            llOwnerSay("ERROR: " + llList2String(tempList, i) + " already defined in command list");
            return -1; // reset script
          }
        }
        commandList += tempList;
      }
    }
    else
    {
      llOwnerSay("ERROR: " + tempString + " did not provide any commands");
          return -1; // reset script
    }
  }
  else
  {
    llOwnerSay("ERROR: processCommandList() passed empty string");
          return -1; // reset script
  }
  return 0; // continue normally
}

string getScriptName(string command)
{
  integer i;
  integer index = llListFindList(commandList, [ command ]);
  string subString = "";

  for (i=(index-1); i >= 0; i--)
  {
    subString = llList2String(commandList, i);
    if (llSubStringIndex(subString, "=") == 0)
    {
      return subString;
    }
  }
  return "";
}

default
{
  state_entry()
  {
    float dilation = llGetRegionTimeDilation();
    while (dilation <= 0.65)
    {
      llSleep(2);
      dilation = llGetRegionTimeDilation();
    }
    icommChannels = [ llGetScriptName() ]; // icomm script will always be 0.
    llSay(0, "Initializing Internal Communications...");
    llSleep((float)2/dilation); // allow other scripts to activate. they will wait for the broadcast message before requesting a channel
    sendBroadcastMessage("SEND_LINK_CHANNEL_REQUESTS", "");
    
    // Give scripts time to check in
    llSetTimerEvent((float)4/dilation);
  }

  link_message(integer sender_num, integer num, string command, key data)
  {
    if (sender_num == llGetLinkNumber())
    {
      if (debug) llOwnerSay("DEBUG:icomm.lsl:link_message() " + command + "!" + (string)data);
      
        string tempName;
        if (num == 0)
        {
          if (command == "LINK_CHANNEL_REQUEST") // a script is requesting a link channel
          {
              linkChannelRequest((string)data);
          }
          else if (command == "COMMAND_LIST") // a script is giving us thier command list
          {
            // if there is an error processing a command list, we will reset the system.
            if (processCommandList((string)data) == -1)
            {
              state reset;
            }
          }
          else if (command == "curState") // main changed state, broadcast state
          {
            sendBroadcastMessage(command, (string)data);
          }
          else if (command == "resetSystem")
          {
            state reset;
          }
          else // send linked message to correct script
          {
            sendLinkedMessage(command, (string)data);
          }
        }
    }
  }

  on_rez(integer start_param)
  {
      state reset;
  }

  timer()
  {
    llSetTimerEvent(0);
    
    // once all the scripts have checked in, send broadcast message to let them know.
    // main will then tell us its state and option list and we can begin normal operations
    sendBroadcastMessage("COMMUNICATIONS_ACTIVE", "");
    llSay(0, "Internal Communications Active.");
  }
}

// If something goes ary, we'll can set state reset.
// Reset all other scripts and go back to original state.
state reset
{
  state_entry()
  {
    string tempName;
    integer i;
    integer length = llGetInventoryNumber(INVENTORY_SCRIPT);

    llSay(0, "Resetting Internal Communications...");
    icommChannels = [];
    commandList = [];

    for (i=1; i < length; i++)
    {
      tempName = llGetInventoryName(INVENTORY_SCRIPT, i);
      if (tempName != llGetScriptName() &&
          tempName != "=transportPrim.lsl" &&
          tempName != "=update.lsl" &&
          tempName != "=texture.lsl" &&
          tempName != "=zht_OnRezUpdateCheck.lsl" &&
          tempName != "=zht_TimedUpdateCheck.lsl")
      {
        llResetOtherScript(tempName);
      }
    }

    state default;
  }
}
