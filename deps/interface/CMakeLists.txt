cmake_minimum_required(VERSION 3.0)
project(librawInterface CXX)

list(APPEND CMAKE_MODULE_PATH "${CMAKE_CURRENT_LIST_DIR}")
find_package(LibRaw)

add_library(raw_interface SHARED interface.cc)
include_directories(${LibRaw_INCLUDE_DIR})
target_link_libraries(raw_interface ${LibRaw_LIBRARIES})

install(TARGETS raw_interface DESTINATION lib)
