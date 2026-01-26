enable_testing()
# find_package(GTest REQUIRED)
find_package(Catch2 REQUIRED)

set(TEST_BIN_NAME unitTests)

file(GLOB
  TEST_SRC_FILES
  # "${CMAKE_CURRENT_LIST_DIR}/another.cpp"
)

add_executable(${TEST_BIN_NAME} "${CMAKE_CURRENT_LIST_DIR}/main.cpp")
target_sources(${TEST_BIN_NAME} PRIVATE
  ${SRC_FILES}
  ${TEST_SRC_FILES}
)

target_link_libraries("${TEST_BIN_NAME}" PRIVATE
  Catch2::Catch2WithMain
  # Test::GTest
)

target_include_directories(${TEST_BIN_NAME} PRIVATE
  "${PROJECT_SOURCE_DIR}/src"
  "${PROJECT_BINARY_DIR}"
  "${CMAKE_CURRENT_LIST_DIR}"
  "${CMAKE_CURRENT_BINARY_DIR}"
)

add_test(NAME "${TEST_BIN_NAME}" COMMAND "${TEST_BIN_NAME}" "<args>")
