#include <stdio.h>
#include <stdlib.h>
#include "Loc_UDG.txt"
#include <math.h>

#define RADIO_RANGE 3

int **node_id;
int max_row, max_col;

void findNeighbors(int id, FILE *fp) {
   int cur_x, cur_y; // current location
   int nei_x, nei_y; // neighbor location
   int i,j;
   double distance;
 
   cur_x = init_x[id];
   cur_y = init_y[id];
 
   for (i=0; i < max_row; i++) {
      for (j=0; j < max_col; j++) {
         if (id == node_id[i][j]) continue;
         nei_x = init_x[node_id[i][j]];
         nei_y = init_y[node_id[i][j]];
         distance = sqrt((float)(abs(cur_x - nei_x)*abs(cur_x - nei_x) + abs(cur_y - nei_y)*abs(cur_y - nei_y)));
         if (distance < RADIO_RANGE) {
            fprintf(fp, "gain\t%d\t%d\t-1.0\n", id, node_id[i][j]); 
         }
         else 
            fprintf(fp, "gain\t%d\t%d\t-150.0\n", id, node_id[i][j]); 
      }
   }
   
}

int main(void) {

   FILE *fp_in, fp_out;
   char tmp_str[128];
   char dummy[128];
   int i, j;
   float dbm;
   int k = 0;
  
   printf("row?:"); 
   scanf("%d", &max_row);
   printf("col?:"); 
   scanf("%d", &max_col);

   node_id = malloc(max_row * sizeof(int*));
   for (i=0; i < max_row; i++)
      node_id[i] = malloc(max_col * sizeof(int));

   for (i=0; i < max_row; i++) {
      for (j=0; j < max_col; j++) {
         node_id[i][j] = k;
         k++;
         //printf("node id of row %d col %d is %d\n", i, j, node_id[i][j]);
      }
   }

   //sprintf(tmp_str, "%d_by_%d_topo_udg.txt", max_row, max_col);
   //printf("%s generated.\n", tmp_str);  
 
   fp_in = fopen("udg_topo.out", "w");
 
   for (i = 0; i < max_row; i++) {
      for (j = 0; j < max_col; j++) {
         findNeighbors(node_id[i][j], fp_in);
      }
   } 
    
   for (i=0; i < max_row; i++)
      free(node_id[i]);

   return 0;
}

