/*******************************************************************
 * Implementation for the interface of Geometry Support
 * Mainly designed for code reduction by abstracting common code used in different modules
 * Author: Myounggyu Won
 */
 #include "../../Common.h"
 
interface GeometrySupport{
	command bool isPointOnLineSegment(point_t pt, line_t lineSeg);
	command point_t getIntersection(line_t lineA, line_t lineB);
	command line_t getPerpendicularBisector(line_t line);
	command int16_t getAngleABC(point_t a, point_t b, point_t c);
	command location_t ToLocation(nx_location_t p_location);
	command float leastSqrRegression(point_t* xyCollection, uint16_t dataSize);
}