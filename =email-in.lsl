// =email-in.lsl
// ring-to-ring email inbox handler
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
integer ringPing = 0;

integer linkChannel = -1; // this will be changed after init comms with icomm.lsl

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
}

default
{
  state_entry()
  {
    // set the list of commands we respond to
    commandList = llGetScriptName() + 
                  " noCommands";

    ringPing = 0;
  }
  
  timer()
  {
    llSetTimerEvent(0);
    if (ringPing)
    {
      ringPing = 0;
      sendMessage("ringEmailPing", "");
      llSetTimerEvent(5);
    }
    else
    {
      llSetTimerEvent(600);
      llGetNextEmail("", "ringEmailPong");
    }
  }

  email(string time, string address, string subj, string message, integer num_left)
  {
    llSetTimerEvent(0);
    if (debug) llOwnerSay("DEBUG (=email-in.lsl): " + time + ":" + address + ":" + subj + ":" + message);
    address = llGetSubString(address, 0, llSubStringIndex(address, "@")-1);
    sendMessage("addRing", address);
    if (num_left)
    {
      llGetNextEmail("", "ringEmailPong");
    }
    else
    {
      ringPing = 1;
      llSetTimerEvent(600);
    }
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
              sendMessage("LINK_CHANNEL_REQUEST", (key)llGetScriptName());
          }
          // we've been assigned a channel
          else if (str == llGetScriptName())
          {
              linkChannel = (integer)((string)id);
          }
          else if (str == "COMMUNICATIONS_ACTIVE")
          {
            ringPing = 1;
            llSetTimerEvent(1);
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
