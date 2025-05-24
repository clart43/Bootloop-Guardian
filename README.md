🛡️ Bootloop Guardian: Magisk Module Detector 🔍
This Magisk module acts as your personal system protector, designed to automatically detect and recover your device from annoying bootloops caused by other Magisk modules. Say goodbye to manual flashing in recovery and hours of troubleshooting!
What it Does:
 * ⚡ Proactive Bootloop Detection: This module intelligently monitors your device's boot process. If it detects that your system is failing to start correctly (e.g., critical system processes like Zygote or SystemUI are not launching) for a set number of attempts (the "bootloop threshold"), it springs into action.
 * 🚫 Automatic Module Disablement: Once a bootloop is confirmed, the "Bootloop Guardian" will automatically disable ALL other Magisk modules that might be causing the issue. This allows your device to boot successfully into a working state.
 * 🎯 Culprit Identification: The best part? After recovering from a bootloop, this module will tell you exactly which Magisk module was the likely culprit! It updates its own description in the Magisk Manager app to display the ID and Name of the module that caused the bootloop. No more guessing games!
 * 🧹 Smart Log Management: If your device boots successfully without any issues, the module will clear its internal "last active module" log, keeping things tidy and ensuring that next time, it only reports genuine bootloop causes.
 * ✨ Lightweight Background Monitoring: Even after a successful boot, the module runs in the background with minimal resource consumption, quietly monitoring system logs for critical error "codes" (like fatal app crashes or system service failures) that might indicate instability, logging them for your review.
How it Helps You:
 * Save Time & Frustration: Quickly identify and fix bootloops without needing to manually disable modules in recovery or perform clean flashes.
 * Effortless Diagnosis: Get clear, actionable information about the problematic module directly in Magisk Manager.
 * Enhanced Stability: A smarter, more resilient Magisk experience.
Where to See the Information:
After a bootloop event and successful recovery, simply open your Magisk Manager app. Navigate to the "Modules" section, and look for your installed module, "Bootloop Guardian: Magisk Module Detector". Its description will be updated to show the ID and name of the module that caused the bootloop.
Inspired in : https://github.com/Magisk-Modules-Alt-Repo/Simple_BootloopSaver
