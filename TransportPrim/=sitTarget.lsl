// =sitTarget.lsl
// transporter prim sit-target script
// by: Faliku Congrejo, edited by CB Radek
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

key av = NULL_KEY;
string animation = "";

default
{
  state_entry()
  {
    av = NULL_KEY;
    animation = "";
    llSitTarget(<0,0,1>,<0,0,0,1>);
  }
  changed(integer change)
  {
    key av;
    if (change & CHANGED_LINK)
    { 
      av = llAvatarOnSitTarget();
      if (av)
      {//evaluated as true if not NULL_KEY or invalid
        llRequestPermissions(av, PERMISSION_TRIGGER_ANIMATION);
      }
      else
      {
        if ((llGetPermissions() & PERMISSION_TRIGGER_ANIMATION) && llStringLength(animation)>0)
        {
          llStopAnimation(animation);
        }
        animation="";
      }
    }
  }
  run_time_permissions(integer perm)
  {
    if (perm & PERMISSION_TRIGGER_ANIMATION)
    {
      llStopAnimation("sit");
      animation="6b61c8e8-4747-0d75-12d7-e49ff207a4ca";//llGetInventoryName(INVENTORY_ANIMATION,0);
      llStartAnimation("stand");
    }
  }
  on_rez(integer param)
  {
    llResetScript();
  }
}
