// =main.lsl
// primary system script
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

integer debug = 0; // only enable this on one platform in 'llSay' Distance!!!!!!!!!!! (or your head will explode)

integer dilationKonstant = 3; // increase this value to increase the wait time for 'ringPong' responses.
integer dilationTimerSet = 0; // 

integer linkChannel; // channel we'll listen on for internal communications. set later
integer listen_dialog_handle = 0; // dialog handle
integer listen_dialog_channel; // dialog channel, set later
integer listenChannel = -3141592;

list ringListNames = []; // list of ring names
list ringList = []; // list of ring keys and vectors

list optionList = [ "All Rings", "9 Pass", "Texture", "RESET", "Temp Rez" ]; // option list. added 6/23/08 CB Radek

integer listStart; // for dialog menu browsing. to know where we were
integer listEnd; // ditto.

vector basePosition; // position of this ring platform. set later

key av = NULL_KEY; // key of avatar using ring at any time
key destination_key = NULL_KEY; // key of destination ring platform
key transport_key = NULL_KEY; // key of transport prim, set when created.
key ringBase = NULL_KEY; // key of the main ring base

string version = ""; // current version
string currentState; // current state
string newPrim = ""; // used with on_rez event to make sure we do the correct action. see transport state below.
string commandList; // list of internal commands we respond to. set later.

////////////////////////////////////////////////////////////////////////////////////////////////
// The MakeParticles() function is not subject to the openRings GNU-GPL licensing.
// "It's completely public domain. Look at it, modify it, sell it in an item, whatever.
//  But I'll be annoyed if you scam noobs into buying it." - Keknehv Psaltery
//
// http://lslwiki.net/lslwiki/wakka.php?wakka=LibraryKeknehvParticles
//
//This is the function that actually starts the particle system.
// aka: Keknehv's Particle Script
MakeParticles()
{
    // Keknehv's Particle Script v1.2
    // 1.0 -- 5/30/05
    // 1.1 -- 6/17/05
    // 1.2 -- 9/22/05 (Forgot PSYS_SRC_MAX_AGE)

    //     This script may be used in anything you choose, including and not limited to commercial products. 
    //     Just copy the MakeParticles() function; it will function without any other variables in a different script
    //         ( You can, of course, rename MakeParticles() to something else, such as StartFlames() )

    //    This script is basically an llParticleSystem() call with comments and formatting. Change any of the values
    //    that are listed second to change that portion. Also, it is equipped with a touch-activated off button,
    //    for when your particles go haywire and cause everyone to start yelling at you.

    //  Contact Keknehv Psaltery if you have questions or comments.

    llParticleSystem([                   //KPSv1.0  
        PSYS_PART_FLAGS , 0 //Comment out any of the following masks to deactivate them
    //| PSYS_PART_BOUNCE_MASK           //Bounce on object's z-axis
    //| PSYS_PART_WIND_MASK             //Particles are moved by wind
//    | PSYS_PART_INTERP_COLOR_MASK       //Colors fade from start to end
//    | PSYS_PART_INTERP_SCALE_MASK       //Scale fades from beginning to end
//    | PSYS_PART_FOLLOW_SRC_MASK         //Particles follow the emitter
//    | PSYS_PART_FOLLOW_VELOCITY_MASK    //Particles are created at the velocity of the emitter
    //| PSYS_PART_TARGET_POS_MASK       //Particles follow the target
    | PSYS_PART_EMISSIVE_MASK           //Particles are self-lit (glow)
    //| PSYS_PART_TARGET_LINEAR_MASK    //Undocumented--Sends particles in straight line?
    ,
    
    //PSYS_SRC_TARGET_KEY , NULL_KEY,   //Key of the target for the particles to head towards
                                                //This one is particularly finicky, so be careful.
    //Choose one of these as a pattern:
    //PSYS_SRC_PATTERN_DROP                 Particles start at emitter with no velocity
    //PSYS_SRC_PATTERN_EXPLODE              Particles explode from the emitter
    //PSYS_SRC_PATTERN_ANGLE                Particles are emitted in a 2-D angle
    //PSYS_SRC_PATTERN_ANGLE_CONE           //Particles are emitted in a 3-D cone
    //PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY     Particles are emitted everywhere except for a 3-D cone
    
    PSYS_SRC_PATTERN,           PSYS_SRC_PATTERN_ANGLE_CONE_EMPTY
    
    ,PSYS_SRC_TEXTURE,           "2d1cc751-383e-910a-dc3c-c8793bacf90c"                 //UUID of the desired particle texture, or inventory name
    ,PSYS_SRC_MAX_AGE,           2.0                //Time, in seconds, for particles to be emitted. 0 = forever
    ,PSYS_PART_MAX_AGE,          1.0                //Lifetime, in seconds, that a particle lasts
    ,PSYS_SRC_BURST_RATE,        0.02               //How long, in seconds, between each emission
    ,PSYS_SRC_BURST_PART_COUNT,  8                  //Number of particles per emission
    ,PSYS_SRC_BURST_RADIUS,      6.0                //Radius of emission
    ,PSYS_SRC_BURST_SPEED_MIN,   19.5                //Minimum speed of an emitted particle
    ,PSYS_SRC_BURST_SPEED_MAX,   20.0                //Maximum speed of an emitted particle
    ,PSYS_SRC_ACCEL,             <0.0,0.0,4.0>     //Acceleration of particles each second
    ,PSYS_PART_START_COLOR,      <1.0,1.0,1.0>      //Starting RGB color
//    ,PSYS_PART_END_COLOR,        <1.0,1.0,1.0>      //Ending RGB color, if INTERP_COLOR_MASK is on 
    ,PSYS_PART_START_ALPHA,      1.0                //Starting transparency, 1 is opaque, 0 is transparent.
    ,PSYS_PART_END_ALPHA,        1.0                //Ending transparency
    ,PSYS_PART_START_SCALE,      <6.0,6.0,0.0>      //Starting particle size
//    ,PSYS_PART_END_SCALE,        <5.0,5.0,0.0>      //Ending particle size, if INTERP_SCALE_MASK is on
    ,PSYS_SRC_ANGLE_BEGIN,       PI                 //Inner angle for ANGLE patterns
    ,PSYS_SRC_ANGLE_END,         PI                 //Outer angle for ANGLE patterns
    ,PSYS_SRC_OMEGA,             <0.0,0.0,0.0>       //Rotation of ANGLE patterns, similar to llTargetOmega()
            ]);
}
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////

