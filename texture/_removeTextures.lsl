// _removeSetTextures.lsl
// in-ring texture script
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

default
{
  state_entry()
  {
    list remList = [ "ring", "}bottom", "}inner", "}outer", "}top" ];
    integer i;
    integer length = llGetListLength(remList);
    for (i=0; i < length; i+=1)
    {
      llRemoveInventory(llList2String(remList, i));
    }
    llSleep(1.0);
    llWhisper(updateListenChannel, "sendTextures");
    llSleep(1.0);
    llRemoveInventory(llGetScriptName());
  }
}
