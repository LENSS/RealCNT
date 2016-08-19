/**
 * Application code for testing the GPSR module
 * Author: MG Won
 **/
 
configuration GPSRTesterC
{
}
implementation
{
  //components MainC, GPSRTesterP, LedsC, GPSRP, IdentityP, NeighborManagementP;
  components MainC, GPSRTesterP, LedsC, NeighborManagementC, ActiveMessageC, GPSRC, IdentityC;
  components new TimerMilliC() as Timer0;
  components new TimerMilliC() as Timer1;
  components new TimerMilliC() as Timer2;
  components BoundaryDetectionC;
  
  GPSRTesterP -> MainC.Boot;
  GPSRTesterP.BoundaryDetection -> BoundaryDetectionC;
  GPSRTesterP.Timer0 -> Timer0;
  GPSRTesterP.Timer1 -> Timer1;
  GPSRTesterP.Timer2 -> Timer2;
  GPSRTesterP.Leds -> LedsC;
  GPSRTesterP.GPSR -> GPSRC.GPSR[0];
  GPSRTesterP.Identity -> IdentityC;
  GPSRTesterP.Neighborhood -> NeighborManagementC;
  GPSRTesterP.AMControl -> ActiveMessageC;
}
