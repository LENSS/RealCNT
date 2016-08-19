module IdentityP{
	provides interface Identity;
}
implementation{
	#include "20_by_20_loc.txt"
	//#include "smallTestLoc.txt"
    //#include "5by5.txt"
	
	command location_t Identity.getMyLoc(){
		location_t myLoc;
		
		myLoc.x = node_x[TOS_NODE_ID];
		myLoc.y = node_y[TOS_NODE_ID];
		return myLoc;
	}

	command location_t Identity.getLoc(uint16_t id){
		location_t loc;
		
		loc.x = node_x[id];
		loc.y = node_y[id];
		return loc;
	}
}
