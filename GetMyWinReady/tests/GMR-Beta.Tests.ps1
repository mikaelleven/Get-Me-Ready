$repositoryRoot = Split-Path -Parent $PSScriptRoot

BeforeAll {
    $testRepositoryRoot = Split-Path -Parent $PSScriptRoot
    . (Join-Path $testRepositoryRoot 'GMR.ps1')
}

Describe 'GMR beta menu model' {
    It 'uses the fewest columns while keeping at most 12 rows' {
        $cases = @(
            @{ Items = 1; Columns = 1; Rows = 1 }
            @{ Items = 12; Columns = 1; Rows = 12 }
            @{ Items = 13; Columns = 2; Rows = 7 }
            @{ Items = 25; Columns = 3; Rows = 9 }
            @{ Items = 48; Columns = 4; Rows = 12 }
        )
        foreach ($case in $cases) {
            $layout = Get-GmrMenuLayout -ItemCount $case.Items
            $layout.ColumnCount | Should -Be $case.Columns
            $layout.RowsPerColumn | Should -Be $case.Rows
        }
        { Get-GmrMenuLayout -ItemCount 49 } | Should -Throw
    }

    It 'ignores standalone default comments and rejects inline default metadata' {
        $path = Join-Path $TestDrive 'Defaults.gmr'
        Set-Content -LiteralPath $path -Value @(
            'One.Package'
            '# default: false'
            'Two.Package'
            'Three.Package # default: no'
        )

        { Get-GmrEntryRecords -FilePath $path } | Should -Throw '*Inline # default:*'

        Set-Content -LiteralPath $path -Value @('One.Package', '# default: false', 'Two.Package')
        $records = @(Get-GmrEntryRecords -FilePath $path)
        $records.Count | Should -Be 2
        $records[0].DefaultEnabled | Should -Be $true
        $records[1].DefaultEnabled | Should -Be $true
    }

    It 'interprets required and selected metadata as module attributes' {
        $path = Join-Path $TestDrive 'Required.gmr'
        Set-Content -LiteralPath $path -Value @(
            '# required: true'
            '# selected: true'
            '? One.Package'
            '! Two.Package'
        )

        $records = @(Get-GmrEntryRecords -FilePath $path)
        $records.Count | Should -Be 2
        $records[0].Mandatory | Should -Be $false
        $records[1].Mandatory | Should -Be $true

        $module = Get-GmrDescriptor -File (Get-Item -LiteralPath $path)
        $module.Required | Should -Be $true
        $module.Selected | Should -Be $true
        $module.Enabled | Should -Be $true
        $module.Entries[0].Enabled | Should -Be $false
        $module.Entries[1].Enabled | Should -Be $true

        $cleanModule = Get-GmrDescriptor -File (Get-Item -LiteralPath $path) -Clean
        $cleanModule.Required | Should -Be $false
        $cleanModule.Selected | Should -Be $false
        $cleanModule.Enabled | Should -Be $false
        @($cleanModule.Entries | Where-Object Enabled).Count | Should -Be 0
    }

    It 'allows a selected module to be disabled but keeps a required module enabled' {
        $selectedModule = [pscustomobject] @{
            Required = $false; Enabled = $false; DisplayName = 'Selected'; MenuItem = $null
            Entries = [object[]] @([pscustomobject] @{ Enabled = $false; DefaultEnabled = $true; MenuItem = $null; DisplayName = 'One' })
        }
        $requiredModule = [pscustomobject] @{
            Required = $true; Enabled = $false; DisplayName = 'Required'; MenuItem = $null
            Entries = [object[]] @([pscustomobject] @{ Enabled = $false; DefaultEnabled = $true; MenuItem = $null; DisplayName = 'One' })
        }

        Set-GmrModuleState -Module $selectedModule -Enabled $true
        Set-GmrModuleState -Module $selectedModule -Enabled $false
        $selectedModule.Enabled | Should -Be $false
        $selectedModule.Entries[0].Enabled | Should -Be $false

        Set-GmrModuleState -Module $requiredModule -Enabled $false
        $requiredModule.Enabled | Should -Be $true
        $requiredModule.Entries[0].Enabled | Should -Be $true
    }

    It 'rejects .gmrs descriptors' {
        $path = Join-Path $TestDrive 'Unsupported.gmrs'
        Set-Content -LiteralPath $path -Value 'Write-Host Hello'

        { Get-GmrDescriptor -File (Get-Item -LiteralPath $path) } | Should -Throw '*only supports .gmr descriptors*'
    }

    It 'enables module entries according to their defaults and disables all entries' {
        $module = [pscustomobject] @{
            Enabled = $false
            DisplayName = 'Test'
            MenuItem = $null
            Entries = [object[]] @(
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $true; MenuItem = $null; DisplayName = 'One' }
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $false; MenuItem = $null; DisplayName = 'Two' }
            )
        }

        Set-GmrModuleState -Module $module -Enabled $true
        $module.Enabled | Should -Be $true
        $module.Entries[0].Enabled | Should -Be $true
        $module.Entries[1].Enabled | Should -Be $false

        Set-GmrModuleState -Module $module -Enabled $false
        @($module.Entries | Where-Object Enabled).Count | Should -Be 0
    }

    It 'keeps required entries enabled and prevents toggling them off' {
        $module = [pscustomobject] @{
            Enabled = $false
            DisplayName = 'Test'
            MenuItem = $null
            Menu = $null
            Entries = [object[]] @(
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $false; Mandatory = $true; MenuItem = $null; DisplayName = 'Required' }
            )
        }

        Set-GmrModuleState -Module $module -Enabled $true
        $module.Entries[0].Enabled | Should -Be $true

        $menu = New-GmrModuleMenu -Module $module
        & $menu.Items[1].SpaceAction
        $module.Entries[0].Enabled | Should -Be $true
    }

    It 'selects a required entry when its inactive module is opened' {
        $module = [pscustomobject] @{
            Enabled = $false
            DisplayName = 'Test'
            MenuItem = $null
            Menu = $null
            Entries = [object[]] @(
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $false; Mandatory = $true; MenuItem = $null; DisplayName = 'Required' }
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $false; Mandatory = $false; MenuItem = $null; DisplayName = 'Optional' }
            )
        }
        $mainMenu = New-GmrMainMenu -Modules @($module)

        & $module.Menu.Items[1].SpaceAction

        $module.Entries[0].Enabled | Should -Be $true
        $module.Entries[1].Enabled | Should -Be $false
        $module.Enabled | Should -Be $true
        $mainMenu.Items[0].Label | Should -Be '[*] Test [1/2]'
    }

    It 'cycles module Space through Selective, All, and None' {
        $module = [pscustomobject] @{
            Enabled = $false
            DisplayName = 'Test'
            MenuItem = $null
            Menu = $null
            Entries = [object[]] @(
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $true; MenuItem = $null; DisplayName = 'One' }
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $false; MenuItem = $null; DisplayName = 'Two' }
            )
        }
        $script:GmrState.SelectionTouched = $false
        $mainMenu = New-GmrMainMenu -Modules @($module)

        & $mainMenu.Items[0].SpaceAction
        $mainMenu.Items[0].Label | Should -Be '[*] Test [1/2]'
        $module.Menu.Items[1].Label | Should -Be '[x] One'
        $module.Menu.Items[2].Label | Should -Be '[ ] Two'

        & $mainMenu.Items[0].SpaceAction
        $mainMenu.Items[0].Label | Should -Be '[x] Test [2/2]'
        @($module.Entries | Where-Object Enabled).Count | Should -Be 2

        & $mainMenu.Items[0].SpaceAction
        $mainMenu.Items[0].Label | Should -Be '[ ] Test [0/2]'
        @($module.Entries | Where-Object Enabled).Count | Should -Be 0

        & $module.Menu.Items[2].SpaceAction
        $mainMenu.Items[0].Label | Should -Be '[*] Test [1/2]'
        $module.Menu.Items[1].Label | Should -Be '[ ] One'
        $module.Menu.Items[2].Label | Should -Be '[x] Two'
        $script:GmrState.SelectionTouched | Should -Be $true
    }

    It 'selects required entries but not defaults with the first manual entry selection' {
        $module = [pscustomobject] @{
            Enabled = $false
            DisplayName = 'Test'
            MenuItem = $null
            Menu = $null
            Entries = [object[]] @(
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $true; Mandatory = $false; MenuItem = $null; DisplayName = 'Default' }
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $false; Mandatory = $true; MenuItem = $null; DisplayName = 'Required' }
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $false; Mandatory = $false; MenuItem = $null; DisplayName = 'Chosen' }
            )
        }
        $mainMenu = New-GmrMainMenu -Modules @($module)

        & $module.Menu.Items[3].SpaceAction

        $module.Entries[0].Enabled | Should -Be $false
        $module.Entries[1].Enabled | Should -Be $true
        $module.Entries[2].Enabled | Should -Be $true
        $mainMenu.Items[0].Label | Should -Be '[*] Test [2/3]'
    }

    It 'places Back first and selects Save configuration by default in step two' {
        $module = [pscustomobject] @{
            Enabled = $false
            DisplayName = 'Test'
            MenuItem = $null
            Menu = $null
            Entries = [object[]] @()
        }
        $submenu = New-GmrModuleMenu -Module $module
        $submenu.Items[0].GoBack | Should -Be $true
        $submenu.Items[0].Label | Should -Be '(Back)'

        $moduleWithEntry = [pscustomobject] @{
            Enabled = $false
            DisplayName = 'Test'
            MenuItem = $null
            Menu = $null
            Entries = [object[]] @(
                [pscustomobject] @{ Enabled = $false; DefaultEnabled = $true; Mandatory = $false; MenuItem = $null; DisplayName = 'One' }
            )
        }
        $submenu = New-GmrModuleMenu -Module $moduleWithEntry
        $submenu.Items[1].GoBack | Should -Be $true
        $submenu.Items[1].SpaceAction | Should -Not -BeNullOrEmpty

        $restorePoint = $true
        $executionMenu = New-GmrExecutionMenu -CreateRestorePoint ([ref] $restorePoint)
        $executionMenu.Items[0].Label | Should -Be '[x] Create restore point'
        $executionMenu.Items[1].Id | Should -Be 'save-configuration'
        $executionMenu.InitialSelectedIndex | Should -Be 1
        $executionMenu.Items[-1].Id | Should -Be 'quit'

        & $executionMenu.Items[0].SpaceAction
        $restorePoint | Should -Be $false
        $executionMenu.Items[0].Label | Should -Be '[ ] Create restore point'
    }

    It 'places Continue immediately before Quit in the main menu' {
        $module = [pscustomobject] @{
            Enabled = $false
            DisplayName = 'Test'
            MenuItem = $null
            Menu = $null
            Entries = [object[]] @()
        }
        $menu = New-GmrMainMenu -Modules @($module)
        $menu.Items[-2].Id | Should -Be 'continue'
        $menu.Items[-1].Id | Should -Be 'quit'
    }

    It 'uses the requested branded title and title detail' {
        $module = [pscustomobject] @{
            Enabled = $false
            DisplayName = 'Test'
            MenuItem = $null
            Menu = $null
            Entries = [object[]] @()
        }

        $menu = New-GmrMainMenu -Modules @($module)
        $menu.Title | Should -Be 'GetMeReady (beta)'
        $menu.TitleDetail | Should -Be ' - Created by Mikael Levén'
    }
}

