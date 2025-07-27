#!/usr/bin/env python3
"""
D-Bus IPC Communication Test
Tests communication between system hooks and Flutter app
"""

import dbus
import dbus.service
import dbus.mainloop.glib
from gi.repository import GLib
import threading
import time
import json

# D-Bus service configuration
SERVICE_NAME = "com.instant_ai_translator.TextProcessor"
OBJECT_PATH = "/com/instant_ai_translator/TextProcessor"
INTERFACE_NAME = "com.instant_ai_translator.TextProcessor"

class AITranslatorService(dbus.service.Object):
    """D-Bus service for AI text processing"""
    
    def __init__(self):
        # Initialize D-Bus
        dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
        self.bus = dbus.SessionBus()
        self.bus_name = dbus.service.BusName(SERVICE_NAME, bus=self.bus)
        super().__init__(self.bus_name, OBJECT_PATH)
        
        print(f"🚀 AI Translator D-Bus Service Started")
        print(f"📡 Service: {SERVICE_NAME}")
        print(f"📍 Path: {OBJECT_PATH}")
        print("=" * 50)
    
    @dbus.service.method(INTERFACE_NAME, in_signature='sss', out_signature='s')
    def ProcessText(self, operation, text, source_app="unknown"):
        """
        Process text with specified operation
        Args:
            operation: translate, fix_grammar, enhance, summarize
            text: the text to process
            source_app: name of the application that sent the text
        Returns:
            processed text
        """
        print(f"📨 Received request:")
        print(f"   Operation: {operation}")
        print(f"   Source App: {source_app}")
        print(f"   Text: '{text[:50]}{'...' if len(text) > 50 else ''}'")
        
        # Simulate processing time
        time.sleep(0.5)
        
        # Mock processing based on operation
        if operation == "translate":
            result = f"[TRANSLATED] {text}"
        elif operation == "fix_grammar":
            result = f"[GRAMMAR_FIXED] {text}"
        elif operation == "enhance":
            result = f"[ENHANCED] {text}"
        elif operation == "summarize":
            result = f"[SUMMARY] {text[:30]}..."
        else:
            result = f"[UNKNOWN_OP] {text}"
        
        print(f"📤 Sending result: '{result[:50]}{'...' if len(result) > 50 else ''}'")
        return result
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='s')
    def GetStatus(self):
        """Get service status"""
        return "AI Translator Service is running"
    
    @dbus.service.method(INTERFACE_NAME, in_signature='', out_signature='as')
    def GetSupportedOperations(self):
        """Get list of supported operations"""
        return ["translate", "fix_grammar", "enhance", "summarize"]

class DBusClient:
    """Client for testing D-Bus communication"""
    
    def __init__(self):
        self.bus = dbus.SessionBus()
        
    def get_service(self):
        """Get the AI Translator service"""
        try:
            obj = self.bus.get_object(SERVICE_NAME, OBJECT_PATH)
            return dbus.Interface(obj, INTERFACE_NAME)
        except dbus.DBusException as e:
            print(f"❌ Failed to connect to service: {e}")
            return None
    
    def test_communication(self):
        """Test basic communication with the service"""
        service = self.get_service()
        if not service:
            return False
        
        try:
            print("🧪 Testing D-Bus Communication")
            print("-" * 30)
            
            # Test status
            status = service.GetStatus()
            print(f"📊 Status: {status}")
            
            # Test supported operations
            operations = service.GetSupportedOperations()
            print(f"🔧 Operations: {', '.join(operations)}")
            
            # Test text processing
            test_text = "This is a test sentence for processing."
            for op in operations:
                result = service.ProcessText(op, test_text, "test_client")
                print(f"✅ {op}: {result}")
            
            return True
            
        except Exception as e:
            print(f"❌ Communication test failed: {e}")
            return False

def run_service():
    """Run the D-Bus service"""
    try:
        service = AITranslatorService()
        loop = GLib.MainLoop()
        loop.run()
    except KeyboardInterrupt:
        print("\n🛑 Service stopped")
    except Exception as e:
        print(f"❌ Service error: {e}")

def run_client_test():
    """Run client tests"""
    print("⏳ Waiting for service to start...")
    time.sleep(2)
    
    client = DBusClient()
    success = client.test_communication()
    
    if success:
        print("\n✅ D-Bus communication test successful!")
    else:
        print("\n❌ D-Bus communication test failed!")

def main():
    if len(sys.argv) > 1 and sys.argv[1] == "client":
        run_client_test()
    else:
        print("Starting D-Bus service...")
        print("Run with 'client' argument in another terminal to test")
        run_service()

if __name__ == "__main__":
    import sys
    main()
