/*******************************************************************
 * Implementation for the module of Geometry Support
 * Mainly designed for code reduction by abstracting common code used in different modules
 * Author: Myounggyu Won
 */
#include <math.h>

module GeometrySupportP{
	provides interface GeometrySupport;
}
implementation{

	command float GeometrySupport.leastSqrRegression(point_t* xyCollection, uint16_t dataSize)
	{
		float SUMx = 0;     //sum of x values
		float SUMy = 0;     //sum of y values
		float SUMxy = 0;    //sum of x * y
		float SUMxx = 0;    //sum of x^2
		float SUMres = 0;   //sum of squared residue
		float res = 0;      //residue squared
		float slope = 0;    //slope of regression line
		float y_intercept = 0; //y intercept of regression line
		float SUM_Yres = 0; //sum of squared of the discrepancies
		float AVGy = 0;     //mean of y
		float AVGx = 0;     //mean of x
		float Yres = 0;     //squared of the discrepancies
		float Rsqr = 0;     //coefficient of determination
		uint16_t i;
		
		//calculate various sums 
		for (i = 0; i < dataSize; i++)
		{
			//sum of x
			SUMx = SUMx + (xyCollection + i)->x;
			//sum of y
			SUMy = SUMy + (xyCollection + i)->y;
			//sum of squared x*y
			SUMxy = SUMxy + (xyCollection + i)->x * (xyCollection + i)->y;
			//sum of squared x
			SUMxx = SUMxx + (xyCollection + i)->x * (xyCollection + i)->x;
		}
		//calculate the means of x and y
		AVGy = SUMy / dataSize;
		AVGx = SUMx / dataSize;
		//slope or a1
		slope = (dataSize * SUMxy - SUMx * SUMy) / (dataSize * SUMxx - SUMx*SUMx);
		//y itercept or a0
		y_intercept = AVGy - slope * AVGx;

		//printf("x mean(AVGx) = %0.5E\n", AVGx);
		//printf("y mean(AVGy) = %0.5E\n", AVGy);
		//printf ("\n");
		//printf ("The linear equation that best fits the given data:\n");
		//printf ("       y = %2.8lfx + %2.8f\n", slope, y_intercept);
		//printf ("------------------------------------------------------------\n");
		//printf ("   Original (x,y)   (y_i - y_avg)^2     (y_i - a_o - a_1*x_i)^2\n");
		//printf ("------------------------------------------------------------\n");
		//calculate squared residues, their sum etc.
		for (i = 0; i < dataSize; i++) 
		{
			//current (y_i - a0 - a1 * x_i)^2
			Yres = (float)pow(((xyCollection + i)->y - y_intercept - (slope * (xyCollection + i)->x)), 2);

			//sum of (y_i - a0 - a1 * x_i)^2
			SUM_Yres += Yres;

			//current residue squared (y_i - AVGy)^2
			res = (float)pow((xyCollection + i)->y - AVGy, 2);

			//sum of squared residues
			SUMres += res;
 
			//printf ("   (%0.2f %0.2f)      %0.5E         %0.5E\n", 
			//(xyCollection + i)->x, (xyCollection + i)->y, res, Yres);
		}
		//calculate r^2 coefficient of determination
		Rsqr = (SUMres - SUM_Yres) / SUMres;

		dbg("BoundaryDetection", "--------------------------------------------------\n");
		//printf("Sum of (y_i - y_avg)^2 = %0.5E\t\n", SUMres);
		//printf("Sum of (y_i - a_o - a_1*x_i)^2 = %0.5E\t\n", SUM_Yres);
		//dbg("BoundaryDetection", "Standard deviation(St) = %0.5E\n", sqrt(SUMres / (dataSize - 1)));
		//dbg("BoundaryDetection", "Standard error of the estimate(Sr) = %0.5E\t\n", sqrt(SUM_Yres / (dataSize-2)));
		//dbg("BoundaryDetection", "Coefficent of determination(r^2) = %0.5E\t\n", (SUMres - SUM_Yres)/SUMres);
		//dbg("BoundaryDetection", "Correlation coefficient(r) = %0.5E\t\n", sqrt(Rsqr));
		dbg("BoundaryDetection", "Standard deviation(St) = %f\n", sqrtf(SUMres / (dataSize - 1)));
		dbg("BoundaryDetection", "Standard error of the estimate(Sr) = %f\t\n", sqrtf(SUM_Yres / (dataSize-2)));
		dbg("BoundaryDetection", "Coefficent of determination(r^2) = %f\t\n", (SUMres - SUM_Yres)/SUMres);
		dbg("BoundaryDetection", "Correlation coefficient(r) = %f\t\n", sqrtf(Rsqr));
		return sqrtf(Rsqr);
	}

	command bool GeometrySupport.isPointOnLineSegment(point_t pt, line_t lineSeg){
		float slope, intercept;
		float x1_, y1_, x2_, y2_;
		float px, py;
		float left, top, right, bottom; // Bounding Box For Line Segment
		float dx, dy;
		float epsilon = 0.00001f;
		
		px = pt.x; py = pt.y;
		x1_ = lineSeg.start.x; y1_ = lineSeg.start.y;
		x2_ = lineSeg.end.x; y2_ = lineSeg.end.y;	
		dx = x2_ - x1_;
		dy = y2_ - y1_;
		slope = dy / dx;
		intercept = y1_ - slope * x1_; // which is same as y2 - slope * x2
		// For Bounding Box
		if(x1_ < x2_)
		{
			left = x1_;
			right = x2_;
		}
		else
		{
			left = x2_;
			right = x1_;
		}
		if(y1_ < y2_)
		{
			bottom = y1_;
			top = y2_;
		}
		else
		{
			top = y1_;
			bottom = y2_;
		}
		if (fabs(x1_ - x2_) < epsilon)
		{
			if (fabs(x1_ - px) < epsilon)
			{
				if( ((px > left) || (fabs(px - left) < epsilon)) && ((px < right) || (fabs(px - right) < epsilon)) && 
					((py < top) || (fabs(py - top) < epsilon)) && ((py > bottom) || (fabs(py - bottom) < epsilon)))
				{
					return TRUE;
				}
				else
					return FALSE;
			}	
			else
				return FALSE;
		}
		else {
			if (fabs(slope * px + intercept - py) < epsilon)
			{
				//dbg("BoundaryDetection", "pt: (%f, %f) left: %f right: %f top: %f bottom: %f\n", px, py, left, right, top, bottom);
				if( ((px > left) || (fabs(px - left) < epsilon)) && ((px < right) || (fabs(px - right) < epsilon)) && 
					((py < top) || (fabs(py - top) < epsilon)) && ((py > bottom) || (fabs(py - bottom) < epsilon)))
				{
					return TRUE;
				}
				else
					return FALSE;
			}
			else
				return FALSE;
		}	
	}

	command point_t GeometrySupport.getIntersection(line_t lineA, line_t lineB){
		point_t intersection;
		float a1, b1, c1;
		float a2, b2, c2;
		float det;
		float epsilon = 0.00001f;
		
		intersection.x = 0.0f;
		intersection.y = 0.0f;
		a1 = lineA.end.y - lineA.start.y;
		b1 = lineA.start.x - lineA.end.x;
		c1 = a1 * lineA.start.x + b1 * lineA.start.y;
		a2 = lineB.end.y - lineB.start.y;
		b2 = lineB.start.x - lineB.end.x;
		c2 = a2 * lineB.start.x + b2 * lineB.start.y;
		det = a1 * b2 - a2 * b1;
		
		if (fabs(det) < epsilon)
			dbg("BoundaryDetection", "det is 0!\n");
		else
		{
			intersection.x = (b2 * c1 - b1 * c2) / det;
			intersection.y = (a1 * c2 - a2 * c1) / det;
		}
		return intersection;
	}

	command line_t GeometrySupport.getPerpendicularBisector(line_t line){
		line_t bisector;
		float a1, b1, c1;
		
		a1 = line.end.y - line.start.y;
		b1 = line.start.x - line.end.x;
		bisector.start.x = (float)(line.start.x	+ line.end.x) / 2.0f;
		bisector.start.y = (float)(line.start.y	+ line.end.y) / 2.0f;
		c1 = -b1 * bisector.start.x + a1 * bisector.start.y;
		// bisector.end ...
		bisector.end.x = 0;
		bisector.end.y = c1 / a1;
		
		return bisector;
	}

	command int16_t GeometrySupport.getAngleABC(point_t a, point_t b, point_t c){
		point_t ab = { b.x - a.x, b.y - a.y };
    	point_t cb = { b.x - c.x, b.y - c.y };
    	float dot = (ab.x * cb.x + ab.y * cb.y);
    	float abSqr = ab.x * ab.x + ab.y * ab.y;
    	float cbSqr = cb.x * cb.x + cb.y * cb.y; 
    	float cosSqr = dot * dot / abSqr / cbSqr;
    	float cos2 = 2 * cosSqr - 1;
    	float pi = 3.141592f;
    	float alpha2 =
        	(cos2 <= -1) ? pi :
        	(cos2 >= 1) ? 0 :
        	(float)acos(cos2);
    	float rslt = alpha2 / 2;
    	float rs = rslt * 180.0f / pi;
		float det = (ab.x * cb.y - ab.y * cb.x);

    	if (dot < 0)
    	{
        	rs = 180 - rs;
        }
    	if (det < 0)
        	rs = -rs;
        if (rs < 0)
        	rs = 360 + rs;
    	return (int16_t) floor(rs + 0.5);
	}

	command location_t GeometrySupport.ToLocation(nx_location_t p_location){
		location_t tmp;

		tmp.x = p_location.x;
		tmp.y = p_location.y;

		return tmp;
	}
}