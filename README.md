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

- 3 Initialize repo based off JSON file.

`make init`

- 4 Update scripts, directories and any other files under rootfs.

	- 4.7.6/DockerfileRuntime
	- 4.7.6/gearbox.json
	- 4.7.6/logs
	- 4.7.6/logs/.keep
	- build/build-adminer.apks
	- build/build-adminer.env
	- build/build-adminer.sh
	- build/gearbox-adminer.json
	- build/rootfs
	- build/rootfs/etc
	- build/rootfs/etc/gearbox
	- build/rootfs/etc/gearbox/services
	- build/rootfs/etc/gearbox/services/adminer
	- build/rootfs/etc/gearbox/services/adminer/finish
	- build/rootfs/etc/gearbox/services/adminer/run
	- build/rootfs/etc/gearbox/unit-tests
	- build/rootfs/etc/gearbox/unit-tests/adminer
	- build/rootfs/etc/gearbox/unit-tests/adminer/01-base.sh

- 5 Create docker image.

`make build-4.7.6` - Build a specific version.

`make build-all` - Build all versions.

- 6 Test build.

`make test-4.7.6` - Test a specific version.

`make test-all` - Test all versions.

- 7 Maybe run a shell.

`make shell-4.7.6` - Shell into a specific version.

`make shell-all` - Shell into all versions.

- 8 Push build.

`make push-4.7.6` - Test a specific version.

`make push-all` - Test all versions.