// reset working variables to a default state
ResetTransporter()
{
    ringBase = llGetLinkKey(llGetLinkNumber());
    
    ringList = []; // clear list of transporter rings
    ringListNames = [];
    
    av = NULL_KEY;
    
    basePosition = llGetPos();

    transport_key = NULL_KEY;
    destination_key = NULL_KEY;
    newPrim = "";
    dilationTimerSet = 0;
    
    llParticleSystem([]); // need to do this to keep it from show more and more and more particles.
}

abortTransport()
{
  llWhisper(listenChannel, (string)transport_key + ":" + (string)ringBase + ":abortTransport");
}

// internal messages pass through icomm.lsl. use this function to communicate with other scripts
sendMessage(string command, string data)
{
  llMessageLinked(LINK_THIS, 0, command, (key)data);
}

// process received internal message
string processLinkMessage(string command, string data)
{
    list tempList = [];
  
    if (command == "LIST_COMMANDS")
    {
      sendMessage("COMMAND_LIST", commandList);
    }
    // if ecomm received a ringPong, it will relay it back to us
    // parse message and store data if in normal state.
    else if (command == "ringPong" &&
        currentState == "normal")
    {
        if (debug) llOwnerSay("ringPong Data: " + data);
      tempList = llParseString2List(data, [":"], [""]);

      if (llListFindList(ringList, llList2List(tempList, 1, 1)) == -1)
      {
        ringListNames += llList2List(tempList, 0, 0); // destination ring name
        ringList += llList2List(tempList, 1, 1); // destination ring key
      }
    }
    // if we've been asked to make particles, and we're in transport or incoming state... do it!
    else if (command == "makeParticles" && 
             (currentState == "transport" || currentState == "incoming"))
    {
        MakeParticles();
    }
    // someone requested to know what our current state is. give it to them.
    else if (command == "getState")
    {
      sendMessage("curState", currentState);
      sendMessage("setOptions", llDumpList2String(optionList, ":"));
    }
    else if (command == "commenceTransport")
    {
          llWhisper(listenChannel, 
              (string)transport_key + ":" +   // child prim key
              (string)ringBase + ":" +        // my key
              "commenceTransport");           // command
    }
    else if (command == "ringList")
    {
      if (debug) llOwnerSay("DEBUG =main.lsl: Received ring list...");
      
      ringList = llParseString2List(data, [":"], [""]);
      ringListNames = [];
      integer length = llGetListLength(ringList);
      integer i;
      string tempData;
    
      for (i=0; i < length; i+=1)
      {
        if (debug) llOwnerSay("DEBUG =main.lsl: Processing ring item [" + (string)i + "] of [" + (string)length + "]");

        tempData = llList2String(ringList, i);
        if (tempData == "OPTIONS" || tempData == "<<" || tempData == ">>")
        {
          ringListNames += [ tempData ];
        }
        else
        {
          if (llListFindList(optionList, ["Own Rings"]) && llGetOwnerKey((key)tempData) != llGetOwner())
          {
            ringList = llDeleteSubList(ringList, i, i);
            length -= 1;
          }
          else
          {
            ringListNames += llGetObjectDetails((key)tempData, [OBJECT_DESC]);;
          }
        }
      }

      if (debug) llOwnerSay("DEBUG =main.lsl: Processed ring list...");

    }
    else if (command == "remoteActivate")
    {
      ringActivate((key)data, TRUE);
    }
    else if (command == "abortTransport")
    {
        abortTransport();
    }
    else if (command == "transportDestination")
    {
      destination_key = (key)data;
      return "transport";
    }
    else if (command == "dialogOptionChange")
    {
      // Current status is list all rings in region. change to just owners rings
      if (data == "All Rings")
      {
          integer i = llListFindList(optionList, ["All Rings"]);
          optionList = llListReplaceList(optionList, ["Own Rings"], i, i);
          sendMessage("setOptions", llDumpList2String(optionList, ":"));
          llOwnerSay("Listing only owners rings in region...");
          return "normal";
      }
      // Current status is list only owners rings in region, change to all rings.
      else if (data == "Own Rings")
      {
          integer i = llListFindList(optionList, ["Own Rings"]);
          optionList = llListReplaceList(optionList, ["All Rings"], i, i);
          sendMessage("setOptions", llDumpList2String(optionList, ":"));
          llOwnerSay("Listing all rings in region...");
          return "normal";
      }
      else if (data == "9 Pass")
      {
          integer i = llListFindList(optionList, ["9 Pass"]);
          optionList = llListReplaceList(optionList, ["17 Pass"], i, i);
          sendMessage("setOptions", llDumpList2String(optionList, ":"));
          llOwnerSay("Using 17 passenger transport prim...");
          return "normal";
      }
      else if (data == "17 Pass")
      {
          integer i = llListFindList(optionList, ["17 Pass"]);
          optionList = llListReplaceList(optionList, ["9 Pass"], i, i);
          sendMessage("setOptions", llDumpList2String(optionList, ":"));
          llOwnerSay("Using 9 passenger transport prim...");
          return "normal";
      }
      else if (data == "Temp Rez")
      {
          integer i = llListFindList(optionList, ["Temp Rez"]);
          optionList = llListReplaceList(optionList, ["Non-Temp"], i, i);
          sendMessage("setOptions", llDumpList2String(optionList, ":"));
          llOwnerSay("Setting Transport Prim to Non-Temp on Rez");
          return "normal";
      }
      else if (data == "Non-Temp")
      {
          integer i = llListFindList(optionList, ["Non-Temp"]);
          optionList = llListReplaceList(optionList, ["Temp Rez"], i, i);
          sendMessage("setOptions", llDumpList2String(optionList, ":"));
          llOwnerSay("Setting Transport Prim to Temp on Rez");
          return "normal";
      }
    }
    return "";
}

