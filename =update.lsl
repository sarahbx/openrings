//  update.lsl: OpenGate2 update code
//  Copyright (C) 2007 Adam Wozniak
//
//  This program is free software: you can redistribute it and/or modify
//  it under the terms of the GNU General Public License as published by
//  the Free Software Foundation, either version 3 of the License, or
//  (at your option) any later version.
//
//  This program is distributed in the hope that it will be useful,
//  but WITHOUT ANY WARRANTY; without even the implied warranty of
//  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
//  GNU General Public License for more details.
//
//  You should have received a copy of the GNU General Public License
//  along with this program.  If not, see <http://www.gnu.org/licenses/>.
//
//  Adam Wozniak
//  1352 Fourteenth St, Los Osos, CA 93402
//  adam-opengate@cuddlepuddle.org

//  3/9/08 changed channel to a OpenRings specific communication channel.
integer listen_channel = -1618033;
integer linkChannel = -1;

default
{
  state_entry ()
  {
      if (llSubStringIndex(llGetObjectName(), "updater") == 0) {
         llSetScriptState(llGetScriptName(), FALSE);
         return;
      }
      llSetRemoteScriptAccessPin(listen_channel);
      llListen(listen_channel, "", NULL_KEY, "update?");
      llAllowInventoryDrop(FALSE);
  }

   listen(integer channel, string name, key id, string mesg) {
      if (mesg == "update?") {
         llWhisper(listen_channel, "update!");
         if (id == llGetCreator()) {
            llAllowInventoryDrop(TRUE);
         }
      }
   }

   changed(integer kind) {
      if (kind & (CHANGED_INVENTORY|CHANGED_ALLOWED_DROP)) {
         integer max = llGetInventoryNumber(INVENTORY_OBJECT);
         integer i;
         for (i = 0; i < max; i++) {
            if (llSubStringIndex(llGetInventoryName(INVENTORY_OBJECT, i), "updater ") == 0) {
               llRezObject(llGetInventoryName(INVENTORY_OBJECT, i), llGetPos(), ZERO_VECTOR, ZERO_ROTATION, 0);
               llRemoveInventory(llGetInventoryName(INVENTORY_OBJECT, i));
               llResetScript();
            }
         }
      }
   }
}
