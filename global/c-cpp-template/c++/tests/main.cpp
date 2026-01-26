#include <catch2/catch_test_macros.hpp>

#include "functions.hpp"
#include "CmakeConfig.h"

TEST_CASE("FactorialTest", "FactorialOfPositiveNos") {
	REQUIRE(Fun::add(1, 1) == 11);
}
