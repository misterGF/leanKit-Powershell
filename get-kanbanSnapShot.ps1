#requires -version 2

<#
	This script is meant to download a snapshot of your kanban board from leankit.
	It uses web automation to login and navigate the site. Then clicks the link that generates
	the snapshot. Once clicked it requieres WASP to click on the "Save" button the IE presents.

	It saves it to your download folder under the default naming scheme (board_xxxx.png). The script
	removes old entries by default. Can comment out if you choice too.

	Make sure you keep the WASP.dll in the same directory. Required powershell v2+

	The boardID can be found in the URL when you are logged in to your leankit account.

	Syntax Example:

	./get-kanvanSnapShot.ps1 -userName "gil@myEmail.com" -password "Super!Secure!" -leankitURL "myBoard.leankit.com" -boardID "100201"

	Create by GF
	Last modified May 22 2014 by GF

#>

param(
	#Passed params
	[Parameter(Position=0, Mandatory=$true)]
	[String]$username,

	[Parameter(Position=1, Mandatory=$true)]
	[String]$password,

	[Parameter(Position=2), Mandatory=$true)]
	[String]$leanKitURL,

	[Parameter(Position=3), Mandatory=$true)]
	[String]$boardID
)

#Other Dependances
	$localUser = [Environment]::UserName
	$defaultIEDownloadFolder = "C:\Users\{0}\Downloads" -f $localUser

#Remove old downloads of the board
	Get-ChildItem -Path $defaultIEDownloadFolder -Filter "board_$boardID*.png" | Remove-Item
	write-progress -activity "Removing old snapshots" -status "100% Complete" -percentcomplete 100

	$ErrorActionPreference = "STOP"

	try
	{
		#Open up a browser instance
			write-progress -activity "Get leankit snapshot" -status "5% Complete" -percentcomplete 5 -CurrentOperation "Opening IE"
			$ie = New-Object -comobject InternetExplorer.Application
			$ie.Visible = $true

		#Check that browser is ready
			while($ie.Busy)
			{
				Sleep -Milliseconds 100
			}

		#Navigate to leankit
			$pageUrl = "https://$leanKitURL/Account/Membership/Login"
			$ie.Navigate($pageUrl)

			if($ie)
			{
				#Check that browser is ready
				while($ie.ReadyState -ne 4)
				{
				    Sleep -Milliseconds 100
				}

				#Login using admin account
					write-progress -activity "Get leankit snapshot" -status "25% Complete" -percentcomplete 25 -CurrentOperation "Logging in"
					#fill in username
						$inputEmail = $ie.Document.getElementById("userName")
						$inputEmail.value = $username

					#fill in pw
						$inputPW = $ie.Document.getElementById("password")
						$inputPW.value = $password

					#Click login
						$loginBtn = $ie.Document.forms.item(0)
						$loginBtn.submit()

				#Wait till we logged in
					Write-Host "Logging into leanKit. If this takes a while check IE for details. You may have mistyped your password."

					while($ie.LocationURL -eq $locationURL)
					{
					    Sleep -Milliseconds 100
					}


				#Navigate to migration page
					write-progress -activity "Get leankit snapshot" -status "50% Complete" -percentcomplete 50 -CurrentOperation "Navigate to board"

					$migrationURL = "https://{0}/Boards/View/{1}#workflow-view" -f $leanKitURL, $boardID
					$ie.navigate($migrationURL)

				#Check that browser is ready
					while($ie.ReadyState -ne 4)
					{
						Sleep -Milliseconds 100
					}

				#Click link from cog
					write-progress -activity "Get leankit snapshot" -status "75% Complete" -percentcomplete 75 -CurrentOperation "Download snapshot"
					$title = $ie.Document.title
					$dropdown = $ie.Document.getElementById("dropmenu-settings")
					$dlSnapBtn = $dropdown.getElementsByTagName('a') | where { $_.getAttributeNode('class').Value -eq 'download-snapshot menulink'}
					$dlSnapBtn.click()

				#Determine if file is downloading
					if($?)
					{
						while($ie.ReadyState -ne 4)
						{
							Sleep -Milliseconds 100
						}

						write-host "Snapshot is downloading!" -foreground:green

						#Use WASP for clicking the confirmation button in IE
						Import-Module "$PSScriptRoot\WASP.dll"

						$confirmation = Select-Window iexplore | where { $_.Title -like "$title *"}

					}
					else
					{
						Write-Host "Unable to download snapshot" -ForegroundColor:Red
						return
					}

				#Check for downloaded file. Sleep for 5 second intravals
					$totalTime = 0
					while(!(Get-ChildItem -Path $defaultIEDownloadFolder -Filter "board_$boardID*.png"))
					{
						sleep -Seconds 5
						$totalTime+=5

						Send-Keys -Window $confirmation -Keys "%S" #send a tab and enter to click on save

						if($totalTime -ge 50) #After 50 seconds we cancel out
							{
								Write-Host "Unable to download snapshop in alloted time" -ForegroundColor:Red
								return
							}

					}

				#Kill IE
					write-progress -activity "Get leankit snapshot" -status "100% Complete" -percentcomplete 100 -CurrentOperation "Closing IE"
					$ie.Visible = $false
					$ie.quit()

			}
			else
			{
				Write-Host "Unable to create IE instance"
				return
			}
	}
	catch
	{
		Write-Host "Error: $_"
	}