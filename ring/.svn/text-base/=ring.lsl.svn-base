integer debug = 0;

float position;
integer listen_handle;
integer listen_channel = -3141592;
list message_list;
key ringKey;
key basePlatform = NULL_KEY;
float f;
vector originalLocation;
vector destination;
vector target;
float timeToTarget;
float targetRange;
integer targetID;
integer die;
integer atTarget;

string messageTO;
string messageFROM;
string messageCOMMAND;

default
{
    state_entry()
    {
    }
    listen( integer channel, string name, key id, string message )
    {
        if(debug) llSay(0, "DEBUG:" + message);

        message_list = llParseString2List(message, [":"], [""]);
        
        messageTO = llList2String(message_list, 0);
        messageFROM = llList2String(message_list, 1);
        messageCOMMAND = llList2String(message_list, 2);
        
        if (messageTO == (string)ringKey)
        {
            if (messageCOMMAND == "HelloRing")
            {
                basePlatform = (key)messageFROM;

                llWhisper(listen_channel, 
                        (string)basePlatform + ":" +
                        (string)ringKey + ":" +
                        "ringCreated");

                if (atTarget)
                {
                    llWhisper(listen_channel, 
                            (string)basePlatform + ":" +
                            (string)ringKey + ":" +
                            "ringPositioned");
                }

            }
            else if (messageCOMMAND == "Die")
            {
                die = 1;
                target = originalLocation;
                timeToTarget = 0.1;
                targetRange = 0.1; 

                targetID = llTarget( target, targetRange );
                llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y | STATUS_ROTATE_Z, FALSE);
                llSetStatus(PRIM_PHYSICS, TRUE);
                llMoveToTarget(target, timeToTarget);
            }
        }
    }
    on_rez(integer start_param)
    {
        die = 0;
        atTarget = 0;
        ringKey = llGetKey();
        originalLocation = llGetPos();
        
        listen_handle = llListen(listen_channel, "", "", "");

        position = (float)llGetStartParameter() / (float)1.8;
        f = position - 0.2;

        target = originalLocation + <0,0,f>;
        timeToTarget = 0.1;
        targetRange = 0.1; 

        targetID = llTarget( target, targetRange );
        llSetStatus(STATUS_ROTATE_X | STATUS_ROTATE_Y | STATUS_ROTATE_Z, FALSE);
        llSetStatus(PRIM_PHYSICS, TRUE);
        llMoveToTarget(target, timeToTarget);
                
    }
    not_at_target()
    {
        // We're not there yet.
//        llWhisper(0, "Still going"+(string)llGetPos()+(string)target);
    }
    at_target( integer number, vector targetpos, vector ourpos )
    {
        // Stop notifications of being there or not
        llTargetRemove(targetID);

        // Stop moving towards the destination
        llStopMoveToTarget();

        // Become non-physical
        llSetStatus(STATUS_PHYSICS, FALSE);
        if (die)
            llDie();
        else
        {
            atTarget = 1;
            if (basePlatform != NULL_KEY)
            {
                llWhisper(listen_channel, 
                        (string)basePlatform + ":" +
                        (string)ringKey + ":" +
                        "ringPositioned");

                atTarget = 0;
            }
        }
    }
}
