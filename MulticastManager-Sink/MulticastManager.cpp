/**********************************************************
 * Implementation of the multicast manager.
 * Main
 * Author: Myounggyu Won
 */
#include <pthread.h>
#include <stdio.h>
#include <stdlib.h>
#include <errno.h>
#include "MulticastManager.h"

void handleJoin(unsigned int mcastID, Location nodeLoc)
{
	// implementation for handleJoin
}

void handleLeave(unsigned int mcastID, Location nodeLoc)
{
	// implementation for handleLeave
}

void handleLocReport(Location nodeLoc)
{
	// implementation for handleLocReport
}

void handleRequest(unsigned int mcastID)
{
	// TODO-2: realize a fast heuristic for the facility
	//         computation.
	computeFacility(mcastID);

	// then ask the sink to send the locations of facility
	// nodes and corresponding member nodes.
	// e.g., f1 | m1 | m2 | f2 | m1 | m2 | m3 ...
	// TODO-3: realize this
}

void handleMCastRequest(unsigned int mcastID)
{
	// implementation for handleMCastRequest
	pthread_t th;
	pthread_attr_t ta;

	pthread_attr_init(&ta);
	pthread_attr_setdetachstate(&ta, PTHREAD_CREATE_DETACHED);
	// handle the facility computation in a separate thread
	// so that the multicast manager can still receive
	// messages while computing facility nodes.
	pthread_create(&th, &ta, handleRequest, &mcastID);
}

int main(void){
	unsigned int mcastID;
	Location nodeLoc;

	while (1)
	{
		// wait for message from the USB interface which
		// connects to the sink node.
		// DOTO-1: see how to realize this.
		msgType msgType_ = waitForMsg();
		parseMsg(&mcastID, &nodeLoc);
		// msg arrived - handle it.
		switch (msgType_)
		{
			case JOIN:
				handleJoin(mcastID, nodeLoc);
				break;
			case LEAVE:
				handleLeave(mcastID, nodeLoc);
				break;
			case LOCREPORT:
				handleLocReport(nodeLoc);
				break;
			case MCASTREQUEST:
				handleMCastRequest(mcastID);
				break;
			default:
				printf("unknown message type!\n");
		}
	}
}
