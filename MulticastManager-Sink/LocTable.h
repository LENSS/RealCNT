#ifndef LOCTABLE_H
#define LOCTABLE_H

class LocTable {
	private:
		vector<String> locTable;
	public:
		void addLocation(unsigned int memberID, Location nodeLoc);
		void deleteLocation(unsigned int memberID, Location nodeLoc);
}

#endif