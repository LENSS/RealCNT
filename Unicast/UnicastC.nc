configuration UnicastC{
	provides Unicast;
}
implementation{
	components GFP, BoudaryDetectionP, UnicastP;
	
	Unicast.GF -> GFP
	Unicast.BoundaryDetection -> BoundaryDetectionP;
	Unicast = UnicastP;
}