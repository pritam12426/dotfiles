# find_package(GTest REQUIRED)
# find_package(Catch2 REQUIRED)
find_package(Unity REQUIRED)

#### Source Files ####
file(GLOB TEST_SOURCES
  "${CMAKE_CURRENT_LIST_DIR}/*.c"
)

foreach(test_src IN LISTS TEST_SOURCES)
  get_filename_component(test_name ${test_src} NAME_WE)

  add_executable(${test_name} ${test_src})

  if(DEFINED SRC_FILES AND SRC_FILES)
    target_sources(${test_name} PRIVATE ${SRC_FILES})
  endif()

  target_link_libraries(${test_name} PRIVATE
    unity::framework
    # Catch2::Catch2WithMain
    # Test::GTest
  )

  target_include_directories(${test_name} PRIVATE
    "${CMAKE_SOURCE_DIR}/src"
    ${PROJECT_BINARY_DIR}
    "${CMAKE_CURRENT_BINARY_DIR}"
  )

  add_test(NAME ${test_name} COMMAND $<TARGET_FILE:${test_name}>)
endforeach()
