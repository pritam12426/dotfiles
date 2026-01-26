cmake_minimum_required(VERSION 4.0.0)

project(
  "main"
  VERSION 0.1.0
  DESCRIPTION "Small Project"
  HOMEPAGE_URL "https://github.com/pritam12426/"
  LANGUAGES CXX
)

configure_file(${CMAKE_CURRENT_LIST_DIR}/src/CmakeConfig.h.in ${CMAKE_CURRENT_BINARY_DIR}/CmakeConfig.h)

#### C++ Standard Settings ####
set(CMAKE_CXX_STANDARD 20)
set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_EXPORT_COMPILE_COMMANDS ON)
set(MAIN_BINARY "main")

#### Source Files ####
file(GLOB
  SRC_FILES
  "${CMAKE_CURRENT_LIST_DIR}/wx-form/FormBuilder.cpp"
)

#### Dependencies ####
find_package(wxWidgets REQUIRED COMPONENTS core base)
include(${wxWidgets_USE_FILE})

#### Main Executable ####
add_executable(${MAIN_BINARY} MACOSX_BUNDLE
  ${SRC_FILES}
  "${CMAKE_CURRENT_LIST_DIR}/src/App.cpp"
)

set_target_properties(${MAIN_BINARY} PROPERTIES
  MACOSX_BUNDLE_INFO_PLIST ${CMAKE_SOURCE_DIR}/src/Info.plist
  RESOURCE "${CMAKE_SOURCE_DIR}/doc/icon.icns"
)

target_link_libraries(${MAIN_BINARY} PRIVATE
  ${wxWidgets_LIBRARIES}
)

target_include_directories(${MAIN_BINARY} PRIVATE
  ${PROJECT_SOURCE_DIR}/src
  ${PROJECT_SOURCE_DIR}/wx-form
  ${PROJECT_BINARY_DIR}
  # ${LIBXML_INCLUDE_DIRS}
)

add_custom_target(run
  COMMAND open ${MAIN_BINARY}.app
  COMMENT "Runing ${MAIN_BINARY}"
  DEPENDS ${MAIN_BINARY}
  WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR}
)

#### Setting the conditional variable ####
option(BUILD_TESTING "Enable unit testing"           OFF)
option(BUILD_DOC     "Generate doc for the project"  OFF)

#### Unit Tests ####
if(BUILD_TESTING)
  enable_testing()
  add_subdirectory(tests)
endif()

#### Bulding doc ####
if(BUILD_DOC)
  add_subdirectory(doc)
endif()
