interface Multicast
{
    // computes the locations of facility
    // command void computeFacility(uint8_t mcastID);

    // send to the sink a request for retrieving locations corresponding to a multicast ID. the sink also gives the locations of facilities.
    command Location *getMcastMembers(uint8_t mcastID);

    // sends a packet to a set of multicast members
    command error_t sendPacket(uint8_t mcastID);

    command error_t join(uint8_t mcastID);
    command error_t leave(uint8_t mcastID);

    // triggered when a retx request is received.
    //event uint8_t retxRequestRcvd(void);

    // triggered when a multicast packet is received
    event uint8_t mcastPktReceived(message_t *response);

    event uint8_t mcastRequestDone(message_t *response); 
}

