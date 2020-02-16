![template 1.0.0](https://img.shields.io/badge/adminer-1.0.0-green.svg)

![Gearbox](https://github.com/gearboxworks/gearbox.github.io/raw/master/Gearbox-100x.png)

# Template Docker Container for Gearbox
This is the main template repository for creating Docker containers within Gearbox.

## Using this template container.

- 1 Fetch this repo.

`git clone https://github.com/gearboxworks/docker-template`

`cd docker-template`

- 2 Create JSON file.

Check out the gearbox-TEMPLATE.json file for an example.

- 3 Build template files.

`bin/Create.sh gearbox-TEMPLATE.json`

- 4 Update scripts, directories and any other files under rootfs.

- 5 Create docker image.

`bin/Build.sh 4.7.6` - Build a specific version.

`bin/Build.sh` - Build all versions.

- 6 Test build.

`bin/Test.sh 4.7.6` - Test a specific version.

`bin/Test.sh` - Test all versions.

- 7 Push build.

`bin/Push.sh 4.7.6` - Test a specific version.

`bin/Push.sh` - Test all versions.

