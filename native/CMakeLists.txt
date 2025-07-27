cmake_minimum_required(VERSION 3.16)
project(instant_translator_native)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

# Find required packages
find_package(PkgConfig REQUIRED)

# GTK3 for context menu integration
pkg_check_modules(GTK3 REQUIRED gtk+-3.0)

# X11 for text selection monitoring
find_package(X11 REQUIRED)

# XTest extension for keyboard/mouse simulation
find_library(XTEST_LIB Xtst)

# DBus for IPC with Flutter app
pkg_check_modules(DBUS REQUIRED dbus-1)

# GLib for GObject integration
pkg_check_modules(GLIB REQUIRED glib-2.0)

# Include directories
include_directories(${GTK3_INCLUDE_DIRS})
include_directories(${X11_INCLUDE_DIR})
include_directories(${DBUS_INCLUDE_DIRS})
include_directories(${GLIB_INCLUDE_DIRS})

# Link directories
link_directories(${GTK3_LIBRARY_DIRS})
link_directories(${DBUS_LIBRARY_DIRS})
link_directories(${GLIB_LIBRARY_DIRS})

# Compiler flags
add_definitions(${GTK3_CFLAGS_OTHER})
add_definitions(${DBUS_CFLAGS_OTHER})
add_definitions(${GLIB_CFLAGS_OTHER})

# Source files
set(SOURCES
    src/system_hooks.cpp
    src/text_selection_monitor.cpp
    src/context_menu_injector.cpp
    src/dbus_service.cpp
    src/text_replacement.cpp
    src/main.cpp
)

# Create shared library for Flutter FFI
add_library(instant_translator_native SHARED ${SOURCES})

# Link libraries
target_link_libraries(instant_translator_native
    ${GTK3_LIBRARIES}
    ${X11_LIBRARIES}
    ${XTEST_LIB}
    ${DBUS_LIBRARIES}
    ${GLIB_LIBRARIES}
    pthread
)

# Set library properties
set_target_properties(instant_translator_native PROPERTIES
    VERSION 1.0
    SOVERSION 1
    PUBLIC_HEADER "include/instant_translator.h"
)

# Install targets
install(TARGETS instant_translator_native
    LIBRARY DESTINATION lib
    PUBLIC_HEADER DESTINATION include
)

# Create executable for testing
add_executable(instant_translator_test ${SOURCES})
target_compile_definitions(instant_translator_test PRIVATE STANDALONE_TEST)
target_link_libraries(instant_translator_test
    ${GTK3_LIBRARIES}
    ${X11_LIBRARIES}
    ${XTEST_LIB}
    ${DBUS_LIBRARIES}
    ${GLIB_LIBRARIES}
    pthread
)
