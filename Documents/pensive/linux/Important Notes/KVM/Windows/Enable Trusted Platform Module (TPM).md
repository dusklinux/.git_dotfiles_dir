# For Win11 only. 

> [!INFO] Why do we need this?
> 
> Trusted Platform Module (TPM) is a technology designed to provide hardware-based, security-related functions. Windows 11 explicitly requires TPM version 2.0 to install and run. Since we are using a Virtual Machine, we will emulate this hardware feature.

### Prerequisites

Ensure you have the software TPM emulator installed on your host system. On Arch Linux, this is provided by the `swtpm` package.

should already have been installed in one of the previous steps.
```bash
sudo pacman -S --needed swtpm
```

### Configuration Steps

1. **Select TPM**: Click on the entry labeled **TPM** (it may appear as `TPM vNone` or simply `TPM`).
    
2. **Configure Attributes**:
    
    - Locate the **Advanced options** dropdown on the right side.
        
    - **Version**: Change this to `2.0`.
        
    - **Type**: Ensure this is set to `Emulated`.
        
    - **Model**: Ensure this is set to `CRB`.
        
3. **Save Changes**: Click **Apply** at the bottom right.
    

> [!SUCCESS] Result
> 
> Your Virtual Machine now has a virtualized TPM 2.0 security chip, satisfying the Windows 11 installation requirements.