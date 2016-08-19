#include "../../Common.h"

interface Identity{
	command location_t getMyLoc(); 
	command location_t getLoc(uint16_t id);
}