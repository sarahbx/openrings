// =dialog.lsl
// UI dialog handler
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

integer linkChannel = -1; // this will be changed after init comms with icomm.lsl

string commandList;

integer dialog_channel;
integer dialog_handle;

integer curGroup;

list ringListNames;
list optionList;

key av = NULL_KEY;
key destination_key = NULL_KEY;

sendMessage(string command, string data)
{
  llMessageLinked(LINK_THIS, 0, command, (key)data);
}

processLinkedMessage(string command, string data)
{
  integer i;
  if (command == "LIST_COMMANDS")
  {
    sendMessage("COMMAND_LIST", commandList);
  }
  else if (command == "activateDialog")
  {
    optionList = llParseString2List(data, [":"], [""]);
    av = llList2Key(optionList, 0);
    optionList = (optionList = []) + llDeleteSubList(optionList, 0, 0);

    if (llListFindList(optionList, ["All Rings"]) != -1)
    {
      sendMessage("getRings", "All Rings");
    }
    else
    {
      sendMessage("getRings", "Own Rings");
    }
  }
  else if (command == "ringListNames")
  {
    ringListNames = llParseString2List(data, [":"], [""]);
    
    // use a random dialog channel to minimize interference with other objects (inluding other rings)
    dialog_channel = -1 * ((integer)llFrand(0xFFFFFF)+1);

    curGroup = 0;
    integer listLen = llGetListLength(ringListNames);

    if (debug) llOwnerSay("DEBUG: "+llGetScriptName()+": processLinkedMessage("+command+"): listLen: "+(string)listLen);
    if (debug) llOwnerSay("DEBUG: "+llGetScriptName()+": processLinkedMessage("+command+"): dialog_channel: "+(string)dialog_channel);
    if (debug) llOwnerSay("DEBUG: "+llGetScriptName()+": processLinkedMessage("+command+"): av: "+(string)av);

    if (listLen == 0)
    {
      llSay(0, "No rings found in region.");
      sendMessage("setState", "normal");
      initVariables();
    }
    else if (listLen > 11)
    {
      dialog_handle = llListen(dialog_channel, "", av, "");
      if (av == llGetOwner())
      {
        llDialog(av, "Choose your destination", ["OPTIONS"] + llList2List(ringListNames, (curGroup*10), ((curGroup+1)*10)-1) + [">>"], dialog_channel);
      }
      else
      {
        llDialog(av, "Choose your destination", ["ABORT"] + llList2List(ringListNames, (curGroup*10), ((curGroup+1)*10)-1) + [">>"], dialog_channel);
      }
    }
    else
    {
      dialog_handle = llListen(dialog_channel, "", av, "");
      if (av == llGetOwner())
      {
        llDialog(av, "Choose your destination", ["OPTIONS"] + ringListNames, dialog_channel);
      }
      else
      {
        llDialog(av, "Choose your destination", ["ABORT"] + ringListNames, dialog_channel);
      }
    }
  }
  else if (command == "ringKey")
  {
    destination_key = (key)data;
    if (destination_key == NULL_KEY)
    {
      llSay(0, "Unable to locate chosen ring. Please try again.");
      sendMessage("abortTransport", "");
      sendMessage("setState", "normal");
      initVariables();
    }
    else
    {
      dialog_handle = llListen(dialog_channel+1, "", av, "");
      llSetTimerEvent(120);
      llDialog(av, "Awaiting command.", [ "Transport", "<----->", "Abort" ], dialog_channel+1);
    }
  }
}

initVariables()
{
  dialog_channel = -1;
  dialog_handle = 0;
  curGroup = 0;

  ringListNames = [];
  optionList = [];

  av = NULL_KEY;
  destination_key = NULL_KEY;
}

