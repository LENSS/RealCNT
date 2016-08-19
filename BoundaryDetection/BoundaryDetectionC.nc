/*******************************************************
 * Implementation of boundary detection module 
 * Author: Myounggyu Won
 */

#include "../../Common.h"
#ifdef LOG
#include "StorageVolumes.h"
#endif

configuration BoundaryDetectionC{
	provides interface BoundaryDetection;
}
implementation{
	components BoundaryDetectionP, NeighborManagementC, ActiveMessageC, GeometrySupportC, IdentityC;
	components new AMSenderC(TYPE_CONTROL_BOUND_HOLE) as controlPktSend;
	components new AMReceiverC(TYPE_CONTROL_BOUND_HOLE) as controlPktReceive;
	components new QueueC(message_t, CTLPKT_QUEUE_SIZE) as ctlPktQueue;
	components new TimerMilliC() as QueueChecker;
	components LedsC;
	components DisseminationC;
	components new DisseminatorC(uint16_t, 0x1234) as Diss16C;
	
#ifdef LOG
	components DebugC;
	components new LogStorageC(VOLUME_DATALOG, FALSE);
    components CC2420ActiveMessageC;
    BoundaryDetectionP.LogRead -> LogStorageC;
  	BoundaryDetectionP.LogWrite -> LogStorageC;
    BoundaryDetectionP.CC2420Packet -> CC2420ActiveMessageC.CC2420Packet;
    BoundaryDetectionP.Debug -> DebugC;
#endif
	BoundaryDetectionP.Leds -> LedsC;
	BoundaryDetectionP.Identity -> IdentityC;
	BoundaryDetectionP.QueueChecker -> QueueChecker;
	BoundaryDetectionP.Neighborhood -> NeighborManagementC;
	BoundaryDetectionP.GeometrySupport -> GeometrySupportC;
	BoundaryDetectionP.controlPktSend -> controlPktSend;
	BoundaryDetectionP.controlPktReceive -> controlPktReceive;
	BoundaryDetectionP.controlPktAck -> controlPktSend;
	BoundaryDetectionP.Packet -> ActiveMessageC;
	BoundaryDetectionP.ctlPktQueue -> ctlPktQueue;
	BoundaryDetectionP.DisseminationControl -> DisseminationC;
	BoundaryDetectionP.Value -> Diss16C;
	BoundaryDetectionP.Update -> Diss16C;
	BoundaryDetection = BoundaryDetectionP;
}
