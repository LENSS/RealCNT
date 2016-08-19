#ifndef COMMON_H
#define COMMON_H

#define NEIGHBOR_DISCOVERY_PERIOD 2000 //2000
#define NEIGHBOR_DISCOVERY_DURATION 180000
#define SYM_LINK_DISCOVERY_DURATION 180000
// before deployment reset buttons of all nodes must be clicked 
// within this time. set to 300000 for actual disaster city deployment
//#define BOUNDARY_DETECTION_WAIT_DURATION 300000 //5 mins 
#define BOUNDARY_DETECTION_WAIT_DURATION 60000 //5 mins 
#define BOUNDARY_DETECTION_DURATION 60000
#define LOG_WRITE_DURATION 60000 
#define MAX_PDR 0.5f
#define MAX_VERTICES 10 
#define PREV_LOC_REF_SIZE 4
#define MAX_PREV_LOCS 10 
#define MAX_NEIGHBORS 15 
#define MAX_BOUNDARY_NODES 50 
#define MAX_BUFFER MAX_NEIGHBORS
#define MAX_RETX 50 
#define MAX_TTL 100
#define DELTA 4 // the width of the box used for abstraction
#define MAX_SHARING_HOLES 10
#define STD_DEV_THRESHOLD 0 // the degree of hole abstraction

// Deployment-related time
#define DEPLOYMENT_TIME 1000 //15 mins
#define LOG_TIME (DEPLOYMENT_TIME + NEIGHBOR_DISCOVERY_DURATION + SYM_LINK_DISCOVERY_DURATION + BOUNDARY_DETECTION_WAIT_DURATION + BOUNDARY_DETECTION_DURATION)
#define RESET_TIME (DEPLOYMENT_TIME + NEIGHBOR_DISCOVERY_DURATION + SYM_LINK_DISCOVERY_DURATION + BOUNDARY_DETECTION_WAIT_DURATION + BOUNDARY_DETECTION_DURATION + LOG_WRITE_DURATION)
 
// Message types - DO NOT MODIFY.
#define TYPE_KEEPALIVE 1
#define TYPE_CONTROL_BOUND_HOLE 2    

// Queue sizes
#define CTLPKT_QUEUE_SIZE 20

typedef nx_struct nx_location_t {
    nx_uint16_t x;
    nx_uint16_t y;
} nx_location_t;    
    
typedef struct location {
	uint16_t x;
	uint16_t y;
} location_t;

// information about a particular neighbor 
typedef struct _neighbor 
{
    location_t m_location; 
    uint16_t m_id;
    uint16_t firstSeq;
    uint16_t lastSeq;
    uint16_t numRcvdPkts;
} neighbor_t;

typedef struct _point
{
    float x;
    float y;
} point_t;

typedef struct _line
{
    point_t start;
    point_t end;
} line_t;


//typedef struct _polygon
//{
//    point_t polyVertices[20];
//} polygon_t

uint16_t retxCnt = 0;

#ifdef LOG
uint8_t TX_POWER = 31;
// Disaster-city paramters
float PDRs[10] = {0.3f, 0.4f, 0.5f, 0.6f, 0.7f};
uint8_t TX_POWER_[10] = {31, 23, 15, 7, 3}; 
// Disaster-city records
typedef struct record
{
    uint8_t expNum;
    uint8_t txpower;
    bool isBoundary;
    uint16_t retxCnt;
    uint16_t neighborIDs[MAX_NEIGHBORS];
    location_t vertexLocs[MAX_VERTICES];
} record_t;
#endif

#endif /* COMMON_H */
