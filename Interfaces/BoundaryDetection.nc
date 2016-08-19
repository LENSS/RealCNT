interface BoundaryDetection
{
    // initiates the boundary detection
    // i.e., runs BOUNDHOLE algorithm
    // during the application of BOUNDHOLE algorithm, 
    // vertex nodes are identified.
    command error_t initBoundaryDetection(uint8_t delta);

    command error_t abstractBoundary(uint8_t delta);

    // returns true if this node is a boundary node
    command bool isBoundaryNode(void);

    // returns true if this node is a vertex node
    command bool isVertexNode(void);

    // returns vertex nodes
    command Loc *getVertexNodes(uint8_t holeID);
  
    // returns the number of holes
    command uint8_t getNumHoles(void);
}

