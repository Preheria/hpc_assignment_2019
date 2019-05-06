	#include <stdio.h>
	#include <string.h>
	#include <stdlib.h>
	#include <crypt.h>
	#include <mpi.h>
	#include <string.h>
	#include <time.h>

/*****************************************************************************
The variable names and the function names of this program is same as provided by the university.
The added variable and function are the only changes made to this program.
  

To compile:
     mpicc -o two_initial_four_digit_mpi two_initial_four_digit_mpi.c -lrt -lcrypt
     
  To run 3 processes on this computer:
    mpirun -n 3 ./two_initial_four_digit_mpi 
*****************************************************************************/



	int count = 0;// Global variable declaration so they can be accessed throughout the file.
	int n_passwords = 4;
	int size, rank, pass;

// Passwords encrypted using EncryptSHA512.c program
	char *encrypted_passwords[] = {
		"$6$KB$i0MtbMk6WFXus6NB3.xFM7hIM610KWPiJdplbL19YeUB7EhMDxN1umaLZYZZv5X1LVy8EpZXjLulqglrV2q6f1",//IN3421
		"$6$KB$2oE9wbvi4YcecFBAHREpH2AXyNFQqpf2fC4yQjEwzK.j3PnhBk5ZbFWFrmmepKP4p8QmAB1.Op4mQ3H.dEp6E0",//PR3354
		"$6$KB$12j9F8cq/.BNCevMDdcdWlxVOEv3wxZ0PEHB1Xo1eFUIP9Vh10IPbxvc.ACfkVzLWZIKDhZ4bh3nwUTwCvZ4n/",//SH3334
		"$6$KB$.p3APL1SgIZzCQy8w7cHrzvF1IaiUf.geL3VniOyIViIGGYo7VMmOZbVF/xO9nDstetZCRoq.NppctHue4Ue21"//MY1917
	};


	void substr(char *dest, char *src, int start, int length){
	  memcpy(dest, src + start, length);
	  *(dest + length) = '\0';
	}

	int time_difference(struct timespec *start, struct timespec *finish,
		                long long int *difference) {
	  long long int ds =  finish->tv_sec - start->tv_sec; 
	  long long int dn =  finish->tv_nsec - start->tv_nsec; 

	  if(dn < 0 ) {
		ds--;
		dn += 1000000000; 
	  } 
	  *difference = ds * 1000000000 + dn;
	  return !(*difference > 0);
	}

	char salt[7],*encrypted;

	typedef struct encry
	{
		int start;
		int stride;
	} encry;

	void crack(char *salt_and_encrypted){ // decrypts the encrypted value

		substr(salt, salt_and_encrypted, 0, 6);

		pthread_t thread_1, thread_2;

		encrypted = salt_and_encrypted;

		void *kernel_function_1();
		void *kernel_function_2();

		
  		if(size != 3) {
    		if(rank == 0) {
      		printf("This program needs to run on exactly 3 processes\n");
   		 }
  		} else {
    	if(rank ==0){
			long long int time_elapsed;
    
      		MPI_Send(&pass, 1, MPI_INT, 1, 0, MPI_COMM_WORLD);
      		MPI_Send(&pass, 1, MPI_INT, 2, 0, MPI_COMM_WORLD);


 
		} else if(rank==1){
		  	MPI_Recv(&pass, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, 
		                     MPI_STATUS_IGNORE);
		    kernel_function_1();
		  }
		  else{
		  	MPI_Recv(&pass, 1, MPI_INT, 0, 0, MPI_COMM_WORLD, 
		                     MPI_STATUS_IGNORE);
		    kernel_function_2();
		  }
		}
		 
	}
	void *kernel_function_1(){
		int x,y,z,w;
		char plain[7],*enc;
		for(x='A'; x<='M'; x++){
			for(y='A'; y<='Z'; y++){
				for(z=0; z<=99; z++){
					for(w = 0; w<=99; w++){
						sprintf(plain, "%c%c%02d%02d", x, y, z,w);
						enc=(char *) crypt(plain,salt); // encrypts each and every values obtained through loop
						count++;
						if(strcmp(encrypted, enc) == 0){ // comparision between two encrypted values if matched returns 0
							printf("#%-8d%s %s\n", count, plain, enc);
						} else {
							printf(" %-8d%s %s\n", count, plain, enc);
						}
					}
				}
			}
		}
	}

	void *kernel_function_2(){
		int x,y,z,w;
		char plain[7],*enc;
		for(x='N'; x<='Z'; x++){
			for(y='A'; y<='Z'; y++){
				for(z=0; z<=99; z++){
					for(w=0; w<=99; w++){
						sprintf(plain, "%c%c%02d%02d", x, y, z,w);
						enc=(char *) crypt(plain,salt); // encrypts each and every values obtained through loop
						count++;
						if(strcmp(encrypted, enc) == 0){ // comparision between two encrypted values if matched returns 0
							printf("#%-8d%s %s\n", count, plain, enc);
						} else {
							printf(" %-8d%s %s\n", count, plain, enc);
						}
					}
				}
			}
		}
	}
	
	struct timespec start, finish;
	
	int main(int argc, char *argv[]){
		   
		MPI_Init(NULL, NULL);
  		MPI_Comm_size(MPI_COMM_WORLD, &size);
  		MPI_Comm_rank(MPI_COMM_WORLD, &rank);
    	clock_gettime(CLOCK_MONOTONIC, &start);
		for(int i=0;i<n_passwords;i<i++) {
    		crack(encrypted_passwords[i]);
  		} // encrypted value passed through crack() function
		
		MPI_Finalize();
		if(rank == 0){
    		long long int time_elapsed;
    		clock_gettime(CLOCK_MONOTONIC, &finish);
    		time_difference(&start, &finish, &time_elapsed);
    		printf("Time elapsed was %lldns or %0.9lfs\n", time_elapsed, 
           (time_elapsed/1.0e9)); 
  		}
		return 0;

	}
