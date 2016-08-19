/***********************************
 * Implementation of Boundary Detection module
 * Author: Myounggyu Won
 */

#include "../../Common.h"
#include "BoundaryDetection.h"
#include "Debug.h"

module BoundaryDetectionP{
	uses
	{
		interface Neighborhood;
		interface GeometrySupport;
		interface AMSend as controlPktSend;
		interface Receive as controlPktReceive;
		interface PacketAcknowledgements as controlPktAck;
		interface Timer<TMilli> as QueueChecker;
		interface Packet;
		interface Queue<message_t> as ctlPktQueue;
		interface Identity;
		interface Leds;
		interface StdControl as DisseminationControl;
		interface DisseminationValue<uint16_t> as Value;
  		interface DisseminationUpdate<uint16_t> as Update;
#ifdef LOG
		interface Debug;
        interface CC2420Packet;
        interface LogRead;
    	interface LogWrite;
#endif
	}
	provides interface BoundaryDetection;
}
implementation{
	// MEMORY SIZE REDUCTION !!!!!!!!!
	//#include "20_by_20_loc.txt"
	//neighbor_t neighborsCClockwise[MAX_NEIGHBORS];  // 1. TODO: make it a local variable
	//uint8_t neighborsClockwiseSize; // 1. TODO: make it a local variable
	// 2. TODO: remember my left and right neighbor
	neighbor_t boundHoleStarter;
	bool isBusy = FALSE;
	bool stuckNode = FALSE;
	bool boundHoleFinished = FALSE; // improvement: it should be an array for adjacent holes.
	bool isBoundary = FALSE;
	message_t msgCtlPkt;
	uint16_t prevOfVisited[MAX_SHARING_HOLES];
	uint16_t visitedNodes[MAX_SHARING_HOLES];
	uint16_t largestVisited = 0;
	uint16_t visitedOriginators[MAX_BOUNDARY_NODES];
	uint16_t visitedOriginatorsSeq[MAX_BOUNDARY_NODES];
	uint16_t visitedOriginatorsSize = 0;
	//uint16_t a, b, c, d; // DEBUG
	//int16_t e; // DEBUG
	//uint16_t loopCnt = 0; // DEBUG
	location_t discoveredVertices[MAX_VERTICES];
    uint16_t numRetransmit = 0;

#ifdef LOG
	error_t Dbg(char *fmt, ...)	{
 		error_t t;
		DEBUG_START;
		t = call DEBUG_OUT;
		DEBUG_END;
		return t;
	}
#endif	
	
	bool hasIdAsNeighbor(uint16_t id)
	{
		uint16_t i;
		point_t neiRight;
		neighbor_t* neighborsCClockwise = NULL;
		uint8_t neighborsClockwiseSize;
		
		neighborsClockwiseSize = call Neighborhood.GetNeighborSize();
		neighborsCClockwise = call Neighborhood.GetNeighbor();
		for (i = 0; i < MAX_NEIGHBORS; i++)
		{
			if (neighborsCClockwise[i].m_id == id)
			{
				neiRight.x = neighborsCClockwise[i].m_location.x;
				neiRight.y = neighborsCClockwise[i].m_location.y;
				//if (!inForbiddenRegion(neiRight, prevLocs))
					return TRUE;
			}
		}
		return FALSE;
	}
	
	bool originatorAlreadyVisited(uint16_t originatorId, uint16_t originatorSeq)
	{
		uint16_t i;
		
		for (i = 0; i < visitedOriginatorsSize; i++)
		{
			dbg("BoundaryDetection", "visited originator: %d seq: %d recvdSeq: %d\n", visitedOriginators[i], visitedOriginatorsSeq[i], originatorSeq);
			//Dbg("visited originator: %d seq: %d recvdSeq: %d\n", visitedOriginators[i], visitedOriginatorsSeq[i], originatorSeq);
			if ((visitedOriginators[i] == originatorId) && (originatorSeq - visitedOriginatorsSeq[i] < 3))
			{
				return TRUE;
			}	
		}	
		return FALSE;
	}
	
	
	
	bool applyTentRule(void)
	{
		bool isStuckNode = FALSE;
		uint16_t i;
		int16_t angle;
		point_t myLoc, neiLeft, neiRight;
		neighbor_t* neighborsCClockwise = NULL; 
		uint8_t neighborsClockwiseSize;
		
		neighborsClockwiseSize = call Neighborhood.GetNeighborSize();
		neighborsCClockwise = call Neighborhood.GetNeighbor();
		myLoc.x = (call Identity.getMyLoc()).x;
		myLoc.y = (call Identity.getMyLoc()).y;
		for (i = 0; i < neighborsClockwiseSize; i++)
		//TODO: Verify for (i = 0; i <= neighborsClockwiseSize; i++)
		{
			neiLeft.x = (float)neighborsCClockwise[i].m_location.x;
			neiLeft.y = (float)neighborsCClockwise[i].m_location.y;
			if (neighborsClockwiseSize == i+1)
			{
				neiRight.x = (float)neighborsCClockwise[0].m_location.x;
				neiRight.y = (float)neighborsCClockwise[0].m_location.y;
			}
			else
			{
				neiRight.x = (float)neighborsCClockwise[i+1].m_location.x;
				neiRight.y = (float)neighborsCClockwise[i+1].m_location.y;
			}
			angle = call GeometrySupport.getAngleABC(neiLeft, myLoc, neiRight);
			dbg("BoundaryDetection", "angle: %d\n", angle);
			//Dbg("angle: %d\n", angle);
			if (angle >= 120)
			{
				boundHoleStarter = neighborsCClockwise[i];
				isStuckNode = TRUE;	
			}
		}	
		return isStuckNode;
	}
	
	void startBoundHole()
	{
		controlPktBoundHole_t* ctlPkt;
		neighbor_t nextNeighbor;
		point_t prevLocs[PREV_LOC_REF_SIZE];
		uint16_t i;
		location_t myLoc;
		
		myLoc = call Identity.getMyLoc();
		// initialize prevLocs
		for (i = 0; i < PREV_LOC_REF_SIZE; i++)
		{
			prevLocs[i].x = 0.0f;
			prevLocs[i].y = 0.0f;
		}
		prevLocs[0].x = boundHoleStarter.m_location.x;
		prevLocs[0].y = boundHoleStarter.m_location.y;
		if (isBusy == FALSE)
		{
			ctlPkt = (controlPktBoundHole_t*) call Packet.getPayload(&msgCtlPkt,
				sizeof(controlPktBoundHole_t));
			nextNeighbor = call Neighborhood.getNextNeighborRightHand(prevLocs);
			for (i = 0; i < MAX_PREV_LOCS; i++)
			{
				ctlPkt->prevLocs[i].x = 0;
				ctlPkt->prevLocs[i].y = 0;
                        }
			ctlPkt->id = TOS_NODE_ID;
			ctlPkt->originatorLeftId = boundHoleStarter.m_id;
			ctlPkt->originatorId = TOS_NODE_ID;
			ctlPkt->originatorRightId = nextNeighbor.m_id;
			ctlPkt->nextNeiId = nextNeighbor.m_id;
			ctlPkt->location.x = myLoc.x;
			ctlPkt->location.y = myLoc.y;
			ctlPkt->prevLocs[0].x = myLoc.x;
			ctlPkt->prevLocs[0].y = myLoc.y;
			ctlPkt->prevLocs[1].x = boundHoleStarter.m_location.x;
			ctlPkt->prevLocs[1].y = boundHoleStarter.m_location.y;
			ctlPkt->seqNum = 0;
			for (i = 0; i < MAX_VERTICES; i++)
			{
				ctlPkt->vertices[i].x = 0;
				ctlPkt->vertices[i].y = 0;
			}
			call controlPktAck.requestAck(&msgCtlPkt);
			#ifdef LOG
            call CC2420Packet.setPower(&msgCtlPkt, TX_POWER);
            #endif
			if (call controlPktSend.send(nextNeighbor.m_id, &msgCtlPkt, 
					sizeof(controlPktBoundHole_t)) == SUCCESS)
			{
				isBusy = TRUE;
			}
		}
	}

	// This is the core function of the abstraction process.
	// based on previous nodes, and DELTA, determine if the given location is a vertex or not.
	bool isVertex(point_t* prevLocs, point_t* vertices, location_t queryLoc)
	{
		int16_t i,j;
		int16_t startIdx = -1;
		point_t ptsForTest[MAX_PREV_LOCS+2];
		float epsilon = 0.00001f;
		location_t myLoc;
		float leastSquare;
	
                for (i = 0; i < MAX_PREV_LOCS+2; i++)
                {
                	ptsForTest[i].x = 0;
                	ptsForTest[i].y = 0;
                }
		myLoc = call Identity.getMyLoc();
		// first get the most recent vertex, so we can know where to start in the pervLocs list.
		for (i = 0; i < MAX_VERTICES; i++)
		{
			dbg("BoundaryDetection", "i in loop1: %d\n", i);
			if (vertices[i].x < epsilon && vertices[i].y < epsilon)
				break;	
		}
		dbg("BoundaryDetection", "i for check: %d\n", i);
		if (i != 0) // there are at least one vertices. find the starting index for the prevLocs list.
		{
			for (j = 0; j < PREV_LOC_REF_SIZE; j++)
			{
				if ((fabs(prevLocs[j].x - vertices[i-1].x) < epsilon) && (fabs(prevLocs[j].y - vertices[i-1].y) < epsilon))
				{
					startIdx = j;
					break;
				}
			}
		}
		dbg("BoundaryDetection", "startIdx: %d\n", startIdx);
		if (startIdx >= 0) // vertex present, consider all prev locs after the vertex
		{
			//set up the points for test
			for (i = startIdx, j = 0; i >= 0; i--)
			{
				dbg("BoundaryDetection", "i in loop2: %d\n", i);
				//if (prevLocs[i].x < epsilon && prevLocs[i].y < epsilon)
				//	break;
				ptsForTest[j].x = prevLocs[i].x;
				ptsForTest[j].y = prevLocs[i].y;
                                ++j;	
			}
			ptsForTest[j].x = myLoc.x;
			ptsForTest[j].y = myLoc.y;
			ptsForTest[j+1].x = queryLoc.x;
			ptsForTest[j+1].y = queryLoc.y;
			leastSquare = call GeometrySupport.leastSqrRegression(ptsForTest, j+2);
		}
		else { // no vertex present -> consider all prev locs in a buffer
			for (i = 0, j = 0; i < PREV_LOC_REF_SIZE; i++)
			{
				if (prevLocs[i].x < epsilon && prevLocs[i].y < epsilon)
				{
					j--;
					break;
				}
				ptsForTest[j].x = prevLocs[i].x;
				ptsForTest[j].y = prevLocs[i].y;
                                ++j;
			}
			ptsForTest[j].x = myLoc.x;
			ptsForTest[j].y = myLoc.y;
			ptsForTest[j+1].x = queryLoc.x;
			ptsForTest[j+1].y = queryLoc.y;
			leastSquare = call GeometrySupport.leastSqrRegression(ptsForTest, j+2);
		}

		// now perform linear regression! to find if the queryLoc deviates too much from a expected line
		//call GeometrySupport.leastSqrRegression(ptsForTest, j);
		
		for (i = 0; i < j+2; i++)
		{
			dbg("BoundaryDetection", "ptsForTest[%d]: %f %f \n", i, ptsForTest[i].x, ptsForTest[i].y);
			//Dbg("(%d %d)\n", i, ptsForTest[i].x, ptsForTest[i].y);
		}
		// for test
		/*
		for (i = 0; i < MAX_PREV_LOCS; i++)
		{
			if (prevLocs[i].x == 0 && prevLocs[i].y == 0)
				break;
			ptsForTest[i].x = prevLocs[i].x;
			ptsForTest[i].y = prevLocs[i].y;
		}
		ptsForTest[j].x = queryLoc.x;
		ptsForTest[j].y = queryLoc.y;
		*/
		//Dbg("Least Square: %d", leastSquare * 10000);
		if (leastSquare > STD_DEV_THRESHOLD)
			return TRUE;
		return FALSE;
	}

	bool visited(controlPktBoundHole_t* rcvdCtlPkt)
	 {	
	 	 uint16_t i;
	 	 
	 	 for (i = 0; i < MAX_SHARING_HOLES; i++)
	 	 {
	 	 	if (prevOfVisited[i] == rcvdCtlPkt->id && visitedNodes[i] > rcvdCtlPkt->originatorId)
	 	 	{
	 	 		return TRUE;
	 	 	}	
	 	 	if (prevOfVisited[i] == rcvdCtlPkt->id)
	 	 	{
	 	 		visitedNodes[i] = rcvdCtlPkt->originatorId;
	 	 		return FALSE;
	 	 	}	
	 	 	if (prevOfVisited[i] == 0)  // end
	 	 	{
	 	 		break;
	 	 	}
	 	 }	
	 	 prevOfVisited[i] = rcvdCtlPkt->id;
	 	 visitedNodes[i] = rcvdCtlPkt->originatorId;
	 	 return FALSE;
	 }
	 
/************************************ TASKS *********************************************************/
	task void retransmitPkt()
	{
		controlPktBoundHole_t* ctlPkt;

                retxCnt++;
		ctlPkt = (controlPktBoundHole_t*) call Packet.getPayload(&msgCtlPkt,
				sizeof(controlPktBoundHole_t));
		call controlPktAck.requestAck(&msgCtlPkt);
		#ifdef LOG
        call CC2420Packet.setPower(&msgCtlPkt, TX_POWER);
        #endif
		call controlPktSend.send(ctlPkt->nextNeiId, &msgCtlPkt, sizeof(controlPktBoundHole_t));	
	}
	
	task void processCtlPkt()
	{
		controlPktBoundHole_t* rcvdCtlPkt;
	 	controlPktBoundHole_t* outgoingCtlPkt;
	 	neighbor_t nextNeighbor, newNeighbor;
	 	message_t msg;
	 	uint16_t i;
	 	point_t prevLocs[PREV_LOC_REF_SIZE]; // for nx_location_t to point_t conversion.
	 	point_t vertices[MAX_VERTICES]; // for nx_location_t to point_t conversion.
		neighbor_t* neighborsCClockwise = NULL;
		uint8_t neighborsClockwiseSize;
		location_t myLoc;
		uint16_t queueSize;
		
		myLoc = call Identity.getMyLoc();
		neighborsClockwiseSize = call Neighborhood.GetNeighborSize();
		neighborsCClockwise = call Neighborhood.GetNeighbor();
		/////////////////////////////////////////////////////////////////////////////////////////////
	 	atomic
	 	{
	 		queueSize = call ctlPktQueue.size();
	 		if (queueSize > 0)
	 		{
	 			msg = call ctlPktQueue.element(0);
	 			rcvdCtlPkt = (controlPktBoundHole_t*) call Packet.getPayload(&msg, sizeof(controlPktBoundHole_t));
	 			outgoingCtlPkt = (controlPktBoundHole_t*) call Packet.getPayload(&msgCtlPkt,
							sizeof(controlPktBoundHole_t));
				// make some local copies -- i.e., location_t to point_t -- be careful...
				for (i = 0; i < PREV_LOC_REF_SIZE; i++)
				{
					prevLocs[i].x = rcvdCtlPkt->prevLocs[i].x;
					prevLocs[i].y = rcvdCtlPkt->prevLocs[i].y;
				}
				for (i = 0; i < MAX_VERTICES; i++)
				{
					vertices[i].x = rcvdCtlPkt->vertices[i].x;
					vertices[i].y = rcvdCtlPkt->vertices[i].y;
				}
				if (hasIdAsNeighbor(rcvdCtlPkt->id))
				{	
					nextNeighbor = call Neighborhood.getNextNeighborRightHand(prevLocs);
				}
				else
				{
					// special treatment! - in case this node does not have the sender in its neighbor table.
					//                      Although we prevent this situation by ensuring enough time to 
					//                      find only neighbors with symmetric links. But this situation 
					//                      can still happen with a low probability.
					newNeighbor.m_location.x = rcvdCtlPkt->location.x;
					newNeighbor.m_location.y = rcvdCtlPkt->location.y;
					newNeighbor.m_id = rcvdCtlPkt->id;
					newNeighbor.firstSeq = 0;
					newNeighbor.lastSeq = 0;
					newNeighbor.numRcvdPkts = 0;
					//newNeighbor.pdr = 0;
					call Neighborhood.addNeighbor(newNeighbor);
					call Neighborhood.sortNeighborsCounterClockwise();
					//for (i = 0; i < neighborSize; i++)
					//{
					//	dbg("BoundaryDetection", "New Neighbors: %d\n", neighbors[i].m_id);
					//}
					//sortNeighborsCounterClockwise(neighbors, neighborSize);
					nextNeighbor = call Neighborhood.getNextNeighborRightHand(prevLocs);
				}
				// If this node has the originator as its neighbor, and satisfies the 
				// forbidden region constraint, forward the packet to the originator.
				//if (hasIdAsNeighbor(rcvdCtlPkt->originatorId) && rcvdCtlPkt->seqNum > 2)
				//{
				//	nextNeighbor.m_id = rcvdCtlPkt->originatorId;
				//}
				// end of New code
				outgoingCtlPkt->id = TOS_NODE_ID;
				outgoingCtlPkt->originatorLeftId = rcvdCtlPkt->originatorLeftId;
				outgoingCtlPkt->originatorId = rcvdCtlPkt->originatorId;
				outgoingCtlPkt->originatorRightId = rcvdCtlPkt->originatorRightId;
				outgoingCtlPkt->nextNeiId = nextNeighbor.m_id;
				outgoingCtlPkt->location.x = myLoc.x;
				outgoingCtlPkt->location.y = myLoc.y;
				outgoingCtlPkt->prevLocs[0].x = myLoc.x;
				outgoingCtlPkt->prevLocs[0].y = myLoc.y;
				// the core of the hole abstraction!!!
				// see if this node is a vertex node or not.
				if (isVertex(prevLocs, vertices, nextNeighbor.m_location))
				{
					//dbg("BoundaryDetection", "%d is a vertex node!\n", TOS_NODE_ID);
					// find insertion point of the vertices field of the received packet.
					// and insert the new vertex.
					for (i = 0; i < MAX_VERTICES; i++)
					{
						if (rcvdCtlPkt->vertices[i].x == 0 && rcvdCtlPkt->vertices[i].y == 0)
						{
							//call Leds.led2On();
							dbg("BoundaryDetection", "New vertice inserted at %d th slot\n", i);
							//Dbg("New vertice inserted at %d th slot\n", i);
							rcvdCtlPkt->vertices[i].x = myLoc.x;
							rcvdCtlPkt->vertices[i].y = myLoc.y;
							break;
						}
					}	
				}
				// copy the field of the received packet to the outgoing packet.
				for (i = 0; i < PREV_LOC_REF_SIZE - 1; i++)
				{
					outgoingCtlPkt->prevLocs[i+1].x = rcvdCtlPkt->prevLocs[i].x;
					outgoingCtlPkt->prevLocs[i+1].y = rcvdCtlPkt->prevLocs[i].y;
				}
				for (i = 0; i < MAX_VERTICES; i++)
				{
					outgoingCtlPkt->vertices[i].x = rcvdCtlPkt->vertices[i].x;
					outgoingCtlPkt->vertices[i].y = rcvdCtlPkt->vertices[i].y;
				}
				outgoingCtlPkt->seqNum = rcvdCtlPkt->seqNum + 1;
				call controlPktAck.requestAck(&msgCtlPkt);
				// improvement: address the issue of packet received in the middle of transmission -- addressed.
                #ifdef LOG
                call CC2420Packet.setPower(&msgCtlPkt, TX_POWER); 
                #endif
				if (call controlPktSend.send(nextNeighbor.m_id, &msgCtlPkt, 
						sizeof(controlPktBoundHole_t)) == SUCCESS)
				{
					isBusy = TRUE;
				}		
	 		}
	 		else
	 		{
	 			dbg("BoundaryDetection", "ctlPktQueue empty!\n");
	 		}
	 	} 		
	 	
	}


/************************************ COMMANDS *********************************************************/

	/*************************************************************************
	 * initBoundaryDetection
	 * description: This command initiates the boundary detection procedure. 
	 * This command is called by an application when the neighbor discovery is finished.
	 * This command uses the 1-hop neighbor information, i.e., the link quality and the location of a neighbor.
	 * Basically, what it does it to run the TENT and BOUNDHOLE algorithm to find the chain of boundary nodes.
	 */
	 command error_t BoundaryDetection.initBoundaryDetection(uint8_t delta)
	 {

		uint16_t neighborSize = 0;
		neighbor_t * neighbors = NULL;
		uint16_t i;
		
		//call Leds.led0Off();
		//call Leds.led1Off();
		//call Leds.led2Off();
		
		call QueueChecker.startPeriodic(1000);
		call DisseminationControl.start();
		//i = 5;
		//if (TOS_NODE_ID == 1)
		//	call Update.change(&i);
	 	//for (i = 0; i < MAX_NEIGHBORS; i++)
	 	//{
	 	//	neighborsCClockwise[i].m_location.x = -1;
	 	//	neighborsCClockwise[i].m_location.y = -1;
	 	//}
	 	//call Neighborhood.sortNeighborsCounterClockwise();
	 	neighborSize = call Neighborhood.GetNeighborSize();
		neighbors = call Neighborhood.GetNeighbor();
		for (i = 0; i < neighborSize; i++)
		// TODO: verify for (i = 0; i <= neighborSize; i++)
		{
			dbg("BoundaryDetection", "Neighbors: %d\n", neighbors[i].m_id);
			//Dbg("Neighbors: %d\n", neighbors[i].m_id);
		}
		// sort the neighbors in a clockwise order and save them in 
		// neighborsClockwise data structure.
		
		if (applyTentRule())
		{
			stuckNode = TRUE;
			dbg("BoundaryDetection", "is a stuck node\n");
			//call Leds.led0On();
			startBoundHole();
			return SUCCESS;
		}
		else
		{
			dbg("BoundaryDetection", "is not a stuck node\n");
		}
	 	return SUCCESS;
	 }
	 
	 command void BoundaryDetection.Init()
	 {
	 	uint16_t i;
	 	boundHoleStarter.m_location.x = 0;
	 	boundHoleStarter.m_location.y = 0;
	 	boundHoleStarter.m_id = 0;
		isBusy = FALSE;
		stuckNode = FALSE;
		isBoundary = FALSE;
		boundHoleFinished = FALSE; // improvement: it should be an array for adjacent holes.
		for (i = 0; i < MAX_SHARING_HOLES; i++)
		{
			prevOfVisited[i] = 0;
			visitedNodes[i] = 0;
		}
		largestVisited = 0;
		for (i = 0; i < MAX_BOUNDARY_NODES; i++)
		{
			visitedOriginators[i] = 0;
			visitedOriginatorsSeq[i] = 0;
		}
		visitedOriginatorsSize = 0;
		//loopCnt = 0; // DEBUG
                retxCnt = 0;
	 }
	 
	 /**********************************************************************
	  * isBoundaryNode
	  * description: just returns true if this node is a boundary node.
	  */
	 command bool BoundaryDetection.isBoundaryNode()
	 {
	 	return isBoundary;
	 }

	 command location_t* BoundaryDetection.getVertices()
	 {
	 	return discoveredVertices;
	 }
/************************************ EVENTS *********************************************************/

	 event void controlPktSend.sendDone(message_t *msg, error_t error){
	 	 bool wasAcked = FALSE;
	 	 
		 controlPktBoundHole_t* ctlPkt;
		 ctlPkt = (controlPktBoundHole_t*) call Packet.getPayload(msg,
				 sizeof(controlPktBoundHole_t));
		 wasAcked = call controlPktAck.wasAcked(msg);
		 if (wasAcked)
		 {
			 dbg("BoundaryDetection", "sent a control pakcet to %d.\n", ctlPkt->nextNeiId);
#ifdef LOG
			 Dbg("sent a control pakcet to %d.\n", ctlPkt->nextNeiId);
#endif
			 atomic {
			 	call ctlPktQueue.dequeue();
			 } 
			 isBusy = FALSE;
             numRetransmit = 0;
		 }
		 else
		 {
			 dbg("BoundaryDetection", "retransmitted a control pakcet to %d.\n", ctlPkt->nextNeiId);
			 //Dbg("retransmitted a control pakcet to %d.\n", ctlPkt->nextNeiId);
			 // retransmit
			 numRetransmit++;
			 if (numRetransmit < MAX_RETX)
			 {
				 post retransmitPkt();	
			 }
			 else
			 {
			 	 atomic {
			 	 	call ctlPktQueue.dequeue();
			 	 } 
				 numRetransmit = 0;
			 }
		 }
	 }
	 
	 event message_t * controlPktReceive.receive(message_t *msg, void *payload, uint8_t len){
		 controlPktBoundHole_t* rcvdCtlPkt;
		 message_t msgCopy;
		 uint16_t i;
		 uint8_t neighborsClockwiseSize;
		 location_t myLoc;
		 uint16_t queueSize, queueMax;
		 
		 isBoundary = TRUE;
		 myLoc = call Identity.getMyLoc();
		 neighborsClockwiseSize = call Neighborhood.GetNeighborSize();
		 rcvdCtlPkt = (controlPktBoundHole_t*) call Packet.getPayload(msg, sizeof(controlPktBoundHole_t));
		 dbg("BoundaryDetection", "received a control pakcet from %d (originator: %d).\n", rcvdCtlPkt->id, rcvdCtlPkt->originatorId);
#ifdef LOG
		 Dbg("received a control pakcet from %d (originator: %d).\n", rcvdCtlPkt->id, rcvdCtlPkt->originatorId);
#endif
		 // if the neighbor table is not ready, drop the packet.
		 if (neighborsClockwiseSize == 0)
		 {
			 return msg;
		 }
		 //if ((TOS_NODE_ID > rcvdCtlPkt->originatorId) && stuckNode)
		 //{
		 //	return msg;
		 //}	
		 if (visited(rcvdCtlPkt)) // better algorithm for reducing the number of ctl packets
		                          // than the swallowing-based one.
		 {
		 	return msg;
		 }
		 if (originatorAlreadyVisited(rcvdCtlPkt->originatorId,rcvdCtlPkt->seqNum))
		 {
		 	return msg;
		 }
		 else
		 {
		 	visitedOriginators[visitedOriginatorsSize] = rcvdCtlPkt->originatorId;
			visitedOriginatorsSeq[visitedOriginatorsSize] = rcvdCtlPkt->seqNum;
			visitedOriginatorsSize++;
		 }
		 if (rcvdCtlPkt->seqNum > MAX_TTL)
		 {
		 	return msg;	
		 }
		 else
		 {
		 	 if (largestVisited == 0)
		 	 	largestVisited = TOS_NODE_ID;
			 // terminating condition for the BOUND HOLE algorithm.
			 //if (((rcvdCtlPkt->originatorId == TOS_NODE_ID) || (rcvdCtlPkt->originatorLeftId == TOS_NODE_ID) || (rcvdCtlPkt->originatorRightId == TOS_NODE_ID)) && rcvdCtlPkt->seqNum > 2) 
			 if (rcvdCtlPkt->originatorId == largestVisited && rcvdCtlPkt->seqNum > 2) 
			 {
				 // BOUNDHOLE done
				 if (!boundHoleFinished)
				 {
				 	 //call Leds.led2On();
					 dbg("BoundaryDetection", "finished the BOUNDHOLE. Hole size: %d\n", rcvdCtlPkt->seqNum);
					 //Dbg("finished the BOUNDHOLE. Hole size: %d\n", rcvdCtlPkt->seqNum);
					 // print vertices for debug
					 for (i = 0; i < MAX_VERTICES; i++)
					 {
					 	if (rcvdCtlPkt->vertices[i].x == 0 && rcvdCtlPkt->vertices[i].y == 0)
					 		break;
					 	dbg("BoundaryDetection", "vertex: %d %d\n", rcvdCtlPkt->vertices[i].x, rcvdCtlPkt->vertices[i].y);	
					 	//Dbg("vertex: %d %d\n", rcvdCtlPkt->vertices[i].x, rcvdCtlPkt->vertices[i].y);	
					 	discoveredVertices[i].x = rcvdCtlPkt->vertices[i].x;
					 	discoveredVertices[i].y = rcvdCtlPkt->vertices[i].y;
					 }
					 dbg("BoundaryDetection", "vertex: %d %d\n", myLoc.x, myLoc.y);	
					 //Dbg("vertex: %d %d\n", myLoc.x, myLoc.y);	
					 discoveredVertices[i].x = myLoc.x;
					 discoveredVertices[i].y = myLoc.y;
					 // TODO: save vertices and broadcast the vertices
					 boundHoleFinished = TRUE;
				 }
				 return msg;
			 }
			 else
			 {
			 	 if (rcvdCtlPkt->originatorId > largestVisited)
			 	 	largestVisited = rcvdCtlPkt->originatorId;
				 atomic
				 {
				 	 queueSize = call ctlPktQueue.size(); queueMax = call ctlPktQueue.maxSize();
					 if (queueSize >= queueMax)
					 {
						 dbg("BoundaryDetection", "Control Packet queue is full! Message is dropped!\n");
						 return msg;
					 }
					 memcpy(&msgCopy, msg, sizeof(message_t));
					 call ctlPktQueue.enqueue(msgCopy);
				 }
				 post processCtlPkt();
			 }
		 }
		 return msg;
	 }
 
 	// periodically check the tx queue and process unprocessed packets.
 	event void QueueChecker.fired(){
 		uint16_t queueSize;
 		atomic {
 			queueSize = call ctlPktQueue.size();
 			if (queueSize > 0)
 			{
 				dbg("BoundaryDetection", "processing non-empty queue\n");
 				//Dbg("processing non-empty queue\n");
 				if (!isBusy)
 					post processCtlPkt();
 			}
 		}
 	}
 	
 	event void Value.changed() {
 		//const uint16_t* newVal;
 		//newVal = call Value.get();
    	//dbg("BoundaryDetection", "Floood: id %d, value %d\n", TOS_NODE_ID, *newVal);
    }
  
#ifdef LOG
 	event void Debug.recvByte(uint8_t *str, uint16_t len){
		
	}	
	
	event void LogWrite.appendDone(void *buf, storage_len_t len, bool recordsLost, error_t error){
		
	}

	event void LogWrite.eraseDone(error_t error){
		
	}

	event void LogWrite.syncDone(error_t error){
		
	}

	event void LogRead.seekDone(error_t error){
		
	}

	event void LogRead.readDone(void *buf, storage_len_t len, error_t error){
		
	}
#endif
}
