// =database-names.lsl
// ring name database handler
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

list ringListNames = [];

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
  else if (command == "addRingNameIndex") // data = "index:key"
  {
    list tempList = llParseString2List(data, [":"], [""]);
    integer length = llGetListLength(ringListNames);
    integer index = llList2Integer(tempList, 0);
    while (index+1 > length)
    {
      ringListNames += ["EMPTY"];
      length += 1;
    }
    ringListNames = (ringListNames=[]) + llListReplaceList(ringListNames, llGetObjectDetails(llList2Key(tempList, 1), [OBJECT_DESC]), index, index);
  }
  else if (command == "deleteRingNameIndex") // data = index
  {
    if ((integer)data < llGetListLength(ringListNames))
    {
      ringListNames = (ringListNames=[]) + llDeleteSubList(ringListNames, (integer)data, (integer)data);
    }
  }
  else if (command == "syncRingNames") // data = key:key:key:key:...
  {
    integer i;
    list ringList = llParseString2List(data, [":"], [""]);
    integer length = llGetListLength(ringList);
    data = "";
    ringListNames = [];
    for (i=0; i < length; i+=1)
    {
      ringListNames += llGetObjectDetails(llList2Key(ringList, i), [OBJECT_DESC]);
    }
    ringList = [];
  }
  else if (command == "returnRingListNames") // data = ALL or data = index:index:index:index:...
  {
    if (data == "ALL")
    {
      sendMessage("ringListNames", llDumpList2String(ringListNames, ":"));
    }
    else if (data == "")
    {
      sendMessage("ringListNames", "");
    }
    else
    {
      list tempList = llParseString2List(data, [":"], [""]);
      integer i;
      integer len = llGetListLength(tempList);
      integer tempInt;
      data = "";
      for (i=0; i < len; i+=1)
      {
        tempInt = llList2Integer(tempList, i);
        tempList = (tempList = []) + llListReplaceList(tempList, llList2List(ringListNames, tempInt, tempInt), i, i);
      }
      sendMessage("ringListNames", llDumpList2String(tempList, ":"));
      tempList = [];
    }
  }
  else if (command == "getRingKey") // return the ring key for the given name
  {
    integer index = llListFindList(ringListNames, [ data ]);
    if (index == -1)
    {
      sendMessage("ringKey", (string)NULL_KEY);
    }
    else
    {
      sendMessage("returnRingKey", (string)index);
    }
  }
}
default
{
  state_entry()
  {
    // set the list of commands we respond to
    commandList = llGetScriptName() +
                  " addRingNameIndex" +
                  " deleteRingNameIndex" +
                  " syncRingNames" +
                  " returnRingListNames" +
                  " getRingKey";

    ringListNames = [];
  }
  
  timer()
  {
  }
  
  link_message(integer sender_num, integer num, string str, key id)
  {
    if (sender_num == llGetLinkNumber())
    {
        if (debug) llOwnerSay("DEBUG: =database.lsl: link_message(): str("+str+") id("+(string)id+")");

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
