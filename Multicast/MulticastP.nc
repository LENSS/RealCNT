/*********************************************************
 * Implementation of IROS multicast routing module.
 * Note that the MulticastManager must be running at the sink
 * before a node attempts to send a multicast packet.
 * Author: Myounggyu Won
 */
#include "multicast.h"
module MulticastP{
	//uses interface Unicast; // not implemented yet.
	                          // used for sending a packet to
	                          // an individual multicast member.
	//uses interface Convergecast; // not implemented yet.
	                               // used for sending a msg to the sink.
	                               // like Join, Leave, and McastRequest
	provides interface Multicast;
}
implementation{
	command error_t join (uint8_t mcastID, Location myLoc)
	{
		// implement the logic for join here	
	}
	command error_t leave (uint8_t mcastID, Location myLoc)
	{
		// implement the logic for leave here	
	}
	/*
	 * This command is usually called by an app when it wants to
	 * send a packet to a set of nodes belong to the multicast
	 * ID, i.e., mcastID.
	 */
	command error_t sendPacket (uint8_t mcastID)
	{
		// implement the logic for sendPacket	
		
		// getMcastMembers must be first called. And wait for 
		// the mcastRequestDone event.

	}
	/*
	 * This command forces to send a mCastRequest packet 
	 * to the sink to obtain the set of locations corresponding
	 * to the multicast ID as well as the locations of facility
	 * node.
	 */
	command error_t getMcastMembers (uint8_t mcastID)
	{
		// implement the logic for getMcastMembers.

	}
	
	/*
	 * event triggered when the response for mcast member request
	 * comes from the sink. The "response" contains a set of
	 * facility nodes, and a set of locations of members for each
	 * facility node.
	 */
	event uint8_t mcastRequestDone (message_t *response)
	{
		// implement the logic for mcastRequestDone.
	}
	
	/*
	 * This event is triggered when a multicast packet is received.
	 * When the receiver is a facility node, it distributes the 
	 * received packet to its members using the unicast. 
	 * When the receiver is not a facility node, nothing needs
	 * to be done, other than notifying the app for the multicast
	 * arrival.
	 */
	event uint8_t mcastPktReceived (message_t *response)
	{
		// implement the logic for mcastPktReceived.
	}
}