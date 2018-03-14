# Copyright 2018 Autodesk, Inc.  All rights reserved.
#
# Use of this software is subject to the terms of the Autodesk license agreement
# provided at the time of installation or download, or which otherwise accompanies
# this software in either electronic or hard copy form.
#

# See docs folder for detailed usage info.

import os
import datetime
import time
from datetime import timedelta
import shotgun_api3


_state = {
    'sequential': -1,
    'rotating': -1,
}


def registerCallbacks(reg):
    """
    Register all necessary or appropriate callbacks for this plugin.
    """

    server = os.environ["SG_SERVER"]
    scriptName = os.environ["SGDAEMON_SHAREDSTATEA_NAME"]
    scriptKey = os.environ["SGDAEMON_SHAREDSTATEA_KEY"]

    sg = shotgun_api3.Shotgun(server, script_name=scriptName, api_key=scriptKey)

    # Callbacks are called in registration order. So callbackA will be called
    # before callbackB and callbackC
    reg.registerCallback(scriptName, scriptKey, callbackA)


def callbackA(sg, logger, event, args):
    """
    :param sg: Shotgun API handle.
    :param logger: Logger instance.
    :param event: A Shotgun EventLogEntry entity dictionary.
    :param args: Any additional misc arguments passed through this plugin.
    """

    # We know callbackA will be called first because we registered it first.
    # As the first thing to run on each event, we can reinizialize the rotating
    # counter.
    global _state
    _state['rotating'] = -1

    # Then we pass off to our helper function... because I'm lazy.
    now = datetime.datetime.now()
    now_str = now.strftime("%Y-%m-%d")
    print now_str

    result = sg.find_one('Project', [['id', 'is', 86]], ['id', 'sg_pro_today','sg_pro_end_date', 'sg_pro_start_date', 'sg_pro_today'])
    print result
    dt = datetime.datetime.strptime(result["sg_pro_end_date"], "%Y-%m-%d")
    
    duration=dt-now
    d = duration.days

    print d

    d=sg.update("Project", 86, {'sg_pro_today':now_str, "sg_deadline":d})
    result = sg.find_one('Project', [['id', 'is', 86]], ['id', 'sg_pro_today','sg_deadline', 'sg_pro_end_date', 'sg_pro_start_date'])
    print result

    printIds(sg, logger, event, args)

def printIds(sg, logger, event, args):
    # Here we can increment the two counters that are in shared state. Each
    # callback has played with the contents of this shared dictionary.
    #global _state
    _state['sequential'] += 1
    _state['rotating'] += 1

    # Log the counters so we can actually see something.
    logger.info('Sequential #%d - Rotating #%d', _state['sequential'], _state['rotating'])
