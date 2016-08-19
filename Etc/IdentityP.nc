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
 * @file   IdentityP.nc
 * @author Krzysztof Piotrowski
 * @date   Sat Nov 08 07:00:00 2008
 *
 * @brief IdentityP - The implementation of the Identity module.
 * Do not use direct, use IdentityC instead.
 */

#include "identity.h"

module IdentityP{
  provides{
	interface Identity;
	interface IdentityWriter;
	interface ClusterInfoWriter;
	interface KeyInfoWriter;
	interface Init as SoftwareInit;
  }    
}

implementation{

  // identity related information
  node_id_t       id;
  lock_counter_t id_lock;
    
  rolev_t    role_vector;
  lock_counter_t role_vector_lock;
    
  sensorv_t  sensors_vector;
  lock_counter_t sensors_vector_lock;
    
#ifdef LOCATIONS    
  location_t location;
  lock_counter_t location_lock;
    
  //cluster related information
  location_t cluster_head_location;
  lock_counter_t cluster_head_location_lock;
    
  location_t cluster_ref_location;
  lock_counter_t cluster_ref_location_lock;
    
  location_t backup_cluster_ref_location;
  lock_counter_t backup_cluster_ref_location_lock;
#endif

  // more cluster related information
  cluster_id_t cluster_id;
  lock_counter_t cluster_id_lock;

  cluster_id_t backup_cluster_id;
  lock_counter_t backup_cluster_id_lock;

  node_id_t         cluster_head_id;
  lock_counter_t cluster_head_id_lock;
    
  node_id_t         cluster_sink_id;
  lock_counter_t cluster_sink_id_lock;
    
  node_id_t         aggregator_id;
  lock_counter_t aggregator_id_lock;

  //keys
  uint8_t 	master_key[SYM_KEY_LEN]; //network-wide
  lock_counter_t master_key_lock;
    
  uint8_t 	cluster_key[SYM_KEY_LEN]; //cluster-wide
  lock_counter_t cluster_key_lock;
    
  uint8_t 	sink_key[SYM_KEY_LEN]; //shared with the sink
  lock_counter_t sink_key_lock;
    
  //keys shared with other nodes
  shared_key_t pairwise_keys[MAX_KEY_NUM]; 
  lock_counter_t pairwise_keys_lock[MAX_KEY_NUM];
    
  //a public key, WHOSE KEY IS THAT?
  uint8_t	public_key[ASYM_PKEY_LEN]; 
  lock_counter_t public_key_lock;
    

#ifdef BUFFERED
  // identity related information - buffers
  node_id_t       id_buf;
  rolev_t    role_vector_buf;
  sensorv_t  sensors_vector_buf;

  #ifdef LOCATIONS    
    location_t location_buf;
    location_t cluster_head_location_buf;
    location_t cluster_ref_location_buf;
    location_t backup_cluster_ref_location_buf;
  #endif

  // cluster related information - buffers
  cluster_id_t cluster_id_buf;
  cluster_id_t backup_cluster_id_buf;
  node_id_t         cluster_head_id_buf;
  node_id_t         cluster_sink_id_buf;
  node_id_t         aggregator_id_buf;
    
  //keys
  uint8_t 	master_key_buf[SYM_KEY_LEN]; //network-wide
  uint8_t 	cluster_key_buf[SYM_KEY_LEN]; //cluster-wide
  uint8_t 	sink_key_buf[SYM_KEY_LEN]; //shared with the sink
  shared_key_buf_t pairwise_keys_buf[MAX_KEY_NUM]; //shared with other nodes
    
  //a public key, WHOSE KEY IS THAT?
  uint8_t	public_key_buf[ASYM_PKEY_LEN]; 
    
  //a bitvector that indicates that updates to variables 
  //are waiting in the buffer to be written on unlock
  //EXCEPT the pairwise keys
  vector_t 	update_vector;
    
  //an array of bytes containing the update bits for the pairwise keys
  uint8_t 	key_update_vector[(MAX_KEY_NUM >> 3) + 1];    
#endif

  //helper functions
    
  /**
  * searching shared keys by node_id
  * returns the index or MAX_KEY_NUM if unknown node_id
  */
  uint16_t getSKIndex(node_id_t node_id){
    uint16_t ix;
	for(ix=0; ix<MAX_KEY_NUM; ix++){
	  if(pairwise_keys[ix].node_id == node_id){
	    return ix;
	  }
	}
    return ix;
  }
    
  /**
  * searching for empty slot in shared key array
  * returns index of first free slot or MAX_KEY_NUM if full
  */
  uint16_t getFreeSKIndex(){
	uint16_t ix;
	for(ix=0; ix<MAX_KEY_NUM; ix++){
	  if(pairwise_keys[ix].node_id == 0){
		return ix;
	  }
	}
	return ix;
  }
    
    
#ifdef BUFFERED
  //helper functions - for buffered (update related)
  /**
  * was the field updated during lock?
  */
  bool getUpdate(uint8_t ix){
	return (update_vector & (((vector_t)1) << ix)) != 0;
  }
    
  /**
  * sets the update flag for the given field index
  */
  void setUpdate(uint8_t ix){
	update_vector |= (((vector_t)1) << ix);
  }

  /**
  * clears the update flag for the given field index
  */
  void clearUpdate(uint8_t ix){
	update_vector &= !(((vector_t)1) << ix);
  }
    
  //and now the same for the shared keys by index
  //(16-bit index value compared to fields)
  /**
  * was the key updated during lock?
  */
  bool getSKUpdate(uint16_t ix){
	return (key_update_vector[ix >> 3] & (1 << (ix % 8))) != 0;
  }
    
  /**
  * sets the update flag for the given key index
  */
  void setSKUpdate(uint16_t ix){
	key_update_vector[ix >> 3] |= (1 << (ix % 8));
  }

  /**
  * clears the update flag for the given key index
  */
  void clearSKUpdate(uint16_t ix){
	key_update_vector[ix >> 3] &= !(uint8_t)(1 << (ix % 8));
  }
#endif    
    
//interface Identity. 

  command node_id_t Identity.getID(){ 
	return id;
  }

  command error_t Identity.lockID(){
	id_lock++; 
	return SUCCESS;
  }

  command error_t Identity.unlockID(){    
	if(id_lock == 0){
      return EUNLOCKU;
	}
	id_lock--;
    #ifdef BUFFERED
	  if(id_lock==0 && getUpdate(IX_ID)){
	    id = id_buf; //memcpy...
	    clearUpdate(IX_ID);
	  }	
    #endif	
	return SUCCESS;
  }
    
  command rolev_t Identity.getRoleVector(){
	return role_vector;
  }    

  command error_t Identity.lockRoleVector(){
	role_vector_lock++;
	return SUCCESS;
  }

  command error_t Identity.unlockRoleVector(){
	if(role_vector_lock == 0){
      return EUNLOCKU;
	}
	role_vector_lock--;
    #ifdef BUFFERED
	  if(role_vector_lock==0 && getUpdate(IX_ROLES)){
        role_vector = role_vector_buf; //memcpy...
        clearUpdate(IX_ROLES);
	  }	
    #endif	
	return SUCCESS;
  }
    
  command sensorv_t Identity.getSensorVector(){
	return sensors_vector;
  }
  
  command error_t Identity.lockSensorVector(){
	sensors_vector_lock++;
	return SUCCESS;
  }
  
  command error_t Identity.unlockSensorVector(){
    if(sensors_vector_lock == 0){
      return EUNLOCKU;
	}
    sensors_vector_lock--;
    #ifdef BUFFERED
      if(sensors_vector_lock==0 && getUpdate(IX_SENSORS)){
        sensors_vector = sensors_vector_buf; //memcpy...
        clearUpdate(IX_SENSORS);
	  }	
    #endif	
	return SUCCESS;
  }
    
#ifdef LOCATIONS
  command location_t Identity.getLocation(){
    return location;
  }
  
  command error_t Identity.lockLocation(){
    location_lock++;
    return SUCCESS;
  }
  
  command error_t Identity.unlockLocation(){
    if(location_lock == 0){
      return EUNLOCKU;
	}
    location_lock--;
    #ifdef BUFFERED
      if(location_lock==0 && getUpdate(IX_LOCATION)){
        location = location_buf; //memcpy...
        clearUpdate(IX_LOCATION);
      }	
    #endif	
    return SUCCESS;
  }

  command location_t Identity.getClusterHeadLocation(){
    return cluster_head_location;
  }
   
  
  command error_t Identity.lockClusterHeadLocation(){
    cluster_head_location_lock++;
    return SUCCESS;
  }
  
  command error_t Identity.unlockClusterHeadLocation(){
    if(cluster_head_location_lock == 0){
      return EUNLOCKU;
    }
    cluster_head_location_lock--;
    #ifdef BUFFERED
      if(cluster_head_location_lock==0 && getUpdate(IX_CLUSTER_HEAD_LOCATION)){
        cluster_head_location = cluster_head_location_buf; //memcpy...
        clearUpdate(IX_CLUSTER_HEAD_LOCATION);
      }	
    #endif	
    return SUCCESS;
  }
  
  command location_t Identity.getClusterRefLocation(){
    return cluster_ref_location;
  }
  
  
  command error_t Identity.lockClusterRefLocation(){
    cluster_ref_location_lock++;
    return SUCCESS;
  }
  
  command error_t Identity.unlockClusterRefLocation(){
    if(cluster_ref_location_lock == 0){
      return EUNLOCKU;
    }
    cluster_ref_location_lock--;
    #ifdef BUFFERED
      if(cluster_ref_location_lock==0 && getUpdate(IX_CLUSTER_REF_LOCATION)){
        cluster_ref_location = cluster_ref_location_buf; //memcpy...
        clearUpdate(IX_CLUSTER_REF_LOCATION);
      }	
    #endif	
    return SUCCESS;
  }

  command location_t Identity.getBackupClusterRefLocation(){
    return backup_cluster_ref_location;
  }
  
  command error_t Identity.lockBackupClusterRefLocation(){
    backup_cluster_ref_location_lock++;
    return SUCCESS;
  }
  
  command error_t Identity.unlockBackupClusterRefLocation(){
    if(backup_cluster_ref_location_lock == 0){
      return EUNLOCKU;
    }
    backup_cluster_ref_location_lock--;
    #ifdef BUFFERED
    if(backup_cluster_ref_location_lock==0 && 
                              getUpdate(IX_BACKUP_CLUSTER_REF_LOCATION)){
      backup_cluster_ref_location = backup_cluster_ref_location_buf; //memcpy...
      clearUpdate(IX_BACKUP_CLUSTER_REF_LOCATION);
    }	
    #endif	
    return SUCCESS;
  }
#endif

  command cluster_id_t Identity.getClusterID(){
	return cluster_id;
  }

  command error_t Identity.lockClusterID(){
	cluster_id_lock++;
	return SUCCESS;
  }
    
  command error_t Identity.unlockClusterID(){
	if(cluster_id_lock == 0){
	  return EUNLOCKU;
	}
	cluster_id_lock--;
	#ifdef BUFFERED
  	  if(cluster_id_lock==0 && getUpdate(IX_CLUSTER_ID)){
		cluster_id = cluster_id_buf; //memcpy...
		clearUpdate(IX_CLUSTER_ID);
	  }	
    #endif	
    return SUCCESS;
  }
    
  command cluster_id_t Identity.getBackupClusterID(){
    return backup_cluster_id;
  }
 
  command error_t Identity.lockBackupClusterID(){
    backup_cluster_id_lock++;
    return SUCCESS;
  }

  command error_t Identity.unlockBackupClusterID(){
    if(backup_cluster_id_lock == 0){
      return EUNLOCKU;
    }
    backup_cluster_id_lock--;
    #ifdef BUFFERED
      if(backup_cluster_id_lock==0 && getUpdate(IX_BACKUP_CLUSTER_ID)){
        backup_cluster_id = backup_cluster_id_buf; //memcpy...
        clearUpdate(IX_BACKUP_CLUSTER_ID);
      }	
    #endif	
    return SUCCESS;
  }

  command node_id_t Identity.getClusterHeadID(){
    return cluster_head_id;
  }
  
  command error_t Identity.lockClusterHeadID(){
	cluster_head_id_lock++;
	return SUCCESS;
  }
  
  command error_t Identity.unlockClusterHeadID(){
	if(cluster_head_id_lock == 0){
      return EUNLOCKU;
	}
	cluster_head_id_lock--;
    #ifdef BUFFERED
	  if(cluster_head_id_lock==0 && getUpdate(IX_CLUSTER_HEAD_ID)){
	    cluster_head_id = cluster_head_id_buf; //memcpy...
	    clearUpdate(IX_CLUSTER_HEAD_ID);
	  }	
    #endif	
	return SUCCESS;
  }

  command bool Identity.isClusterHead(){
	return (cluster_head_id == id);
  }

  command node_id_t Identity.getClusterSinkID(){
	return cluster_sink_id;
  }
  
  command error_t Identity.lockClusterSinkID(){
	cluster_sink_id_lock++;
	return SUCCESS;
  }
  
  command error_t Identity.unlockClusterSinkID(){
	if(cluster_sink_id_lock == 0){
	  return EUNLOCKU;
	}
	cluster_sink_id_lock--;
    #ifdef BUFFERED
	  if(cluster_sink_id_lock==0 && getUpdate(IX_SINK_ID)){
	    cluster_sink_id = cluster_sink_id_buf; //memcpy...
	    clearUpdate(IX_SINK_ID);
	  }	
    #endif	
	return SUCCESS;
  }

  command node_id_t Identity.getAggregatorID(){
	return aggregator_id;
  }
  
  command error_t Identity.lockAggregatorID(){
	aggregator_id_lock++;
	return SUCCESS;
  }
  
  command error_t Identity.unlockAggregatorID(){
	if(aggregator_id_lock == 0){
	  return EUNLOCKU;
	}
	aggregator_id_lock--;
    #ifdef BUFFERED
	  if(aggregator_id_lock==0 && getUpdate(IX_AGGREGATOR_ID)){
	    aggregator_id = aggregator_id_buf; //memcpy...
	    clearUpdate(IX_AGGREGATOR_ID);
	  }	
    #endif	
	return SUCCESS;
  }

  command uint8_t Identity.getSymKeyLen(){
	return SYM_KEY_LEN;
  }
    
  command uint8_t* Identity.getMasterKey(){
	return (uint8_t*)&master_key;
  }
  
  command error_t Identity.lockMasterKey(){
	master_key_lock++;
	return SUCCESS;
  }
  
  command error_t Identity.unlockMasterKey(){
	if(master_key_lock == 0){
	  return EUNLOCKU;
	}
	master_key_lock--;
    #ifdef BUFFERED
	  if(master_key_lock==0 && getUpdate(IX_MASTER_KEY)){
	    memcpy(&master_key, &master_key_buf, sizeof(master_key_buf));
	    clearUpdate(IX_MASTER_KEY);
	  }	
    #endif	
	return SUCCESS;
  }
    
  command uint8_t* Identity.getClusterKey(){
	return (uint8_t*)&cluster_key;
  }
  
  command error_t Identity.lockClusterKey(){
	cluster_key_lock++;
	return SUCCESS;
  }
  
  command error_t Identity.unlockClusterKey(){
	if(cluster_key_lock == 0){
	  return EUNLOCKU;
	}
	cluster_key_lock--;
    #ifdef BUFFERED
	  if(cluster_key_lock==0 && getUpdate(IX_CLUSTER_KEY)){
	    memcpy(&cluster_key, &cluster_key_buf, sizeof(cluster_key_buf));
	    clearUpdate(IX_CLUSTER_KEY);
	  }	
    #endif	
	return SUCCESS;
  }

  command uint8_t* Identity.getSinkKey(){
	return (uint8_t*)&sink_key;
  }
  
  command error_t Identity.lockSinkKey(){
	sink_key_lock++;
	return SUCCESS;
  }
  
  command error_t Identity.unlockSinkKey(){
	if(sink_key_lock == 0){
	  return EUNLOCKU;
	}
	sink_key_lock--;
    #ifdef BUFFERED
	  if(sink_key_lock==0 && getUpdate(IX_SINK_KEY)){
	    memcpy(&sink_key, &sink_key_buf, sizeof(sink_key_buf));
	    clearUpdate(IX_SINK_KEY);
	  }	
    #endif	
	return SUCCESS;
  }
    
  command uint8_t* Identity.getSharedKey(node_id_t nodeID){
	uint16_t ix = getSKIndex(nodeID);
	if(ix != MAX_KEY_NUM){
	  return (uint8_t*)&pairwise_keys[ix].key;
	}
	return NULL;
  }
  
  command error_t Identity.lockSharedKey(node_id_t nodeID){
	uint16_t ix = getSKIndex(nodeID);
	if(ix != MAX_KEY_NUM){
	  pairwise_keys_lock[ix]++;
	  return SUCCESS;
	}
	return EKEYNA;
  }
  
  command error_t Identity.unlockSharedKey(node_id_t nodeID){
	uint16_t ix = getSKIndex(nodeID);
	if(ix != MAX_KEY_NUM){
	  if(pairwise_keys_lock[ix] == 0){
		return EUNLOCKU;
	  }
	  pairwise_keys_lock[ix]--;
	  #ifdef BUFFERED
	    if(pairwise_keys_lock[ix]==0 && getSKUpdate(ix)){
	      memcpy(&pairwise_keys[ix].key, &pairwise_keys_buf[ix].key, 
	 				           sizeof(pairwise_keys_buf[ix].key));
	      clearSKUpdate(ix);
	    }	
	  #endif	
	  return SUCCESS;
	}
	return EKEYNA;    
  }

  command uint8_t Identity.getAsymPKeyLen(){
	return ASYM_PKEY_LEN;
  }
    
  command uint8_t* Identity.getPublicKey(){
	return (uint8_t*)&public_key;
  }
  
  command error_t Identity.lockPublicKey(){
	public_key_lock++;
	return SUCCESS;
  }
  
  command error_t Identity.unlockPublicKey(){
	if(public_key_lock == 0){
	  return EUNLOCKU;
	}
	public_key_lock--;
    #ifdef BUFFERED
	if(public_key_lock==0 && getUpdate(IX_PUBLIC_KEY)){
	  memcpy(&public_key, &public_key_buf, sizeof(public_key_buf));
	  clearUpdate(IX_PUBLIC_KEY);
	}	
    #endif	
	return SUCCESS;
  }

//interface IdentityWriter 

  command error_t IdentityWriter.setID(node_id_t new_id){
    #ifdef BUFFERED
	if(id_lock == 0){
	  id = new_id;
	  clearUpdate(IX_ID);
	}
	else{
	  id_buf = new_id;
	  setUpdate(IX_ID);
	}
	return SUCCESS;
    #else
	if(id_lock == 0){
	  id = new_id;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }
    
  command error_t IdentityWriter.setRoleVector(rolev_t new_role_vector){
    #ifdef BUFFERED
	if(role_vector_lock == 0){
	  role_vector = new_role_vector;
	  clearUpdate(IX_ROLES);
	}
	else{
	  role_vector_buf = new_role_vector;
	  setUpdate(IX_ROLES);
	}
	return SUCCESS;
    #else
	if(role_vector_lock == 0){
	  role_vector = new_role_vector;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }
    
  command error_t IdentityWriter.setSensorVector(sensorv_t new_sens_vector){
    #ifdef BUFFERED
	if(sensors_vector_lock == 0){
      sensors_vector = new_sens_vector;
	  clearUpdate(IX_SENSORS);
	}
	else{
	  sensors_vector_buf = new_sens_vector;
	  setUpdate(IX_SENSORS);
	}
	return SUCCESS;
    #else
	if(sensors_vector_lock == 0){
	  sensors_vector = new_sens_vector;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }
    
#ifdef LOCATIONS
  command error_t IdentityWriter.setLocation(location_t new_location){
    #ifdef BUFFERED
	if(location_lock == 0){
	  location = new_location;
	  clearUpdate(IX_LOCATION);
	}
	else{
	  location_buf = new_location;
	  setUpdate(IX_LOCATION);
	}
	return SUCCESS;
    #else
	if(location_lock == 0){
	  location = new_location;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }
#endif

//interface ClusterInfoWriter 

#ifdef LOCATIONS
  command error_t ClusterInfoWriter.setClusterHeadLocation(location_t new_cluster_head_location){
    #ifdef BUFFERED
	if(cluster_head_location_lock == 0){
	  cluster_head_location = new_cluster_head_location;
	  clearUpdate(IX_CLUSTER_HEAD_LOCATION);
	}
	else{
	  cluster_head_location_buf = new_cluster_head_location;
	  setUpdate(IX_CLUSTER_HEAD_LOCATION);
	}
	return SUCCESS;
    #else
	if(cluster_head_location_lock == 0){
	  cluster_head_location = new_cluster_head_location;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }

  command error_t ClusterInfoWriter.setClusterRefLocation(location_t new_cluster_ref_location){
    #ifdef BUFFERED
	if(cluster_ref_location_lock == 0){
	  cluster_ref_location = new_cluster_ref_location;
	  clearUpdate(IX_CLUSTER_REF_LOCATION);
	}
	else{
	  cluster_ref_location_buf = new_cluster_ref_location;
	  setUpdate(IX_CLUSTER_REF_LOCATION);
	}
	return SUCCESS;
    #else
	if(cluster_ref_location_lock == 0){
	  cluster_ref_location = new_cluster_ref_location;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }

  command error_t ClusterInfoWriter.setBackupClusterRefLocation(location_t new_backup_cluster_ref_location){
    #ifdef BUFFERED
	if(backup_cluster_ref_location_lock == 0){
	  backup_cluster_ref_location = new_backup_cluster_ref_location;
	  clearUpdate(IX_BACKUP_CLUSTER_REF_LOCATION);
	}
	else{
	  backup_cluster_ref_location_buf = new_backup_cluster_ref_location;
	  setUpdate(IX_BACKUP_CLUSTER_REF_LOCATION);
	}
	return SUCCESS;
    #else
	if(backup_cluster_ref_location_lock == 0){
	  backup_cluster_ref_location = new_backup_cluster_ref_location;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }
#endif

  command error_t ClusterInfoWriter.setClusterID(cluster_id_t new_cluster_id){
    #ifdef BUFFERED
	if(cluster_id_lock == 0){
	  cluster_id = new_cluster_id;
	  clearUpdate(IX_CLUSTER_ID);
	}
	else{
	  cluster_id_buf = new_cluster_id;
	  setUpdate(IX_CLUSTER_ID);
	}
	return SUCCESS;
    #else
	if(cluster_id_lock == 0){
	  cluster_id = new_cluster_id;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }
    
  command error_t ClusterInfoWriter.setBackupClusterID(cluster_id_t new_backup_cluster_id){
    #ifdef BUFFERED
	if(backup_cluster_id_lock == 0){
	  backup_cluster_id = new_backup_cluster_id;
	  clearUpdate(IX_BACKUP_CLUSTER_ID);
	}
	else{
	  backup_cluster_id_buf = new_backup_cluster_id;
	  setUpdate(IX_BACKUP_CLUSTER_ID);
	}
	return SUCCESS;
    #else
	if(backup_cluster_id_lock == 0){
	  backup_cluster_id = new_backup_cluster_id;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }

  command error_t ClusterInfoWriter.setClusterHeadID(node_id_t new_cluster_head_id){
    #ifdef BUFFERED
	if(cluster_head_id_lock == 0){
	  cluster_head_id = new_cluster_head_id;
	  clearUpdate(IX_CLUSTER_HEAD_ID);
	}
	else{
	  cluster_head_id_buf = new_cluster_head_id;
	  setUpdate(IX_CLUSTER_HEAD_ID);
	}
	return SUCCESS;
    #else
	if(cluster_head_id_lock == 0){
	  cluster_head_id = new_cluster_head_id;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }

  command error_t ClusterInfoWriter.setClusterSinkID(node_id_t new_cluster_sink_id){
    #ifdef BUFFERED
	if(cluster_sink_id_lock == 0){
	  cluster_sink_id = new_cluster_sink_id;
	  clearUpdate(IX_SINK_ID);
	}
	else{
	  cluster_sink_id_buf = new_cluster_sink_id;
	  setUpdate(IX_SINK_ID);
	}
	return SUCCESS;
    #else
	if(cluster_sink_id_lock == 0){
	  cluster_sink_id = new_cluster_sink_id;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }

  command error_t ClusterInfoWriter.setAggregatorID(node_id_t new_aggregator_id){
    #ifdef BUFFERED
	if(aggregator_id_lock == 0){
	  aggregator_id = new_aggregator_id;
	  clearUpdate(IX_AGGREGATOR_ID);
	}
	else{
	  aggregator_id_buf = new_aggregator_id;
	  setUpdate(IX_AGGREGATOR_ID);
	}
	return SUCCESS;
    #else
	if(aggregator_id_lock == 0){
	  aggregator_id = new_aggregator_id;
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }

//interface KeyInfoWriter 

  command error_t KeyInfoWriter.setMasterKey(void* new_master_key, 
                                                        uint8_t size){
    #ifdef BUFFERED
	if(master_key_lock == 0){
	  if(size < sizeof(master_key)){
		memset(&master_key, 0, sizeof(master_key));
		memcpy(&master_key, new_master_key, size);
	  }	
	  else{
		memcpy(&master_key, new_master_key, sizeof(master_key));
	  }	
	  clearUpdate(IX_MASTER_KEY);
	}
	else{
	  if(size < sizeof(master_key_buf)){
		memset(&master_key_buf, 0, sizeof(master_key_buf));
		memcpy(&master_key_buf, new_master_key, size);
	  }
	  else{
		memcpy(&master_key_buf, new_master_key, sizeof(master_key_buf));
	  }	
	  setUpdate(IX_MASTER_KEY);
	}
	return SUCCESS;
    #else
	if(master_key_lock == 0){
	  if(size < sizeof(master_key)){
		memset(&master_key, 0, sizeof(master_key));
		memcpy(&master_key, new_master_key, size);
	  }	
	  else{
		memcpy(&master_key, new_master_key, sizeof(master_key));
	  }	
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }
    
  command error_t KeyInfoWriter.setClusterKey(void* new_cluster_key, 
                                                              uint8_t size){
    #ifdef BUFFERED
	if(cluster_key_lock == 0){
	  if(size < sizeof(cluster_key)){
		memset(&cluster_key, 0, sizeof(cluster_key));
		memcpy(&cluster_key, new_cluster_key, size);
	  }	
	  else{
		memcpy(&cluster_key, new_cluster_key, sizeof(cluster_key));
	  }	
	  clearUpdate(IX_CLUSTER_KEY);
	}
	else{
	  if(size < sizeof(cluster_key_buf)){
		memset(&cluster_key_buf, 0, sizeof(cluster_key_buf));
		memcpy(&cluster_key_buf, new_cluster_key, size);
	  }
	  else{
		memcpy(&cluster_key_buf, new_cluster_key, sizeof(cluster_key_buf));
	  }	
	  setUpdate(IX_CLUSTER_KEY);
	}
	return SUCCESS;
    #else
	if(cluster_key_lock == 0){
	  if(size < sizeof(cluster_key)){
		memset(&cluster_key, 0, sizeof(cluster_key));
		memcpy(&cluster_key, new_cluster_key, size);
	  }	
	  else{
		memcpy(&cluster_key, new_cluster_key, sizeof(cluster_key));
	  }	
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }

  command error_t KeyInfoWriter.setSinkKey(void* new_sink_key, uint8_t size){
    #ifdef BUFFERED
	if(sink_key_lock == 0){
	  if(size < sizeof(sink_key)){
		memset(&sink_key, 0, sizeof(sink_key));
		memcpy(&sink_key, new_sink_key, size);
	  }	
	  else{
		memcpy(&sink_key, new_sink_key, sizeof(sink_key));
	  }	
	  clearUpdate(IX_SINK_KEY);
	}	
	else{
	  if(size < sizeof(sink_key_buf)){
		memset(&sink_key_buf, 0, sizeof(sink_key_buf));
		memcpy(&sink_key_buf, new_sink_key, size);
	  }
	  else{
		memcpy(&sink_key_buf, new_sink_key, sizeof(sink_key_buf));
	  }	
	  setUpdate(IX_SINK_KEY);
	}
	return SUCCESS;
    #else
	if(sink_key_lock == 0){
	  if(size < sizeof(sink_key)){
		memset(&sink_key, 0, sizeof(sink_key));
		memcpy(&sink_key, new_sink_key, size);
	  }	
	  else{
		memcpy(&sink_key, new_sink_key, sizeof(sink_key));
	  }	
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }
    
  command error_t KeyInfoWriter.setSharedKey(node_id_t nodeID, void* new_shared_key, 
                                                                 uint8_t size){
    //is this a key for a not yet "known" node?
    uint16_t ix = getSKIndex(nodeID);
    if(ix == MAX_KEY_NUM){
	  //do we have any empty slot for this new key?
	  ix = getFreeSKIndex();
	  
      //no all full :(
	  if(ix == MAX_KEY_NUM){
	    return ENMAFK;
	  }
	  
      //ok we have a slot, store the key, it is new so not locked for sure
	  pairwise_keys[ix].node_id = nodeID;
	
	  if(size < sizeof(pairwise_keys[ix].key)){
	    memset(&pairwise_keys[ix].key, 0, sizeof(pairwise_keys[ix].key));
	    memcpy(&pairwise_keys[ix].key, new_shared_key, size);
	  }        
	  else{
	    memcpy(&pairwise_keys[ix].key, new_shared_key, sizeof(pairwise_keys[ix].key));
	  }	
    }
    #ifdef BUFFERED
    //the node's key is already stored, check if it is locked
	if(pairwise_keys_lock[ix] == 0){
	  if(size < sizeof(pairwise_keys[ix].key)){
		memset(&pairwise_keys[ix].key, 0, sizeof(pairwise_keys[ix].key));
	    memcpy(&pairwise_keys[ix].key, new_shared_key, size);
	  }	
	  else{
		memcpy(&pairwise_keys[ix].key, new_shared_key, sizeof(pairwise_keys[ix].key));
	  }	
	  clearSKUpdate(ix);
	}
	else{
	  if(size < sizeof(pairwise_keys_buf[ix].key)){
		memset(&pairwise_keys_buf[ix].key, 0, sizeof(pairwise_keys_buf[ix].key));
	    memcpy(&pairwise_keys_buf[ix].key, new_shared_key, size);
	  }	
	  else{
		memcpy(&pairwise_keys_buf[ix].key, new_shared_key, sizeof(pairwise_keys_buf[ix].key));
	  }	
	  setSKUpdate(ix);
	}
	return SUCCESS;
    #else
    //the node's key is already stored, check if it is locked
	if(pairwise_keys_lock[ix] == 0){
	  if(size < sizeof(pairwise_keys[ix].key)){
	    memset(&pairwise_keys[ix].key, 0, sizeof(pairwise_keys[ix].key));
	    memcpy(&pairwise_keys[ix].key, new_shared_key, size);
	  }	
	  else{
		memcpy(&pairwise_keys[ix].key, new_shared_key, sizeof(pairwise_keys[ix].key));
	  }	
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }

  command error_t KeyInfoWriter.setPublicKey(void* new_public_key, uint8_t size){
    #ifdef BUFFERED
	if(public_key_lock == 0){
	  if(size < sizeof(public_key)){
		memset(&public_key, 0, sizeof(public_key));
		memcpy(&public_key, new_public_key, size);
	  }	
	  else{
		memcpy(&public_key, new_public_key, sizeof(public_key));
	  }	
	  clearUpdate(IX_PUBLIC_KEY);
	}
	else{
	  if(size < sizeof(public_key_buf)){
		memset(&public_key_buf, 0, sizeof(public_key_buf));
		memcpy(&public_key_buf, new_public_key, size);
	  }
	  else{
		memcpy(&public_key_buf, new_public_key, sizeof(public_key_buf));
	  }	
	  setUpdate(IX_PUBLIC_KEY);
	}
	return SUCCESS;
    #else
	if(public_key_lock == 0){
	  if(size < sizeof(public_key)){
		memset(&public_key, 0, sizeof(public_key));
		memcpy(&public_key, new_public_key, size);
	  }	    
	  else{
		memcpy(&public_key, new_public_key, sizeof(public_key));
	  }	
	  return SUCCESS;
	}
	return ELOCKED;	
    #endif
  }

 /**
  * initialize the module
  * used to clear the variables as needed
  */
  command error_t SoftwareInit.init(){

    // identity related information
    id = 0;
    id_lock = 0;
    
    role_vector = 0;
    role_vector_lock = 0;
    
    sensors_vector = 0;
    sensors_vector_lock = 0;
    
    #ifdef LOCATIONS
      memset(&location, 0, sizeof(location));
	  location_lock = 0;
    #endif

    // cluster related information
    cluster_id = 0;
    cluster_id_lock = 0;
    
    cluster_sink_id = 0;
    cluster_sink_id_lock = 0;
    
    aggregator_id = 0;
    aggregator_id_lock = 0;

    //keys
    //master_key[SYM_KEY_LEN]; //network-wide
    memset(&master_key, 0, sizeof(master_key));
    master_key_lock = 0;
    
    //cluster_key[SYM_KEY_LEN]; //cluster-wide
    memset(&cluster_key, 0, sizeof(cluster_key));
    cluster_key_lock = 0;
    
    //sink_key[SYM_KEY_LEN]; //shared with the sink
    memset(&sink_key, 0, sizeof(sink_key));
    sink_key_lock = 0;
      
    //keys shared with other nodes
    //pairwise_keys[MAX_KEY_NUM]; 
    memset(&pairwise_keys, 0, sizeof(pairwise_keys));
    //pairwise_keys_lock[MAX_KEY_NUM];
    memset(&pairwise_keys_lock, 0, sizeof(pairwise_keys_lock));
    
    //the public key
    //public_key[ASYM_PKEY_LEN]; 
    memset(&public_key, 0, sizeof(public_key));
    public_key_lock = 0;

  #ifdef BUFFERED
    
    //a bitvector that indicates that updates to variables 
    //are waiting in the buffer to be written on unlock
    //EXCEPT the pairwise keys
    update_vector = 0;
    
    //an array of bytes containing the update bits for the pairwise keys
    //key_update_vector[(MAX_KEY_NUM >> 3) + 1];    
    memset(&key_update_vector, 0, sizeof(key_update_vector));

  #endif
	
    return SUCCESS;
  }
}
