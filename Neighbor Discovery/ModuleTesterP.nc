/****************************************************************
 * NeighborManagement module tester
 * Author: Myounggyu Won
 */
 
#include "../../Common.h"

module ModuleTesterP{
	uses interface Neighborhood;
	uses interface Boot; 
	uses interface SplitControl as AMControl;
}
implementation{
  
  	event void Boot.booted()
  	{
  		dbg("GENERAL", "Node %d booted!\n", TOS_NODE_ID);
  		call AMControl.start();
  	}

  	event void AMControl.startDone(error_t err) 
  	{
    	if (err == SUCCESS) {
    		// start neighbor discovery here with dummy location.
    		call Neighborhood.startDiscovery(0, 0, 0.5f, 2000);
    	}
    	else {
      		call AMControl.start();
    	}
  	}
  
  	event void AMControl.stopDone(error_t err) 
  	{
  	}
	
}