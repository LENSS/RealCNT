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
 * @file   Identity.nc
 * @author Krzysztof Piotrowski
 * @date   Sat Nov 08 07:00:00 2008
 *
 * @brief Identity - The interface for the Identity readers.
 * The sets of functions getAA, lockAA, unlockAA (where AA is fieldname)
 * provide the functionality to:
 * - get the current value of the field (returns the value or pointer) 
 * - lock it to protect from changes during use (returns SUCCESS),
 * - unlock after use (returns SUCCESS or EUNLOCKU - if unlocked to much :) )
 * DO NOT FORGET TO UNLOCK FIELDS YOU LOCKED!! 1 lock -> 1 unlock
 */

#include "identity.h"

interface Identity {

  //functions to access the ID
  command node_id_t getID();
  command error_t lockID();
  command error_t unlockID();
    
  //functions to access the RoleVector
  command rolev_t getRoleVector();
  command error_t lockRoleVector();
  command error_t unlockRoleVector();
    
  //functions to access the SensorVector
  command sensorv_t getSensorVector();
  command error_t lockSensorVector();
  command error_t unlockSensorVector();
    
  //functions to access the Location related fields  
#ifdef LOCATIONS

  //functions to access the Location
  command location_t getLocation();
  command error_t lockLocation();
  command error_t unlockLocation();
    
  //functions to access the ClusterHeadLocation
  command location_t getClusterHeadLocation();
  command error_t lockClusterHeadLocation();
  command error_t unlockClusterHeadLocation();
    
  //functions to access the ClusterReferenceLocation
  command location_t getClusterRefLocation();
  command error_t lockClusterRefLocation();
  command error_t unlockClusterRefLocation();

  //functions to access the BackupClusterReferenceLocation
  command location_t getBackupClusterRefLocation();
  command error_t lockBackupClusterRefLocation();
  command error_t unlockBackupClusterRefLocation();
#endif

  //functions to access the ClusterID
  command cluster_id_t getClusterID();
  command error_t lockClusterID();
  command error_t unlockClusterID();

  //functions to access the BackupClusterID
  command cluster_id_t getBackupClusterID();
  command error_t lockBackupClusterID();
  command error_t unlockBackupClusterID();

  //functions to access the ClusterHeadID
  command node_id_t getClusterHeadID();
  command error_t lockClusterHeadID();
  command error_t unlockClusterHeadID();

  //returns true iff the node is a ClusterHead    
  command bool isClusterHead();
  
  //functions to access the ClusterSinkID
  command node_id_t getClusterSinkID();
  command error_t lockClusterSinkID();
  command error_t unlockClusterSinkID();

  //functions to access the AggregatorID
  command node_id_t getAggregatorID();
  command error_t lockAggregatorID();
  command error_t unlockAggregatorID();

  //returns the length of the symmetric keys (in bytes)
  command uint8_t getSymKeyLen(); //returns SYM_KEY_LEN
    
  //functions to access the MasterKey
  command uint8_t* getMasterKey();
  command error_t lockMasterKey();
  command error_t unlockMasterKey();
    
  //functions to access the ClusterKey
  command uint8_t* getClusterKey();
  command error_t lockClusterKey();
  command error_t unlockClusterKey();

  //functions to access the SinkKey
  command uint8_t* getSinkKey();
  command error_t lockSinkKey();
  command error_t unlockSinkKey();
    
  //functions to access the keys shared with a node with 
  //the given nodeID
  command uint8_t* getSharedKey(node_id_t nodeID);
  command error_t lockSharedKey(node_id_t nodeID);
  command error_t unlockSharedKey(node_id_t nodeID);

  //returns the length of the asymmetric keys (in bytes)
  command uint8_t getAsymPKeyLen(); //returns ASYM_PKEY_LEN
    
  //functions to access the PublicKey
  command uint8_t* getPublicKey();
  command error_t lockPublicKey();
  command error_t unlockPublicKey();
}
