/****************************************************************
 * BoundaryDetection module tester
 * Author: Myounggyu Won
 */
 
#include "../../Common.h"
#include "Debug.h"

module ModuleTesterP {
	uses interface Neighborhood;
	uses interface BoundaryDetection;
	uses interface Identity;
	uses interface Boot; 
	uses interface Timer<TMilli> as NeighborDiscoveryTimer;
	uses interface Timer<TMilli> as BoundaryDetectionTimer;
	uses interface Timer<TMilli> as DeploymentTimer;
	uses interface SplitControl as AMControl;
#ifdef LOG
	uses interface Debug;
	uses interface LogRead;
    uses interface LogWrite;
    uses interface Timer<TMilli> as LogTimer;
    uses interface Timer<TMilli> as ResetTimer;
#endif
    uses interface Reset;
    uses interface Leds;
}
implementation{
  
#ifdef LOG
  	uint16_t ids[MAX_NEIGHBORS];
  	uint8_t expCounter = 0;
    uint8_t txPowerCounter = 0;
  	record_t record; 	

    error_t Dbg(char *fmt, ...)	{
 		error_t t;
		DEBUG_START;
		t = call DEBUG_OUT;
		DEBUG_END;
		return t;
	}
#endif 
	 
  	event void Boot.booted()
  	{
  		location_t myLoc;
#ifdef LOG  		
  		call Debug.Init();
#endif
  		myLoc = call Identity.getMyLoc();
  		dbg("GENERAL", "Node %d (Loc: %d, %d) booted!\n", TOS_NODE_ID, myLoc.x, myLoc.y);
  		call AMControl.start();
  	}

  	event void AMControl.startDone(error_t err) 
  	{
    	if (err == SUCCESS) {
    		// TEST *********************** 
  			//call LogWrite.erase();
  			//
    		if (TOS_NODE_ID != 0)
    		{
    			call DeploymentTimer.startOneShot(DEPLOYMENT_TIME);
    			
    			#ifdef LOG
    			call LogTimer.startOneShot(LOG_TIME);
    			call ResetTimer.startOneShot(RESET_TIME); // initial deployment time + neighbor discovery time + sym link selection time + wait time + boundary detection time + logging time.
    			#endif
    		}
    	}
    	else {
      		call AMControl.start();
    	}
  	}
  
  	event void AMControl.stopDone(error_t err) 
  	{
  	}
	
	event void NeighborDiscoveryTimer.fired()
	{
		//neighbor_t* neighbors;
		//uint16_t neighborSize;
		//neighbor_t neighbor;
		//nx_location_t loc;
		
		//neighbor.m_id = 1;
		// test logging
		//neighbors = call Neighborhood.GetNeighbor();
		//neighborSize = call Neighborhood.GetNeighborSize();
      	//if (call LogWrite.append(neighbors, sizeof(neighbor_t) * neighborSize) != SUCCESS) {
			//m_busy = FALSE;
      	//}
		// end of testing
#ifdef LOG
		Dbg("Choosing cymmetric links ...\n");
#endif
		call Neighborhood.stopDiscovery();
		call Neighborhood.sortNeighborsCounterClockwise();
		// allow some time for the neighbor discovery to stabilize, i.e., finding symmetric links with good pdrs.
		call BoundaryDetectionTimer.startOneShot(SYM_LINK_DISCOVERY_DURATION + BOUNDARY_DETECTION_WAIT_DURATION);
	}

	event void BoundaryDetectionTimer.fired(){
		call BoundaryDetection.initBoundaryDetection(10);
	}

#ifdef LOG
	event void Debug.recvByte(uint8_t *str, uint16_t len){
	}
#endif

	event void DeploymentTimer.fired(){
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
    		call NeighborDiscoveryTimer.startOneShot(NEIGHBOR_DISCOVERY_DURATION); 
    		
    	}
	}
	
//------------------------------------ for experiments -----------------------------------------------------------
	
#ifdef LOG
	event void LogWrite.syncDone(error_t error){
	}

	event void LogWrite.appendDone(void *buf, storage_len_t len, bool recordsLost, error_t error){
		Dbg("error type %d\n", error);
	}

	event void LogWrite.eraseDone(error_t error){
		if (error == SUCCESS)
		{
			//loc.x = 5; loc.y = 5;
			ids[0] = 1; ids[1] = 2; ids[2] = 3;
    		if (call LogWrite.append(ids, sizeof(uint16_t) * MAX_NEIGHBORS) != SUCCESS) 
    		{
    			Dbg("Write Fail\n");
    			return;
			}
			Dbg("Write Success\n");
		}
	}

	event void LogRead.readDone(void *buf, storage_len_t len, error_t error){
	}

	event void LogRead.seekDone(error_t error){
	}
	event void ResetTimer.fired(){
		location_t myLoc;
		// we are going to use software reset.
		//call Reset.reset(); - hardware reset.
                atomic {
		expCounter++;
                if (expCounter > 6)
                {
                	expCounter = 0;
                        txPowerCounter++;
                        TX_POWER = TX_POWER_[txPowerCounter];
                }
		call Leds.led0Off();
		call Leds.led1Off();
		call Leds.led2Off();
		call Neighborhood.Init();
		call BoundaryDetection.Init();
		myLoc = call Identity.getMyLoc();
		if (TOS_NODE_ID != 0)
		{
			Dbg("Neighbor discovery started exp %d\n", expCounter);
			call NeighborDiscoveryTimer.startOneShot(NEIGHBOR_DISCOVERY_DURATION); // do the neighbor discovery for 3 mins.
			#ifdef LOG
			call LogTimer.startOneShot(LOG_TIME - DEPLOYMENT_TIME); // rerunning does not consider time for deployment
			call ResetTimer.startOneShot(RESET_TIME - DEPLOYMENT_TIME); 
			#endif
			call Neighborhood.startDiscovery(myLoc.x, myLoc.y, PDRs[expCounter], NEIGHBOR_DISCOVERY_PERIOD);
		}
                }
	}
	event void LogTimer.fired(){
		neighbor_t* neighbors;
		uint16_t neighborSize;
		uint16_t i;
		location_t* vertices;
		
		neighbors = call Neighborhood.GetNeighbor();
		neighborSize = call Neighborhood.GetNeighborSize();
		// start logging
		// given time is LOG_WRITE_DURATION -- currently 60 seconds -- seconds.
		record.expNum = expCounter;
                record.txpower = TX_POWER;
		record.isBoundary = call BoundaryDetection.isBoundaryNode();
                record.retxCnt = retxCnt;
		for (i = 0; i < neighborSize; i++)   //TODO: <= neighborSize 
		{
			record.neighborIDs[i] = neighbors[i].m_id;
		}
		vertices = call BoundaryDetection.getVertices();
		for (i = 0; i < MAX_VERTICES; i++)
		{
			record.vertexLocs[i] = vertices[i];
		}
		if (call LogWrite.append(&record, sizeof(record_t)) != SUCCESS) 
		{
			Dbg("Write Fail\n");
			return;
		}
		Dbg("Write Success\n");
	}
#endif

//-------------------------------------------------------------------------------------------------------
}
