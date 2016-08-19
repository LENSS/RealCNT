#ifndef BOUNDARY_DETECTION_H
#define BOUNDARY_DETECTION_H

#include "../../Common.h"

//#define PREV_LOC_REF_SIZE 4
//#define MAX_PREV_LOCS 10 

// control message for bound hole algorithm
typedef nx_struct _controlPktBoundHole
{
    nx_location_t location;
    nx_location_t prevLocs[MAX_PREV_LOCS]; // for abstraction
    nx_location_t vertices[MAX_VERTICES]; // for abstraction
    nx_uint16_t id;
    nx_uint16_t nextNeiId; // used for retransmission.
    nx_uint16_t originatorId; // used for determining whether a packet reached back.
    nx_uint16_t originatorLeftId;
    nx_uint16_t originatorRightId;
    nx_uint16_t seqNum; // used to measure the hole size, i.e., the number of boundary
                        // nodes for the hole.
} controlPktBoundHole_t;

#endif /* BOUNDARY_DETECTION_H */
