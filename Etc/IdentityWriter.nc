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
 * @file   IdentityWriter.nc
 * @author Krzysztof Piotrowski
 * @date   Sat Nov 08 07:00:00 2008
 *
 * @brief IdentityWriter - The interface for Identity Writers
 *
 */

#include "identity.h"

interface IdentityWriter {

  //function to set the ID
  command error_t setID(node_id_t new_id);
    
  //function to set the RoleVector
  command error_t setRoleVector(rolev_t new_role_vector);
    
  //function to set the SensorVector
  command error_t setSensorVector(sensorv_t new_sens_vector);
    
#ifdef LOCATIONS
  //function to set the Location
  command error_t setLocation(location_t new_location);
#endif

}
