// =email-out.lsl
// ring-to-ring email outbox handler
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

integer linkChannel = -1; // this will be changed after init comms with icomm.lsl
string commandList;

sendMessage(string command, string data)
{
  llMessageLinked(LINK_THIS, 0, command, (key)data);
}

processLinkedMessage(string command, string data)
{
  if (command == "LIST_COMMANDS")
  {
    sendMessage("COMMAND_LIST", commandList);
  }
  else if (command == "ringEmailPong")
  {
    llEmail(data + "@lsl.secondlife.com", "ringEmailPong", "");
  }
  else if (command == "updaterRingList")
  {
    string messageTO = llGetSubString(data, 0, llSubStringIndex(data, "<")-1);
    data = llDeleteSubString(data, 0, llSubStringIndex(data, "<"));
    llEmail(messageTO + "@lsl.secondlife.com", "updaterRingList", data);
  }
}

default
{
  state_entry()
  {
    // set the list of commands we respond to
    commandList = llGetScriptName() + 
                  " ringEmailPong" +
                  " updaterRingList";

  }

  link_message(integer sender_num, integer num, string str, key id)
  {
    if (sender_num == llGetLinkNumber())
    {
        // broadcast message from icomm
        if (num == -1)
        {
          // icomm looking for check-ins
          if (str == "SEND_LINK_CHANNEL_REQUESTS")
          {
              sendMessage("LINK_CHANNEL_REQUEST", llGetScriptName());
          }
          // we've been assigned a channel
          else if (str == llGetScriptName())
          {
              linkChannel = (integer)((string)id);
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
