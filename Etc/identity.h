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
 * @file   identity.h
 * @author Krzysztof Piotrowski
 * @date   Sat Nov 08 07:00:00 2008
 *
 * @brief identity header file
 *
 */

#ifndef IDENTITY_H
#define IDENTITY_H

//comment out the following line to save memory
#define BUFFERED

//TODO:Added by Mike to fix compile problem
//Diagnose and fix problem later
#define GEOLOCATIONS

//define the constants
enum {
    //ROLES
    SENSOR 	= 1, // 2^0
    AGGREGATOR 	= 2, // 2^1
    SINK	= 4, // 2^2
    GPS   =16,
    
    //AVAILABLE SENSORS
    TEMP	= 1,
    HUM		= 2,
    LIGHT	= 4, //To be extended
    
    //KEY PARAMETERS - TO DEFINE THE ARRAY SIZES
    SYM_KEY_LEN = 16, // IN BYTES!!! -> 128 bits
    MAX_KEY_NUM = 2, // the max number of nodes to share the key with

    //Asymmetric private key length
    ASYM_SKEY_LEN = 20, // IN BYTES!!! 160 bits - field size for ECC
    //Asymmetric public key length
    ASYM_PKEY_LEN = 40, // IN BYTES!!! 320 bits - 2 x field size for ECC

    //errors
    EKEYNA      = 20, //key not available for the nodeid
    ELOCKED	= 21, //value is locked
    EUNLOCKU 	= 22, //unlock underflow (unlock rqst but counter already 0)
    ENMAFK	= 23, //no memory available for key
};
//the type for the role vector (adjust according to the number of roles)
typedef uint8_t rolev_t;

//the type for the sensor vector (adjust according to the number of
//possible sensor type)
typedef uint8_t sensorv_t;

//the node ID type
typedef uint16_t node_id_t;

//the cluster ID type
typedef uint8_t cluster_id_t;


//LOCATION RELATED STUFF
//the type for the coordinates
typedef uint16_t coord_t;

typedef nxle_uint16_t nxle_coord_t;

#ifdef GEOLOCATIONS
    #define LOCATIONS
    //two dimensions - the geo coords
    
    typedef nx_struct nxle_location_t {
    nxle_coord_t     x;
    nxle_coord_t  y;
    } nxle_location_t;    
    
    typedef struct location {
	coord_t   x;
	coord_t	  y;
    } location_t;
        
    enum{DIMENSIONS = 2};
    

#else
    #ifdef TRIDLOCATIONS
	#define LOCATIONS
	//three dimensions - 3D coords
        typedef struct location {
    	    coord_t 	x, 
			y, 
			z;
        } location_t;    
	enum{DIMENSIONS = 3};
    #endif
#endif

//update(if BUFFERED) vector bit indices
enum{				 // index	
    IX_ID		= 0x00, //  0 
    IX_ROLES		= 0x01, //  1 
    IX_SENSORS		= 0x02, //  2 
    IX_LOCATION		= 0x03, //  3 
    IX_CLUSTER_HEAD_LOCATION = 0x04, //  4
    IX_CLUSTER_REF_LOCATION = 0x05, // 5
    IX_BACKUP_CLUSTER_REF_LOCATION = 0x06, // 6
    IX_CLUSTER_ID	= 0x07, //  7
    IX_BACKUP_CLUSTER_ID = 0x08, //  8
    IX_CLUSTER_HEAD_ID	= 0x09, //  9
    IX_SINK_ID		= 0x0a, //  10
    IX_AGGREGATOR_ID	= 0x0b, //  11
    IX_MASTER_KEY	= 0x0c, //  12
    IX_CLUSTER_KEY	= 0x0d, //  13
    IX_SINK_KEY		= 0x0e, //  14
    IX_PUBLIC_KEY	= 0x0f, // 15    
};

//always define a type that is big enough to hold the vector
typedef uint16_t vector_t;

//define type used for lock counters
typedef uint8_t lock_counter_t;

//structure to store the key shared with a node with the given id
typedef struct shared_key{
    node_id_t    node_id;
    uint8_t key[SYM_KEY_LEN];
} shared_key_t;

//structure to buffer a key shared with a node
typedef struct shared_key_buf{
    uint8_t key[SYM_KEY_LEN];
} shared_key_buf_t;

#endif

