#include "GPSR.h"

configuration GPSRC
{
	// standard receive and send interface including general functions
	provides interface GPSR[uint8_t id];
}

implementation 
{
	components GPSRP, ActiveMessageC, IdentityC, NeighborManagementC;
	components new AMSenderC(TYPE_GPSR) as GPSRMsgSenderC;
	components new AMReceiverC(TYPE_GPSR) as GPSRMsgReceiverC;
	// Buffer for reception
	components new QueueC(message_t*, MAX_RECEIVE_BUFFER) as QueueReceiveC;

	// Buffer for sending
	components new QueueC(message_t*, MAX_SEND_BUFFER) as QueueSendC;

	// Message storage
	//components new PoolC(message_t, MAX_RECEIVE_BUFFER + MAX_SEND_BUFFER);
	components new TimerMilliC() as QueueTimer;
	//components BoundaryDetectionC;

	//GPSRP.BoundaryDetection -> BoundaryDetectionC;
	GPSRP.MsgSend -> GPSRMsgSenderC;
	GPSRP.MsgReceiver -> GPSRMsgReceiverC;
	GPSRP.AMPacket -> ActiveMessageC;
	GPSRP.Packet -> ActiveMessageC;
	GPSRP.Neighborhood -> NeighborManagementC;
	GPSRP.Identity -> IdentityC.Identity;
	//GPSRP.MessagePool -> PoolC;
	GPSRP.QueueReceive -> QueueReceiveC;
	GPSRP.QueueSend -> QueueSendC;
	GPSRP.MsgAck -> GPSRMsgSenderC;
	GPSRP.QueueTimer -> QueueTimer;
	//GPSRP.Leds -> LedsC;
	GPSR = GPSRP.GPSR;
}

