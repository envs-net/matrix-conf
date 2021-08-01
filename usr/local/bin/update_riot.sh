#!/usr/bin/env bash
[[ ! -d /opt/Riot/resources ]] && mkdir -p /opt/Riot/resources
cd /opt/Riot/resources

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

# Remove previous backup riot
rm -rf riot.bak

# Create temp directory for new riot
mkdir riot.new
cd riot.new

echo "Downloading Riot $new_version"
curl -L "$URL" -o riot-tmp.tar.gz

echo "Unpacking archive"
tar -xzf riot-tmp.tar.gz --strip-components=1
rm -f riot-tmp.tar.gz

echo "Replacing files"
cd ..
cp -f webapp/config.json riot.new/config.json
# Back up old version and activate new version
mv webapp webapp.bak
mv riot.new webapp

echo "Updated to Riot from $old_version to $new_version"

exit 0
