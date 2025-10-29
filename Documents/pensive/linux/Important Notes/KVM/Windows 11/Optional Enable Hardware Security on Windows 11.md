Optional and not recommanded unless you want crazy security for some reason. 

With the Q35 chipset selected, Secure Boot and TPM 2.0 enabled, and the latest WHQL-certified VirtIO drivers installed, your Windows 11 guest virtual machine already has standard security.

You can check if your VM passes standard security by opening the Device Security page.

To access the Device Security page, navigate to Settings > Privacy & Security > Windows Security > Device Security.

To make Windows 11 even more secure, you can enable Core Isolation.

Core isolation safeguards against malware and other attacks by separating computer processes from your operating system and device.

But before attempting to enable this feature, make sure that your processor supports it.

Your processor must meet the [Windows Processor Requirements](https://learn.microsoft.com/en-us/windows-hardware/design/minimum/windows-processor-requirements) to enable this feature. If your processor is not on the list, skip this section and proceed to the next one.

Shut down your Windows 11 guest virtual machine. Open the **virtual hardware details** page, then click the **Overview** option on the left panel and the **XML** tab on the right.

Under the **<cpu>** section, specify the CPU mode and add the policy flag.

Replace this:

<cpu mode="host-passthrough" check="none" migratable="on"/>

With this:

<cpu mode="host-passthrough" check="none" migratable="on">
  <feature policy="require" name="vmx"/>
</cpu>

Start your Windows 11 guest virtual machine and navigate to the Core isolation details page.

To access the Core isolation details page, navigate to Settings > Privacy & Security > Windows Security > Device Security > Core isolation details.

Toggle the Memory Integrity switch to enable it. When prompted, restart the Windows 11 VM.

After the reboot, check the security level of your device once more. Go to the **Device Security** page by navigating to **Settings** > **Privacy & Security** > **Windows Security** > **Device Security**.