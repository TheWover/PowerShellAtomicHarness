<#
.SYNOPSIS
This script will iterate over the Atomic Red Team yaml files, create objects for each test. 
The aim is to allow defedenders to excercise MITRE ATT&CK Techniques to test defenses.


Function: Invoke-AtomicRedTeam
Author: Casey Smith @subTee
License:  http://opensource.org/licenses/MIT
Required Dependencies: powershell-yaml , Install-Module powershell-yaml https://github.com/cloudbase/powershell-yaml
Optional Dependencies: None
Version: 1.0

.DESCRIPTION
Create Atomic Tests from yaml files described in Atomic Red Team. https://github.com/redcanaryco/atomic-red-team
.PARAMETER AtomicRedTeamPath
Required: Local Path To The atomics folder
.PARAMETER GenerateTestPlan
Optional: Local Path To The atomics folder

.EXAMPLE
Generate command line output for each test described.
Invoke-AtomicRedTeam -GenerateTestPlan
.EXAMPLE
	. C:\Users\subTee\Downloads\atomic-red-team-master\execution-frameworks\Invoke-Atomic.ps1
	[System.Collections.HashTable]$AllAtomicTests = @{};
	$AtomicFilePath = 'C:\Users\subtee\downloads\atomic-red-team-fixed\atomics\';
	Get-Childitem $AtomicFilePath -Recurse -Filter *.yaml -File | ForEach-Object {
	$currentTechnique = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName);
	$parsedYaml = (ConvertFrom-Yaml (Get-Content $_.FullName -Raw ));
	$AllAtomicTests.Add($currentTechnique, $parsedYaml);
	#New-Variable -Name $currentTechnique -Value $parsedYaml -Scope "Local";
	}
	$AllAtomicTests.T1117 | %{ Get-AtomicTest $_ } 
	
	$AllAtomicTests.GetEnumerator() | %{ Get-AtomicTest $_.Value } 


.NOTES

.LINK
Blog: http://subt0x11.blogspot.com/2018/08/invoke-atomictest-automating-mitre-att.html
Github repo: https://github.com/redcanaryco/atomic-red-team

#>

function Get-AtomicTechnique {
[CmdletBinding()]
Param(

	[string]
	$Path
)
# Returns A HashTable For Each File Passed In
BEGIN { }
PROCESS {
	
		$parsedYaml = (ConvertFrom-Yaml (Get-Content $Path -Raw ))
		Write-Output $parsedYaml
}	
END { }

}

function Get-AtomicTestExecCommand{
[CmdletBinding()]
Param(

	[System.Collections.Hashtable]
	$AtomicTest
) 
BEGIN{}
PROCESS{
		#Only Process Windows Tests For Now
		if ( !($AtomicTest.supported_platforms.Contains('windows')) ){ return }
		#Reject Manual Tests
		if ( ($AtomicTest.executor.name.Contains('manual')) ) 	{ return }

		Write-Host $AtomicTest.name.ToString()
		Write-Host $AtomicTest.description.ToString()
		
		$finalCommand = $AtomicTest.executor.command
		if($AtomicTest.input_arguments.Count -gt 0)
		{
			$InputArgs = [Array]($AtomicTest.input_arguments.Keys).Split(" ")
			$InputDefaults = [Array]( $AtomicTest.input_arguments.Values | %{$_.default }).Split(" ")
			
			for($i = 0; $i -lt $InputArgs.Length; $i++)
			{	
				$findValue = '#{' + $InputArgs[$i] + '}'
				$finalCommand = $finalCommand.Replace( $findValue, $InputDefaults[$i] )
			}
			Write-Output $finalCommand
		}
		else
		{
			Write-Output $finalCommand
		}
		
		
	}
	
}


function Get-AtomicTest{
[CmdletBinding()]
Param(
	[System.Collections.Hashtable] 
	$AtomicTechnique
) 
BEGIN{}
PROCESS {
	Write-Host "[********BEGIN TEST*******]`n" $AtomicTechnique.display_name.ToString(), $AtomicTechnique.attack_technique.ToString() "has" $AtomicTechnique.atomic_tests.Count "Test(s)"  -Foreground Yellow 
	$AtomicTechnique.atomic_tests | %{ Get-AtomicTestExecCommand $_  }
	Write-Host "[!!!!!!!!END TEST!!!!!!!]`n"
	}
END {}

}
