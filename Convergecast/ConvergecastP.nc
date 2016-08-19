/*********************************************************************
 * Implementation of Convergecast module
 * This module heavily relies on Unicast module. The main functionality
 * of this module is to determine an intermediate destination. By first
 * sending a pakcet to the intermediate destination and then sending to
 * the sink, this module avoids the energy hole problem.
 * Author: Myounggyu Won
 */

#include "Convergecast.h"

module ConvergecastP{
	uses interface Unicast; // not yet implemented.
	provides interface Convergecast;
}

implementation{
	/************************************************************************
	 * sendPacket
	 * description: This command contains the main functionality of the 
	 * convergecast module. Applications can call this command.
	 */
	 command error_t sendPacket(message_t msg)
	 {
	 	// implement the logic of sendPacket
	 
	 	// basically, determines the intermediate destination based on the 
	 	// two parameters - delta and d - and then send the packet to the 
	 	// sink.		
	 }
	 
	 /***********************************************************************
	  * convergePktReceived
	  * description: This event is triggered when a convergecast packet is
	  * received. If the receiver is the intermediate destination, the node
	  * keeps forwarding the packet to the sink. Otherwise, if the receiver
	  * is the sink, no action needs to be taken.
	  */
	event uint8_t convergePktReceived(message_t *recvdMsg)
	{
		// implement the logic of convergePktReceived.
	}	  	
	
	/***********************************************************************
	 * setParameters
	 * description: This command simply sets the two main parameters used for
	 * determining the intermediate destination. 
	 */
	command void setParameters(uint8_t maxDelta, uint8_t maxD)
	{
		// implement the logic of setParameters.
	}	 
}