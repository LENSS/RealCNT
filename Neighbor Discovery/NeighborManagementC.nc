
#include "NeighborManagement.h"
#include "../../Common.h"

configuration NeighborManagementC
{
    provides interface Neighborhood;
}

implementation
{
    components NeighborManagementP, ActiveMessageC, GeometrySupportC, IdentityC; //, LedsC;

    // for keep alive timing
    components new TimerMilliC() as KeepAliveTimer;
    components new TimerMilliC() as SymmetricLinkTimer;
    components new AMSenderC(TYPE_KEEPALIVE) as KeepAliveSenderC;
    components new AMReceiverC(TYPE_KEEPALIVE) as KeepAliveReceiverC;

    // buffer for received keep alive messages
    components new QueueC(message_t*, MAX_BUFFER);
    //components new PoolC(message_t, MAX_BUFFER);
    components LedsC;
    #ifdef LOG
    components CC2420ActiveMessageC;
    NeighborManagementP.CC2420Packet -> CC2420ActiveMessageC.CC2420Packet;
    #endif

	NeighborManagementP.Leds -> LedsC;
	NeighborManagementP.GeometrySupport -> GeometrySupportC;
    NeighborManagementP.KeepAliveTimer -> KeepAliveTimer;
    NeighborManagementP.SymmetricLinkTimer -> SymmetricLinkTimer;
    NeighborManagementP.KeepAliveSend -> KeepAliveSenderC;
    NeighborManagementP.KeepAliveReceive -> KeepAliveReceiverC;
    NeighborManagementP.Packet -> ActiveMessageC;
    //NeighborManagementP.MessagePool -> PoolC;
    NeighborManagementP.QueueReceive -> QueueC;
    NeighborManagementP.Identity -> IdentityC;
    Neighborhood = NeighborManagementP;
}


