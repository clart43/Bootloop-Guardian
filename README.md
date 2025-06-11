Bootloop Guardian 🛡️


A smart Magisk module designed to automatically detect and recover from bootloops caused by other modules.

The Problem
We've all been there: you install a new Magisk module, reboot with excitement, and... the device never finishes booting. You're stuck in a bootloop. The usual solution involves rebooting into recovery, finding the problematic module's files, and manually deleting them—a tedious and frustrating process.

The Solution: Your Automatic Safety Net
Bootloop Guardian is your personal system protector. It acts as an automatic safety net that watches over the boot process. If it detects a failure, it intervenes automatically so you can regain control of your device effortlessly.

Key Features
🔍 Smart Bootloop Detection
The module actively monitors your device's boot process. If critical system processes (like Zygote or SystemUI) fail to start after a configurable number of attempts, it considers it a bootloop and springs into action.

🚫 Automatic Module Disablement
Once a bootloop is confirmed, Bootloop Guardian automatically disables ALL other Magisk modules. This neutralizes the cause of the problem and allows your device to boot successfully.

🎯 Accurate Culprit Identification
No more guessing games! After a successful recovery, the module updates its own description in the Magisk app to show you the name and ID of the module that likely caused the bootloop.

✨ Lightweight Background Monitoring
Even after a successful boot, the module keeps a silent watch with minimal resource consumption. It logs critical events like fatal exceptions (FATAL EXCEPTION) or system crashes (SystemServer crash) for your review.

How It Works
For your peace of mind, here’s a transparent breakdown of how it operates:

Logging Phase (post-fs-data): As the boot process begins, the module logs the last enabled Magisk module it finds.
Verification Phase (service.sh): After a reasonable waiting period (90 seconds by default), the module checks if essential Android processes are running.
Rescue Action:
If the boot fails: It assumes a bootloop. It then disables other modules, updates its own description with the likely culprit's name (from the log in step 1), and forces a clean reboot.
If the boot succeeds: It resets its internal counter and clears the log, getting everything ready for the next boot.
Installation
Download the module's .zip file from the Releases section.
Open the Magisk app.
Go to the Modules tab.
Tap on "Install from storage" and select the .zip file.
Reboot the device.
Finding the Culprit's Info
After the module has rescued you from a bootloop:

Open the Magisk app.
Go to the Modules tab.
Find Bootloop Guardian in your list of installed modules.
Read its description: The name of the problematic module will be displayed there.
Configuration
You can adjust the reboot threshold for triggering the rescue action. To do so, edit the service.sh file within the module and modify the variable:

Bash

BOOTLOOP_THRESHOLD=2 # Number of failed boots before taking action
Credits and Inspiration
This project was inspired by the work and original idea of Simple_BootloopSaver.
