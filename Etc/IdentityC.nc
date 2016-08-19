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
 * @file   IdentityC.nc
 * @author Krzysztof Piotrowski
 * @date   Sat Nov 08 07:00:00 2008
 *
 * @brief IdentityC - The configuration of the Identity module, 
 * Wire to the provided interfaces to get the desired 
 * access functionality 
 * questions? piotrowski at ihp-ffo.de
 */

configuration IdentityC{
    provides{
	interface Identity;
	interface IdentityWriter;
	interface ClusterInfoWriter;
	interface KeyInfoWriter;
    }    
}

implementation{
    components IdentityP;
    Identity          = IdentityP.Identity;
    IdentityWriter    = IdentityP.IdentityWriter;
    ClusterInfoWriter = IdentityP.ClusterInfoWriter;
    KeyInfoWriter     = IdentityP.KeyInfoWriter;
    
    components MainC;
    MainC -> IdentityP.SoftwareInit;
}
