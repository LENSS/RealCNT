/******************************
 * Implementation of Unicast module.
 * This module finds intermediate destinations and 
 * sends a packet to them using GF module.
 */
module UnicastP{
	uses interface BoundaryDetection;
	uses interface GF;
	provides Unicast;
}
implementation{
	
	Location outsideConvex(Location dest)
	{
		// given source and destination outside convex hulls
		// return the next intermediate destination.	
	}
	
	Location insideConvex(Location dest)
	{
		// when the routing mode is insideConvex,
		// this function is used to find the
		// next hop 
		
		// consult with the routing table defined for the inside convex routing.
	}
	
	/******************************************
	 * This is the core of the unicast module.
	 * This module determines the next intermediate destination.
	 * And send a packet to the intermediate destination using a default GF.
	 */
	command sendPacket(Location dest, message_t msg)
	{
		// implement the logic for the sendPacket.
		
		// based on the locations of src and destination
		// determine which routing mode to use.
		
		intDest = outsideConvex(dest);
		// or intDest = insideConvex(dest);	
		
		// send a packet to the intDeest using a default GF
		GF.sendPacket(dest, msg);
	}
	
	/*************************************
	 * This event is triggered when a packet is stuck.
	 * If boundary chain is known - known by consulting with the Boundary Detection module -
	 * call sendAlongBoundary to send a packet along the chain of the boundary nodes.
	 * If the stuck node is not a boundary, initiate the boundary detection by using the interface for the Boundary Detection.
	 */
	event uint8_t packetStuck(void)
	{
		// implement the logic here.
	}
	
	/***************************************
	 * This event is triggered when a packet is received from the underlying GF module.
	 * If the receiver is an intermediate destination, rerun the sendPacket to find the next intermediate destination,
	 * If the receiver is the final destination, signal the application for the reception of the packet.
	 */
	event uint8_t packetReceived(void)
	{
		// implement the logic of packetReceived event.
	}	
	
	/***********************************************************
	 * This is called when a node finds that it is inside a convex hull.
	 * After certain amount of time for discovering the boundary,
	 * the app must call this command as an initialization procedure for the unicast module
	 * before using the unicast module.
	 */
	command void initLocVisibility(uint8_t param1, uint8_t param2)
	{
		// implement the logic of initLocVisibility
		
		// exchange routing tables with its neighboring visible nodes.
		
		// the objective is to build a routing table for supporting the
		// inside convex routing.
	}	
	
	/********************************************************
	 * used when a packet is stuck and the chain of boundary nodes is known.
	 * usually called for small holes.
	 */
	command void sendAlongBoundary(Location dest, message_t msg)
	{
		
	}
}