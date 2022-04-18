<#  

Script to run diagnosis on a VMware Workspace ONE UEM Dropship Cache Server and collect logs
The bundle will be called cache-diag.zip placed in the temp directory %temp%
After the bundle is created  - please submit to:  Dl-ws1provisioning@vmware.com

.NOTES
Version:        1.0
Author:         Chris Halstead - chalstead@vmware.com
Creation Date:  2022/04/15
Purpose/Change: Initial Version

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL 
VMWARE,INC. BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

#>

function RunServerDiag 

{
    $mytemp = $env:TEMP 
    $workingdir = $mytemp + "\cache-diag"
    $tempdir = New-Item -Path $mytemp -Name "cache-diag" -ItemType "directory"

    Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'Getting IIS Version Information' 

    Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\InetStp\*' | Out-File -FilePath $workingdir\IISversion.txt -Encoding ascii -Force

    Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'Checking Internet Connectivity' 
   
    Test-NetConnection('8.8.8.8') | export-csv $workingdir\connectivity.csv -NoTypeInformation
            
    Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'Getting Server Information' 

    $computerinfo = Get-ComputerInfo

    $computerinfo | Out-File -FilePath $workingdir\ServerInfo.txt -Encoding ascii -Force
  
    Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'Getting Certificate Data' 
    
    $certs = Get-ChildItem -path Cert:\ -Recurse
    $certs | Out-File -FilePath $workingdir\certinfo.txt -Encoding ascii -Force

    Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'Getting Services Status' 
    
    Get-Service | Out-File -FilePath $workingdir\services.txt -Encoding ascii -Force

    Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'Getting IIS Configuration' 
   
    $iisFolder = 'C:\inetpub\history'

  if (Test-Path -Path $iisFolder) 
  
    { 
        
        Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'Capturing IIS Configuration'
     
        $latestfolder = Get-ChildItem $iisFolder | ? { $_.PSIsContainer } | sort CreationTime -desc | select -f 1
     
        Copy-Item $latestfolder.FullName -Recurse -Destination $workingdir\"IISConfig"

    }    

else

    {

        Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'c:\inetpub not found' 

    }

    Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'Getting Cache Disk Details'

    $newpath = $latestfolder.FullName+'\applicationHost.config'
   
    [xml]$iisconfig = Get-Content $newpath

    $dcdrive = $iisconfig.configuration.'system.webServer'.diskCache.sharedDriveLocation.outerxml
   
    $justdcdrivearray = [System.Collections.ArrayList]::new()

    $justdcdrivearray= $dcdrive -split "path="    

    $justdcdrive = $justdcdrivearray[1]

    $justdcdrive = $justdcdrive.trimend(' />')

    $justdcdrive = $justdcdrive.trim('"')

    Get-ChildItem -Path $justdcdrive -Force -Recurse  | Out-File -FilePath $workingdir\CacheDriveInfo.txt -Encoding ascii -Force

    Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'Getting IIS Modules'

    Get-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\IIS Extensions\*' | Out-File -FilePath $workingdir\IISModules.txt -Encoding ascii -Force
     
    Write-Progress -Activity 'Collecting Cache Server Diagnostic Data' -Status 'Compressing Files' 
    Compress-Archive $workingdir $mytemp\cache-diag.zip -Force
   
    remove-item $workingdir -Recurse -Force

    [System.Reflection.Assembly]::LoadWithPartialName('System.Windows.Forms')
    [System.Windows.Forms.MessageBox]::Show('The Cache Server Diagnostic Bundle is at: ' + $mytemp + '\cache-diag.zip','Cache Server Diagnostic Bundle')


}


#***** Script Execution

RunServerDiag