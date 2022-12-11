/**
 * spigot.c
 *
 * (c) Samuel DEVULDER, Nov 2015
 */
#include <stdio.h>
#include <stdlib.h>

typedef unsigned long long num;

int bitmax(num v) {
	int i=0;
	while(v) {++i;v>>=1;}
	return i;
}

int main(int argc, char **argv) {
	int i,j,N,LEN;
	int nines=0, predigit=0;
	num *a, bitsA=0, bitsX=0, bitsQ=0, maxQ=0;
	
	N = atoi(argv[1]);
	printf("N=%d\n",N);
	if(N==0) N=770;
	LEN = (N*10)/3+5;
	a = malloc(sizeof(*a)*(LEN+1)); if(a==NULL) exit(-1);
	
	for(i=LEN;--i;) a[i]=2;
	for(j=N; --j;) {
		num q = 0,x;
		for(i=LEN;i;--i) {
			bitsX |= (x = 10*a[i] + q*i);
			bitsA |= (a[i] = x % (2*i-1));
			bitsQ |= (q = x / (2*i-1));
		}
		a[1] = q%10; q=q/10;if(q>maxQ) maxQ=q;
		switch(q) {
			case 9: ++nines; break;
			case 10: //printf(" %d", predigit+1); for(i=0;i<nines;++i) printf("0"); 
			predigit=0;nines=0; break;
			default: //printf(" %d", predigit);   for(i=0;i<nines;++i) printf("9"); 
			predigit=q;nines=0; break;
		}
		//fflush(stdout);
	}
	//printf(" %d\n",predigit);
	free(a);
	
	printf("%d bits for %c\n", bitmax(bitsX), 'X');
	printf("%d bits for %c\n", bitmax(bitsA), 'A');
	printf("%d bits for %c\n", bitmax(bitsQ), 'Q');
	printf("maxQ=%lld\n", maxQ);
	
	return 0;
}
