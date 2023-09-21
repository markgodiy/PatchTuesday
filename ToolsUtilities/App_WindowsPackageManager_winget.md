# winget, aka Windows Package Manager

Windows Package Manager is a comprehensive package manager solution that consists of a command line tool and set of services for installing applications on Windows 10 and Windows 11.

More info here: https://learn.microsoft.com/en-us/windows/package-manager/

The winget command line tool enables users to discover, install, upgrade, remove and configure applications on Windows 10 and Windows 11 computers. This tool is the client interface to the Windows Package Manager service.

![Alt text](/ToolsUtilities/images/wingetversion.png)

## Getting available upgrades

```powershell
winget list --upgrade-available
```

![Alt text](/ToolsUtilities/images/wingetlistavailable.png)

## Install upgrade for a single application 

```powershell
winget upgrade <Application Name>

winget upgrade "windows terminal"
```

![Alt text](/ToolsUtilities/images/wingetinstallone.png)


## Install upgrade for all available  

```powershell
winget upgrade --all
```

![Alt text](/ToolsUtilities/images/wingetupgradeall.png)