ringActivate(key id, integer remote)
{
    vector remoteLocation = llList2Vector(llGetObjectDetails(id, [OBJECT_POS]), 0);
    llSay(0, "Looking for ring platforms...");

    // set working variables to a default state
    ResetTransporter();
    
    // create Transport Prim for av to sit on
    newPrim = "transportPrim";
    
    if (llListFindList(optionList, ["9 Pass"]) != -1)
    {
      llRezObject("TransportPrim-9", basePosition + <0.0,0.0,1.5>, <0.0,0.0,0.0>, llGetRot(), 10);
    }
    else if (llListFindList(optionList, ["17 Pass"]) != -1)
    {
      llRezObject("TransportPrim-17", basePosition + <0.0,0.0,1.5>, <0.0,0.0,0.0>, llGetRot(), 10);
    }

    // get the key of the avatar interacting with the ring
    av = id;

    // Broadcast call to any OpenRings platform through icomm
    sendMessage("ringEmailPing", "");

    setDilationTimer();
}

setDilationTimer()
{
    // If the current sim is too overwhelmed, we need to give other rings time to respond and to
    // get the info on those rings.
    float dilation = llGetRegionTimeDilation();
    if (dilation <= 0.65)
    {
      llSay(0, "Extreme server load. Please wait... will continue when time dilation > 0.65");
      llSay(0, "Region Time Dilation at " + (string)dilation);
    }
    while (dilation <= 0.65)
    {
      // extreme server load
      // wait for region lag to lessen.
      llSleep(5);
      dilation = llGetRegionTimeDilation();
      llSay(0, "Region Time Dilation at " + (string)dilation);
    }
    
    // a script error will occur if there is a heavy load on the server
    // set timeout to account for this.
    // The dialationKonstant is a default value to wait if there is no lag
    // As the load on the server increases, the 'dilation' value decreases
    // which will increase the amount of time to wait.
    dilationTimerSet = 1;
    llSetTimerEvent(dilationKonstant/dilation);
}

