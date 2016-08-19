/* **********************************************************************/
/* This program is free software; you can redistribute it and/or        */
/* modify it under the terms of the GNU General Public License as       */
/* published by the Free Software Foundation; either version 2 of the   */
/* License, or (at your option) any later version.                      */
/*                                                                      */
/* This program is distributed in the hope that it will be useful, but  */
/* WITHOUT ANY WARRANTY; without even the implied warranty of           */
/* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU    */
/* General Public License for more details.                             */
/*                                                                      */
/* Written and (c) by IHP, Krzysztof Piotrowski                         */
/* Contact <piotrowski@ihp-microelectronics.com> for comment,           */
/* bug reports and possible alternative licensing of this program       */
/************************************************************************/

/**
 * @file   KeyInfoWriter.nc
 * @author Krzysztof Piotrowski
 * @date   Sat Nov 08 07:00:00 2008
 *
 * @brief KeyInfoWriter - The interface for KeyInfo Writers
 *
 */


#include "identity.h"

interface KeyInfoWriter {

  //the function to set the MasterKey
  command error_t setMasterKey(void* new_master_key, uint8_t size);
    
  //the function to set the ClusterKey
  command error_t setClusterKey(void* new_cluster_key, uint8_t size);

  //the function to set the SinkKey
  command error_t setSinkKey(void* new_sink_key, uint8_t size);
    
  //the function to set the Key shared with the node with the given nodeID
  command error_t setSharedKey(node_id_t nodeID, void* new_shared_key, uint8_t size);

  //the function to set the PublicKey
  command error_t setPublicKey(void* new_public_key, uint8_t size);
}
