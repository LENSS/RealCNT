interface Convergecast{
	// sends a packet to the sink.
    command error_t sendPacket(message_t msg);

    // sets parameters used to derive a deviated path
    command void setParameters(uint8_t maxDelta, uint8_t maxD);

    // triggered when a packet is received (at the sink)
    event uint8_t convergePktReceived(message_t *recvdMsg);
}