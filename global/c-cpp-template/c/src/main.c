#include <stdio.h>

#include "CmakeConfig.h"
#include "functions.h"

int main(int argc, char *argv[]) {
	printf("Your prject \"%s\" --version \"%s\". Dis-[ %s ] is ready to.\nURL -- "
	       "%s\n",
	       PROJECT_NAME,
	       PROJECT_VERSION,
	       PROJECT_DESCRIPTION,
	       PROJECT_HOMEPAGE_URL);

	int a = add(2, 2);
	printf("\nSum -> %d\n", a);
	return 0;
}
