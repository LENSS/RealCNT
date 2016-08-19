
#include "../../Common.h"

#ifndef NEIGHBORMANAGEMENT_H
#define NEIGHBORMANAGEMENT_H

typedef nx_struct _keepAlive 
{
    nx_location_t m_location; 
    nx_uint16_t m_id;
    nx_uint16_t seqNum;
    nx_uint16_t neiList[MAX_NEIGHBORS];
} keep_alive_t;

#endif

