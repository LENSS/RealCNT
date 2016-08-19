/**
 * @file GPSR.nc
 *
 * Description: Interface of GPSR (Greedy Perimeter Stateless Routing).
 * 
 * @version $Id: GPSR.nc,v 1.1 2012/09/28 03:45:14 mgwon Exp $
 * @author Gergely ACS, acs@crysys.hu
 * @date 2007 august
 */

#include "./identity.h"

interface GPSR
{

    // Sends a message.
    // @p_msg the message content to be sent
    // @p_length the length of the message content
    // @p_type the type of the message (in order to aid multiplexing messages in the upper layer)
    // @p_destination the location of the destination node
    command error_t sendMsg(void* p_msg, uint8_t p_length, uint8_t p_type, location_t p_destination);

    // Signals a message reception. The return value is the routing action to be taken (forwarding, dropping, etc.)
    // @p_msg the recevied message content
    // @p_length the length of the recevied message content
    // @p_type the type of the received message (in order to aid multiplexing messages in the upper layer)
    // @p_destination the location of the destination node
    event uint8_t receiveMsg(void* p_msg, uint8_t p_len, uint8_t p_type, location_t p_destination);

    // Initlizes the routing procedure.
    command error_t Init();

    // Computes the square of the distance between two points.
    // @p_location1 location 1
    // @p_location2 location 2
    command uint32_t Distance(location_t p_location1, location_t p_location2);
}

