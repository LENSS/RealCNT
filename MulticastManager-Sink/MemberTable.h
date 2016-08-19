#ifndef MEMBERTABLE_H
#define MEMBERTABLE_H

class MemberTable {
	private:
		vector<String> memberTable;
	public:
		void addMember(unsigned int memberID, Location nodeLoc);
		void deleteMember(unsigned int memberID, Location nodeLoc);
}
#endif