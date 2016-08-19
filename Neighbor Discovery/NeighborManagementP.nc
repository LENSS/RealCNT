/**
 * Implementation of NeighborManagement module
 * Author: Myounggyu Won
 */

#include "NeighborManagement.h"

module NeighborManagementP
{
	provides interface Neighborhood;

	uses interface AMSend as KeepAliveSend;
	uses interface Receive as KeepAliveReceive;
	uses interface Timer<TMilli> as KeepAliveTimer;
	uses interface Timer<TMilli> as SymmetricLinkTimer;
	uses interface Queue<message_t*> as QueueReceive;
	//uses interface Pool<message_t> as MessagePool;
	uses interface Packet;
	uses interface GeometrySupport;
	uses interface Identity;
	uses interface Leds;
	#ifdef LOG
    uses interface CC2420Packet;
    #endif
}

implementation
{
	//#include "20_by_20_loc.txt"
	// where is a free slot for a neighbor?
	uint8_t m_freeNeighborPtr = 0;

	// neighbor information table
	neighbor_t m_neighbors[MAX_NEIGHBORS];

	// for keep alive messages
	message_t m_keepAlivePacket;

	bool m_isBusy = FALSE;

	uint16_t seqNum = 0;
	uint16_t x,y;
	float maxLinkQuality;
	bool symmetricLinkDiscovery = FALSE;
	
	void SendKeepAliveMsg();
  
    location_t ToLocation(nx_location_t p_location)
	{
		location_t tmp;

		tmp.x = p_location.x;
		tmp.y = p_location.y;

		return tmp;
	}
    
    command void Neighborhood.Init(void)
    {
    	uint16_t i;
    	
    	m_freeNeighborPtr = 0;
	    m_isBusy = FALSE;
		seqNum = 0;
		x = 0;
		y = 0;
		maxLinkQuality = 0.0f;
	    symmetricLinkDiscovery = FALSE;
	    for (i = 0; i < MAX_NEIGHBORS; i++)
	    {
	    	m_neighbors[i].m_location.x = 0;
	    	m_neighbors[i].m_location.y = 0;
	    	m_neighbors[i].m_id = 0;
	    	m_neighbors[i].firstSeq = 0;
	    	m_neighbors[i].lastSeq = 0;
	    	m_neighbors[i].numRcvdPkts = 0;
	    	//m_neighbors[i].pdr = 0.0f;
	    }
    }
    
    command uint8_t Neighborhood.GetNeighborSize()
    {
    	return m_freeNeighborPtr;
    }
    
    command neighbor_t* Neighborhood.GetNeighbor()
    {
    	return m_neighbors;
    }
    
	// starting neighbor discovery by starting the keep alive sending timer
	command void Neighborhood.startDiscovery(uint16_t x_, uint16_t y_, float maxLinkQuality_, uint16_t neighborDiscoveryPeriod)
	{
		dbg("NeighborManagement", "Neighbor Discovery Started\n", TOS_NODE_ID);
		x = x_; y = y_;
		maxLinkQuality = maxLinkQuality_;
		SendKeepAliveMsg();
		call KeepAliveTimer.startPeriodic(neighborDiscoveryPeriod);	
	}

	command void Neighborhood.stopDiscovery()
	{
		// leave only neighbors with good pdrs.
		call Neighborhood.UpdateNeighborlist(maxLinkQuality);		
		// leave only symmetric links
		call SymmetricLinkTimer.startOneShot(SYM_LINK_DISCOVERY_DURATION);  // for 3 mins. - set as a parameter!
		symmetricLinkDiscovery = TRUE;
	}
	
	// updating neighbor information table
	command void Neighborhood.UpdateNeighborlist(float maxLinkQuality_)
	{
		uint8_t i, j;
		float pdr;

		atomic
		{
			for (i = 0; i < m_freeNeighborPtr; i++)
			{
				// if the neighbor's pdr is smaller than the maxLinkQuality, delete the neighbor.
				pdr = (float) m_neighbors[i].numRcvdPkts / (float) (m_neighbors[i].lastSeq - m_neighbors[i].firstSeq + 1);
				if (pdr < maxLinkQuality_ - 1.0f)
				{
					for (j = i; j < m_freeNeighborPtr - 1; j++)
					{
						m_neighbors[j] = m_neighbors[j+1];
					}
					m_freeNeighborPtr--;
				}
			}
		}
	}

	// retrieving a particular neighbor (e.g., for nested loops)
	command neighbor_t* Neighborhood.GetSpecNeighbor(uint8_t p_num)
	{
		atomic
		{
			if (p_num < m_freeNeighborPtr)
				return &m_neighbors[p_num];
		}
		return NULL;
	}

	// retrieving a neighbor who has id p_node
	command neighbor_t* Neighborhood.GetNeighborById(uint16_t p_node)
	{
		uint8_t i = 0;
		neighbor_t* neighbor = NULL;

		atomic
		{
			// Someone else may use GetNeighbor()
			while ( (neighbor = call Neighborhood.GetSpecNeighbor(i++)) != NULL )
			{
				if (p_node == neighbor->m_id)
					return neighbor;
			}
		}
		return NULL;
	}

	bool alreadySelected(neighbor_t* neighborsCClockwise, point_t loc)
	{
		uint8_t i;
		
		for (i = 0; i < MAX_NEIGHBORS; i++)
		{
			if ((neighborsCClockwise[i].m_location.x == loc.x) &&
			    (neighborsCClockwise[i].m_location.y == loc.y))
			{
				return TRUE;
			}
		}
		return FALSE;
	}
	
	command void Neighborhood.addNeighbor(neighbor_t newNeighbor) 
	{
		m_neighbors[m_freeNeighborPtr] = newNeighbor;
		if (m_freeNeighborPtr < MAX_BUFFER - 1) {
			m_freeNeighborPtr++;
		}
		//call Neighborhood.sortNeighborsCounterClockwise();
	}
	
	command void Neighborhood.sortNeighborsCounterClockwise() {
		point_t myLoc;
		uint16_t i, j, k, idx;
		int16_t angle;
		point_t neiLeft, neiRight;
		int16_t maxAngle = 360;
		neighbor_t neighborsCClockwise[MAX_NEIGHBORS];
		location_t myLoc_;
		
		myLoc_ = call Identity.getMyLoc();
		myLoc.x = (float)myLoc_.x;
		myLoc.y = (float)myLoc_.y;
		k = m_freeNeighborPtr;
		j = 0;
		for (i = 0; i < MAX_NEIGHBORS; i++)
	 	{
	 		neighborsCClockwise[i].m_location.x = -1;
	 		neighborsCClockwise[i].m_location.y = -1;
	 	}
		neighborsCClockwise[0] = m_neighbors[0];
		while (k > 0)
		{
			for (i = 0; i < m_freeNeighborPtr; i++)
			{
				// Improvement: rename neiLeft and neiRight! - confusing!
				neiLeft.x = (float)neighborsCClockwise[j].m_location.x;
				neiLeft.y = (float)neighborsCClockwise[j].m_location.y;
				neiRight.x = (float)m_neighbors[i].m_location.x;
				neiRight.y = (float)m_neighbors[i].m_location.y;
				angle = call GeometrySupport.getAngleABC(neiLeft, myLoc, neiRight);	
				// already selected?
				if (alreadySelected(neighborsCClockwise, neiRight))
					continue;
				//dbg("BoundaryDetection", "angle: %d\n", angle);
				if ((angle < maxAngle && angle > 0) || angle == 0)
				{
					maxAngle = angle;	
					idx = i;
				}
			}
			//dbg("BoundaryDetection", "max angle: %d idx: %d\n", maxAngle, idx);
			//dbg("BoundaryDetection", "neighbors[i]: %d\n", neighbors[idx].m_id);
			neighborsCClockwise[++j] = m_neighbors[idx];
			idx = 0; maxAngle = 360; k--;
		}
		memcpy(m_neighbors, neighborsCClockwise, sizeof(neighbor_t) * MAX_NEIGHBORS);
		//neighborsClockwiseSize = m_freeNeighborPtr;
		// debug
		for (i = 0; i < m_freeNeighborPtr; i++)
		{
			dbg("BoundaryDetection", "clockwise neighbor id: %d\n", neighborsCClockwise[i].m_id);
		}
	}
	
	command void Neighborhood.deleteNeighborByID(uint16_t id)
	{
		uint8_t i, j;
		
		atomic
		{
			for (i = 0; i < m_freeNeighborPtr; i++)
			{
				if (m_neighbors[i].m_id == id)
				{
					for (j = i; j < m_freeNeighborPtr - 1; j++)
					{
						m_neighbors[j] = m_neighbors[j+1];
					}
					m_freeNeighborPtr--;
				}
			}
		}
	}
	
	command void Neighborhood.deleteNeighborByLoc(uint16_t x_, uint16_t y_)
	{
		uint8_t i, j;
		
		atomic
		{
			for (i = 0; i < m_freeNeighborPtr; i++)
			{
				if (m_neighbors[i].m_location.x == x_ && m_neighbors[i].m_location.y == y_)
				{
					for (j = i; j < m_freeNeighborPtr - 1; j++)
					{
						m_neighbors[j] = m_neighbors[j+1];
					}
					m_freeNeighborPtr--;
				}
			}
		}
	}
	
	bool inForbiddenRegion(point_t rightNei, point_t* prevLocs)
	{
		line_t lineseg;
		line_t line;
		point_t intersection, myLoc;//, originatorLoc;
		float epsilon = 0.00001f;
		uint16_t i;
		bool boola, boolb;
		location_t myLoc_;
		//uint16_t originatorId;
		
		boola = FALSE;
		boolb = FALSE;
		//originatorId = visitedOriginators[visitedOriginatorsSize - 1];
		//myLoc.x = (float)node_x[TOS_NODE_ID];
		//myLoc.y = (float)node_y[TOS_NODE_ID];
		//originatorLoc.x = (float)node_x[originatorId];
		//originatorLoc.y = (float)node_y[originatorId];
		myLoc_ = call Identity.getMyLoc();
		myLoc.x = myLoc_.x;
		myLoc.y = myLoc_.y;
		lineseg.start = myLoc; lineseg.end = rightNei; // we are to see if this line seg intersects with any previous edges
		for (i = 0; i < PREV_LOC_REF_SIZE - 1; i++)
		{
			if (prevLocs[i+1].x < epsilon && prevLocs[i+1].y < epsilon) // searched through all available preLocs.
				break;
			dbg("BoundaryDetection", "prevLocs[%d] %f %f, prevLocs[%d] %f %f\n", i, prevLocs[i].x, prevLocs[i].y, i+1, prevLocs[i+1].x, prevLocs[i+1].y);
			//Dbg("prevLocs[%d] %d %d, prevLocs[%d] %d %d\n", i, prevLocs[i].x, prevLocs[i].y, i+1, prevLocs[i+1].x, prevLocs[i+1].y);
			line.start = prevLocs[i]; line.end = prevLocs[i+1];
			intersection = call GeometrySupport.getIntersection(line, lineseg);
			// intersection should not be me, nor the originator!
			// take care here!!
			if (((fabs(intersection.x - myLoc.x) >= epsilon) || (fabs(intersection.y - myLoc.y) >= epsilon)))
			 //&& ((fabs(intersection.x - originatorLoc.x) >= epsilon) || (fabs(intersection.y - originatorLoc.y) >= epsilon))) 
			{
				dbg("BoundaryDetection", "Intersection: %f %f\n", intersection.x, intersection.y);
				//Dbg("Intersection: %f %f\n", intersection.x, intersection.y);
				boola = call GeometrySupport.isPointOnLineSegment(intersection, lineseg);
				boolb = call GeometrySupport.isPointOnLineSegment(intersection, line);
				//if (call GeometrySupport.isPointOnLineSegment(intersection, lineseg) && call GeometrySupport.isPointOnLineSegment(intersection, line))
				if (boola && boolb)
				{
					//loopCnt++;
					dbg("BoundaryDetection", "Forbidden region violated!\n");
					//Dbg("sec: %d %d !\n", intersection.x, intersection.y);
					return TRUE;
				}
			}
		}
		// no intersection with edges at all, thus not in a forbidden region.
		return FALSE;
	}
	
	command neighbor_t Neighborhood.getNextNeighborRightHand(point_t *prevLocs)
	{
		uint16_t i, j = 0;
		uint16_t cnt = 0;
		point_t neiLeft, neiRight, myLoc;
		neighbor_t* neighborsCClockwise = NULL;
		uint8_t neighborsClockwiseSize;
		location_t tmp;
		int16_t angle_;
		
		tmp.x = prevLocs[0].x;
		tmp.y = prevLocs[0].y;
		neighborsClockwiseSize = call Neighborhood.GetNeighborSize();
		neighborsCClockwise = call Neighborhood.GetNeighbor();
		myLoc.x = (call Identity.getMyLoc()).x;
		myLoc.y = (call Identity.getMyLoc()).y;
		for (i = 0; i < MAX_NEIGHBORS; i++)
		{
			if ((neighborsCClockwise[i].m_location.x == tmp.x) &&
			    (neighborsCClockwise[i].m_location.y == tmp.y))
			{
				j = i;
				break;
			}	
		}
		//a = j;
		i = j;
		//b = neighborsClockwiseSize;
		//Dbg("neighborsClockwiseSize %d\n", neighborsClockwiseSize);
		while (cnt < neighborsClockwiseSize)
		//TODO: Verify while (cnt <= neighborsClockwiseSize)
		{
			neiRight.x = neighborsCClockwise[i].m_location.x;
			neiRight.y = neighborsCClockwise[i].m_location.y;
			neiLeft.x = prevLocs[0].x;
			neiLeft.y = prevLocs[0].y;
			dbg("BoundaryDetection", "nextNei (i: %d)? ID: %d Loc: %d %d\n", i, neighborsCClockwise[i].m_id, neighborsCClockwise[i].m_location.x, neighborsCClockwise[i].m_location.y);
			//Dbg("nextNei (i: %d)? ID: %d Loc: %d %d\n", i, neighborsCClockwise[i].m_id, neighborsCClockwise[i].m_location.x, neighborsCClockwise[i].m_location.y);
			//Dbg("getAngle %d\n", call GeometrySupport.getAngleABC(neiLeft, myLoc, neiRight));
			//if (cnt == 0)
			//{
			//	c = (uint16_t)neiRight.x;
			//	d = (uint16_t)neiRight.y;
			//	e = call GeometrySupport.getAngleABC(neiLeft, myLoc, neiRight);
			//}
			angle_ = call GeometrySupport.getAngleABC(neiLeft, myLoc, neiRight);
			if ((angle_ == 0) || (inForbiddenRegion(neiRight, prevLocs)))
			{
				i++;
				if (i == neighborsClockwiseSize) i = 0; // make it circular back to 0
				//TODO: Verify if (i == (neighborsClockwiseSize+1)) i = 0; // make it circular back to 0
				cnt++;
				continue;
			}
			else
				break;
		}
		return neighborsCClockwise[i];
	}
	
	bool isAsymmetricLink(keep_alive_t* keepAliveMsg)
	{
		uint8_t i;
		
		for (i = 0; i < MAX_NEIGHBORS; i++)
		{
			if (keepAliveMsg->neiList[i] == TOS_NODE_ID)
				return FALSE;
		}
		return TRUE;	
	}
	/***************************************************************
	 *
	 * Neighbor discovery
	 *
	 ***************************************************************/

	// sending a keep alive message
	void SendKeepAliveMsg()
	{
		keep_alive_t* keepAliveMsg;
		uint8_t i;
		
		if (m_isBusy == TRUE)
			return;

		keepAliveMsg = (keep_alive_t*) call Packet.getPayload(&m_keepAlivePacket,
				sizeof(keep_alive_t));

		if (keepAliveMsg == NULL)
			return;

		// we broadcast our id and location
		keepAliveMsg->m_id = TOS_NODE_ID;
		keepAliveMsg->m_location.x = x;
		keepAliveMsg->m_location.y = y;
		keepAliveMsg->seqNum = seqNum++;
		for (i = 0; i < m_freeNeighborPtr; i++)
		{
			keepAliveMsg->neiList[i] = m_neighbors[i].m_id;
		}
		#ifdef LOG
	    call CC2420Packet.setPower(&m_keepAlivePacket, TX_POWER);	
	    #endif
		if (call KeepAliveSend.send(AM_BROADCAST_ADDR, &m_keepAlivePacket,
					sizeof(keep_alive_t)) == SUCCESS) {
			m_isBusy = TRUE;
        }
	}
	
	// keep alive message should be broadcast 
	event void KeepAliveTimer.fired()
	{
		SendKeepAliveMsg();
	}

	event void KeepAliveSend.sendDone(message_t* p_bufPtr, error_t p_error)
	{
		//call Leds.led1Toggle();
		if (&m_keepAlivePacket == p_bufPtr)
			m_isBusy = FALSE;
	}

	// a task for processing received keep alive messages
	task void Process()
	{
		message_t* msg;
		keep_alive_t* keepAliveMsg;
		neighbor_t *neighbor;
		
		atomic
		{
			if (call QueueReceive.empty())
			{
				dbg("NeighborList", "Receive queue is empty! No need for processing!\n");
				return;
			}
			msg = call QueueReceive.dequeue();
		}
		keepAliveMsg = (keep_alive_t*) call Packet.getPayload(msg, sizeof(keep_alive_t));

		neighbor = call Neighborhood.GetNeighborById(keepAliveMsg->m_id);
		if (!symmetricLinkDiscovery)
		{
			if (neighbor == NULL) // this neighbor does not exist; add it to the table.
			{
				m_neighbors[m_freeNeighborPtr].m_location = ToLocation(keepAliveMsg->m_location);
				m_neighbors[m_freeNeighborPtr].m_id = keepAliveMsg->m_id;
				m_neighbors[m_freeNeighborPtr].firstSeq = keepAliveMsg->seqNum;
				m_neighbors[m_freeNeighborPtr].lastSeq = keepAliveMsg->seqNum;
				m_neighbors[m_freeNeighborPtr].numRcvdPkts = 1;
				//m_neighbors[m_freeNeighborPtr].pdr = 1.0f;
				if (m_freeNeighborPtr < MAX_BUFFER - 1) {
					m_freeNeighborPtr++;
				}
				dbg("NeighborManagement", "NeiID: %d added.\n", keepAliveMsg->m_id);
			}
			else // neighbor already exists; thus update its pdr.
			{
				neighbor->lastSeq = keepAliveMsg->seqNum;
				neighbor->numRcvdPkts = neighbor->numRcvdPkts + 1;
				//neighbor->pdr = (float) neighbor->numRcvdPkts / (float) (neighbor->lastSeq - neighbor->firstSeq + 1);
				//dbg("NeighborManagement", "NeiID: %d PDR %f\n", neighbor->m_id, neighbor->pdr);
			}
		}
		else 
		{
			if (isAsymmetricLink(keepAliveMsg))
			{
				call Neighborhood.deleteNeighborByID(keepAliveMsg->m_id);
			}
		}
		//call MessagePool.put(msg);
	}

	// receiving a keep alive message and passing that to the buffer
	event message_t* KeepAliveReceive.receive(message_t* p_bufPtr, void* p_payload,
			uint8_t p_len)
	{
		//message_t *new_msg;
        
        call Leds.led1Toggle();
		atomic
		{
			if (p_len != sizeof(keep_alive_t) || call QueueReceive.size() >= call QueueReceive.maxSize())
			{
				dbg("NeighborList", "Receive queue is full! Message is dropped!\n");
				return p_bufPtr;
			}

			call QueueReceive.enqueue(p_bufPtr);
		}
		//new_msg = call MessagePool.get();
		post Process();	
		return p_bufPtr;
	}

	event void SymmetricLinkTimer.fired(){
		call Neighborhood.sortNeighborsCounterClockwise();
		call KeepAliveTimer.stop();	
//		symmetricLinkDiscovery = FALSE;
	}
}

