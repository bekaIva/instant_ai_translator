#ifndef DBUS_SERVICE_H
#define DBUS_SERVICE_H

#include "../include/instant_translator.h"

#ifdef __cplusplus
extern "C" {
#endif

// Initialize D-Bus service
int init_dbus_service();

// Cleanup D-Bus service
void cleanup_dbus_service();

// Send processing request to Flutter app
int send_processing_request(const char* text, const char* operation, char** result);

#ifdef __cplusplus
}
#endif

#endif // DBUS_SERVICE_H
