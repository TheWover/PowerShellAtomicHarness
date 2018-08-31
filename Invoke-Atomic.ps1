# Invoke-AtomicTests
# Notes and Setup
# Requirements Windows 10, and PowerShell-Yaml
# Admin Rights
# Caveat... We make no effort to clean up the tests artifacts. we probably should lol
# Only run on test Systems


<#
TODO:
Fix Quotations
Verbs
Output Objects, not Text


#>


#Define Script Param for SupportedPlatforms
$SupportedPlatforms = 'windows'


#Ascii Art 

$AtomicAsciiArt = @'
     ___   __                  _         ____           __   ______
    /   | / /_____  ____ ___  (_)____   / __ \___  ____/ /  /_  __/__  ____ _____ ___
   / /| |/ __/ __ \/ __ `__ \/ / ___/  / /_/ / _ \/ __  /    / / / _ \/ __ `/ __ `__ \
  / ___ / /_/ /_/ / / / / / / / /__   / _, _/  __/ /_/ /    / / /  __/ /_/ / / / / / /
 /_/  |_\__/\____/_/ /_/ /_/_/\___/  /_/ |_|\___/\__,_/    /_/  \___/\__,_/_/ /_/ /_/
                                                                                    


'@

# Scripted & Interactive 

Write-Host $AtomicAsciiArt -Foreground Green

# Loop Over All Files, Convert Each to Variable Name Of the Test.

$AtomicFilePath = 'C:\Users\subtee\downloads\atomic-red-team-fixed\atomics\' #Input Parameter Defined in beginning of script.

function Set-AtomicArray([string] $AtomicFilePath)
{
	#All or Just One?  Modify this to accept one, some, or all tests
	$AtomicTechniqueArray = @()
	
	Get-Childitem $AtomicFilePath -Recurse -Filter *.yaml -File | ForEach-Object {
		try
		{
			$currentTechnique = [System.IO.Path]::GetFileNameWithoutExtension($_.FullName);
			$parsedYaml = (ConvertFrom-Yaml (Get-Content $_.FullName -Raw ))
			New-Variable -Name $currentTechnique -Value $parsedYaml -Scope "Script";
			#TODO properly return Objects Allows For Pipeline BEGIN PROCESS FINISH etc..
			$AtomicTechniqueArray += $parsedYaml
		}
		catch
		{
			#Add some putput if desired like Write-Verbose...
		}
		
	}
	
	return ,$AtomicTechniqueArray
}

function ExecuteAtomicTechnique([System.Collections.Hashtable] $AtomicTechnique)
{
	#Takes $AtomicTechnique Parsed From YAML and Executes it with Default Values
	#Designed to Run ALL Tests For A Technique
	Write-Host "[********BEGIN TEST*******]`n" $AtomicTechnique.display_name.ToString(), $AtomicTechnique.attack_technique.ToString() "has" $AtomicTechnique.atomic_tests.Count "Test(s)"  -Foreground Yellow 
	#Call Get-AtomicTest
	$AtomicTechnique.atomic_tests | %{ Get-AtomicTest $_ }
	Write-Host "[!!!!!!!!END TEST!!!!!!!]`n"
	
}

#Refactor this to Get-AtomicTest and output execution plans

function Get-AtomicTest([System.Collections.Hashtable] $AtomicTest)
{
	#Short Circuit Exit On Conditions
	#For Now We Only care about Windows Tests
	if ( !($AtomicTest.supported_platforms.Contains($SupportedPlatforms)) ){ return }
	#Reject Manual Tests
	if ( ($AtomicTest.executor.name.Contains('manual')) ) 	{ return }

	Write-Host $AtomicTest.name.ToString()
	Write-Host $AtomicTest.description.ToString()
	
	$finalCommand = $AtomicTest.executor.command
		
	if($AtomicTest.input_arguments.Count -gt 0)
	{
		#Check Data Type, s/b string. example 1065 is being cast as int
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
		Write-Host $finalCommand -Foreground Green
	}
	
	
}

function Invoke-AtomicTest ([System.Collections.Hashtable] $AtomicTest)
{
	#Short Circuit Exit On Conditions
	#For Now We Only care about Windows Tests
	if ( !($AtomicTest.supported_platforms.Contains($SupportedPlatforms)) ){ return }
	#Reject Manual Tests
	if ( ($AtomicTest.executor.name.Contains('manual')) ) 	{ return }

	Write-Host $AtomicTest.name.ToString()
	Write-Host $AtomicTest.description.ToString()
	
	$finalCommand = $AtomicTest.executor.command
		
	if($AtomicTest.input_arguments.Count -gt 0)
	{
		#Check Data Type, s/b string. example 1065 is being cast as int
		$InputArgs = [Array]($AtomicTest.input_arguments.Keys).Split(" ")
		$InputDefaults = [Array]( $AtomicTest.input_arguments.Values | %{$_.default }).Split(" ")
		
		for($i = 0; $i -lt $InputArgs.Length; $i++)
		{	
			$findValue = '#{' + $InputArgs[$i] + '}'
			$finalCommand = $finalCommand.Replace( $findValue, $InputDefaults[$i] )
		}
		
		#Write-Host $finalCommand -Foreground Green
	}
	else
	{
		#Write-Host $finalCommand -Foreground Green
	}
	
	$shellcommand = ""
	if ($AtomicTest.executor.name -eq 'command_prompt') { $shellCommand = "cmd.exe /c $finalCommand"  }
	if ($AtomicTest.executor.name -eq 'powershell') { $shellCommand = "powershell.exe -iex $finalCommand"  }
	Write-Host  -Foreground Green
	
	Write-Host $shellCommand -Foreground Green
	iex "& $shellCommand" 
	
	
	
}


