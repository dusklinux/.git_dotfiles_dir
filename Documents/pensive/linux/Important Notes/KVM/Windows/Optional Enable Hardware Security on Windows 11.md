# Advanced Security: Core Isolation & Memory Integrity

> [!WARNING] Optional Configuration
> 
> This step is optional. Your Windows 11 VM already has standard security if you have selected the Q35 chipset, enabled Secure Boot and TPM 2.0, and installed the correct VirtIO drivers.
> 
> Enabling Core Isolation requires **Nested Virtualization**. This adds a layer of complexity and may impact performance (FPS in games or general responsiveness). Only proceed if you specifically require high-level security features or VBS (Virtualization-based Security).

## 1. Prerequisites

Before attempting to enable Core Isolation, you must ensure your physical host processor supports the necessary virtualization extensions.

1. Check if your CPU meets the [Microsoft Processor Requirements](https://learn.microsoft.com/en-us/windows-hardware/design/minimum/windows-processor-requirements "null").
    
2. If your processor is not supported, **skip this entire guide**.
    

## 2. Enabling Nested Virtualization (XML Editing)

To allow Windows to use Core Isolation, we need to pass specific CPU features from your host Linux system to the Guest VM.

1. **Shut down** your Windows 11 Guest VM completely.
    
2. Open **Virt-Manager**.
    
3. Open the **Virtual Hardware Details** page (the lightbulb icon).
    
4. Select **Overview** in the left panel.
    
5. Click the **XML** tab in the right panel.
    

> [!TIP] Intel vs. AMD
> 
> You need to add a specific flag depending on your processor manufacturer:
> 
> - **Intel** users need the `vmx` flag.
>     
> - **AMD** users need the `svm` flag.
>     

Locate the `<cpu>` section. It will usually look like a single line ending in `/>`. You need to expand this tag to include the feature policy.

**Find this line:**

```
<cpu mode="host-passthrough" check="none" migratable="on"/>
```

**Replace it with ONE of the following blocks:**

### Option A: For Intel CPUs

```
<cpu mode="host-passthrough" check="none" migratable="on">
  <feature policy="require" name="vmx"/>
</cpu>
```

### Option B: For AMD CPUs

```
<cpu mode="host-passthrough" check="none" migratable="on">
  <feature policy="require" name="svm"/>
</cpu>
```

6. Click **Apply** to save the changes.
    

## 3. Enabling Security in Windows

Now that the VM has access to the virtualization hardware features, you can enable the security settings inside Windows.

1. **Start** your Windows 11 VM.
    
2. Navigate to **Settings** > **Privacy & security** > **Windows Security** > **Device security**.
    
3. Click on **Core isolation details**.
    
4. Toggle the **Memory integrity** switch to **On**.
    

> [!NOTE] Reboot Required
> 
> Windows will prompt you to restart to apply these changes.

## 4. Verification

After the VM reboots:

1. Go back to **Settings** > **Privacy & security** > **Windows Security** > **Device security**.
    
2. Verify that **Core isolation** is active and that your device meets the enhanced security requirements.