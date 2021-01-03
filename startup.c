#include <stdio.h>
#include <unistd.h>
#include <stdlib.h>
#include <string.h>



int main(int argc, char *argv[]) {
	printf("starting\n");
	
	if( access( "/bin/application", F_OK ) == 0 ) {
    	printf("file exist\n");
	} else {
    	printf("does not exist\n");
	}	

	if (rename("/bin/application", argv[1]) == 0){
        	printf("File renamed successfully.\n");
		
		char *args[2];
		args[0] = (char *)malloc(20);
		args[1] = (char *)malloc(20);

		strcpy(args[0], argv[1]);
		strcpy(args[1], "/input/default.json");		
		
		char runme[50];
		sprintf(runme, "./%s", argv[1]);
		printf("executing %s\n", runme);
		execvp(runme, args);
	} else {
		printf("NOT renamed");
	}
	
	return 0;
}