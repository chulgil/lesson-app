# CMakeLists.txt for Oboe-based Metronome Engine
cmake_minimum_required(VERSION 3.18)
project(metronome_engine)

# Set C++ standard
set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find Oboe package (prefab from AAR)
find_package(oboe REQUIRED CONFIG)

# Source files
set(SOURCES
    MetronomeEngine.cpp
    jni_bridge.cpp
)

# Create shared library
add_library(metronome_engine SHARED ${SOURCES})

# Link libraries
target_link_libraries(metronome_engine
    PRIVATE
    oboe::oboe
    android
    log
)

# Include directories
target_include_directories(metronome_engine
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}
)
