```html
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">

    <meta http-equiv="Content-Security-Policy"
          content="default-src 'self';
                   connect-src 'self' http://*:1234;
                   script-src 'self' 'unsafe-inline';
                   style-src 'self' 'unsafe-inline';">

    <title>Local LM Studio Chat</title>
    <style>
        /* Basic styling for the chat interface */
        :root {
            /* Light Mode Colors - NEW WARM PALETTE (Amber/Orange) */
            --bg-color: #f9fafb; /* Tailwind gray-50 */
            --border-color: #d1d5db; /* Tailwind gray-300 */
            --text-color-main: #1f2937; /* Tailwind gray-800 */
            --text-color-secondary: #6b7280; /* Tailwind gray-500 */
            --chatbox-bg: #ffffff;
            --chatbox-border: #e5e7eb; /* Tailwind gray-200 */
            --user-msg-bg: #fef3c7; /* Tailwind amber-100 */
            --user-msg-text: #92400e; /* Tailwind amber-800 */
            --assistant-msg-bg: #f3f4f6; /* Tailwind gray-100 */
            --assistant-msg-text: #1f2937; /* Tailwind gray-800 */
            --input-border: #d1d5db; /* Tailwind gray-300 */
            --button-bg: #f59e0b; /* Tailwind amber-500 */
            --button-hover-bg: #d97706; /* Tailwind amber-600 */
            --button-disabled-bg: #9ca3af; /* Tailwind gray-400 */
            --button-text: #ffffff; /* White text for better contrast on amber */
            --toggle-bg: #ccc;
            --toggle-slider: white;
            --toggle-checked-bg: #f59e0b; /* Tailwind amber-500 */
        }

        body {
            font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif;
            max-width: 800px;
            margin: 1rem auto; /* Use rem and add top/bottom margin */
            padding: 1rem; /* Use rem */
            border: 1px solid var(--border-color);
            border-radius: 0.5rem;
            background-color: var(--bg-color);
            color: var(--text-color-main);
            display: flex;
            flex-direction: column;
            /* Adjust height calculation for mobile */
            height: calc(100vh - 2rem); /* Full viewport height minus margin */
            box-sizing: border-box;
            transition: background-color 0.3s, color 0.3s; /* Smooth transition for dark mode */
        }

        /* Dark Mode Styles - NEW WARM PALETTE */
        body.dark-mode {
            --bg-color: #1f2937; /* Tailwind gray-800 */
            --border-color: #4b5563; /* Tailwind gray-600 */
            --text-color-main: #f9fafb; /* Tailwind gray-50 */
            --text-color-secondary: #9ca3af; /* Tailwind gray-400 */
            --chatbox-bg: #374151; /* Tailwind gray-700 */
            --chatbox-border: #4b5563; /* Tailwind gray-600 */
            --user-msg-bg: #92400e; /* Tailwind amber-800 */
            --user-msg-text: #fef3c7; /* Tailwind amber-100 */
            --assistant-msg-bg: #4b5563; /* Tailwind gray-600 */
            --assistant-msg-text: #f3f4f6; /* Tailwind gray-100 */
            --input-border: #4b5563; /* Tailwind gray-600 */
            --button-bg: #f59e0b; /* Tailwind amber-500 */
            --button-hover-bg: #fbbf24; /* Tailwind amber-400 */
            --button-disabled-bg: #6b7280; /* Tailwind gray-500 */
            --button-text: #1f2937; /* Darker text for better contrast on amber */
            --toggle-bg: #4b5563; /* Tailwind gray-600 */
            --toggle-slider: #d1d5db; /* Tailwind gray-300 */
            --toggle-checked-bg: #f59e0b; /* Tailwind amber-500 */
        }

        .header-container {
            display: flex;
            justify-content: space-between;
            align-items: center;
            margin-bottom: 1rem;
            flex-shrink: 0; /* Prevent header from shrinking */
        }

        h1 {
            /* Adjust font size for potentially smaller screens */
            font-size: 1.25rem; /* Tailwind text-xl */
            text-align: center;
            color: var(--text-color-main);
            margin: 0;
            flex-grow: 1;
            /* Prevent text overflow */
            overflow: hidden;
            text-overflow: ellipsis;
            white-space: nowrap;
        }

        /* Dark Mode Toggle Switch Styles - Refined */
        .switch {
          position: relative;
          display: inline-block;
          /* Use em for slightly more scalable size */
          width: 3em;
          height: 1.5em;
          margin-left: 1rem; /* Space from title */
          flex-shrink: 0; /* Prevent toggle from shrinking */
        }

        .switch input {
          opacity: 0;
          width: 0;
          height: 0;
        }

        .slider {
          position: absolute;
          cursor: pointer;
          top: 0;
          left: 0;
          right: 0;
          bottom: 0;
          background-color: var(--toggle-bg);
          transition: .4s;
          border-radius: 1.5em; /* Fully rounded */
        }

        .slider:before {
          position: absolute;
          content: "";
          /* Size relative to the switch height */
          height: 1.1em;
          width: 1.1em;
          /* Position centered vertically and offset horizontally */
          left: 0.2em;
          bottom: 0.2em;
          background-color: var(--toggle-slider);
          transition: .4s;
          border-radius: 50%;
        }

        input:checked + .slider {
          background-color: var(--toggle-checked-bg);
        }

        input:focus + .slider {
          box-shadow: 0 0 1px var(--toggle-checked-bg);
        }

        input:checked + .slider:before {
          /* Translate relative to the switch width */
          transform: translateX(1.5em);
        }


        #chatbox {
            flex-grow: 1; /* Takes up available space */
            overflow-y: auto; /* Scrollable */
            border: 1px solid var(--chatbox-border);
            padding: 1rem;
            margin-bottom: 1rem;
            background-color: var(--chatbox-bg);
            border-radius: 0.375rem; /* Tailwind rounded-md */
            transition: background-color 0.3s, border-color 0.3s;
        }
        .message {
            margin-bottom: 0.75rem; /* Tailwind mb-3 */
            padding: 0.5rem 0.75rem; /* Tailwind p-2 px-3 */
            border-radius: 0.375rem; /* Tailwind rounded-md */
            max-width: 85%;
            word-wrap: break-word; /* Wrap long words */
            transition: background-color 0.3s, color 0.3s;
            line-height: 1.4; /* Improve readability */
        }
        .user-message {
            background-color: var(--user-msg-bg);
            color: var(--user-msg-text);
            margin-left: auto; /* Align to right */
            text-align: left; /* Keep text left-aligned within the bubble */
        }
        .assistant-message {
            background-color: var(--assistant-msg-bg);
            color: var(--assistant-msg-text);
            margin-right: auto; /* Align to left */
            text-align: left;
        }
        #input-area {
            display: flex;
            border-top: 1px solid var(--chatbox-border);
            padding-top: 1rem;
            transition: border-color 0.3s;
            flex-shrink: 0; /* Prevent input area from shrinking */
        }
        #userInput {
            flex-grow: 1;
            padding: 0.75rem;
            border: 1px solid var(--input-border);
            border-radius: 0.375rem; /* Tailwind rounded-md */
            margin-right: 0.5rem; /* Tailwind mr-2 */
            font-size: 1rem;
            background-color: var(--chatbox-bg); /* Match chatbox bg */
            color: var(--text-color-main); /* Match main text color */
            transition: background-color 0.3s, color 0.3s, border-color 0.3s;
            /* Prevent zooming on focus in iOS */
            -webkit-text-size-adjust: 100%;
        }
         #userInput::placeholder { /* Style placeholder */
            color: var(--text-color-secondary);
        }
        #sendButton {
            padding: 0.75rem 1.25rem;
            cursor: pointer;
            background-color: var(--button-bg);
            color: var(--button-text);
            border: none;
            border-radius: 0.375rem; /* Tailwind rounded-md */
            font-size: 1rem;
            transition: background-color 0.2s ease;
            font-weight: 500; /* Medium weight */
        }
        #sendButton:hover {
            background-color: var(--button-hover-bg);
        }
        #sendButton:disabled {
            background-color: var(--button-disabled-bg);
            cursor: not-allowed;
        }
        #status {
            font-size: 0.875rem; /* Tailwind text-sm */
            color: var(--text-color-secondary);
            margin-top: 0.5rem; /* Tailwind mt-2 */
            text-align: center;
            min-height: 1.25rem; /* Reserve space */
            transition: color 0.3s;
            flex-shrink: 0; /* Prevent status from shrinking */
        }

        /* Cursor animation for streaming text */
        @keyframes blink {
          0%, 100% { opacity: 1; }
          50% { opacity: 0; }
        }
        
        .typing-cursor {
          display: inline-block;
          width: 0.5rem;
          height: 1rem;
          background-color: var(--assistant-msg-text);
          margin-left: 0.2rem;
          vertical-align: middle;
          animation: blink 1s step-end infinite;
        }

        /* Media query for smaller screens if needed */
        @media (max-width: 600px) {
            body {
                margin: 0.5rem auto;
                padding: 0.5rem;
                height: calc(100vh - 1rem);
            }
            h1 {
                font-size: 1.1rem;
            }
            #userInput, #sendButton {
                font-size: 0.95rem; /* Slightly smaller font on mobile */
                padding: 0.6rem 1rem;
            }
            .message {
                 max-width: 90%; /* Allow slightly wider messages */
            }
        }
    </style>
</head>
<body>
    <div class="header-container">
        <h1>Chat with Local LLM</h1> <label class="switch">
            <input type="checkbox" id="darkModeToggle">
            <span class="slider"></span>
        </label>
    </div>

    <div id="chatbox"></div>

    <div id="input-area">
        <input type="text" id="userInput" placeholder="Type your message..." autocomplete="off">
        <button id="sendButton">Send</button>
    </div>

    <div id="status">Status: Idle</div>

    <script>
        // Get references to the HTML elements
        const chatbox = document.getElementById('chatbox');
        const userInput = document.getElementById('userInput');
        const sendButton = document.getElementById('sendButton');
        const statusDiv = document.getElementById('status');
        const darkModeToggle = document.getElementById('darkModeToggle');
        const bodyElement = document.body;

        // --- Dark Mode Logic ---
        function applyTheme(isDark) {
            if (isDark) {
                bodyElement.classList.add('dark-mode');
            } else {
                bodyElement.classList.remove('dark-mode');
            }
        }

        const savedTheme = localStorage.getItem('darkMode');
        if (savedTheme) {
            const isDark = savedTheme === 'true';
            darkModeToggle.checked = isDark;
            applyTheme(isDark);
        } else {
            const prefersDark = window.matchMedia && window.matchMedia('(prefers-color-scheme: dark)').matches;
            darkModeToggle.checked = prefersDark;
            applyTheme(prefersDark);
            // Optionally save the detected preference
            // localStorage.setItem('darkMode', prefersDark);
        }

        darkModeToggle.addEventListener('change', () => {
            const isDark = darkModeToggle.checked;
            applyTheme(isDark);
            localStorage.setItem('darkMode', isDark);
        });


        // --- Configuration ---
        // IMPORTANT: Replace 'YOUR_PC_IP_ADDRESS' with the actual local IP address
        // of the computer running LM Studio. Find it using 'ipconfig' (Windows)
        // or 'ifconfig' (Mac/Linux) in the terminal/command prompt.
        // It usually looks like 192.168.x.x or 10.0.x.x
        const LM_STUDIO_SERVER_IP = '192.168.29.125'; // <--- *** EDIT THIS LINE ***

        // Construct the final API URL
        const LMSTUDIO_API_URL = `http://${LM_STUDIO_SERVER_IP}:1234/v1/chat/completions`;

        // Store chat history (role and content pairs)
        const messages = [];
        
        // Flag for tracking active streaming
        let isStreaming = false;
        // Reference to the current assistant message element
        let currentAssistantMessageElement = null;
        // Reference to typing cursor element
        let typingCursor = null;

        /**
         * Adds a message to the chatbox UI and the internal message history.
         * @param {string} role - 'user' or 'assistant' or 'system'.
         * @param {string} content - The text content of the message.
         * @param {boolean} addToHistory - Whether to add this message to the history sent to the API (default: true).
         * @param {boolean} isStreaming - Whether this message will be streamed (default: false).
         * @returns {HTMLElement} The message element that was created.
         */
        function addMessage(role, content, addToHistory = true, isStreaming = false) {
            if (addToHistory && (role === 'user' || role === 'assistant')) {
                messages.push({ role: role, content: content });
            }

            if (role === 'system') {
                console.log("System Prompt (not displayed):", content);
                return null;
            }

            const messageDiv = document.createElement('div');
            messageDiv.classList.add('message');
            messageDiv.classList.add(role === 'user' ? 'user-message' : 'assistant-message');
            messageDiv.textContent = content;
            
            // Add typing cursor for streaming assistant messages
            if (role === 'assistant' && isStreaming) {
                // Create and append the typing cursor
                typingCursor = document.createElement('span');
                typingCursor.classList.add('typing-cursor');
                messageDiv.appendChild(typingCursor);
            }
            
            chatbox.appendChild(messageDiv);
            chatbox.scrollTop = chatbox.scrollHeight;
            
            return messageDiv;
        }

        /**
         * Updates the content of an existing message element.
         * @param {HTMLElement} messageElement - The message element to update.
         * @param {string} content - The new content for the message.
         * @param {boolean} finished - Whether streaming is complete.
         */
        function updateMessageContent(messageElement, content, finished = false) {
            if (!messageElement) return;
            
            // Update the text content
            messageElement.textContent = content;
            
            // Re-add the typing cursor if still streaming
            if (!finished && typingCursor) {
                messageElement.appendChild(typingCursor);
            }
            
            // Keep scrolling to the bottom as content is added
            chatbox.scrollTop = chatbox.scrollHeight;
        }

        /**
         * Processes a chunk of streamed text from the API.
         * @param {string} chunk - The text chunk to process.
         */
        function processStreamChunk(chunk) {
            try {
                // Handle empty or invalid chunks
                if (!chunk.trim()) return;
                
                // Parse the chunk data
                const data = JSON.parse(chunk);
                
                // Check if this is a content delta
                if (data.choices && data.choices[0] && data.choices[0].delta && data.choices[0].delta.content) {
                    const contentDelta = data.choices[0].delta.content;
                    
                    // Get current assistant message text
                    const currentText = messages[messages.length - 1].content;
                    
                    // Update the message content in our history array
                    messages[messages.length - 1].content = currentText + contentDelta;
                    
                    // Update the UI with the new content
                    updateMessageContent(currentAssistantMessageElement, messages[messages.length - 1].content);
                }
                
                // Check if stream is finished
                if (data.choices && data.choices[0] && data.choices[0].finish_reason) {
                    isStreaming = false;
                    statusDiv.textContent = 'Status: Idle';
                    sendButton.disabled = false;
                    userInput.disabled = false;
                    userInput.focus();
                    
                    // Remove typing cursor when done
                    if (currentAssistantMessageElement && typingCursor) {
                        updateMessageContent(currentAssistantMessageElement, messages[messages.length - 1].content, true);
                        typingCursor = null;
                    }
                }
            } catch (error) {
                console.error('Error processing stream chunk:', error);
            }
        }

        /**
         * Handles the streaming response from the LM Studio API.
         * @param {ReadableStream} stream - The stream of data from the API.
         */
        async function handleStream(stream) {
            const reader = stream.getReader();
            const decoder = new TextDecoder('utf-8');
            let buffer = '';
            
            try {
                while (true) {
                    const { done, value } = await reader.read();
                    if (done) {
                        // Process any remaining data in the buffer
                        if (buffer.trim()) {
                            const lines = buffer.split('\n');
                            for (const line of lines) {
                                if (line.trim().startsWith('data: ')) {
                                    const chunk = line.trim().substring(6);
                                    if (chunk && chunk !== '[DONE]') {
                                        processStreamChunk(chunk);
                                    }
                                }
                            }
                        }
                        break;
                    }
                    
                    // Decode and process the chunk
                    buffer += decoder.decode(value, { stream: true });
                    
                    // Split by newlines and process complete events
                    const lines = buffer.split('\n');
                    buffer = lines.pop() || ''; // Keep the last incomplete line in the buffer
                    
                    for (const line of lines) {
                        if (line.trim().startsWith('data: ')) {
                            const chunk = line.trim().substring(6);
                            if (chunk && chunk !== '[DONE]') {
                                processStreamChunk(chunk);
                            }
                        }
                    }
                }
            } catch (error) {
                console.error('Stream processing error:', error);
                isStreaming = false;
                statusDiv.textContent = 'Status: Stream Error';
                sendButton.disabled = false;
                userInput.disabled = false;
            }
        }

        /**
         * Sends the user's message and conversation history to the LM Studio API.
         */
        async function sendMessage() {
            const userText = userInput.value.trim();
            if (!userText) return;

            addMessage('user', userText);
            userInput.value = '';

            statusDiv.textContent = 'Status: Thinking...';
            sendButton.disabled = true;
            userInput.disabled = true;

            try {
                const systemPrompt = { role: "system", content: "You are a helpful assistant." };
                const messagesToSend = [systemPrompt, ...messages];

                // --- Make the API call with streaming enabled ---
                const response = await fetch(LMSTUDIO_API_URL, {
                    method: 'POST',
                    headers: {
                        'Content-Type': 'application/json',
                    },
                    body: JSON.stringify({
                        messages: messagesToSend,
                        temperature: 0.7,
                        max_tokens: -1,
                        stream: true  // Enable streaming
                    }),
                });

                // --- Handle the API response ---
                if (!response.ok) {
                    // Provide more specific feedback for network errors vs server errors
                    let errorDetail = '';
                    try {
                         errorDetail = await response.text(); // Try to get server error message
                    } catch (textError) {
                        // Ignore if reading text fails (e.g., network totally down)
                    }
                    throw new Error(`API Error: ${response.status} ${response.statusText}. ${errorDetail || 'Check if LM Studio server is running and reachable at ' + LMSTUDIO_API_URL}`);
                }

                // Set up streaming - add empty message to start with
                isStreaming = true;
                statusDiv.textContent = 'Status: Generating...';
                
                // Add empty assistant message to history (will be updated as we stream)
                messages.push({ role: 'assistant', content: '' });
                
                // Create message element with streaming indicator
                currentAssistantMessageElement = addMessage('assistant', '', false, true);
                
                // Process the streamed response
                await handleStream(response.body);

            } catch (error) {
                console.error('Fetch Error:', error);
                // Display a user-friendly error message
                let displayError = error.message;
                if (error instanceof TypeError && error.message.includes('Failed to fetch')) {
                     displayError = `Load Failed: Could not connect to the LM Studio server. Please check:\n1. LM Studio is running.\n2. The IP address '${LM_STUDIO_SERVER_IP}' is correct for the PC running LM Studio.\n3. Your phone and PC are on the same Wi-Fi network.\n4. Any firewall on the PC allows connections on port 1234.`;
                     statusDiv.textContent = 'Status: Connection Error';
                } else {
                     statusDiv.textContent = `Status: Error - Check console.`;
                }
                addMessage('assistant', `[Error: ${displayError}]`, false); // Don't add error to history
                
                // Ensure we're not left in a streaming state
                isStreaming = false;
                sendButton.disabled = false;
                userInput.disabled = false;
            }
        }

        // --- Event Listeners ---
        sendButton.addEventListener('click', sendMessage);
        userInput.addEventListener('keypress', (event) => {
            if (event.key === 'Enter' && !sendButton.disabled) {
                sendMessage();
            }
        });

         // --- Initial Setup ---
         // Check if the IP address placeholder is still there
         if (LM_STUDIO_SERVER_IP === 'YOUR_PC_IP_ADDRESS') {
             addMessage('assistant', 'Configuration needed! Please edit the HTML file and replace "YOUR_PC_IP_ADDRESS" with the actual IP address of the computer running LM Studio.', false);
             statusDiv.textContent = 'Status: Needs Configuration';
             userInput.disabled = true; // Disable input until configured
             sendButton.disabled = true;
         } else {
             addMessage('assistant', `Hello! Ready to chat with the model at ${LM_STUDIO_SERVER_IP}.`, false);
             statusDiv.textContent = 'Status: Ready';
             userInput.focus();
         }

    </script>

    </body>
</html>
```