// =rcomm.lsl
// rezzed-ring communications handler
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
integer listenChannel = -3141592;
integer listen_handle = 0;

key ringBase = NULL_KEY;
key ring1 = NULL_KEY;
key ring2 = NULL_KEY;
key ring3 = NULL_KEY;
key ring4 = NULL_KEY;
key ring5 = NULL_KEY;

string newPrim = "";
string currentState = "";
string messageTO;
string messageFROM;
string messageCOMMAND;
string commandList;

integer ringPos;

float ringHeight;

list message_list = [ "" , "" , <0,0,0>];

// internal messages pass through icomm.lsl. use this function to communicate with other scripts
sendMessage(string command, string data)
{
  llMessageLinked(LINK_THIS, 0, command, (key)data);
}

// Start ring process
rezRings()
{
    // set the ring base texture        
    llSetPrimitiveParams([PRIM_GLOW, 0, 1.0]);

    llTriggerSound("ringSound", 1.0);
    // we need to set this 'flag' so we know below in obj_rez that the event was meant for us
    newPrim = "ringPrim";
    // rez the first ring
    llRezObject("ring", // object name
                llGetPos() + <0.0,0.0,ringHeight>, 
                <0.0,0.0,0.0>, 
                llEuler2Rot(<0,0,0>*DEG_TO_RAD), 
                ringPos--); // position value sent to new ring object
}

// called by obj_rez if due to a ring creation
// need to store the keys of the rings so we can communicate with them
onRezRings(key id)
{
    if (ring1 == NULL_KEY)
    {
        ring1 = id;
    }
    else if (ring2 == NULL_KEY)
    {
        ring2 = id;
    }
    else if (ring3 == NULL_KEY)
    {
        ring3 = id;
    }
    else if (ring4 == NULL_KEY)
    {
        ring4 = id;
    }
    else if (ring5 == NULL_KEY)
    {
        ring5 = id;
    }
    // when we've identified the key of the ring, we say a quick hello to
    // give the ring our key. Otherwise it wouldn't know future messages were from us
    llWhisper(listenChannel,
        (string)id + ":" +
        (string)ringBase + ":" +
        "HelloRing");
}

// called when transport is complete. lowering ring back down in reverse sequence.
deRezRings()
{
    if (ring5 != NULL_KEY)
        llSay(listenChannel, (string)ring5 + ":" + (string)ringBase + ":Die");
    if (ring4 != NULL_KEY)
        llSay(listenChannel, (string)ring4 + ":" + (string)ringBase + ":Die");
    if (ring3 != NULL_KEY)
        llSay(listenChannel, (string)ring3 + ":" + (string)ringBase + ":Die");
    if (ring2 != NULL_KEY)
        llSay(listenChannel, (string)ring2 + ":" + (string)ringBase + ":Die");
    if (ring1 != NULL_KEY)
        llSay(listenChannel, (string)ring1 + ":" + (string)ringBase + ":Die");
                
    resetRings();
    // after the rings are down, tell main to go back to its normal state.
    sendMessage("setState", "normal");
    // set the ring base texture        
    llSetPrimitiveParams([PRIM_GLOW, 0, 0.0]);
}

// reset working variables to a default state.
resetRings()
{
    ringBase = llGetLinkKey(llGetLinkNumber());
    ring1 = NULL_KEY;
    ring2 = NULL_KEY;
    ring3 = NULL_KEY;
    ring4 = NULL_KEY;
    ring5 = NULL_KEY;
    ringPos = 5;
    ringHeight = 0.1;
    
    message_list = [ "" , "" , <0,0,0>];
    newPrim = "";
}

// function used to process external ring-to-ringBase communicaions
ProcessMessage(string name, key id, string message)
{
    if (debug) llOwnerSay("DEBUG:" + message);
    
    string tempName;

    message_list = llParseString2List(message, [":"], [""]);
        
    messageTO = llList2String(message_list, 0);
    messageFROM = llList2String(message_list, 1);
    messageCOMMAND = llList2String(message_list, 2);

    if (messageTO == (string)ringBase)
    // only talk to those who know our UUID
    {
      if (messageCOMMAND == "ringCreated" && ring5 == NULL_KEY)
      {
          // if we receive a message stating a ring has been created, and the last one
          // hasn't been created, keep rezzing.
          newPrim = "ringPrim";
          llRezObject("ring", 
                      llGetPos() + <0.0,0.0,ringHeight>, 
                      <0.0,0.0,0.0>, 
                      llEuler2Rot(<0,0,0>*DEG_TO_RAD), 
                      ringPos--);
      }
      else if (messageCOMMAND == "ringPositioned" && ring5 != NULL_KEY)
      {
          // if the last ring is in position, tell main to transport
          sendMessage("commenceTransport", "");
      }
    }
}
        
default
{
    state_entry()
    {
        // set the list of internal commands that we will respond to
        commandList = llGetScriptName() + 
                      " rezRings" + 
                      " deRezRings" + 
                      " resetRings";

        resetRings();
        listen_handle = llListen(listenChannel, "", "", "");
    }
    
    link_message(integer sender_num, integer num, string command, key data)
    {
      if (sender_num == llGetLinkNumber())
      {
         // Broadcast message received from icomm
        if (num == -1)
        {
          if (command == "SEND_LINK_CHANNEL_REQUESTS")
          {
              sendMessage("LINK_CHANNEL_REQUEST", (key)llGetScriptName());
          }
          else if (command == llGetScriptName())
          {
              linkChannel = (integer)((string)data);
          }
          else if (command == "COMMAND_LIST_QUERY")
          {
            if (llListFindList(llParseString2List(commandList, [" "], []), [ (string)data]) != -1)
            {
              llOwnerSay("Script for command '"+ (string)data + "' found. Re-initalizing comm link.");
              sendMessage("LINK_CHANNEL_REQUEST", llGetScriptName());
            }
          }
          // mains' current state was broadcasted
          else if (command == "curState")
          {
            currentState = (string)data;
          }
        }
        // Direct message received from icomm
        else if (num == linkChannel)
        {
            if (command == "LIST_COMMANDS")
            {
              sendMessage("COMMAND_LIST", commandList);
            }
            else if (command == "rezRings")
            {
                rezRings();
            }
            else if (command == "deRezRings" ||
                     command == "resetRings")
            {
                deRezRings();
            }
        }
      }
    }

    listen( integer channel, string name, key id, string message )
    {
        // only process external communications if our link to icomm is already established.
        if (linkChannel != -1 && channel == listenChannel)
        {
          ProcessMessage(name, id, message);
        }
    }
    
    object_rez(key id)
    {
        // need to put key storing code here for clear communications to/from child prims
        if (newPrim == "ringPrim")
        {
            onRezRings(id);
        }
        newPrim = "";
    }
}
