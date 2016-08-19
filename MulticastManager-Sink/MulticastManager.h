#ifndef MULTICASTMANAGER_H
#define MULTICASTMANAGER_H

enum {JOIN, LEAVE, LOCREPORT, MCASTREQUEST} msgType;

typedef struct
{
	double x;
	double y;
} Location;

//Location *locationTable;
//Location **memberTable;

#endif /* MULTICASTMANAGER_H */