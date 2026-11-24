# Adreno Vulkan drivers

Builds of [Mesa](https://mesa3d.org)'s Turnip, the open-source Vulkan driver for Qualcomm Adreno GPUs, for arm64
Android (10 and newer). Each build is made from Mesa's own source, unmodified, by this repository's
[workflow](.github/workflows/build.yml), so every file in a release comes with the public log of the run that built it.

The packages use the [adrenotools](https://github.com/bylaws/libadrenotools) format (`meta.json`, the driver as
`vulkan.turnip.so`, Mesa's license), so apps and emulators that load custom drivers through adrenotools can use them.

## Releases

Each release has one `.zip` per driver and `drivers.json`, the list apps read:

```
https://github.com/TomerGamerTV/adreno-vulkan-drivers/releases/latest/download/drivers.json
```

For each driver it gives the name, the Mesa version, tag and commit it was built from, the download link, the size
and the SHA-256. Check the SHA-256 before loading a driver.

## Which GPUs

Turnip supports Adreno 6xx and 7xx GPUs; Mesa's development builds add newer ones as Mesa supports them. It doesn't run
on Mali, PowerVR or older Adreno GPUs: an app should fall back to the phone's own driver there.

## Adding a build

Add an entry to [`builds.json`](builds.json) (`ref` is a Mesa tag such as `mesa-26.3.1`, or a commit); the workflow
builds the list and publishes a new release. It also runs from the Actions tab.

## License

The build scripts are MIT (see [LICENSE](LICENSE)). The drivers are Mesa's, under Mesa's licenses (MIT for the most
part); each package carries Mesa's license file.
