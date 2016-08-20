// =ecomm.lsl
// external ring-base communications handler
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

integer debug = 0; // change this value to '1' to receive debugging messages
integer linkChannel = -1; // this will be changed after init comms with icomm.lsl
integer listenChannel = -3141592;
integer listen_handle = 0;

string commandList;
string messageTO;
string messageFROM;
string messageCOMMAND;

string currentState;

list message_list = [];
list optionList = [];

key ringBase;
key remoteUserKey = NULL_KEY;

sendMessage(string command, string data)
{
  llMessageLinked(LINK_THIS, 0, command, (key)data);
}

ProcessMessage(string name, key id, string message)
{
    if (debug) llOwnerSay("DEBUG:ecomm.lsl: " + message);

    message_list = llParseString2List(message, [":"], [""]);
        
    messageTO = llList2String(message_list, 0);
    messageFROM = llList2String(message_list, 1);
    messageCOMMAND = llList2String(message_list, 2);
    
    if (messageTO == "*")
    {
        if (messageCOMMAND == "ringPing")
        // someone's looking for a ring platform to go to. Let them know we're here.
        {
            llRegionSay(listenChannel, 
                messageFROM + ":" +         // TO UUID
                (string)ringBase + ":" +    // FROM UUID
                "ringPong" + ":" +          // COMMAND
                (string)llGetPos());        // DATA: our position -- ignored by any v0.51 ring or above. now use llGetObjectDetatils(key) for position info.
        }
        else if (messageCOMMAND == "ringEmailPing")
        {
            sendMessage("ringEmailPong", messageFROM);
        }
        else if (messageCOMMAND == "updaterRingList" && llGetOwnerKey((key)messageFROM) == llGetOwner())
        {
            sendMessage("sendUpdaterRingList", messageFROM);
        }
        else if (messageCOMMAND == "remoteActivate")
        {
            remoteUserKey = llGetOwnerKey((key)messageFROM);
            if (remoteUserKey != NULL_KEY)
            {
              // search for user for 10 meters in all directions.
              llSensor("", remoteUserKey, 1, 10.0, PI);
            }
        }
    }
    else if (messageTO == (string)llGetLinkKey(llGetLinkNumber()))
    // only talk to those who know our UUID
    {
        if (messageCOMMAND == "ringPong")
        // response from another OpenRings platform
        {
            sendMessage("addRing", messageFROM);
        }
        else if (messageCOMMAND == "emitParticles")
        // Transport Prim is about to warpPos(), make it look good
        {
            sendMessage("makeParticles", "");
        }
        else if (currentState == "transport" &&
                 messageCOMMAND == "rezRings")
        {
            llSay(0, "Transporting...");
            sendMessage("rezRings", "");
        }
        else if (messageCOMMAND == "transportPrimDead")
        // transport done, reset script
        {
            sendMessage("deRezRings", "");
            
            // 7/22/08 ring needs to go back to 'normal' otherwise it waits for the timeout.
            sendMessage("setState", "normal");
        }
        else if (messageCOMMAND == "incomingTransport")
        {
            sendMessage("setState", "incoming");
        }
    }
}

processLinkedMessage(string command, string data)
{
  if (command == "LIST_COMMANDS")
  {
    sendMessage("COMMAND_LIST", commandList);
  }
  else if (command == "ringPing")
  {
    // Broadcast call to any OpenRings platform
    llRegionSay(listenChannel, 
        "*" + ":" +                 // Broadcast message
        (string)ringBase + ":" +    // our UUID key
        "ringPing");                // command
  }
  else if (command == "ringEmailPing")
  {
    // Broadcast call to any OpenRings platform
    llRegionSay(listenChannel, 
        "*" + ":" +                 // Broadcast message
        (string)ringBase + ":" +    // our UUID key
        "ringEmailPing");                // command
  }
  else if (command == "setOptions")
  {
      optionList = llParseString2List(data, [":"], []);
  }
}

default
{
  state_entry()
  {
    // set the list of commands we respond to
    commandList = llGetScriptName() + 
                  " ringPing" +
                  " ringEmailPing" +
                  " setOptions";

    ringBase = llGetLinkKey(llGetLinkNumber());
    remoteUserKey = NULL_KEY;
    listen_handle = llListen(listenChannel, "", "", "");
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
        // mains' current state was broadcasted
        else if (str == "curState")
        {
          currentState = (string)id;
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
  
  listen( integer channel, string name, key id, string message )
  {
      // if we haven't started communicating with icomm, ignore any external messages
      if (linkChannel != -1 && channel == listenChannel)
      {
        ProcessMessage(name, id, message);
      }
  }

  sensor(integer num_detected)
  {
    // if remote user is located, activate ring.
    sendMessage("remoteActivate", remoteUserKey);
  }
  no_sensor()
  {
    remoteUserKey = NULL_KEY;
  }
}
