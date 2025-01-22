/*
 *	engdemo.c
 *
 *	A simple program to illustrate how to call MATLAB
 *	Engine functions from a C program.
 *
 * Copyright 1984-2016 The MathWorks, Inc.
 * All rights reserved
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#include "engine.h"

#define  BUFSIZE 256

void diagnose(void)
{
	char* p = getenv("LD_LIBRARY_PATH");
	if(p) printf("LD_LIBRARY_PATH: %s\n", p);

	p = getenv("DYLD_LIBRARY_PATH");
	if(p) printf("DYLD_LIBRARY_PATH: %s\n", p);

	p = getenv("PATH");
	if(p) printf("PATH: %s\n", p);
}

int main(void)
{
Engine *ep;
mxArray *T = NULL;
char buffer[BUFSIZE+1];
double time[10] = { 0.0, 1.0, 2.0, 3.0, 4.0, 5.0, 6.0, 7.0, 8.0, 9.0 };

/*
	* Call engOpen with a NULL string. This starts a MATLAB process
		* on the current host using the command "matlab".
	*/

diagnose();

if (!(ep = engOpen(NULL))) {
  fprintf(stderr, "\nCan't start MATLAB engine\n");
  return EXIT_FAILURE;
}


printf("Matlab engine started\n");

/* Create a variable for the data */
T = mxCreateDoubleMatrix(1, 10, mxREAL);
memcpy((void *)mxGetPr(T), (void *)time, sizeof(time));
/* Place the variable T into the MATLAB workspace */
engPutVariable(ep, "T", T);

/*
	* Evaluate a function of time, distance = (1/2)g.*t.^2
	* (g is the acceleration due to gravity)
	*/
engEvalString(ep, "D = .5.*(-9.8).*T.^2;");

printf("Done with Matlab Engine demo.\n");
mxDestroyArray(T);

engClose(ep);

return EXIT_SUCCESS;
}

void mexFunction(int nlhs, mxArray *plhs[], int nrhs, const mxArray *prhs[]){}
/* https://www.mathworks.com/help/matlab/matlab_external/symbol-mexfunction-unresolved-or-not-defined.html */
