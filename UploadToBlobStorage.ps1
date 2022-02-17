$exportPath = "D:\temp\ProductsMissingLanguages.csv"
if (Test-Path -Path $exportPath -PathType Leaf) {
	$blobContainerName = 'product-translation-audit'
	$blobConnectionString = 'DefaultEndpointsProtocol=http;AccountName=devstoreaccount1; AccountKey=Eby8vdM02xNOcqFlqUwJPLlmEtlCDXJ1OUzFT50uSRZ6IFsuFq2UVErCz4I6tq/K1SZFPTOtr/KBHBeksoGMGw==;'
	Write-Host "building stream"
	$stream = New-Object System.IO.StreamReader($exportPath)
	Write-Host "uploading to blob..."
	$blobUploader = New-Object -Typename MilwaukeeTool.Foundation.ThirdPartyAPIs.Helpers.BlobStorage::New($blobContainerName, $blobConnectionString, $true)
	$blobUploader.UploadFile("ProductsMissingLanguages.csv", $stream.BaseStream, $true) 
	Write-host "uploaded"
	$stream.Dispose()
}