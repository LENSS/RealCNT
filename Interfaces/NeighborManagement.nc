/**
 * @file Neighborhood.nc
 *
 * Description: Interface of neighborhood management. 
 * 
 * @version $Id: NeighborManagement.nc,v 1.1 2012/10/03 04:22:48 mgwon Exp $
 * @author Gergely ACS, acs@crysys.hu
 * @date 2007 august
 */

#include "NeighborManagement.h"
#include "DNMessages.h"

interface Neighborhood
{
    // Starts neighborhood discovery.
    // @p_maxEntryAge is the number of epochs until the neighbor is considered to be alive
    // @p_keepAliveTime the periods of sending keep alive messages to discover neighbors
    command void startDiscovery(uint8_t p_maxEntryAge, uint32_t p_keepAliveTime);

    // Updates the current neighborlist. (dead neighbors are removed) 
    // @p_currentEpoch is the current epoch
    command void UpdateNeighborlist(uint16_t p_currentEpoch);

    // Retrieves the next neighbor. This is used to go through all neighbors in a loop.
    // @p_which INIT to go to the beginning of the neighborlist, NEXT to retrieve the next neighbor
    command neighbor_t* GetNeighbor(uint8_t p_which);

    // Retrieves a the p_num th neighbor in the neighborlist. This is used to go through all neighbors in a loop, when 
    // GetNeighbor is in use.
    // @p_num the number of the neighbor in the neighborlist
    command neighbor_t* GetSpecNeighbor(uint8_t p_num);

    // Retrieves a specific neighbor with a given node id.
    // @p_node the id of the neighbor that should be retrieved
    command neighbor_t* GetNeighborById(uint16_t p_node);

    // Adding a neighbor to the neighborlist.
    // @p_neighborInfo the info to be stored about the neighbor
    // @p_currentEpoch in which epoch
    command bool AddNeighbor(keep_alive_t* p_neighborInfo, uint16_t p_currentEpoch);
    // command void setNeighborList(void* p_list, uint8_t p_num);
}

