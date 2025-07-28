# 🚀 Instant AI Translator - Features Explained

## 📋 **Context Menu Manager - Test Action Button**

### What is the Test Action Button?
The **Test Action Button** (▶️ green play icon) allows you to test your configured menu actions directly from the Flutter app without having to:
1. Go to an external application
2. Select text manually  
3. Press Ctrl+Shift+M
4. Navigate the context menu

### How Does It Work?
When you click the Test Action button:

1. **Sample Text Processing**: It uses predefined sample text: `"This is sample text for testing the menu action."`

2. **Action Simulation**: It processes this text through your configured menu action (translate, improve, summarize, etc.)

3. **Real Results**: You get actual processed results that show exactly what your menu would do to real text

4. **UI Feedback**: Results appear in:
   - **Recent Actions** section on the Main screen
   - **System Logs** for detailed tracking
   - **Snackbar notification** confirming the test completed

### Why Use Test Actions?
- **🧪 Quick Testing**: Verify your menu configurations work correctly
- **🔧 Debugging**: Check if processing logic is working as expected  
- **⚡ Fast Feedback**: No need to switch between applications
- **📊 Results Tracking**: See processed outputs immediately in the UI

### What You'll See:
- **Success**: Green checkmark with processed text result
- **Failure**: Red error icon with error details
- **Logs**: Detailed execution information in system logs

## 🎯 **How to Use Production System**

### Step 1: Configure Menu Items
1. Go to **Menu Manager** screen
2. Add/edit menu configurations (labels, prompts, operations)
3. Enable/disable menus as needed
4. Test each menu with the ▶️ button

### Step 2: Use in Real Applications  
1. Open any text editor (VS Code, LibreOffice, etc.)
2. Select text you want to process
3. Press **Ctrl+Shift+M** 
4. Choose from your configured menu options
5. Watch as text gets intelligently replaced!

### Step 3: Monitor Activity
1. Check **Main** screen for real-time status
2. View **Recent Actions** for processing history
3. Monitor **System Logs** for debugging

## 🔧 **Current Processing Types**

| Operation | What It Does |
|-----------|-------------|
| **Translate** | Converts text to different languages |
| **Improve** | Enhances writing quality and clarity |
| **Summarize** | Creates concise summaries |
| **Explain** | Provides detailed explanations |
| **Rewrite** | Restructures text while keeping meaning |
| **Expand** | Adds more detail and context |

*Note: Currently using simple text transformations. AI integration coming next!*

## 🛠️ **Technical Architecture**

### File-Based Communication
- **Action File**: `/tmp/instant_translator_action.txt`
- **Format**: `menuId|selectedText`
- **Monitoring**: Real-time file polling for menu actions

### Persistent Storage
- **SharedPreferences**: Menu configurations saved between sessions
- **JSON Serialization**: Import/export configuration support
- **Default Configs**: Pre-loaded with common operations

### Native Integration
- **Global Hotkey**: System-wide Ctrl+Shift+M registration
- **Text Replacement**: Direct clipboard-based text substitution
- **Context Menu Injection**: Dynamic menu population based on configurations

## 🔜 **Next Steps**
- **AI Service Integration**: Connect OpenAI, Claude, or other AI APIs
- **Custom Prompts**: User-defined processing instructions
- **API Key Management**: Secure credential storage
- **Advanced Features**: Batch processing, templates, shortcuts
