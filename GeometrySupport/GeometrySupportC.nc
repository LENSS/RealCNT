/*******************************************************************
 * Implementation for the configuration of Geometry Support
 * Mainly designed for code reduction by abstracting common code used in different modules
 * Author: Myounggyu Won
 */
configuration GeometrySupportC{
	provides interface GeometrySupport;
}
implementation{
	components GeometrySupportP;
	GeometrySupport = GeometrySupportP;
}