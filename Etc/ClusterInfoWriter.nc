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
 * @file   ClusterInfoWriter.nc
 * @author Krzysztof Piotrowski
 * @date   Sat Nov 08 07:00:00 2008
 *
 * @brief ClusterInfoWriter - Interface for ClusterInfo Writers
 * setAA function where AA is the field name sets the new value of the field,
 * returns SUCCESS or ELOCKED if field locked and writes are not allowed.
 */

#include "identity.h"

interface ClusterInfoWriter {

//functions to location related fields
#ifdef LOCATIONS
  //function to set the ClusterHeadLocation
  command error_t setClusterHeadLocation(location_t new_cluster_head_location);
    
  //function to set the ClusterReferenceLocation
  command error_t setClusterRefLocation(location_t new_cluster_ref_location);
    
  //function to set the BackupClusterReferenceLocation
  command error_t setBackupClusterRefLocation(location_t new_backup_cluster_ref_location);
#endif

  //function to set the ClusterID
  command error_t setClusterID(cluster_id_t new_cluster_id);

  //function to set the BackupClusterID
  command error_t setBackupClusterID(cluster_id_t new_backup_cluster_id);

  //function to set the ClusterHeadID
  command error_t setClusterHeadID(node_id_t new_cluster_head_id);

  //function to set the ClusterSinkID
  command error_t setClusterSinkID(node_id_t new_cluster_sink_id);

  //function to set the AggregatorID
  command error_t setAggregatorID(node_id_t new_aggregator_id);
}
