// _replaceTextures.lsl
// texture replace script
//
//    Open Source 'Stargate' Ring Platform
//    Copyright 2008 (C) CB Radek (Sarah Bennert)
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

integer updateListenChannel = -1618033;
integer listenChannel = -3141592;
integer listenHandle = 0;
key ringKey = NULL_KEY;

default
{
    state_entry()
    {
      listenHandle = llListen(listenChannel, "", NULL_KEY, "");
      llWhisper(listenChannel, "*:" + (string)llGetKey() + ":ringPing");
    }
    listen(integer channel, string name, key id, string message)
    {
      if (channel == listenChannel)
      {
        list message_list = llParseString2List(message, [":"], [""]);
        if (llList2String(message_list, 0) == (string)llGetKey() && llList2String(message_list, 2) == "ringPong")
        {
          ringKey = llList2Key(message_list, 1);
          llSensor("", ringKey, SCRIPTED, 2.0, PI);
        }
      }
      else if (channel == updateListenChannel)
      {
        if (message == "sendTextures")
        {
          llListenRemove(listenHandle);
          llGiveInventory(ringKey, "ring");
          llGiveInventory(ringKey, "}bottom");
          llGiveInventory(ringKey, "}top");
          llGiveInventory(ringKey, "}inner");
          llGiveInventory(ringKey, "}outer");
          llSleep(1.0);
          llRemoteLoadScriptPin(ringKey, "=texture.lsl", updateListenChannel, TRUE, 0);
          llSleep(1.0);
          llDie();
        }
      }
    }
    sensor(integer num_detected)
    {
      llListenRemove(listenHandle);
      listenHandle = llListen(updateListenChannel, "", ringKey, "");
      llRemoteLoadScriptPin(ringKey, "_removeTextures.lsl", updateListenChannel, TRUE, 0);
    }
    no_sensor()
    {
      ringKey = NULL_KEY;
      llWhisper(listenChannel, "*:" + (string)llGetKey() + ":ringPing");
    }
    on_rez(integer param)
    {
      llResetScript();
    }
}
