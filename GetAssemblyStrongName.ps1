function Get-AssemblyStrongName($assemblyPath)
{
	[System.Reflection.AssemblyName]::GetAssemblyName($assemblyPath).FullName
}

Get-AssemblyStrongName C:\Test\bin\fs14api.dll