default
{
    state_entry()
    {
        llSetTimerEvent(0); // need to kill any timers previously set.
        // keeping track of our current state
        currentState = "default";
        if (debug) llOwnerSay("DEBUG: STATE(" + currentState + ")");

        // set the list of internal commands that we will respond to
        commandList = llGetScriptName() + 
                      " ringPong" + 
                      " getState" + 
                      " setState" + 
                      " makeParticles" +
                      " commenceTransport" +
                      " abortTransport" +
                      " ringList" +
                      " remoteActivate" +
                      " transportDestination" +
                      " dialogOptionChange";

        // set the name of the main prim to include current running version number
        version = llGetInventoryName(INVENTORY_BODYPART, 0);
        if (version != "")
        {
            version = llGetSubString(version, 1, -1);
        }
        else
        {
            version = "vUNKNOWN";
        }
        llSetObjectName("OpenRings " + version);

        // set working variables to a default state.
        ResetTransporter();

        // use a random dialog channel to minimize interference with other objects (inluding other rings)
        listen_dialog_channel = -1 * ((integer)llFrand((float)2147483646));
        listen_dialog_handle = llListen(listen_dialog_channel, "", "", "");

        // self initialization done, go to comm initialization state.
        state commInit;
    }
}

// icomm initialization state. We stay here until we get the 'COMMUNICATIONS_ACTIVE'
// message from icomm. At that point we can send out our current state and
// optionList.
state commInit
{
    state_entry()
    {
        llSetTimerEvent(0); // need to kill any timers previously set.
      currentState = "commInit";
        if (debug) llOwnerSay("DEBUG: STATE(" + currentState + ")");
    }
    
    link_message(integer sender_num, integer num, string str, key id)
    {
      if (sender_num == llGetLinkNumber())
      {
        // Broadcast message received from icomm
        if (num == -1)
        {
          // icomm is requesting scripts to check in
          if (str == "SEND_LINK_CHANNEL_REQUESTS")
          {
              sendMessage("LINK_CHANNEL_REQUEST", (key)llGetScriptName());
          }
          // icomm has assigned us a link channel
          else if (str == llGetScriptName())
          {
              linkChannel = (integer)((string)id);
          }
          // icomm has decided time to talk
          else if (str == "COMMUNICATIONS_ACTIVE")
          {
            state normal;
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
        // message directed to us from icomm
        else if (num == linkChannel)
        {
            // icomm requesting our command list
            if (str == "LIST_COMMANDS")
            {
                sendMessage("COMMAND_LIST", commandList);
            }
        }
      }
    }
}

// normal state... waiting for input...
state normal
{
    state_entry()
    {
        llSetTimerEvent(0); // need to kill any timers previously set.
        // keeping track of our current state
        currentState = "normal";
        if (debug) llOwnerSay("DEBUG: STATE(" + currentState + ")");
        sendMessage("curState", currentState);
        sendMessage("setOptions", llDumpList2String(optionList, ":"));
       
        // reset working variables to a default state
        ResetTransporter();
        
        // look for rings in the region to transport to
        sendMessage("ringEmailPing", "");
        llSetTimerEvent(300); // check for new rings periodically
    }
    
    link_message(integer sender_num, integer num, string str, key id)
    {
      string retVal = "";
      if (sender_num == llGetLinkNumber())
      {
        // Broadcast message received from icomm
        if (num == -1)
        {
          // icomm is requesting scripts to check in
          if (str == "SEND_LINK_CHANNEL_REQUESTS")
          {
              sendMessage("LINK_CHANNEL_REQUEST", (key)llGetScriptName());
          }
          // icomm has assigned us a link channel
          else if (str == llGetScriptName())
          {
              linkChannel = (integer)((string)id);
          }
        }
        // Direct message received from icomm
        else if (num == linkChannel)
        {
            // we've been asked to change state
            // you cannot set state in a global function. it must be done in the 
            // working state. So we do it here.
            if (str == "setState")
            {
                // go back to 'idle'
                if ((string)id == "normal")
                {
                    state normal;
                }
                // transport active
                else if ((string)id == "transport")
                {
                    state transport;
                }
                // incoming transport.
                // only change states if ring is 'idle' (normal state)
                else if ((string)id == "incoming" && currentState == "normal")
                {
                    state incoming;
                }
                else if ((string)id == "texture")
                {
                  state texture;
                }
            }
            // if not 'setState', processLinkMessage() will do the rest
            else
            {
                retVal = processLinkMessage(str, (string)id);
                if (retVal == "transport")
                {
                    state transport;
                }
            }
        }
      }
    }
    
    touch_start(integer total_number)
    {
        ringActivate(llDetectedKey(0), FALSE);
    }

    timer()
    {        
        llSetTimerEvent(0);
        listStart = 0;
        
        if (dilationTimerSet) // pending transport
        {
            if (newPrim == "")
            {
                dilationTimerSet = 0;
                // the list of available rings has been created, change to state touched
                // and wait for user to make a choice
                state touched;
            }
            else
            {
                llSetTimerEvent(0.5);
            }
        }
        else // check for new rings
        {
            sendMessage("ringEmailPing", "");
            llSetTimerEvent(300);
        }
    }

    object_rez(key id)
    {
        // need to put key storing code here for clear communications to/from child prims
        if (newPrim == "transportPrim")
        {
            transport_key = id;
            
            // load the transport prim with it's inventory
            llGiveInventory(transport_key, "Smoke");
            llGiveInventory(transport_key, "Transparent");
            llRemoteLoadScriptPin(id, "=transportPrim.lsl", 3141592, 1, listenChannel);
        }
        newPrim = "";
    }
}

// touched state, show user platforms available
state touched
{
    state_entry()
    {
        llSetTimerEvent(0); // need to kill any timers previously set.
        
        // keeping track of our current state
        currentState = "touched";
        if (debug) llOwnerSay("DEBUG: STATE(" + currentState + ")");
        sendMessage("curState", currentState);
        
        // backup time to wait before going back to normal state
        llSetTimerEvent(120);
        
        llPreloadSound("ringSound");
        
        sendMessage("activateDialog", (string)av+":"+llDumpList2String(optionList, ":"));
    }
    
    touch_start(integer total_number)
    {
        // if a second avatar tries to use the platform while someone else is, they will be denied.
        if (llDetectedKey(0) != av)
        {
            llSay(0, "OpenRing Platform in use, please wait...");
        }
        else
        {
            llSay(0, "Resetting Platform...");
            abortTransport();
            state normal;
        }
    }
    
    link_message(integer sender_num, integer num, string str, key id)
    {
      string retVal = "";
      if (sender_num == llGetLinkNumber())
      {
        // Broadcast message received from icomm
        if (num == -1)
        {
          // icomm is requesting scripts to check in
          if (str == "SEND_LINK_CHANNEL_REQUESTS")
          {
              sendMessage("LINK_CHANNEL_REQUEST", (key)llGetScriptName());
          }
          // icomm has assigned us a link channel
          else if (str == llGetScriptName())
          {
              linkChannel = (integer)((string)id);
          }
        }
        // Direct message received from icomm
        else if (num == linkChannel)
        {
            // we've been asked to change state
            // you cannot set state in a global function. it must be done in the 
            // working state. So we do it here.
            if (str == "setState")
            {
                // go back to 'idle'
                if ((string)id == "normal")
                {
                    state normal;
                }
                // transport active
                else if ((string)id == "transport")
                {
                    state transport;
                }
                // incoming transport.
                // only change states if ring is 'idle' (normal state)
                else if ((string)id == "incoming" && currentState == "normal")
                {
                    state incoming;
                }
                else if ((string)id == "texture")
                {
                  state texture;
                }
            }
            // if not 'setState', processLinkMessage() will do the rest
            else
            {
                retVal = processLinkMessage(str, (string)id);
                if (retVal == "normal")
                {
                    state normal;
                }
                else if (retVal == "transport")
                {
                    state transport;
                }
            }
        }
      }
    }

    timer()
    {
        // user waited too long to make decision, reset system
        llSay(0, "Wait time exceeded, resetting system...");
        llSetTimerEvent(0);
        av = NULL_KEY;
        state normal;
    }
}

// transport state. sending user to chosen platform
state transport
{
    state_entry()
    {
        llSetTimerEvent(0); // need to kill any timers previously set.
      currentState = "transport";
        if (debug) llOwnerSay("DEBUG: STATE(" + currentState + ")");
      sendMessage("curState", currentState);

      llSetTimerEvent(90); // this is a backup. the transport prim will notify us when it dies without use, but if something happens...

        // Set the transport prim's 'TEMP_ON_REZ' status from options menu
      if (llListFindList(optionList, ["Temp Rez"]) != -1)
      {
          llWhisper(listenChannel,
                    (string)transport_key + ":" +       // child prim key
                    (string)ringBase + ":" +            // my key
                    "setTempOnRez" + ":" +                  // command
                    "TRUE");                           // set value
      }
      else
      {
          llWhisper(listenChannel,
                    (string)transport_key + ":" +       // child prim key
                    (string)ringBase + ":" +            // my key
                    "setTempOnRez" + ":" +                  // command
                    "FALSE");                           // set value
      }

      // tell the Transport Prim the key of where it's going
      // new version. using on v0.51 and up. We can use llGetObjectDetails to get the rest.
      llWhisper(listenChannel,
                (string)transport_key + ":" +       // child prim key
                (string)ringBase + ":" +            // my key
                "ringDest" + ":" +                  // command
                (string)destination_key);           // destination key
    }
    
    timer()
    {
        llSay(0, "Wait time exceeded, resetting script...");
        llSetTimerEvent(0);
        state normal;
    }
    
    link_message(integer sender_num, integer num, string str, key id)
    {
      string retVal = "";
      
      if (debug) llOwnerSay("DEBUG =main.lsl: link_message linkChannel: " +  (string)linkChannel + "num(" + (string)num + ") str(" + str + ") id(" + (string)id + ")");
      if (sender_num == llGetLinkNumber())
      {
        // Broadcast message received from icomm
        if (num == -1)
        {
          // not sure we care here... we'll see.
        }
        // Direct message received from icomm
        else if (num == linkChannel)
        {
            // we've been asked to change state
            // you cannot set state in a global function. it must be done in the 
            // working state. So we do it here.
            if (str == "setState")
            {
                // go back to 'idle'
                if ((string)id == "normal")
                {
                    state normal;
                }
                // transport active
                else if ((string)id == "transport")
                {
                    state transport;
                }
                // incoming transport.
                // only change states if ring is 'idle' (normal state)
                else if ((string)id == "incoming" && currentState == "normal")
                {
                    state incoming;
                }
                else if ((string)id == "texture")
                {
                  state texture;
                }
            }
            // if not 'setState', processLinkMessage() will do the rest
            else
            {
                retVal = processLinkMessage(str, (string)id);
            }
        }
      }
    }
}

// incoming state. incoming transport
state incoming
{
    state_entry()
    {
        llSetTimerEvent(0); // need to kill any timers previously set.
        currentState = "incoming";
        if (debug) llOwnerSay("DEBUG: STATE(" + currentState + ")");
        sendMessage("curState", currentState);

        llSay(0, "Incoming transport...");
        sendMessage("rezRings", "");
        MakeParticles();
        llSetTimerEvent(10); // this is the time to wait for incoming traveler before returning to normal state.
    }
    
    timer()
    {
        llSay(0, "Wait time exceeded, resetting script...");
        llSetTimerEvent(0);
        state normal;
    }

    link_message(integer sender_num, integer num, string str, key id)
    {
      string retVal = "";
      
      if (debug) llOwnerSay("DEBUG =main.lsl: link_message linkChannel: " +  (string)linkChannel + "num(" + (string)num + ") str(" + str + ") id(" + (string)id + ")");
      if (sender_num == llGetLinkNumber())
      {
        // Broadcast message received from icomm
        if (num == -1)
        {
          // not sure we care here... we'll see.
        }
        // Direct message received from icomm
        else if (num == linkChannel)
        {
            // we've been asked to change state
            // you cannot set state in a global function. it must be done in the 
            // working state. So we do it here.
            if (str == "setState")
            {
                // go back to 'idle'
                if ((string)id == "normal")
                {
                    state normal;
                }
                // transport active
                else if ((string)id == "transport")
                {
                    state transport;
                }
                // incoming transport.
                // only change states if ring is 'idle' (normal state)
                else if ((string)id == "incoming" && currentState == "normal")
                {
                    state incoming;
                }
                else if ((string)id == "texture")
                {
                  state texture;
                }
            }
            // if not 'setState', processLinkMessage() will do the rest
            else
            {
                retVal = processLinkMessage(str, (string)id);
            }
        }
      }
    }
}

state texture
{
  state_entry()
  {
    llSetTimerEvent(0); // need to kill any timers previously set.
    currentState = "texture";
    if (debug) llOwnerSay("DEBUG: STATE(" + currentState + ")");
    sendMessage("curState", currentState);

    listen_dialog_handle = llListen(listen_dialog_channel, "", "", "");
    llSetTimerEvent(60); // time to wait before going back to normal state

    integer i;
    integer l = llGetInventoryNumber(INVENTORY_OBJECT);
    list textureList = [];
    string name;
    for (i=0; i < l; i+=1)
    {
      name = llGetInventoryName(INVENTORY_OBJECT, i);
      if (llSubStringIndex(name, "texture:") == 0)
      {
        textureList += llGetSubString(name, 8, -1);
      }
    }
    llDialog(av, "Textures\nChoose your favorite:", textureList, listen_dialog_channel);
  }
  
  listen( integer channel, string name, key id, string message)
  {
    if(debug) llOwnerSay("DEBUG:" + message);
        
    if (id == av && channel == listen_dialog_channel)
    {
      llRezObject("texture:" + message, llGetPos(), <0.0,0.0,0.0>, llEuler2Rot(<0,0,0>*DEG_TO_RAD), 0);
      state normal;
    }
  }

  timer()
  {
    llSay(0, "Wait time exceeded, resetting script...");
    llSetTimerEvent(0);
    state normal;
  }
}
