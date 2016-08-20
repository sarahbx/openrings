// =database-keys.lsl
// ring key database handler
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

list ringList = [];

string commandList;

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
  else if (command == "addRing") // data = key
  {
    if (llListFindList(ringList, [ data ]) == -1)
    {
        ringList += [ data ];
        sendMessage("addRingNameIndex", (string)(llGetListLength(ringList)-1)+":"+data);
    }
  }
  else if (command == "getRings" && data == "All Rings")
  {
    sendMessage("returnRingListNames", "ALL");
  }
  else if (command == "getRings" && data == "Own Rings")
  {
    string tempString = "";
    integer length = llGetListLength(ringList);
    key owner = llGetOwner();

    for (i=0; i < length; i+=1)
    {
      if (llGetOwnerKey(llList2Key(ringList, i)) == owner)
      {
        tempString += ":"+(string)i;
      }
    }
    sendMessage("returnRingListNames", tempString);
    tempString = "";
  }
  else if (command == "sendUpdaterRingList")
  {
    list tempList = [ (string)llGetKey() ];
    integer length = llGetListLength(ringList);
    key owner = llGetOwner();

    if (debug) llOwnerSay("List Length: " + (string)length);
    for (i=0; i < length; i+=1)
    {
      if (llGetOwnerKey(llList2Key(ringList, i)) == owner)
      {
        if (debug) llOwnerSay("Selecting ring to be sent to updater: (" + (string)i + ") " + llList2String(ringList, i));
        tempList += [ llList2String(ringList, i) ];
      }
    }
    sendMessage("updaterRingList", data + "<" + llDumpList2String(tempList, ":"));
  }
  else if (command == "returnRingKey") // data = index
  {
    if ((integer)data >= 0 && (integer)data < llGetListLength(ringList))
    {
      sendMessage("ringKey", llList2String(ringList, (integer)data));
    }
    else
    {
      sendMessage("ringKey", (string)NULL_KEY);
      cleanList();
      sendMessage("syncRingNames", llDumpList2String(ringList, ":"));
    }
  }
}

cleanList()
{
  integer i;
  integer length = llGetListLength(ringList);
  key tempKey;
  
  for (i=0; i < length; i+=1)
  {
    tempKey = llList2Key(ringList, i);
    if (llGetOwnerKey(tempKey) == tempKey)
    {
      ringList = (ringList=[]) + llDeleteSubList(ringList, i, i);
      sendMessage("deleteRingNameIndex", (string)i);
      i -= 1;
      length -= 1;
    }
  }
}

default
{
  state_entry()
  {
    // set the list of commands we respond to
    commandList = llGetScriptName() + 
                  " addRing" +
                  " getRings" +
                  " getRingDialogList_Owner_All" +
                  " getRingDialogList_Owner_Own" +
                  " getRingDialogList_User_All" +
                  " getRingDialogList_User_Own" +
                  " sendUpdaterRingList" +
                  " returnRingKey";

    ringList = [];
    llSetTimerEvent(60);
  }
  
  timer()
  {
    cleanList();
    sendMessage("syncRingNames", llDumpList2String(ringList, ":"));
  }
  
  link_message(integer sender_num, integer num, string str, key id)
  {
    if (sender_num == llGetLinkNumber())
    {
        if (debug) llOwnerSay("DEBUG: =database-keys.lsl: link_message(): str("+str+") id("+(string)id+")");

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
  
  on_rez(integer param)
  {
    llResetScript();
  }
}
