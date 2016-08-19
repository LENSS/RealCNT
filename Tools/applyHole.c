#include <stdio.h>
#include <stdlib.h>

#define TRUE 1
#define FALSE 0

unsigned int search_hole(int node_id); 

int nodes_in_hole[1000];

int main(int argc, char **argv) {

   FILE *fp_in, *fp_in2, *fp_out;
   char tmp_str[128];
   char dummy[128];
   int i, x, y;
   float dbm, gain;
   int row, col;

   // first argument: linkgain 
   fp_in = fopen(argv[1], "r");
   // second argument: hole file, a set of ids located in a hole 
   fp_in2 = fopen(argv[2], "r");
   fp_out = fopen("linkgain_hole.out", "w");
 
   // save node ids located in the given hole
   for (i = 0; i < 1000; i++) nodes_in_hole[i] = -1;
   i = 0; 
   while (fgets(tmp_str, 128, fp_in2)) {
      sscanf(tmp_str, "%d", &nodes_in_hole[i]);
      i++;
   }

   while (fgets(tmp_str, 128, fp_in)) {
      sscanf(tmp_str, "%s %d %d %f", dummy, &x, &y, &dbm);
      if (!strcmp(dummy, "gain")) {
         if (search_hole(x) || search_hole(y)) {
            dbm = -150.0; 
            fprintf(fp_out, "gain\t%d\t%d\t%f\n", x, y, dbm);
         }
         else
            fprintf(fp_out, "gain\t%d\t%d\t%f\n", x, y, dbm);
      }
   } 
   return 0;
}

// returns TRUE if the node_id is located in the hole, otherwise returns FALSE
unsigned int search_hole(int node_id) {
   int i;
   for (i = 0; i < 1000; i++) {
      if (nodes_in_hole[i]==node_id)
         return TRUE;
   }   
   return FALSE;
}
