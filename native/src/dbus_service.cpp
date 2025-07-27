#include "dbus_service.h"
#include <dbus/dbus.h>
#include <dbus/dbus-glib.h>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>

// D-Bus connection
static DBusConnection* connection = NULL;
static DBusError error;

// Service and interface names
#define DBUS_SERVICE_NAME "com.instantai.Translator"
#define DBUS_OBJECT_PATH "/com/instantai/Translator"
#define DBUS_INTERFACE_NAME "com.instantai.Translator"

// Initialize D-Bus service
int init_dbus_service() {
    // Initialize error
    dbus_error_init(&error);
    
    // Connect to session bus
    connection = dbus_bus_get(DBUS_BUS_SESSION, &error);
    if (dbus_error_is_set(&error)) {
        dbus_error_free(&error);
        return STATUS_ERROR_DBUS;
    }
    
    if (!connection) {
        return STATUS_ERROR_DBUS;
    }
    
    // Request service name
    int result = dbus_bus_request_name(connection, DBUS_SERVICE_NAME,
                                      DBUS_NAME_FLAG_REPLACE_EXISTING, &error);
    
    if (dbus_error_is_set(&error)) {
        dbus_error_free(&error);
        cleanup_dbus_service();
        return STATUS_ERROR_DBUS;
    }
    
    if (result != DBUS_REQUEST_NAME_REPLY_PRIMARY_OWNER) {
        cleanup_dbus_service();
        return STATUS_ERROR_DBUS;
    }
    
    return STATUS_SUCCESS;
}

// Cleanup D-Bus service
void cleanup_dbus_service() {
    if (connection) {
        // Release service name
        dbus_bus_release_name(connection, DBUS_SERVICE_NAME, &error);
        if (dbus_error_is_set(&error)) {
            dbus_error_free(&error);
        }
        
        // Don't close shared connections - just unref
        dbus_connection_unref(connection);
        connection = NULL;
    }
}

// Send processing request to Flutter app
int send_processing_request(const char* text, const char* operation, char** result) {
    if (!connection || !text || !operation || !result) {
        return STATUS_ERROR_DBUS;
    }
    
    *result = NULL;
    
    // Create method call message
    DBusMessage* message = dbus_message_new_method_call(
        DBUS_SERVICE_NAME,      // destination
        DBUS_OBJECT_PATH,       // object path
        DBUS_INTERFACE_NAME,    // interface
        "ProcessText"           // method
    );
    
    if (!message) {
        return STATUS_ERROR_DBUS;
    }
    
    // Add arguments
    DBusMessageIter args;
    dbus_message_iter_init_append(message, &args);
    
    if (!dbus_message_iter_append_basic(&args, DBUS_TYPE_STRING, &text) ||
        !dbus_message_iter_append_basic(&args, DBUS_TYPE_STRING, &operation)) {
        dbus_message_unref(message);
        return STATUS_ERROR_DBUS;
    }
    
    // Send message and get reply
    DBusMessage* reply = dbus_connection_send_with_reply_and_block(
        connection, message, 30000, &error); // 30 second timeout
    
    dbus_message_unref(message);
    
    if (dbus_error_is_set(&error)) {
        dbus_error_free(&error);
        return STATUS_ERROR_DBUS;
    }
    
    if (!reply) {
        return STATUS_ERROR_DBUS;
    }
    
    // Read reply
    DBusMessageIter reply_args;
    if (!dbus_message_iter_init(reply, &reply_args)) {
        dbus_message_unref(reply);
        return STATUS_ERROR_DBUS;
    }
    
    if (dbus_message_iter_get_arg_type(&reply_args) != DBUS_TYPE_STRING) {
        dbus_message_unref(reply);
        return STATUS_ERROR_DBUS;
    }
    
    char* reply_text;
    dbus_message_iter_get_basic(&reply_args, &reply_text);
    
    // Copy result
    *result = strdup(reply_text);
    
    dbus_message_unref(reply);
    
    return STATUS_SUCCESS;
}
