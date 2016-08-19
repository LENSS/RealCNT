#include "GPSR.h"
//#include "Timer.h"
//#include "float.h"

// Macros for setting and retrieving type, handler and mode information from the header
//#define GET_MODE(flag) ( (flag) & 0x03 )
//#define SET_MODE(flag, mode) ( flag = (flag & 0xfc) | ((mode) & 0x03) )
//#define GET_TYPE(flag) ( ((flag) >> 2) & 0x03 )
//#define SET_TYPE(flag, type) ( flag = (flag & 0xf3) | (((type) & 0x03) << 2) )
//#define GET_HANDLER(flag) ( ((flag) >> 4) & 0x03 )
//#define SET_HANDLER(flag, handler) ( flag = (flag & 0xcf) | (((handler) & 0x03) << 4) )

module GPSRP
{
	uses
	{
		interface AMSend as MsgSend;
		interface Receive as MsgReceiver;
		interface PacketAcknowledgements as MsgAck;
		interface AMPacket;
		interface Packet;
		interface Identity;
		// Buffer for reception
		interface Queue<message_t*> as QueueReceive;
		// Buffer for sending
		interface Queue<message_t*> as QueueSend;
		// Message storage pool
		//interface Pool<message_t> as MessagePool;
		// Accessing neighbor information to retrieve locations of neighboring nodes
		interface Neighborhood;
		interface Timer<TMilli> as QueueTimer;
		//interface BoundaryDetection;
		//interface Leds;
	}
	provides interface GPSR[uint8_t id];
}

