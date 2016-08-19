#ifndef GPSR_H
#define GPSR_H

// macros
#define SQUARE(x) ((x) * (x))
#define MAX(x, y) ((x) > (y) ? (x) : (y))
#define MIN(x, y) ((x) > (y) ? (y) : (x))

// Constants, limits
#define MAX_SEND_BUFFER 10
#define MAX_RECEIVE_BUFFER 10
#define MAX_UINT_16 65535u
#define MAX_UINT_32 4294967295u

#define ATAN_90 57.518363f
#define ATAN_0 0

// we use geo locations from identity.h
#ifndef LOCATIONS
#define LOCATIONS 
#endif

#ifndef GEOLOCATIONS
#define GEOLOCATIONS 
#endif

#include "../../Common.h"

//enum{
//GPSR_PANEL_HANDLER=1,
//GPSR_LUNAR_HANDLER=2,
//Four apps are possible in total
//};

// general gpsr header
typedef nx_struct _gpsr_header
{
    // destination location
    nx_location_t m_destLocation;
	nx_uint16_t nextHop;
    // location of node where the packet entered perimeter mode
    //nx_location_t m_enterPerimLocation;	// Location Packet Entered Perimeter Mode
    // location of node where the packet entered the current face
    //nx_location_t m_enterFaceLocation; // Point on xV Packet Entered Current Face

    // the first edge of the current face
    //nx_location_t m_firstEdgeStart;	// Location Packet Entered Perimeter Mode
    //nx_location_t m_firstEdgeEnd;	// Location Packet Entered Perimeter Mode

    // 1 byte for controlling information
    //nx_uint8_t m_controlFlag;   // 0. and 1. bit: packet mode, 1. and 2. bit: content type
    // length of the data
    nx_uint32_t prevDist;
    nx_location_t prevLocs[PREV_LOC_REF_SIZE];
    nx_uint8_t m_dataLen;
} gpsr_header_t;

enum 
{
    GREEDY = 0,
    PERIMETER = 1
};

// Routing actions that can be taken by the protocol
#ifndef ROUTING_ACTIONS
#define ROUTING_ACTIONS
//enum 
//{
//    FORWARD = 0,
//    FORWARD_BROADCAST = 1,
//    NO_FORWARD = 2
//};
#endif

#endif
