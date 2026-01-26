#include <iostream>

#include "CmakeConfig.h"
#include "functions.hpp"

int main(int argc, char *argv[]) {
	std::printf("Your prject \"%s\" --version \"%s\". Dis-[ %s ] is ready "
	            "to.\nURL -- %s\n",
	            PROJECT_NAME,
	            PROJECT_VERSION,
	            PROJECT_DESCRIPTION,
	            PROJECT_HOMEPAGE_URL);

	int a = Fun::add(2, 2);
	std::cout << "\nSum --> " << a << '\n';
	return 0;
}
