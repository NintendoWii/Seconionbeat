Get-ChildItem "C:\Windows\Temp\seconion\" -Recurse | Unblock-File

# Delete and stop the service if it already exists.
if (Get-Service seconion -ErrorAction SilentlyContinue) {
  $service = Get-WmiObject -Class Win32_Service -Filter "name='seconionbeat'"
  $service.StopService()
  Start-Sleep -s 1
  $service.delete()
}

$workdir = $(pwd).tostring()

# Create the new service.
New-Service -name seconionbeat `
  -displayName seconionbeat `
  -binaryPathName "`"C:\Windows\temp\seconion\seconionbeat.exe`" --environment=windows_service -c `"C:\Windows\temp\seconion\seconionbeat.yml`" --path.home `"C:\Windows\temp\seconion`" --path.data `"$env:PROGRAMDATA\seconionbeat`" --path.logs `"$env:PROGRAMDATA\winlogbeat\logs`" -E logging.files.redirect_stderr=true"

# Attempt to set the service to delayed start using sc config.
Try {
  Start-Process -FilePath sc.exe -ArgumentList 'config seconionbeat start= delayed-auto'
}
Catch { Write-Host -f red "An error occured setting the service to delayed start." }


Write-Host "Installing Sysmon..."

C:\Windows\temp\seconion\sysmon.exe -accepteula -i C:\Windows\temp\seconion\config.xml

"sc start seconionbeat" | cmd

Write-Host "Sysmon and seconion Installed!"