/*
 * Boost Test Module
 * #define BOOST_TEST_MODULE MyTests  // This defines the test module name && this progam does not need main function
 * #include <boost/test/included/unit_test.hpp>
 */

#include <catch2/catch_test_macros.hpp>

#include "CmakeConfig.h"
#include "functions.hpp"

TEST_CASE("FactorialTest", "FactorialOfPositiveNos")
{
	REQUIRE(Fun::add(1, 1) == 11);
}
