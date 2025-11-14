# III. Boot File Reconstruction

With the EFI partition successfully created and formatted in the previous step, [[EFI partition synthesis]], we can now populate it. This stage involves using the `bcdboot` utility to copy the essential Windows Boot Manager files and create the Boot Configuration Data (BCD) store, which tells your computer how to load Windows.

### 1. Exit the `diskpart` Environment

First, you must exit the `diskpart` utility to return to the standard Command Prompt. The `bcdboot` command is an external tool and cannot be run from within the `diskpart` interface.

```shell
exit
```

### 2. Execute the `bcdboot` Command

This is the most critical step in the entire process. The `bcdboot` command will copy the necessary boot files from your existing Windows installation to the new EFI partition (`S:`) we just created.

> [!WARNING] Verify Your Drive Letters!
> You **must** replace `W:` in the command below with the actual drive letter of your main Windows installation, which you identified in the [[Preliminary Identification]] step. Using the wrong source drive will cause the command to fail.

Execute the following command precisely:

```shell
bcdboot W:\Windows /s S: /f ALL
```

> [!TIP] Understanding the `bcdboot` Command
> Let's break down what each part of this command does:
> | Parameter | Description |
> | :--- | :--- |
> | `W:\Windows` | This is the **source** directory. It points to the `\Windows` folder on your main Windows partition. |
> | `/s S:` | This specifies the **target** system partition. It instructs `bcdboot` to install the boot files onto our newly created EFI partition, which we assigned the letter `S:`. |
> | `/f ALL` | This sets the **firmware type**. The `ALL` option creates boot files compatible with **both** modern UEFI and older Legacy BIOS systems, ensuring maximum compatibility for your hardware. |

### 3. Confirm Successful Execution

If the command is executed correctly, the system will process the files and you will receive a clear confirmation message in the command prompt:

```
Boot files successfully created.
```

This message confirms that the EFI partition on drive `S:` now contains a valid, functional Windows bootloader. Your system now knows how to find and start Windows.

You are now ready to proceed to the [[Post-Procedure Steps]].
