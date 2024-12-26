#!/usr/bin/env bash

[[ ! -d /opt/element/resources ]] && mkdir -p /opt/element/resources
cd /opt/element/resources

old_version="v$(cat webapp/version)"

version="latest"
if [[ ! -z "$1" ]]; then
	version="tags/$1"
fi

echo "Fetching latest release info from GitHub"
version_info=$(curl -s "https://api.github.com/repositories/39487546/releases/$version")
new_version=$(echo "$version_info" | jq -r '.name')
URL=$(echo "$version_info" | jq -r '.assets[0].browser_download_url')

if [[ "$new_version" == "$old_version" ]]; then
	echo "No updates found"
	exit
fi

# Remove previous backup element
rm -rf element.bak

# Create temp directory for new element
mkdir element.new
cd element.new

echo "Downloading element $new_version"
curl -L "$URL" -o element-tmp.tar.gz

echo "Unpacking archive"
tar -xzf element-tmp.tar.gz --strip-components=1
rm -f element-tmp.tar.gz

echo "Replacing files"
cd ..
cp -f webapp/config.json element.new/config.json
# Back up old version and activate new version
mv webapp webapp.bak
mv element.new webapp

echo "Updated to element from $old_version to $new_version"

exit 0