function Invoke-ChainReaction([System.Collections.Hashtable] $AtomicTechnique)
{

	
	$AtomicTechnique.atomic_tests | %{ Get-AtomicTest $_ }
	
}


$AllAtomicTechniques = Set-AtomicArray([string] $AtomicFilePath) #Sets Up variables, Adjust Method to be one, some, or all...
$AllAtomicTechniques.Count 



$AsciiChainReacion = @'
                     - Diagram of a Chain Reaction -
                        -------------------------------



                                       |
                                       |
                                       |
                                       |
    [1]------------------------------> o

                                    . o o .
                                   . o_0_o . <-----------------------[2]
                                   . o 0 o .
                                    . o o .

                                       |
                                      \|/
                                       ~

                                 . o o. .o o .
    [3]-----------------------> . o_0_o"o_0_o .
                                . o 0 o~o 0 o .
                                 . o o.".o o .
                                       |
                                  /    |    \
                                |/_    |    _\|
                                ~~     |     ~~
                                       |
                           o o         |        o o
    [4]-----------------> o_0_o        |       o_0_o <---------------[5]
                          o~0~o        |       o~0~o
                           o o )       |      ( o o
                              /        o       \
                             /        [1]       \
                            /                    \
                           /                      \
                          /                        \
                         o [1]                  [1] o
                 . o o .            . o o .            . o o .
                . o_0_o .          . o_0_o .          . o_0_o .
                . o 0 o .  <-[2]-> . o 0 o . <-[2]->  . o 0 o .
                 . o o .            . o o .            . o o .

                  /                    |                    \
                |/_                   \|/                   _\|
                ~~                     ~                     ~~

      . o o. .o o .              . o o. .o o .              . o o. .o o .
     . o_0_o"o_0_o .            . o_0_o"o_0_o .            . o_0_o"o_0_o .
     . o 0 o~o 0 o . <--[3]-->  . o 0 o~o 0 o .  <--[3]--> . o 0 o~o 0 o .
      . o o.".o o .              . o o.".o o .              . o o.".o o .
        .   |   .                  .   |   .                  .   |   .
       /    |    \                /    |    \                /    |    \
       :    |    :                :    |    :                :    |    :
       :    |    :                :    |    :                :    |    :
      \:/   |   \:/              \:/   |   \:/              \:/   |   \:/
       ~    |    ~                ~    |    ~                ~    |    ~
  [4] o o   |   o o [5]      [4] o o   |   o o [5]      [4] o o   |   o o
[5]
     o_0_o  |  o_0_o            o_0_o  |  o_0_o            o_0_o  |  o_0_o
     o~0~o  |  o~0~o            o~0~o  |  o~0~o            o~0~o  |  o~0~o
      o o ) | ( o o              o o ) | ( o o              o o ) | ( o o
         /  |  \                    /  |  \                    /  |  \
        /   |   \                  /   |   \                  /   |   \
       /    |    \                /    |    \                /    |    \
      /     |     \              /     |     \              /     |     \
     /      o      \            /      o      \            /      o      \
    /      [1]      \          /      [1]      \          /      [1]      \
   o                 o        o                 o        o
o
  [1]               [1]      [1]               [1]      [1]
[1]

============================================================================

                              - Diagram Outline -
                             ---------------------


                        [1] - Incoming Neutron
                        [2] - Uranium-235
                        [3] - Uranium-236
                        [4] - Barium Atom
                        [5] - Krypton Atom

===========================================================================

'@



<# Sample ChainReaction 

$ChainReaction = @($T1117, $T1118, $T1086 )
$ChainReaction | % { Invoke-ChainReaction $_ }
Write-Host $AsciiChainReacion -Foreground Cyan

#>

#Generates ALL Tests!
$AllAtomicTechniques | %{ ExecuteAtomicTechnique $_ }

# Executes a Single Technique, All Tests
# $T1117.atomic_tests | %{ Invoke-AtomicTest $_ } 
# Executes a Single Technique, Single Test
$T1117.atomic_tests[1] | %{ Invoke-AtomicTest $_ } 

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


 
 
#Write-Host $PowerShellBoom -Foreground Yellow
Write-Host "Test Complete, Go Sift Through The Fallout" -Foreground Cyan

