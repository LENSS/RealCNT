/***************************************************************************
 * NeighborManagement module tester.
 * Author: Myounggyu Won
 */
 
configuration ModuleTesterC{
}
implementation{
	components MainC, ActiveMessageC, ModuleTesterP, NeighborManagementC;
	
	ModuleTesterP -> MainC.Boot;
	ModuleTesterP.Neighborhood -> NeighborManagementC;
	ModuleTesterP.AMControl -> ActiveMessageC;
}