interface Unicast
{
    // sends a packet to a destination
    command void sendPacket(Location dest, message_t msg);

    // send a Packet using the boundary nodes - used when a packet is stuck.
    command void sendAlongBoundary(Location dest, message_t msg);

    // initiates a local visibility graph construction
    command void initLocVisibility(uint8_t param1, uint8_t param2);

    // event triggered when a packet is received.
    event uint8_t packetReceived(void);

    // event triggered when a packet is stuck.
    // because of either small holes, or unfinished boundary
    // detection/abstraction phase
    event uint8_t packetStuck(void);
}

