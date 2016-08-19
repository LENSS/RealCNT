#include "../../Common.h"

interface BoundaryDetection{
	// initiates the boundary detection
    // i.e., runs BOUNDHOLE algorithm
    // during the application of BOUNDHOLE algorithm, 
    // vertex nodes are identified.
    command error_t initBoundaryDetection(uint8_t delta);
    command void Init();
    // returns true if this node is a boundary node
    command bool isBoundaryNode();

    // returns vertex nodes
    command location_t* getVertices();
  	//command neighbor_t getNextNeighborRightHand(point_t *prevLocs);
    // returns the number of holes
    //command uint8_t getNumHoles(void);
}