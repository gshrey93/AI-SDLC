cmake_minimum_required(VERSION 3.10)
project(dj_engine LANGUAGES C CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

include_directories(include)

set(DJ_ENGINE_SOURCES
    src/dj_engine.cpp
    src/deck.cpp
    src/biquad_eq.cpp
    src/crossfader.cpp
)

add_library(dj_engine SHARED ${DJ_ENGINE_SOURCES})

# Target-specific flags and audio driver bindings
if(ANDROID)
    target_link_libraries(dj_engine log android)
elseif(APPLE)
    find_library(COREAUDIO_LIB CoreAudio)
    find_library(AUDIOTOOLBOX_LIB AudioToolbox)
    target_link_libraries(dj_engine ${COREAUDIO_LIB} ${AUDIOTOOLBOX_LIB})
endif()
