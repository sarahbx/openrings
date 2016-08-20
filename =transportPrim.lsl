// =transportPrim.lsl
// transporter script
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

vector originalLocation;  
vector tempLocation;
vector destinationLocation;

rotation destinationRotation;

key destinationKey;
key sourceKey;
key transportKey;

list avList;
list destination_list;
list message_list;

integer listen_handle;
integer listen_channel;

string messageTO;
string messageFROM;
string messageCOMMAND;

string animation = "";


////////////////////////////////////////////////////////////////////////////////////////////////
// The warpPos() function is not subject to the openRings GNU-GPL licensing.
// "It's completely public domain. Look at it, modify it, sell it in an item, whatever.
//  But I'll be annoyed if you scam noobs into buying it." - Keknehv Psaltery
//
// http://lslwiki.net/lslwiki/wakka.php?wakka=LibraryWarpPos
warpPos( vector d ) //R&D by Keknehv Psaltery, ~05/25/2006
{
    integer iterations;
    vector curpos;
    if ( d.z < (llGround(d-llGetPos())+0.01)) 
        d.z = llGround(d-llGetPos())+0.01; //Avoid object getting stuck at destination
    if ( d.z > 4096 )      //Object doesn't get stuck on ceiling as of 1.19
        d.z = 4096;        //havok 4 the height limit is increasing to 4096
    do //This will ensure the code still works.. albeit slowly.. if LL remove this trick (which they have done and reverted in the past..)
    {
        iterations++;
        integer s = (integer)(llVecMag(d-llGetPos())/10)+1; //The number of jumps necessary
        if ( s > 200 )  //Try and avoid stack/heap collisions with far away destinations
            s = 200;    //  with this script compiled to MONO, you'll have plenty of memory for this.
        integer e = (integer)( llLog( s ) / llLog( 2 ) );   //Solve '2^n=s'        
        list rules = [ PRIM_POSITION, d ];  //The start for the rules list
        integer i;
        for ( i = 0 ; i < e ; ++i )     //Start expanding the list
            rules += rules;
        integer r = s - (integer)llPow( 2, e );
        if ( r > 0 )                    //Finish it up
            rules += llList2List( rules, 0, r * 2 + 1 );
        llSetPrimitiveParams( rules );
        curpos=llGetPos();
        if (iterations>200) {
            d=curpos; //We're going nowhere fast, so bug out of the loop
        }
    } while (llVecDist(curpos,d) > 0.2);
}
////////////////////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////////////////////


setLinkTexture(string texture)
{
    integer i;
    integer tempNum = llGetNumberOfPrims();
    for (i = 0; i<tempNum+1; i++)
    {
      if (llGetAgentSize(llGetLinkKey(i)) == ZERO_VECTOR)
      {
        llSetLinkTexture(i, texture, ALL_SIDES);
      }
    }
}

ResetTransportPrim()
{
    llVolumeDetect(TRUE);

    // need to load the texture for the transport beam early so it shows up correctly when called via MakeParticles()
    llSetTexture("Smoke", ALL_SIDES);
    llSetTexture("2d1cc751-383e-910a-dc3c-c8793bacf90c", 0);

//    setLinkTexture("Smoke");

    originalLocation = llGetPos();
    tempLocation = originalLocation;
    destinationLocation = tempLocation;
    destinationKey = NULL_KEY;
    sourceKey = NULL_KEY;
    avList = [];

    message_list = [];
    messageTO = "";
    messageFROM = "";
    messageCOMMAND = "";
    transportKey = llGetKey();
}

