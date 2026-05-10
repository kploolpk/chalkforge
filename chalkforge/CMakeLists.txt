cmake_minimum_required(VERSION 3.16)

project(chalkforge VERSION 0.1 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD 17)
set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(appchalkforge
    main.cpp
)

qt_add_qml_module(appchalkforge
    URI chalkforge
    QML_FILES
        Main.qml
    SOURCES
        holddetector.h
        holddetector.cpp
)

target_link_libraries(appchalkforge
    PRIVATE
        Qt6::Quick
)

# =========================
# OpenCV Android Setup
# =========================

if(ANDROID)

    # OpenCV include headers
    include_directories(
        "C:/opencv-4.12.0-android-sdk/OpenCV-android-sdk/sdk/native/jni/include"
    )

    # Path to ARM64 OpenCV shared library
    set(OpenCV_ANDROID_LIB
        "C:/opencv-4.12.0-android-sdk/OpenCV-android-sdk/sdk/native/libs/armeabi-v7a/libopencv_java4.so"
    )

    # Link OpenCV
    target_link_libraries(appchalkforge
        PRIVATE
            ${OpenCV_ANDROID_LIB}
    )

    # Ensure the .so is packaged into APK
    set_target_properties(appchalkforge PROPERTIES
        QT_ANDROID_EXTRA_LIBS "${OpenCV_ANDROID_LIB}"
    )

endif()

# =========================
# App Properties
# =========================

set_target_properties(appchalkforge PROPERTIES
    MACOSX_BUNDLE_BUNDLE_VERSION ${PROJECT_VERSION}
    MACOSX_BUNDLE_SHORT_VERSION_STRING ${PROJECT_VERSION_MAJOR}.${PROJECT_VERSION_MINOR}
    MACOSX_BUNDLE TRUE
    WIN32_EXECUTABLE TRUE
)

include(GNUInstallDirs)

install(TARGETS appchalkforge
    BUNDLE DESTINATION .
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
)
