// =web.lsl
// internet comm script
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

key httpRequest = NULL_KEY;

sendUpdate()
{
  httpRequest = llHTTPRequest("http://xhub.com/sl/openRings/server.php",
                              [HTTP_METHOD, "GET", HTTP_MIMETYPE, "application/x-www-form-urlencoded"], "");
}

default
{
  state_entry()
  {
    httpRequest = NULL_KEY;
    llSetTimerEvent(3600); // one hour
    sendUpdate();
  }

  timer()
  {
    sendUpdate();
  }
  
  http_response(key request_id, integer status, list metadata, string body)
  {
    if (httpRequest == request_id)
    {
      httpRequest = NULL_KEY;
      if (debug) llOwnerSay("HTTP RESPONSE: status(" + (string)status + ") body(" + body + ")");
      
      if (llSubStringIndex(body, "COMPLETED.") == -1)
      {
        llSetTimerEvent(0);
        llSetTimerEvent(60);
      }
      else if (status < 200 || status > 299)
      {
        llSetTimerEvent(0);
        llSetTimerEvent(1800);
      }
      else
      {
        llSetTimerEvent(0);
        llSetTimerEvent(3600);
      }
    }
  }

  on_rez(integer param)
  {
    llResetScript();
  }
}
