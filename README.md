# PySide6 on NVIDIA Jetson Devices
This guide provides instructions for installing PyQt and PySide 6.6.1 on NVIDIA Jetson devices.

## Compatibility
This installation process is compatible with:

* Jetpack 6.0 (L4T 36.3.0)
* Jetson Orin Series devices:
  - AGX Orin
  - Orin NX
  - Orin Nano

## Prerequisites
Ensure your Jetson device is running Jetpack 6.0 (L4T 36.3.0) before proceeding with the installation.

## Installation
To install PySide6 on your Jetson device, follow these steps:

1. Open a terminal on your Jetson device.
2. Download the installation script and Run the installation script:
```bash
wget https://github.com/suffolk066/pyside6-on-jetson/blob/main/install.sh
bash install.sh
```


The script will automatically download and install all necessary dependencies and components for PySide6.

## Reference
- https://forums.developer.nvidia.com/t/installing-qt6-and-pyside6-on-jetson-orin-nano/274699
- https://forums.developer.nvidia.com/t/qt6-on-jetson-orin-nano-from-source/285242
