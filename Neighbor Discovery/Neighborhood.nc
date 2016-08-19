
#include "NeighborManagement.h"

interface Neighborhood
{
	// start the neighbor discovery process
	// @x : my x coordinate
	// @y : my y coordinate
	// @maxLinkQuality : only a neighbor with pdr higher than maxLinkQuality is considered
	// @neighborDiscoveryPeriod : beacon every neighborDiscoveryPeriod sec.
    command void startDiscovery(uint16_t x, uint16_t y, float maxLinkQuality, uint16_t neighborDiscoveryPeriod);
	command void stopDiscovery();
	
    // Updates the current neighborlist. (dead neighbors are removed) 
    // @p_currentEpoch is the current epoch
    command void UpdateNeighborlist(float maxLinkQuality_);

    // Retrieves a the p_num th neighbor in the neighborlist. This is used to go through all neighbors in a loop, when 
    // GetNeighbor is in use.
    // @p_num the number of the neighbor in the neighborlist
    command neighbor_t* GetSpecNeighbor(uint8_t p_num);

    // Retrieves a specific neighbor with a given node id.
    // @p_node the id of the neighbor that should be retrieved
    command neighbor_t* GetNeighborById(uint16_t p_node);
    command neighbor_t getNextNeighborRightHand(point_t *prevLocs);
    command uint8_t GetNeighborSize();
    command neighbor_t* GetNeighbor();
    command void sortNeighborsCounterClockwise();
    command void addNeighbor(neighbor_t newNeighbor);
    command void deleteNeighborByID(uint16_t id);
    command void deleteNeighborByLoc(uint16_t x, uint16_t y);
    command void Init(void);
}

