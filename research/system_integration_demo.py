#!/usr/bin/env python3
"""
System Integration Proof of Concept
Combines text selection monitoring, context menu injection, and D-Bus IPC
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import subprocess
import threading
import time
import dbus
import dbus.service
import dbus.mainloop.glib
from datetime import datetime

class SystemIntegrationDemo:
    def __init__(self):
        self.selected_text = ""
        self.monitoring = False
        self.dbus_service = None
        
    def setup_dbus_service(self):
        """Setup D-Bus service for IPC"""
        try:
            dbus.mainloop.glib.DBusGMainLoop(set_as_default=True)
            self.bus = dbus.SessionBus()
            print("✅ D-Bus service initialized")
            return True
        except Exception as e:
            print(f"❌ D-Bus setup failed: {e}")
            return False
    
    def get_selected_text(self):
        """Get currently selected text from X11 primary selection"""
        try:
            result = subprocess.run(['xclip', '-o', '-selection', 'primary'], 
                                  capture_output=True, text=True, timeout=1)
            return result.stdout.strip() if result.returncode == 0 else ""
        except:
            return ""
    
    def replace_selected_text(self, new_text):
        """Replace selected text with processed result"""
        try:
            # First, copy new text to clipboard
            process = subprocess.Popen(['xclip', '-selection', 'primary'], 
                                     stdin=subprocess.PIPE, text=True)
            process.communicate(new_text)
            
            # Simulate Ctrl+V to paste (this is a simplified approach)
            # In a real implementation, we'd need more sophisticated text replacement
            print(f"📝 Text replacement simulation: '{new_text[:30]}...'")
            return True
        except Exception as e:
            print(f"❌ Text replacement failed: {e}")
            return False
    
    def process_text_with_ai(self, operation, text):
        """Simulate AI processing"""
        print(f"🤖 AI Processing: {operation}")
        time.sleep(0.5)  # Simulate processing time
        
        # Mock AI responses
        responses = {
            "translate": f"[TRANSLATED] {text}",
            "fix_grammar": f"[GRAMMAR_FIXED] {text}",  
            "enhance": f"[ENHANCED] {text}",
            "summarize": f"[SUMMARY] {text[:50]}..."
        }
        
        return responses.get(operation, f"[PROCESSED] {text}")
    
    def show_context_menu(self, x, y, selected_text):
        """Show custom context menu at cursor position"""
        if not selected_text or len(selected_text) < 3:
            return
        
        menu = Gtk.Menu()
        
        # Add custom AI operations
        operations = [
            ("🌐 Translate", "translate"),
            ("✏️ Fix Grammar", "fix_grammar"),
            ("✨ Enhance", "enhance"),
            ("📝 Summarize", "summarize"),
        ]
        
        for label, operation in operations:
            item = Gtk.MenuItem(label=label)
            item.connect("activate", self.on_menu_item_clicked, operation, selected_text)
            menu.append(item)
        
        menu.append(Gtk.SeparatorMenuItem())
        
        # Add info
        info_item = Gtk.MenuItem(label="🚀 AI Translator PoC")
        info_item.set_sensitive(False)
        menu.append(info_item)
        
        menu.show_all()
        
        # Position menu at cursor
        menu.popup(None, None, None, None, 0, Gtk.get_current_event_time())
    
    def on_menu_item_clicked(self, widget, operation, text):
        """Handle menu item clicks"""
        print(f"🎯 User selected: {operation} for '{text[:30]}...'")
        
        # Process text
        processed_text = self.process_text_with_ai(operation, text)
        
        # Replace original text
        self.replace_selected_text(processed_text)
        
        print(f"✅ Operation complete: {operation}")
    
    def monitor_selection_changes(self):
        """Monitor for text selection changes"""
        print("🔍 Starting text selection monitoring...")
        
        last_selection = ""
        while self.monitoring:
            try:
                current_selection = self.get_selected_text()
                
                if (current_selection != last_selection and 
                    current_selection and 
                    len(current_selection) > 3):
                    
                    print(f"📄 New selection: '{current_selection[:50]}...'")
                    self.selected_text = current_selection
                    
                    # Check if user wants to access AI tools
                    # In a real implementation, this would be triggered by right-click
                    # For demo, we'll show menu after 2 seconds of stable selection
                    def show_menu_delayed():
                        if self.get_selected_text() == current_selection:
                            print("🎯 Stable selection detected - showing context menu")
                            # In reality, this would be triggered by right-click event
                            GLib.idle_add(self.show_context_menu, 0, 0, current_selection)
                        return False
                    
                    GLib.timeout_add(2000, show_menu_delayed)
                    
                    last_selection = current_selection
                
                time.sleep(0.2)
                
            except Exception as e:
                print(f"❌ Monitoring error: {e}")
                time.sleep(1)
    
    def start_demo(self):
        """Start the complete system integration demo"""
        print("🚀 System Integration Demo Starting")
        print("=" * 50)
        
        # Setup components
        if not self.setup_dbus_service():
            print("❌ Failed to setup D-Bus")
            return
        
        # Start monitoring in background thread
        self.monitoring = True
        monitor_thread = threading.Thread(target=self.monitor_selection_changes, daemon=True)
        monitor_thread.start()
        
        # Create demo window
        self.create_demo_window()
        
        print("📝 Demo Instructions:")
        print("1. Select text in the demo window or any other application")
        print("2. Wait 2 seconds for the context menu to appear")
        print("3. Choose an AI operation from the menu")
        print("4. See the text get replaced with processed result")
        print("=" * 50)
        
        try:
            Gtk.main()
        except KeyboardInterrupt:
            self.stop_demo()
    
    def create_demo_window(self):
        """Create demo window with sample text"""
        window = Gtk.Window()
        window.set_title("AI Translator - System Integration Demo")
        window.set_default_size(600, 400)
        window.connect("destroy", self.stop_demo)
        
        # Create text area
        scrolled = Gtk.ScrolledWindow()
        text_view = Gtk.TextView()
        text_buffer = text_view.get_buffer()
        
        text_buffer.set_text("""
🚀 AI Translator System Integration Demo

This demonstrates the complete workflow:

1. TEXT SELECTION MONITORING
   - Select any text below or in other applications
   - The system monitors X11 primary selection

2. CONTEXT MENU INJECTION  
   - Right-click on selected text
   - Custom AI options appear in context menu

3. TEXT PROCESSING & REPLACEMENT
   - Choose an AI operation (Translate, Fix Grammar, etc.)
   - Text gets processed and replaced automatically

Try selecting this text: "Hello world, this needs improvement."

Or this text: "This sentence have some grammer errors to fix."

Select text and wait 2 seconds to see the context menu appear!
""")
        
        scrolled.add(text_view)
        window.add(scrolled)
        window.show_all()
        
        self.demo_window = window
    
    def stop_demo(self, widget=None):
        """Stop the demo"""
        print("\n🛑 Stopping system integration demo...")
        self.monitoring = False
        Gtk.main_quit()

def main():
    print("🔬 AI Translator - System Integration Proof of Concept")
    print("📅", datetime.now().strftime("%Y-%m-%d %H:%M:%S"))
    
    demo = SystemIntegrationDemo()
    demo.start_demo()

if __name__ == "__main__":
    main()
