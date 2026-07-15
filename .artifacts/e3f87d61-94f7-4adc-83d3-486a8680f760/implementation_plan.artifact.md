# Fix PowerShell Executable Not Found Error

The Flutter device daemon and `flutter doctor` are failing because they cannot find the PowerShell executable (`powershell.exe` or `pwsh.exe`) in the system PATH.

## Findings
- `powershell.exe` is missing from the standard 64-bit location: `C:\Windows\System32\WindowsPowerShell\v1.0\`.
- `powershell.exe` **is available** in the 32-bit compatibility folder: `C:\Windows\SysWOW64\WindowsPowerShell\v1.0\`.
- The current system PATH contains a typo: `C:\Users\hillary.kipkorir\System32\WindowsPowerShell\v1.0` (likely meant to be `C:\Windows\System32\...`).
- `pwsh.exe` (PowerShell Core) is not installed in the standard `Program Files` location.

## Proposed Changes

### Environment Configuration
1. **Fix System PATH**:
    - Remove the incorrect entry: `C:\Users\hillary.kipkorir\System32\WindowsPowerShell\v1.0`.
    - Add the valid PowerShell path: `C:\Windows\SysWOW64\WindowsPowerShell\v1.0`.
    - Ensure `C:\Windows\System32\WindowsPowerShell\v1.0` is also present (even if currently missing the exe, it contains other necessary files).

2. **Verify PowerShell Availability**:
    - After updating the PATH, restart Android Studio (or the terminal) and run `where powershell.exe` to ensure it is resolved correctly.

3. **Fallback (Optional but Recommended)**:
    - Install [PowerShell 7](https://aka.ms/powershell-release?tag=stable) (`pwsh.exe`). Flutter will automatically detect and use `pwsh` if it's in the PATH.

## User Review Required

> [!IMPORTANT]
> Modifying system environment variables requires administrative privileges and will affect all applications. Please follow these steps:
> 1. Press `Win + R`, type `sysdm.cpl`, and press Enter.
> 2. Go to the **Advanced** tab and click **Environment Variables**.
> 3. Under **System variables**, find **Path** and click **Edit**.
> 4. Clean up the entries as described above.

## Verification Plan

### Automated Tests
- Run `flutter doctor -v` in the Android Studio terminal after the PATH update.
- Verify that `where powershell.exe` returns `C:\Windows\SysWOW64\WindowsPowerShell\v1.0\powershell.exe`.

### Manual Verification
- Check if the Flutter device daemon starts successfully without the PowerShell error.
