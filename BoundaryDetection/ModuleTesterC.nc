/***************************************************************************
 * NeighborManagement module tester.
 * Author: Myounggyu Won
 */
 
#ifdef LOG
#include "StorageVolumes.h"
#endif

configuration ModuleTesterC{
}
implementation{
	components MainC, ActiveMessageC, ModuleTesterP, NeighborManagementC, BoundaryDetectionC, IdentityC;
	components new TimerMilliC() as NeighborDiscoveryTimer;
	components new TimerMilliC() as BoundaryDetectionTimer;
	components new TimerMilliC() as DeploymentTimer;
	components ResetC, LedsC;
#ifdef LOG
	components DebugC;
	components new LogStorageC(VOLUME_DATALOG, FALSE);
	components new TimerMilliC() as LogTimer;
	components new TimerMilliC() as ResetTimer;
	ModuleTesterP.LogRead -> LogStorageC;
  	ModuleTesterP.LogWrite -> LogStorageC;
  	ModuleTesterP.LogTimer -> LogTimer;
  	ModuleTesterP.ResetTimer -> ResetTimer;	
  	ModuleTesterP.Debug -> DebugC;
#endif
	
	ModuleTesterP.Leds -> LedsC;
	ModuleTesterP.Reset -> ResetC;
	ModuleTesterP -> MainC.Boot;
	ModuleTesterP.NeighborDiscoveryTimer -> NeighborDiscoveryTimer;
	ModuleTesterP.BoundaryDetectionTimer -> BoundaryDetectionTimer;
	ModuleTesterP.DeploymentTimer -> DeploymentTimer;
	ModuleTesterP.Neighborhood -> NeighborManagementC;
	ModuleTesterP.BoundaryDetection -> BoundaryDetectionC;
	ModuleTesterP.AMControl -> ActiveMessageC;
	ModuleTesterP.Identity -> IdentityC;
}