implementation
{
	// for send lock
	bool m_locked = FALSE;
	uint16_t numRetransmit = 0;
    message_t gpsrMsg;
        
	default event uint8_t GPSR.receiveMsg[uint8_t id](void* p_msg, uint8_t p_type, uint8_t p_len, 
			location_t p_destination)
	{
		//signal GenericComms.receiveGPSRMsg(p_msg, p_type, p_len, p_destination);
		return 0;
	}
	

	//void Planarize(location_t);
  	
	location_t ToLocation(nx_location_t p_location)
	{
		location_t tmp;

		tmp.x = p_location.x;
		tmp.y = p_location.y;

		return tmp;
	}

	// Initialization for routing
	command error_t GPSR.Init[uint8_t id]()
	{
		//neighbor_t* neighbor;
		//nx_location_t tmp_loc;

		// Planarizing the connectivity graph
		//Planarize(call Identity.getLocation());

        //call Leds.led2On();
        
		// just for debugging
		//call Neighborhood.GetNeighbor(INIT);
		//while( (neighbor = call Neighborhood.GetNeighbor(NEXT)) != NULL)
		//{
		//	tmp_loc = neighbor->m_neighborInfo.m_location;
		//	dbg("DBG_USR3", "ID:%d\tNei_ID:%d\tNei_Loc(%d,%d)\tPlanar:%d\n", call Identity.getID(), neighbor->m_neighborInfo.m_id, tmp_loc.x, tmp_loc.y, neighbor->m_isPlanar);
		//}
		call QueueTimer.startPeriodic(1000);
		return SUCCESS;
	}

	task void Forward();

	// sending a message
	command error_t GPSR.sendMsg[uint8_t id](void* p_msg, uint8_t p_length, uint8_t p_type,
			location_t p_destination)
	{
		gpsr_header_t* header;
		uint8_t* payload, *data;
		uint8_t i;
		
		dbg("GPSR", "sendMsg() in GPSRC called.\n");
		// checking the size. the packet size cannot exceed TOSH_DATA_LENGTH
		if (TOSH_DATA_LENGTH - sizeof(gpsr_header_t) < p_length)
		{
			dbg("GPSR", "Packet size mismatch! MAX_DATA_SIZE: %d; content: %d.\n",
					TOSH_DATA_LENGTH - sizeof(gpsr_header_t), p_length);
			return FAIL;
		}
		// constructing the routing packet
		//gpsrMsg = call MessagePool.get();
		call AMPacket.setSource(&gpsrMsg, TOS_NODE_ID);
		
		//Mike: made change here
		//original: payload = (uint8_t*) call Packet.getPayload(msg, NULL);
		payload = (uint8_t*) call Packet.getPayload(&gpsrMsg, call Packet.payloadLength(&gpsrMsg));
		header = (gpsr_header_t*) payload;
		data = (uint8_t*) (payload + sizeof(gpsr_header_t));

		// setting up the control flag and the destination
		//SET_HANDLER(header->m_controlFlag,id);
		//SET_TYPE(header->m_controlFlag, p_type);
		header->m_destLocation.x = p_destination.x;
		header->m_destLocation.y = p_destination.y;
		//SET_MODE(header->m_controlFlag, GREEDY);
		memcpy(data, p_msg, p_length);
		header->m_dataLen = p_length;
		header->prevDist = MAX_UINT_32;
		for (i = 0; i < PREV_LOC_REF_SIZE; i++)
		{
			header->prevLocs[i].x = 0;
			header->prevLocs[i].y = 0;
		}
		// Enqueueing the packet return the control
		atomic
		{
			if (call QueueSend.enqueue(&gpsrMsg) == FAIL)
			{
				dbg("GPSR", "GPSR: Send queue is full! Message is dropped!\n");
				//call MessagePool.put(gpsrMsg);
				return FAIL;
			}
		}

		// Starting the sending task
		post Forward();

		return SUCCESS;
	}


	// Processing a received routing packet
	task void Process()
	{
		message_t* msg;
		//uint8_t handlerID;
		gpsr_header_t* header;
		uint8_t* payload, *data;

		// Checking the reception queue
		atomic
		{
			if (call QueueReceive.empty())
			{
				dbg("GPSR", "GPSR: Receive queue is empty! No need for processing!\n");
				return;
			}
			msg = call QueueReceive.dequeue();
		}
		// Extracting routing information from the header
		header = (gpsr_header_t*) call Packet.getPayload(msg, call Packet.payloadLength(msg));
		payload = (uint8_t*) call Packet.getPayload(msg, call Packet.payloadLength(msg)); 
		data = (uint8_t*) (payload + sizeof(gpsr_header_t));
		//handlerID = GET_HANDLER(header->m_controlFlag);
		// Signal reception; ignore the second parameter.
		//if (signal GPSR.receiveMsg[handlerID](data,
		//			0, header->m_dataLen, 
		//			ToLocation(header->m_destLocation)) == FORWARD)
		//{
			// If the packet should be forwarded, we attach that to the sending queue
			//dbg("GPSR", "Forwarding message in inter-routing, no local processing needed.\n");
			atomic
			{
				if ( call QueueSend.enqueue(msg) == FAIL)
				{
					dbg("GPSR", "GPSR: Receive queue is full! Message is dropped!\n");
					//call MessagePool.put(msg);
					return;
				}
			}
			// and forward that
			post Forward();
		//}
		//else
		//	call MessagePool.put(msg);
	}

	// message is received
	// we only enqueue the received packet to the reception queue
	event message_t* MsgReceiver.receive(message_t* p_bufPtr, void* p_payload, uint8_t p_len)
	{
		//message_t* new_msg;
		dbg("GPSR", "Message received from node %d.\n",
				call AMPacket.source(p_bufPtr));
		
		atomic
		{
			if (call QueueReceive.enqueue(p_bufPtr) == FAIL)
			{
				dbg("GPSR", "GPSR: Receive queue is full! Message is dropped!\n");
				return p_bufPtr;
			}

			//new_msg = call MessagePool.get();
		}

		post Process();

		return p_bufPtr;
	}

	/***************************************************************
	 *
	 * GPSR Forwarding
	 *
	 ***************************************************************/

	// Calculates the square of the distance between two nodes
	command uint32_t GPSR.Distance[uint8_t id](location_t p_locA, location_t p_locB)
	{
		uint32_t xDiff = p_locA.x < p_locB.x ? p_locB.x - p_locA.x :  p_locA.x - p_locB.x;
		uint32_t yDiff = p_locA.y < p_locB.y ? p_locB.y - p_locA.y : p_locA.y - p_locB.y;

		return SQUARE(yDiff) + SQUARE(xDiff);
	}

	// Forwarding logic
	task void Forward()
	{
		uint16_t candidateNode = MAX_UINT_16;
		uint32_t candidateNodeDist = MAX_UINT_32;
		gpsr_header_t* header;
		//am_addr_t srcId;
		location_t myLocation = call Identity.getMyLoc(); 
		//bool isFirstNodeOnFace = FALSE, isNewFace = FALSE, 
		bool isNextNode = FALSE;
		//location_t neighborCoord, crossingPoint, refLocation;
		neighbor_t* neighbors;
		uint16_t neighborSize;
		uint16_t i, j;
		neighbor_t dummyNeighbor, nextNeighbor;
		point_t prevLocs[PREV_LOC_REF_SIZE];
		message_t *tmp;
		
		atomic
		{
			if (call QueueSend.empty())
			{
				dbg("GPSR", "GPSR: Send queue is empty! No need for processing!\n");
				return;
			}
			tmp = call QueueSend.element(0);
			gpsrMsg = *tmp;
		}
		header = (gpsr_header_t*) call Packet.getPayload(&gpsrMsg, call Packet.payloadLength(&gpsrMsg));
		dbg("GPSR", "Processing message received from node %d.\n", call AMPacket.source(&gpsrMsg));
		// Did the packet reached its final destination? 
		if (header->m_destLocation.x == myLocation.x &&
				header->m_destLocation.y == myLocation.y)
		{
			//call Leds.led2Toggle();
			dbg("GPSR", "Final destination. No further forwarding needed.\n");
			//call MessagePool.put(gpsrMsg);
			signal GPSR.receiveMsg[0](&gpsrMsg, 0, header->m_dataLen, ToLocation(header->m_destLocation));
			atomic {
				call QueueSend.dequeue();
			} 
			return;
		}
		// Greedy forwarding: we seek a neighbor who is closer to the destination
		if(call GPSR.Distance[1](myLocation, ToLocation(header->m_destLocation)) < header->prevDist)
		{
			neighborSize = call Neighborhood.GetNeighborSize();
			neighbors = call Neighborhood.GetNeighbor();
			for (i = 0; i < neighborSize; i++)
			{
				uint32_t neighborDist =
				call GPSR.Distance[1](neighbors[i].m_location, ToLocation(header->m_destLocation));
				if (neighborDist < call GPSR.Distance[1](myLocation,
									ToLocation(header->m_destLocation))
						&& neighborDist < candidateNodeDist)
				{
					candidateNode = neighbors[i].m_id;
					candidateNodeDist = neighborDist;
					isNextNode = TRUE;
				}
				for (j = 0; j < PREV_LOC_REF_SIZE; j++)
				{
					header->prevLocs[j].x = 0;
					header->prevLocs[j].y = 0;	
				}
			}
			header->prevDist = call GPSR.Distance[1](myLocation, ToLocation(header->m_destLocation));
		}
		
		// Perimeter routing based on the chain of boundary nodes
		// NOT using FaceRouting.
		if (!isNextNode)
		{
			dbg("GPSR", "No close neighbor\n");
			for (i = 0; i < PREV_LOC_REF_SIZE; i++)
			{
				prevLocs[i].x = 0;
				prevLocs[i].y = 0;	
			}
			if (header->prevLocs[0].x == 0 && header->prevLocs[0].y == 0)
			{
				// objective: get the candidateNode along the chain of boundary nodes.
				dummyNeighbor.m_location.x = header->m_destLocation.x;
				dummyNeighbor.m_location.y = header->m_destLocation.y;
				call Neighborhood.addNeighbor(dummyNeighbor);
				call Neighborhood.sortNeighborsCounterClockwise();
				dbg("GPSR", "added and sorted neighbor\n");
				prevLocs[0].x = header->m_destLocation.x;
				prevLocs[0].y = header->m_destLocation.y;
				nextNeighbor = call Neighborhood.getNextNeighborRightHand(prevLocs);
				dbg("GPSR", "obtained next neighbor\n");
				call Neighborhood.deleteNeighborByLoc(dummyNeighbor.m_location.x, dummyNeighbor.m_location.y);
				call Neighborhood.sortNeighborsCounterClockwise();
				dbg("GPSR", "deleted and sorted neighbor\n");
				header->prevLocs[0].x = myLocation.x;
				header->prevLocs[0].y = myLocation.y;
				for (i = 1; i < PREV_LOC_REF_SIZE; i++)
				{
					header->prevLocs[i].x = 0;
					header->prevLocs[i].y = 0;	
				}
				candidateNode = nextNeighbor.m_id;
			}
			else
			{
				for (i = 0; i < PREV_LOC_REF_SIZE; i++)
				{
					prevLocs[i].x = header->prevLocs[i].x;
					prevLocs[i].y = header->prevLocs[i].y;	
				}
				nextNeighbor = call Neighborhood.getNextNeighborRightHand(prevLocs);
				header->prevLocs[0].x = myLocation.x;
				header->prevLocs[0].y = myLocation.y;
				for (i = 0; i < PREV_LOC_REF_SIZE - 1; i++)
				{
					header->prevLocs[i+1].x = (uint16_t)prevLocs[i].x;
					header->prevLocs[i+1].y = (uint16_t)prevLocs[i].y;
				}
				candidateNode = nextNeighbor.m_id;
			}
		}
		// and we send out the packet
		call AMPacket.setSource(&gpsrMsg, TOS_NODE_ID);
		header->nextHop = candidateNode;
		dbg("GPSR", "Dest: (%d,%d), Source: %d, Next hop: %d.\n",
				header->m_destLocation.x, header->m_destLocation.y,
				call AMPacket.source(&gpsrMsg), candidateNode);
		if (m_locked)
		{
			dbg("GPSR", "GPSR: Sending is locked. Message is dropped.\n");
			//call MessagePool.put(gpsrMsg);
			return;
		}
		call MsgAck.requestAck(&gpsrMsg);
		if (call MsgSend.send(candidateNode, &gpsrMsg, sizeof(gpsr_header_t) + header->m_dataLen) == SUCCESS)
		{
			m_locked = TRUE;
			dbg("GPSR", "Message sent to node %d by GPSR.\n", candidateNode);
		}
		else {
			dbg("GPSR", "GPSR: Failed to send message.\n");
		}
	}

	task void retransmitPkt()
	{
		gpsr_header_t* header;

		header = (gpsr_header_t*) call Packet.getPayload(&gpsrMsg, sizeof(gpsr_header_t));
		call MsgAck.requestAck(&gpsrMsg);
		call MsgSend.send(header->nextHop, &gpsrMsg, sizeof(gpsr_header_t) + header->m_dataLen);	
	}
	
	event void MsgSend.sendDone(message_t* p_bufPtr, error_t p_error)
	{
		bool wasAcked = FALSE;
		
		wasAcked = call MsgAck.wasAcked(p_bufPtr);
		if (wasAcked)
		{
			atomic {
				call QueueSend.dequeue();
			} 
			// Message is sent, lock can be released
			m_locked = FALSE;
			if (p_error != SUCCESS)
				dbg("GPSR", "GPSR: Failed to send message.\n");
			//call MessagePool.put(p_bufPtr);
		}
		else
		{
			 dbg("GPSR", "retransmitted a pakcet\n");
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
			 	 	call QueueSend.dequeue();
			 	 } 
				 numRetransmit = 0;
			 }
		}
	}

	event void QueueTimer.fired(){
		atomic 
		{
			if (call QueueSend.size() > 0)
			{
				post Forward();
			}
			if (call QueueReceive.size() > 0)
			{
				post Process();
			}
		}
	}
}
