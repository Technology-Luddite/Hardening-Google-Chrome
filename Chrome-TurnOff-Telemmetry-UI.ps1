# Ensure script is running as Administrator
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Add-Type -AssemblyName System.Windows.Forms
    [System.Windows.Forms.MessageBox]::Show("This script requires administrative privileges to modify Windows Registry policies.", "Admin Required", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Warning)
    exit
}

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$registryPath = "HKLM:\SOFTWARE\Policies\Google\Chrome"

# --- Define Hardened Chrome Policies ---
$policies = [ordered]@{
    # NEW Advanced Deep-Layer Hardware & Time Protocol Isolation
    "Disable WebUSB API (Blocks USB Peripheral Scans)"      = @{ ValueName = "WebUsbAllowed"; HardenedValue = 0; Type = "DWORD" }
    "Disable WebHID API (Blocks Mouse/Keyboard Device IDs)"= @{ ValueName = "WebHidAllowed"; HardenedValue = 0; Type = "DWORD" }
    "Block Web MIDI API Access Entirely"                   = @{ ValueName = "DefaultMidiSetting"; HardenedValue = 2; Type = "DWORD" }
    "Disable Network Time Queries (Stops clock-drift tags)" = @{ ValueName = "NetworkTimeQueriesEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Enforce Maximum Print Rendering Memory Sandboxing"     = @{ ValueName = "SandboxToPrintMode"; HardenedValue = 2; Type = "DWORD" }

    # Advanced Local Environment Hardening
    "Block Sites From Silently Reading Clipboard"          = @{ ValueName = "DefaultClipboardSetting"; HardenedValue = 2; Type = "DWORD" }
    "Disable File System API (Blocks offline drive tracking)"= @{ ValueName = "FileSystemAccessEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Screen Capture Capabilities entirely"          = @{ ValueName = "ScreenCaptureAllowed"; HardenedValue = 0; Type = "DWORD" }

    # JS Control & Anti-Fingerprinting Hardening
    "Block JavaScript By Default (Allow manually per site)" = @{ ValueName = "DefaultJavaScriptSetting"; HardenedValue = 2; Type = "DWORD" }
    "Disable WebGL Graphics 3D APIs (Stops GPU Fingerprinting)"= @{ ValueName = "Disable3DAPIs"; HardenedValue = 1; Type = "DWORD" }
    "Block Access to Microphone Hardware Engines"          = @{ ValueName = "AudioCaptureAllowed"; HardenedValue = 0; Type = "DWORD" }
    "Block Access to Webcam Hardware Engines"              = @{ ValueName = "VideoCaptureAllowed"; HardenedValue = 0; Type = "DWORD" }

    # Anti-fingerprinting, tracking, & isolation
    "Block WebRTC From Leaking Local IP Addresses"         = @{ ValueName = "WebRtcIPHandling"; HardenedValue = "disable_non_proxied_udp"; Type = "String" }
    "Disable Third-Party 'Sign-in with Google' API"         = @{ ValueName = "FederatedIdentityApiEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Contextual State & Search Telemetry"           = @{ ValueName = "ContextualSearchEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Block Browser Sign-In & Profile Cloud Syncing"         = @{ ValueName = "SigninAllowed"; HardenedValue = 0; Type = "DWORD" }

    # Core Privacy Settings
    "Disable On-Device AI / Foundational Models"           = @{ ValueName = "GenAILocalFoundationalModelSettings"; HardenedValue = 1; Type = "DWORD" }
    "Enable Global Privacy Control (Do Not Track)"         = @{ ValueName = "GlobalPrivacyControlEnabled"; HardenedValue = 1; Type = "DWORD" }
    "Auto-Wipe All Browser Data on Closing Window"         = @{ ValueName = "ClearBrowsingDataOnExitList"; HardenedValue = '["browsing_history","download_history","cookies_and_other_site_data","cached_images_and_files","password_signin","autofill","site_settings","hosted_app_data"]'; Type = "String" }

    # Core Telemetry & Tracking
    "Disable Metrics & Telemetry Reporting"                = @{ ValueName = "MetricsReportingEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Privacy Sandbox Ad Tracking Topics"          = @{ ValueName = "PrivacySandboxAdTopicsEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Auditing Hyperlinks (<a ping>)"              = @{ ValueName = "HyperlinkAuditingEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Search/URL Autocomplete Suggestions"         = @{ ValueName = "SearchSuggestEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Network Prediction & Prefetching"            = @{ ValueName = "NetworkPredictionOptions"; HardenedValue = 2; Type = "DWORD" }
    "Disable SafeBrowsing Extended Reporting"             = @{ ValueName = "SafeBrowsingExtendedReportingEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Background Component Updates"                = @{ ValueName = "ComponentUpdatesEnabled"; HardenedValue = 0; Type = "DWORD" }
    
    # Credentials & Autofill Bloat
    "Disable Password Manager (Use external)"             = @{ ValueName = "PasswordManagerEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Autofill for Credit Cards"                   = @{ ValueName = "AutofillCreditCardEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Autofill for Addresses"                      = @{ ValueName = "AutofillAddressEnabled"; HardenedValue = 0; Type = "DWORD" }
    
    # Permissions & Privacy Hardening
    "Block Third-Party Cookies By Default"                = @{ ValueName = "BlockThirdPartyCookies"; HardenedValue = $true; Type = "String" }
    "Block Geolocation Tracking Access"                   = @{ ValueName = "DefaultGeolocationsetting"; HardenedValue = 2; Type = "DWORD" }
    "Block Website Push Notification Prompts"             = @{ ValueName = "DefaultNotificationsSetting"; HardenedValue = 2; Type = "DWORD" }
    "Force HTTPS-Only Connections Everywhere"              = @{ ValueName = "HttpsOnlyMode"; HardenedValue = 1; Type = "DWORD" }
    "Block Third-Party Side-Loaded Extensions"            = @{ ValueName = "BlockExternalExtensions"; HardenedValue = 1; Type = "DWORD" }

    # Advanced Security & Deep Network Control
    "Disable Developer Tools (Inspect Element)"           = @{ ValueName = "DeveloperToolsAvailability"; HardenedValue = 2; Type = "DWORD" }
    "Disable Built-in DNS-over-HTTPS (DoH)"               = @{ ValueName = "BuiltInDnsClientEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Hardware Acceleration (GPU)"                 = @{ ValueName = "HardwareAccelerationModeEnabled"; HardenedValue = 0; Type = "DWORD" }
    "Disable Background Apps On Window Close"             = @{ ValueName = "BackgroundModeEnabled"; HardenedValue = 0; Type = "DWORD" }
}

# --- Build the GUI Form Window ---
$form = New-Object System.Windows.Forms.Form
$form.Text = "Enterprise Chrome Security & Privacy Manager - Version: 1.0" 
$form.Size = New-Object System.Drawing.Size(520, 540) 
$form.StartPosition = "CenterScreen"
$form.FormBorderStyle = "FixedDialog"
$form.MaximizeBox = $false

# Label Instructions
$label = New-Object System.Windows.Forms.Label
$label.Text = "Detected enterprise privacy policies for Google Chrome.`nCheck boxes to enforce restrictions, uncheck to return to default control."
$label.Location = New-Object System.Drawing.Point(20, 15)
$label.Size = New-Object System.Drawing.Size(460, 40)
$form.Controls.Add($label)

# --- Scrollable Panel Container ---
$panel = New-Object System.Windows.Forms.Panel
$panel.Location = New-Object System.Drawing.Point(20, 70)
$panel.Size = New-Object System.Drawing.Size(465, 330)
$panel.AutoScroll = $true
$panel.BorderStyle = [System.Windows.Forms.BorderStyle]::FixedSingle
$form.Controls.Add($panel)

$checkboxes = @{}
$yOffset = 10

# Generate Checkboxes inside the Scrollable Panel
foreach ($key in $policies.Keys) {
    $checkBox = New-Object System.Windows.Forms.CheckBox
    $checkBox.Text = $key
    $checkBox.Location = New-Object System.Drawing.Point(15, $yOffset)
    $checkBox.Size = New-Object System.Drawing.Size(410, 26)
    
    $currentVal = Get-ItemProperty -Path $registryPath -Name $policies[$key].ValueName -ErrorAction SilentlyContinue
    if ($currentVal -and ($currentVal.$($policies[$key].ValueName).ToString() -eq $policies[$key].HardenedValue.ToString())) {
        $checkBox.Checked = $true
    } else {
        $checkBox.Checked = $false
    }
    
    $panel.Controls.Add($checkBox)
    $checkboxes[$key] = $checkBox
    $yOffset += 30
}

# Apply Button
$applyButton = New-Object System.Windows.Forms.Button
$applyButton.Text = "Apply Changes"
$applyButton.Location = New-Object System.Drawing.Point(185, 435)
$applyButton.Size = New-Object System.Drawing.Size(140, 35)

$applyButton.Add_Click({
    if (-not (Test-Path $registryPath)) {
        New-Item -Path "HKLM:\SOFTWARE\Policies\Google" -Name "Chrome" -Force | Out-Null
    }

    foreach ($key in $policies.Keys) {
        $valName = $policies[$key].ValueName
        $hVal = $policies[$key].HardenedValue
        $type = $policies[$key].Type

        if ($checkboxes[$key].Checked) {
            New-ItemProperty -Path $registryPath -Name $valName -Value $hVal -PropertyType $type -Force | Out-Null
        } else {
            Remove-ItemProperty -Path $registryPath -Name $valName -ErrorAction SilentlyContinue
        }
    }

    [System.Windows.Forms.MessageBox]::Show("Chrome privacy policies updated successfully!`n`nPlease restart Google Chrome to see the changes applied.", "Success", [System.Windows.Forms.MessageBoxButtons]::OK, [System.Windows.Forms.MessageBoxIcon]::Information)
    $form.Close()
})

$form.Controls.Add($applyButton)

# Display Form
[void]$form.ShowDialog()