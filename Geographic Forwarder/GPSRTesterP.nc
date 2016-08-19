/**
 * Application code for testing the GPSR module
 * Author: MG Won
 **/

#include "Timer.h"
//#include "identity.h"
#include "GPSR.h"

module GPSRTesterP
{
  // general interfaces 
  uses interface Timer<TMilli> as Timer0;
  uses interface Timer<TMilli> as Timer1;
  uses interface Timer<TMilli> as Timer2;
  uses interface Leds;
  uses interface Boot;
  uses interface SplitControl as AMControl;
  //interfaces for running GPSR
  uses interface GPSR;
  //uses interface IdentityWriter;
  uses interface Neighborhood;
  uses interface Identity;
  uses interface BoundaryDetection;
}
implementation
{
  location_t my_loc;
  
  event void Boot.booted()
  {
  	call AMControl.start();
  }

  event void AMControl.startDone(error_t err) {
    if (err == SUCCESS) {
      call Timer2.startOneShot( 10000 );
    }
    else {
      call AMControl.start();
    }
  }
  
  event void AMControl.stopDone(error_t err) {
  }
  
  // until the timer0 is fired, neighbor discovery is performed
  event void Timer0.fired()
  {
  	uint8_t dummy_msg[5];
  	location_t dest_loc;
  	
  	call GPSR.Init();
  	//call BoundaryDetection.initBoundaryDetection(0);
  	dest_loc.x = 10;
  	dest_loc.y = 26;
  	dummy_msg[0]=1;
  	dummy_msg[0]=2;
  	dummy_msg[0]=3;
  	dummy_msg[0]=4;
  	dummy_msg[0]=5;
  	
  	/*
  	if (TOS_NODE_ID==1) {
  		if (call GPSR.sendMsg(dummy_msg, 5*sizeof(uint8_t), 0, dest_loc) == FAIL)
  			dbg("GPSR", "SendMsg() Fail\n");
  		else {
  			call Leds.led2Toggle();
  			dbg("GPSR", "SendMsg() Success\n");
  		}
  	}
  	*/
 
  	if (TOS_NODE_ID==63) {
  		if (call GPSR.sendMsg(dummy_msg, 5*sizeof(uint8_t), 0, dest_loc) == FAIL)
  			dbg("GPSR", "SendMsg() Fail\n");
  		else {
  			call Leds.led2Toggle();
  			dbg("GPSR", "SendMsg() Success\n");
  		}
  	}
  	
  }
  
  // after finishing the initialization, the first packet is sent
  event void Timer1.fired()
  {
  	#ifdef LOG
	Dbg("Choosing cymmetric links ...\n");
	#endif
	call Neighborhood.stopDiscovery();
	call Neighborhood.sortNeighborsCounterClockwise();
	call Timer0.startOneShot(SYM_LINK_DISCOVERY_DURATION + BOUNDARY_DETECTION_WAIT_DURATION);	
  }
  
  event void Timer2.fired()
  {  	
  	location_t myLoc;
		
	myLoc = call Identity.getMyLoc();
	if (TOS_NODE_ID != 0)
    {
#ifdef LOG
		Dbg("Neighbor discovery started exp %d\n", expCounter);
		call Neighborhood.startDiscovery(myLoc.x, myLoc.y, PDRs[expCounter], NEIGHBOR_DISCOVERY_PERIOD);
#else
		call Neighborhood.startDiscovery(myLoc.x, myLoc.y, 0.7, NEIGHBOR_DISCOVERY_PERIOD);
#endif
    	call Timer1.startOneShot(NEIGHBOR_DISCOVERY_DURATION); 	
    }
  }
  
  event uint8_t GPSR.receiveMsg(void* p_msg, uint8_t p_len, uint8_t p_type, location_t p_destination) {
  	// ... do what you want to do for the event of packet reception.
  	dbg("GPSR", "Message reached final dest.\n");
  	return 0;
  }
  
  
}