Describe 'GMR beta syntax' {
    It 'parses the documented .gmr one-line command forms' {
        $cases = @(
            @{ Line = 'Mozilla.Firefox'; Type = 'Winget'; Command = 'Mozilla.Firefox'; Default = $true; Mandatory = $false; Selector = 'id'; Exact = $true; Source = 'winget'; Title = $null }
            @{ Line = '? fuzzy name msstore "Chrome Store" : Chrome'; Type = 'Winget'; Command = 'Chrome'; Default = $false; Mandatory = $false; Selector = 'name'; Exact = $false; Source = 'msstore'; Title = 'Chrome Store' }
            @{ Line = '> Brave.Brave'; Type = 'Winget'; Command = 'Brave.Brave'; Default = $true; Mandatory = $false; Selector = 'id'; Exact = $true; Source = 'winget'; Title = $null }
            @{ Line = '?> Microsoft.Edge'; Type = 'Winget'; Command = 'Microsoft.Edge'; Default = $false; Mandatory = $false; Selector = 'id'; Exact = $true; Source = 'winget'; Title = $null }
            @{ Line = '? : "Google Chrome"> Chrome'; Type = 'Winget'; Command = 'Chrome'; Default = $false; Mandatory = $false; Selector = 'id'; Exact = $true; Source = 'winget'; Title = 'Google Chrome' }
            @{ Line = '!> Vivaldi.Vivaldi'; Type = 'Winget'; Command = 'Vivaldi.Vivaldi'; Default = $true; Mandatory = $true; Selector = 'id'; Exact = $true; Source = 'winget'; Title = $null }
            @{ Line = '^> Microsoft.Sysinternals'; Type = 'Winget'; Command = 'Microsoft.Sysinternals'; Default = $true; Mandatory = $false; Selector = 'id'; Exact = $true; Source = 'winget'; Title = $null; RequiresElevation = $true }
            @{ Line = '$> .\Installers\Install-uBlockOriginLite.ps1'; Type = 'PowerShell'; Command = '.\Installers\Install-uBlockOriginLite.ps1'; Default = $true; Mandatory = $false; Selector = 'id'; Exact = $true; Source = 'winget'; Title = $null }
            @{ Line = '"Write Hello" : $> Write-Host ''Hello'''; Type = 'PowerShell'; Command = 'Write-Host ''Hello'''; Default = $true; Mandatory = $false; Selector = 'id'; Exact = $true; Source = 'winget'; Title = 'Write Hello' }
            @{ Line = '? "Ollama Qwen 3.5" : $> ollama pull qwen35'; Type = 'PowerShell'; Command = 'ollama pull qwen35'; Default = $false; Mandatory = $false; Selector = 'id'; Exact = $true; Source = 'winget'; Title = 'Ollama Qwen 3.5' }
            @{ Line = 'fuzzy name msstore> "Google Chrome"'; Type = 'Winget'; Command = '"Google Chrome"'; Default = $true; Mandatory = $false; Selector = 'name'; Exact = $false; Source = 'msstore'; Title = $null }
        )
        foreach ($case in $cases) {
            $record = ConvertFrom-GmrEntryLine -Line $case.Line
            $record.Type | Should -Be $case.Type
            $record.Command | Should -Be $case.Command
            $record.DefaultEnabled | Should -Be $case.Default
            $record.Mandatory | Should -Be $case.Mandatory
            $record.RequiresElevation | Should -Be $(if ($case.ContainsKey('RequiresElevation')) { $case.RequiresElevation } else { $false })
            $record.WingetSelector | Should -Be $case.Selector
            $record.WingetExact | Should -Be $case.Exact
            $record.WingetSource | Should -Be $case.Source
            $record.Title | Should -Be $case.Title
        }
    }

    It 'uses the parsed WinGet selector, source, and match mode' {
        $record = ConvertFrom-GmrEntryLine -Line 'fuzzy name msstore> "Google Chrome"'
        $spec = Get-WingetPackageSpec -Entry $record

        $spec.DisplayName | Should -Be 'Google Chrome'
        $spec.Arguments | Should -Be @('--name', 'Google Chrome', '--source', 'msstore', '--silent', '--accept-package-agreements', '--accept-source-agreements', '--disable-interactivity')
    }

    It 'accepts obsolete PS> entries as PowerShell entries' {
        $record = ConvertFrom-GmrEntryLine -Line 'PS> .\Installers\Install-Python.ps1'
        $record.Type | Should -Be 'PowerShell'
        $record.Command | Should -Be '.\Installers\Install-Python.ps1'
    }

    It 'runs a parameterless child script without passing an argument array' {
        $childScriptPath = Join-Path $TestDrive 'Install-Test.ps1'
        $descriptorPath = Join-Path $TestDrive 'Test.gmr'
        Set-Content -LiteralPath $childScriptPath -Value @(
            '[CmdletBinding()]'
            'param()'
            '$global:GmrParameterlessChildScriptRan = $true'
        )
        Set-Content -LiteralPath $descriptorPath -Value '# Test descriptor'
        $global:GmrParameterlessChildScriptRan = $false
        $module = [pscustomobject] @{
            Type = '.gmr'
            File = Get-Item -LiteralPath $descriptorPath
            Enabled = $true
            Entries = [object[]] @(
                [pscustomobject] @{ Enabled = $true; Type = 'PowerShell'; Command = '.\Install-Test.ps1' }
            )
        }

        Invoke-GmrSelectedCommands -Modules @($module) -DryRun $false -CreateRestorePoint $false

        $global:GmrParameterlessChildScriptRan | Should -Be $true
        Remove-Variable -Name GmrParameterlessChildScriptRan -Scope Global
    }

    It 'derives GMR beta titles from the shared program name rules' {
        $descriptor = Get-Item -LiteralPath (Join-Path $testRepositoryRoot 'Browsers.gmr')
        $cases = @(
            @{ Line = '7zip.7zip'; Expected = '7-Zip' }
            @{ Line = 'Microsoft.VisualStudioCode'; Expected = 'Visual Studio Code' }
            @{ Line = '> "Flow Launcher"'; Expected = 'Flow Launcher' }
            @{ Line = '$> .\Installers\Reload-Terminal.ps1'; Expected = 'Reload Terminal' }
            @{ Line = '$> ollama pull ''qwen3.5-9b'''; Expected = 'ollama pull ''qwen3.5-9b''' }
            @{ Line = '? "VS Code" >Microsoft.VisualStudioCode'; Expected = 'VS Code' }
            @{ Line = '$> .\Installers\My_Custom-Script.ps1'; Expected = 'My Custom Script' }
        )
        foreach ($case in $cases) {
            $record = ConvertFrom-GmrEntryLine -Line $case.Line
            (Get-GmrEntryDisplayName -Record $record -DescriptorFile $descriptor) | Should -Be $case.Expected
        }
    }

    It 'parses the beta script and its tests without errors' {
        $testRepositoryRoot = Split-Path -Parent $PSScriptRoot
        $files = @(
            Join-Path $testRepositoryRoot 'GMR.ps1'
            Join-Path $PSScriptRoot 'GMR-Beta.Tests.ps1'
        )
        foreach ($file in $files) {
            $tokens = $null
            $errors = $null
            [void] [Management.Automation.Language.Parser]::ParseFile($file, [ref] $tokens, [ref] $errors)
            $errors.Count | Should -Be 0
        }
    }
}

