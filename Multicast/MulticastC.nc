configuration MulticastC{
	provides Multicast;
}
implementation{
	components MulticastP, UnicastP, ConvergecastP;
	
	MulticastP.Unicast -> UnicastP;
	MulticastP.Convergecast -> ConvergecastP;
	Multicast = MulticastP;
	
}