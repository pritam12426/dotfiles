#include <unity/unity.h>

#include "CmakeConfig.h"
#include "functions.h"


void setUp(void) {}     // Required by Unity
void tearDown(void) {}  // Required by Unity


void test_add(void) {
	TEST_ASSERT_EQUAL(5, add(2, 3));
	TEST_ASSERT_EQUAL(4, add(2, 2));
	TEST_ASSERT_EQUAL(0, add(0, 0));
}


void help(void) {
	TEST_ASSERT_NOT_EQUAL_INT(12, 213);
}


int main(void) {
	UNITY_BEGIN();
	RUN_TEST(test_add);
	return UNITY_END();
}