default
{
  state_entry()
  {
    // set the list of commands we respond to
    commandList = llGetScriptName() +
                  " activateDialog" +
                  " ringListNames" +
                  " ringKey";

    initVariables();
  }

  link_message(integer sender_num, integer num, string str, key id)
  {
    if (sender_num == llGetLinkNumber())
    {
        if (debug) llOwnerSay("DEBUG: =dialog.lsl: link_message(): str("+str+") id("+(string)id+")");

        // broadcast message from icomm
        if (num == -1)
        {
          // icomm looking for check-ins
          if (str == "SEND_LINK_CHANNEL_REQUESTS")
          {
              sendMessage("LINK_CHANNEL_REQUEST", (key)llGetScriptName());
          }
          // we've been assigned a channel
          else if (str == llGetScriptName())
          {
              linkChannel = (integer)((string)id);
          }
          else if (str == "COMMUNICATIONS_ACTIVE")
          {
          }
          else if (str == "COMMAND_LIST_QUERY")
          {
            if (llListFindList(llParseString2List(commandList, [" "], []), [ (string)id ]) != -1)
            {
              llOwnerSay("Script for command '"+ (string)id + "' found. Re-initalizing comm link.");
              sendMessage("LINK_CHANNEL_REQUEST", llGetScriptName());
            }
          }
        }
        // direct message from icomm
        else if (num == linkChannel)
        {
          processLinkedMessage(str, (string)id);
        }
    }
  }
  
  listen(integer channel, string name, key id, string message)
  {
    // destination dialog
    if (id == av && channel == dialog_channel)
    {
      if (message == "ABORT")
      {
        sendMessage("abortTransport", "");
        sendMessage("setState", "normal");
        llListenRemove(dialog_handle);
        initVariables();
      }
      else if (message == "OPTIONS" && av == llGetOwner())
      {
        sendMessage("abortTransport", "");
        llListenRemove(dialog_handle);
        dialog_handle = llListen(dialog_channel+2, "", av, "");
        llDialog(av, "Options Menu", optionList, dialog_channel+2);
      }
      else if (message == ">>")
      {
        curGroup += 1;
        if (llGetListLength(ringListNames) > (curGroup+1)*10)
        {
          llDialog(av, "Choose your destination", ["<<"] + llList2List(ringListNames, (curGroup*10), ((curGroup+1)*10)-1) + [">>"], dialog_channel);
        }
        else
        {
          llDialog(av, "Choose your destination", ["<<"] + llList2List(ringListNames, (curGroup*10), -1), dialog_channel);
        }
      }
      else if (message == "<<")
      {
        curGroup -= 1;
        if (curGroup == 0)
        {
          if (av == llGetOwner())
          {
            llDialog(av, "Choose your destination", ["OPTIONS"] + llList2List(ringListNames, (curGroup*10), ((curGroup+1)*10)-1) + [">>"], dialog_channel);
          }
          else
          {
            llDialog(av, "Choose your destination", ["ABORT"] + llList2List(ringListNames, (curGroup*10), ((curGroup+1)*10)-1) + [">>"], dialog_channel);
          }
        }
        else
        {
          llDialog(av, "Choose your destination", ["<<"] + llList2List(ringListNames, (curGroup*10), ((curGroup+1)*10)-1) + [">>"], dialog_channel);
        }
      }
      else
      {
        llListenRemove(dialog_handle);
        ringListNames = [];
        sendMessage("getRingKey", message);
      }
    }
    // transport dialog
    else if (id == av && channel == dialog_channel+1)
    {
      if (message == "Transport")
      {
        llListenRemove(dialog_handle);
        sendMessage("transportDestination", (string)destination_key);
        initVariables();
      }
      else if (message == "Abort")
      {
        llListenRemove(dialog_handle);
        sendMessage("abortTransport", "");
        sendMessage("setState", "normal");
        initVariables();
      }
      else
      {
        llDialog(av, "Awaiting command.", [ "Transport", "<----->", "Abort" ], dialog_channel+1);
      }
    }
    // options dialog
    else if (id == av && channel == dialog_channel+2)
    {
      llListenRemove(dialog_handle);
      initVariables();
      if (message == "RESET")
      {
        sendMessage("resetSystem", "");
      }
      else if (message == "Texture")
      {
        sendMessage("setState", "texture");
      }
      else
      {
        sendMessage("dialogOptionChange", message);
      }
    }
  }
  
  timer()
  {
    llSetTimerEvent(0);
    sendMessage("abortTransport", "");
    sendMessage("setState", "normal");
    initVariables();
  }
  
  on_rez(integer param)
  {
    llResetScript();
  }
}
