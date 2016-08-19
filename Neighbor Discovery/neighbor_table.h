

typedef nx_struct dn_neighbor_table_t {
	
	//From cc2420_header_t
	nxle_uint8_t length;    //Total size of the packet in bytes
	nxle_uint16_t fcf;      //Frame control field, see p38 of the CC2420 datasheet
	nxle_uint8_t dsn;       //Data sequence number
	nxle_uint16_t destpan;  //Destination PAN number, used to distinguish between nets ont he same freq
	nxle_uint16_t dest;     //Destination address of packet
	nxle_uint16_t src;      //Source address of packet
	
 	//From cc2420_metadata_t
	nxle_uint8_t rssi;        //
	nxle_uint8_t lqi;         // 
	nxle_uint8_t tx_power;    //
	nxle_uint8_t crc;            //
	nxle_uint8_t ack;            //
	nxle_uint8_t timesync;       //
	nxle_uint32_t timestamp;  //
	nxle_uint16_t rxInterval; //
} dn_neighbor_table_t;