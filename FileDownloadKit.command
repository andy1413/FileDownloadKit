#!/usr/bin/env bash
fullPath="$0"
fileName=${fullPath##*/}
fileExtension=${fileName##*.}
fileNameNoExt=${fileName%.*}
fileDirectory=${fullPath%$fileName}

#echo "fileName: $fileName"
#echo "fileExtension: $fileExtension"
#echo "fileNoExtension: $fileNameNoExt"
#echo "fileDirectory: $fileDirectory"

echo start push ${fileDirectory}
cd $fileDirectory
#pod spec lint --sources=https://git.apuscn.com:8443/New-Pika/ViekaPodSpecsRepo,master ${fileNameNoExt}.podspec --allow-warnings
pod repo push --sources=https://git.apuscn.com:8443/New-Pika/ViekaPodSpecsRepo,master ViekaPodSpecsRepo ${fileNameNoExt}.podspec --allow-warnings