default
{
    state_entry()
    {
        ResetTransportPrim();
        listen_channel = llGetStartParameter();
        listen_handle = llListen(listen_channel, "", "", "");

        llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE, PRIM_GLOW, ALL_SIDES, 0.5]);

        llSetTimerEvent(45); // how long to wait for av to sit on prim before dying
        llSay(0, "Touch prim to prepare for transport.");
    }
    timer()
    {
      integer i;
      llSetTimerEvent(0); //  (to stop the timer)
      llSay(0, "Wait time exceeded, resetting script...");

      for (i=0; i < llGetListLength(avList); i++)
      {
        llUnSit((key)llList2Key(avList, i));
      }

      llRegionSay(listen_channel, (string)sourceKey + ":" + (string)transportKey + ":transportPrimDead");
      llDie();
    }
    touch_start(integer total_number)
    {
//        llSay(0, "Touched.");
    }
    listen( integer channel, string name, key id, string message )
    {
      integer i;
      
        if(debug) llSay(0, message);
        
        message_list = llParseString2List(message, [":"], [""]);

        messageTO = llList2String(message_list, 0);
        messageFROM = llList2String(message_list, 1);
        messageCOMMAND = llList2String(message_list, 2);
        
        if (messageTO == (string)transportKey)
        // only listen to those who know us
        {
            if (messageCOMMAND == "ringDest")
            // this command is whispered from source platform
            {
                sourceKey = (key)messageFROM;
                destinationKey = (key)llList2Key(message_list, 3);
                
                // ringList was already cleaned for deleted rings. if we don't get a valid position
                // keep trying til valid. Seems to be a server lag issue.
                do {
                  destination_list = llGetObjectDetails(destinationKey, [ OBJECT_POS, OBJECT_ROT ]);
                  destinationLocation = llList2Vector(destination_list, 0);
                  destinationRotation = llList2Rot(destination_list, 1);
                } while (destinationLocation == ZERO_VECTOR);
                

                llSetTimerEvent(0);//   (to stop the timer)
                setLinkTexture("Transparent");
                llSetPrimitiveParams([PRIM_GLOW, ALL_SIDES, 0.0]);
                originalLocation = llGetPos();

                llSay(0, "Locked on.");

                // Tell Platform to activate rings
                llWhisper(listen_channel, 
                          (string)sourceKey + ":" + 
                          (string)transportKey + ":" +
                           "rezRings");
            }
            else if (messageCOMMAND == "commenceTransport")
            {
                // Tell Platforms to emit particles
                llWhisper(listen_channel, (string)sourceKey + ":" + (string)transportKey + ":emitParticles");
                llRegionSay(listen_channel, (string)destinationKey + ":" + (string)transportKey + ":incomingTransport");

                llSleep(2); // give the platforms a sec to rez their rings.
                
                if (debug) llSay(0, "DEBUG:" + (string)destinationLocation);
                
                llSetRot(destinationRotation); // rotate to destination's set rotation
                // Warp to destination
                warpPos(destinationLocation+<0.0,0.0,1.5>);
                
                llSleep(0.2); // Seems to help rezing extra rings on arrival (rare)

                for (i=0; i < llGetListLength(avList); i++)
                {
                  llUnSit((key)llList2Key(avList, i));
                }

                llRegionSay(listen_channel, (string)sourceKey + ":" + (string)transportKey + ":transportPrimDead");
                llWhisper(listen_channel, (string)destinationKey + ":" + (string)transportKey + ":transportPrimDead");
                
                llDie();
            }
            else if (messageCOMMAND == "abortTransport")
            {
                for (i=0; i < llGetListLength(avList); i++)
                {
                  llUnSit((key)llList2Key(avList, i));
                }

                llDie();
            }
            else if (messageCOMMAND == "setTempOnRez")
            {
                if (llList2String(message_list, 3) == "TRUE")
                {
                    llSetPrimitiveParams([PRIM_TEMP_ON_REZ, TRUE]);
                }
                else
                {
                    llSetPrimitiveParams([PRIM_TEMP_ON_REZ, FALSE]);
                }
            }
        }
    }
    
    changed(integer change)
    {
      key tempKey;
      integer numPrims;
      integer i;
      
      if (change & CHANGED_LINK)
      { 
        numPrims = llGetNumberOfPrims();
        avList = [];
        for (i=0; i < numPrims+1; i+=1)
        {
          tempKey = llGetLinkKey(i);
          if (llGetAgentSize(tempKey) != ZERO_VECTOR)
          {
            avList += [ tempKey ];
            llRequestPermissions(tempKey, PERMISSION_TRIGGER_ANIMATION);
          }
        }
      }
    }

    run_time_permissions(integer perm)
    {
      if (perm & PERMISSION_TRIGGER_ANIMATION)
      {
        llStopAnimation("sit");
        animation="stand";//llGetInventoryName(INVENTORY_ANIMATION,0);
        llStartAnimation(animation);
      }
    }
} 
