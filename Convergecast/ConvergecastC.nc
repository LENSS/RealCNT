configuration ConvergecastC{
	provides Convergecast;
}
implementation{
	componenets ConvergecastP, UnicastP;
	
	Convergecast.Unicast -> UnicastP;
	Convergecast = ConvergecastP;
}