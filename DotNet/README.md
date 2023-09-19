# DotNet | dotnet | .NET

By Mark Go  
Date 2023-09-18

## :information_source: dotnet-install scripts by Microsoft

The `dotnet-install` scripts* perform a non-admin installation of the .NET SDK, which includes the .NET CLI and the shared runtime.

Direct link to script. Clicking URL will trigger download of the file but will not execute it. --> https://dot.net/v1/dotnet-install.ps1

*A `bash` version is also available. More info here: https://learn.microsoft.com/en-us/dotnet/core/tools/dotnet-install-script

## Validating script with `Get-AuthenticodeSignature`

```powershell
# Get Authentication signature of dotnet-install.ps1 script:
PS> Get-AuthenticodeSignature G:\path\to\dotnet-install.ps1

SignerCertificate                         Status                              StatusMessage                      Path
-----------------                         ------                              -------------                      ----
72105B6D5F370B62FD5C82F1512F7AD7DEE5F2C0  Valid                               Signature verified.                dotnet-install.ps1

```

## Practical Application :computer::computer::computer:


**1. Checking current .NET SDK environment**

`dotnet.exe` is included with .NET. 

Use command `dotnet sdk check` but check out what else you can do with it. `dotnet --help`

```text
PS> dotnet sdk check
.NET SDKs:
Version      Status
------------------------
7.0.203      Up to date.

Try out the newest .NET SDK features with .NET 8.0.100-rc.1.23463.5.

.NET Runtimes:
Name                              Version      Status
-------------------------------------------------------------------------
Microsoft.AspNetCore.App          6.0.16       Patch 6.0.22 is available.
Microsoft.NETCore.App             6.0.16       Patch 6.0.22 is available.
Microsoft.WindowsDesktop.App      6.0.16       Patch 6.0.22 is available.
Microsoft.AspNetCore.App          7.0.5        Patch 7.0.11 is available.
Microsoft.NETCore.App             7.0.5        Patch 7.0.11 is available.
Microsoft.WindowsDesktop.App      7.0.5        Patch 7.0.11 is available.
Microsoft.NETCore.App             7.0.11       Up to date.
Microsoft.WindowsDesktop.App      7.0.11       Up to date.


The latest versions of .NET can be installed from https://aka.ms/dotnet-core-download. For more information about .NET lifecycles, see https://aka.ms/dotnet-core-support.
```

**2. Executing `dotnet-install.ps1` script to fetch and install update**

```powershell
PS> .\dotnet-install.ps1

Do you want to run software from this untrusted publisher?
File G:\PatchTuesday\DotNet\dotnet-install.ps1 is published by CN=Microsoft Corporation, O=Microsoft Corporation, L=Redmond, S=Washington, C=US and
 is not trusted on your system. Only run scripts from trusted publishers.
[V] Never run  [D] Do not run  [R] Run once  [A] Always run  [?] Help (default is "D"): R
dotnet-install: Remote file https://dotnetcli.azureedge.net/dotnet/Sdk/6.0.414/dotnet-sdk-6.0.414-win-x64.zip size is 262678092 bytes.
dotnet-install: Downloaded file https://dotnetcli.azureedge.net/dotnet/Sdk/6.0.414/dotnet-sdk-6.0.414-win-x64.zip size is 262678092 bytes.
dotnet-install: The remote and local file sizes are equal.
dotnet-install: Extracting the archive.
dotnet-install: Adding to current process PATH: "C:\Users\jungl\AppData\Local\Microsoft\dotnet\". Note: This change will not be visible if PowerShell was run as a child process.
dotnet-install: Note that the script does not resolve dependencies during installation.
dotnet-install: To check the list of dependencies, go to https://learn.microsoft.com/dotnet/core/install/windows#dependencies
dotnet-install: Installed version is 6.0.414
dotnet-install: Installation finished
```

**3. Checking installed SDK by running dotnet CLI command: `dotnet sdk check`**

```powershell
# Note: old version will be replaced after reboot

PS G:\PatchTuesday\DotNet> dotnet sdk check
.NET SDKs:
Version      Status     
------------------------
6.0.414      Up to date.
7.0.203      Up to date.

Try out the newest .NET SDK features with .NET 8.0.100-rc.1.23463.5.

.NET Runtimes:
Name                              Version      Status
-------------------------------------------------------------------------
Microsoft.AspNetCore.App          6.0.16       Patch 6.0.22 is available.
Microsoft.NETCore.App             6.0.16       Patch 6.0.22 is available.
Microsoft.WindowsDesktop.App      6.0.16       Patch 6.0.22 is available.
Microsoft.AspNetCore.App          6.0.22       Up to date.
Microsoft.NETCore.App             6.0.22       Up to date.
Microsoft.WindowsDesktop.App      6.0.22       Up to date.
Microsoft.AspNetCore.App          7.0.5        Patch 7.0.11 is available.
Microsoft.NETCore.App             7.0.5        Patch 7.0.11 is available.
Microsoft.WindowsDesktop.App      7.0.5        Patch 7.0.11 is available.
Microsoft.NETCore.App             7.0.11       Up to date.
Microsoft.WindowsDesktop.App      7.0.11       Up to date.


The latest versions of .NET can be installed from https://aka.ms/dotnet-core-download. For more information about .NET lifecycles, see https://aka.ms/dotnet-core-support.

```

