# find_package(GTest REQUIRED)
# find_package(Catch2 REQUIRED)
find_package(Unity REQUIRED)

#### Source Files ####
file(GLOB TEST_SOURCES
  "${CMAKE_CURRENT_LIST_DIR}/*.c"
)

foreach(TEST_SRC IN LISTS TEST_SOURCES)
  get_filename_component(TEST_NAME "${TEST_SRC}" NAME_WE)
  set(PREFIXED_TEST_NAME "TEST-${TEST_NAME}")

  add_executable(${PREFIXED_TEST_NAME}
    ${TEST_SRC}
  )

  if(DEFINED SRC_FILES AND SRC_FILES)
    target_sources(${PREFIXED_TEST_NAME} PRIVATE
      ${SRC_FILES}
    )
  endif()

  target_link_libraries(${PREFIXED_TEST_NAME} PRIVATE
    unity::framework
    # Catch2::Catch2WithMain
    # Test::GTest
  )

  target_include_directories(${PREFIXED_TEST_NAME} PRIVATE
    "${PROJECT_BINARY_DIR}"
    "${PROJECT_SOURCE_DIR}/src"
    "${CMAKE_CURRENT_LIST_DIR}"
    "${CMAKE_CURRENT_BINARY_DIR}"
  )

  add_test(NAME
    ${PREFIXED_TEST_NAME}
    COMMAND $<TARGET_FILE:${PREFIXED_TEST_NAME}>
  )
endforeach()
