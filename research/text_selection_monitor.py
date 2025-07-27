#!/usr/bin/env python3
"""
Text Selection Monitor - Proof of Concept
Monitors X11 primary selection for text changes
"""

import subprocess
import time
import threading
from datetime import datetime

class TextSelectionMonitor:
    def __init__(self):
        self.last_selection = ""
        self.running = False
        
    def get_primary_selection(self):
        """Get current primary selection (highlighted text)"""
        try:
            result = subprocess.run(['xclip', '-o', '-selection', 'primary'], 
                                  capture_output=True, text=True, timeout=1)
            return result.stdout.strip() if result.returncode == 0 else ""
        except:
            return ""
    
    def get_clipboard_selection(self):
        """Get current clipboard content (Ctrl+C copied text)"""
        try:
            result = subprocess.run(['xclip', '-o', '-selection', 'clipboard'], 
                                  capture_output=True, text=True, timeout=1)
            return result.stdout.strip() if result.returncode == 0 else ""
        except:
            return ""
    
    def on_selection_changed(self, selection_text):
        """Callback when text selection changes"""
        if len(selection_text) > 3:  # Only process meaningful selections
            print(f"[{datetime.now().strftime('%H:%M:%S')}] Selected: '{selection_text[:50]}{'...' if len(selection_text) > 50 else ''}'")
            print(f"                     Length: {len(selection_text)} chars")
            print(f"                     Lines: {selection_text.count(chr(10)) + 1}")
            print("-" * 60)
    
    def monitor_loop(self):
        """Main monitoring loop"""
        print("🔍 Text Selection Monitor Started")
        print("📝 Highlight any text in another application to see it captured here")
        print("⏹️  Press Ctrl+C to stop")
        print("=" * 60)
        
        while self.running:
            try:
                current_selection = self.get_primary_selection()
                
                # Check if selection changed
                if current_selection != self.last_selection and current_selection:
                    self.on_selection_changed(current_selection)
                    self.last_selection = current_selection
                
                time.sleep(0.1)  # Check every 100ms
                
            except KeyboardInterrupt:
                break
            except Exception as e:
                print(f"Error: {e}")
                time.sleep(1)
    
    def start(self):
        """Start monitoring in background thread"""
        self.running = True
        self.monitor_thread = threading.Thread(target=self.monitor_loop, daemon=True)
        self.monitor_thread.start()
        
        try:
            # Keep main thread alive
            while self.running:
                time.sleep(1)
        except KeyboardInterrupt:
            self.stop()
    
    def stop(self):
        """Stop monitoring"""
        self.running = False
        print("\n🛑 Text Selection Monitor Stopped")

if __name__ == "__main__":
    monitor = TextSelectionMonitor()
    monitor.start()
