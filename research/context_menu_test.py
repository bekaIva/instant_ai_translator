#!/usr/bin/env python3
"""
Context Menu Integration Research
Tests different approaches for adding custom context menus
"""

import gi
gi.require_version('Gtk', '3.0')
from gi.repository import Gtk, Gdk, GLib
import subprocess
import sys

class ContextMenuTester:
    def __init__(self):
        self.window = None
        
    def create_test_window(self):
        """Create a test window with text to demonstrate context menu injection"""
        self.window = Gtk.Window()
        self.window.set_title("Context Menu Test - Right-click on text below")
        self.window.set_default_size(500, 300)
        self.window.connect("destroy", Gtk.main_quit)
        
        # Create a text view for testing
        scrolled = Gtk.ScrolledWindow()
        scrolled.set_policy(Gtk.PolicyType.AUTOMATIC, Gtk.PolicyType.AUTOMATIC)
        
        self.text_view = Gtk.TextView()
        self.text_buffer = self.text_view.get_buffer()
        self.text_buffer.set_text("""
This is a test text for context menu integration.

Try right-clicking on selected text to see our custom menu options.

The goal is to add:
- Translate
- Fix Grammar  
- Enhance
- Summarize

These options should appear in any text editor, not just this test window.
""")
        
        scrolled.add(self.text_view)
        
        # Connect right-click event
        self.text_view.connect("button-press-event", self.on_button_press)
        
        self.window.add(scrolled)
        self.window.show_all()
    
    def on_button_press(self, widget, event):
        """Handle right-click events"""
        if event.button == 3:  # Right click
            self.show_custom_menu(event)
            return True
        return False
    
    def show_custom_menu(self, event):
        """Show our custom context menu"""
        menu = Gtk.Menu()
        
        # Get selected text
        bounds = self.text_buffer.get_selection_bounds()
        selected_text = ""
        if bounds:
            start, end = bounds
            selected_text = self.text_buffer.get_text(start, end, False)
        
        if selected_text:
            # Add our custom menu items
            items = [
                ("🌐 Translate", self.translate_text),
                ("✏️ Fix Grammar", self.fix_grammar),
                ("✨ Enhance", self.enhance_text),
                ("📝 Summarize", self.summarize_text),
            ]
            
            for label, callback in items:
                item = Gtk.MenuItem(label=label)
                item.connect("activate", callback, selected_text)
                menu.append(item)
            
            menu.append(Gtk.SeparatorMenuItem())
        
        # Add info item
        info_item = Gtk.MenuItem(label="ℹ️ AI Translator (Proof of Concept)")
        info_item.set_sensitive(False)
        menu.append(info_item)
        
        menu.show_all()
        menu.popup(None, None, None, None, event.button, event.time)
    
    def translate_text(self, widget, text):
        print(f"🌐 Translate requested for: '{text[:30]}...'")
        self.process_text("translate", text)
    
    def fix_grammar(self, widget, text):
        print(f"✏️ Fix Grammar requested for: '{text[:30]}...'")
        self.process_text("fix_grammar", text)
    
    def enhance_text(self, widget, text):
        print(f"✨ Enhance requested for: '{text[:30]}...'")
        self.process_text("enhance", text)
    
    def summarize_text(self, widget, text):
        print(f"📝 Summarize requested for: '{text[:30]}...'")
        self.process_text("summarize", text)
    
    def process_text(self, operation, text):
        """Simulate text processing and replacement"""
        print(f"📤 Sending to Flutter app: {operation}")
        print(f"📥 Original text: {text}")
        
        # Simulate processing delay
        def simulate_response():
            # Mock processed text
            processed_text = f"[{operation.upper()}] {text}"
            print(f"📤 Processed text: {processed_text}")
            
            # Replace selected text
            bounds = self.text_buffer.get_selection_bounds()
            if bounds:
                start, end = bounds
                self.text_buffer.delete(start, end)
                self.text_buffer.insert(start, processed_text)
                print("✅ Text replaced successfully")
            
            return False
        
        # Simulate async processing
        GLib.timeout_add(500, simulate_response)

def main():
    print("🧪 Context Menu Integration Test")
    print("=" * 50)
    print("This demonstrates custom context menu injection")
    print("1. Select some text in the window")
    print("2. Right-click to see custom AI options")
    print("3. Click an option to see text replacement")
    print("=" * 50)
    
    tester = ContextMenuTester()
    tester.create_test_window()
    
    try:
        Gtk.main()
    except KeyboardInterrupt:
        print("\n🛑 Test stopped")

if __name__ == "__main__":
    main()
