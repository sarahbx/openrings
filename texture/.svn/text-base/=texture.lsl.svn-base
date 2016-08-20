// =texture.lsl
// on_rez set texture script
//
//    Open Source 'Stargate' Ring Platform
//    Copyright 2008 (C) CB Radek
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

default
{
  state_entry()
  {
    // set the ring base texture        
    llSetPrimitiveParams([
                          PRIM_TEXTURE, 0, "}top", <1,1,0>, <0,0,0>, -90,
                          PRIM_TEXTURE, 1, "}outer", <30,1,0>, <0,0,0>, 0,
                          PRIM_TEXTURE, 2, "}inner", <30,1,0>, <0,0,0>, 0,
                          PRIM_TEXTURE, 3, "}bottom", <1,1,0>, <0,0,0>, -90,
                          PRIM_BUMP_SHINY, ALL_SIDES, PRIM_SHINY_LOW, PRIM_BUMP_NONE,
                          PRIM_FULLBRIGHT, ALL_SIDES, FALSE
                          ]);
  }
  on_rez(integer param)
  {
    llResetScript();
  }
}
