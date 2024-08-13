#!/bin/bash
set -e
 
function error_exit {
    echo "Error: $1"
    exit 1
}
 
function change_directory {
    DOWNLOAD_DIR="/home/$USER/Downloads"
    cd "$DOWNLOAD_DIR" || error_exit "Failed to change directory to /home/$USER/Downloads"
    echo "Change directory to: $DOWNLOAD_DIR"
}
 
function install_package {
    sudo apt-get update || error_exit "Failed to update package list"
    sudo apt-get install -y clang-15 clang-tools-15 libclang-15-dev llvm-15-dev llvm-15-tools build-essential libfontconfig1-dev \
                            libdbus-1-dev libfreetype6-dev libicu-dev libinput-dev libxkbcommon-dev libsqlite3-dev libssl-dev libpng-dev \
                            libjpeg-dev libglib2.0-dev libpulse-dev libasound2-dev libcups2-dev libegl1-mesa-dev libxcb1-dev libx11-xcb-dev \
                            libglu1-mesa-dev libxrender-dev libxi-dev libxkbcommon-x11-dev '^libxcb.*-dev' libvulkan-dev libnss3-dev libxshmfence-dev \
                            libxkbfile-dev python3-html5lib cmake curl libopenblas-base libopenmpi-dev zlib1g-dev gcc-10 g++-10 patchelf \
                            python3-pip git-lfs || error_exit "Failed to install packages"
    pip3 install --upgrade pip
    pip3 install --upgrade setuptools==69.3.1 wheel build
}
 
function update_cmake {
    change_directory
    mkdir cmake-3.29.2/Src
    cd cmake-3.29.2/Src || error_exit "Failed to change directory to ~/cmake-3.29.2/Src"
 
    wget -c --show-progress https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2.tar.gz || error_exit "Failed to download CMake"
    tar xvf cmake-3.29.2.tar.gz || error_exit "Failed to extract CMake"
    rm cmake-3.29.2.tar.gz || error_exit "Failed to delete CMake tar file"
 
    cd ..
    mkdir -p cmake-3.29.2-build
    cd cmake-3.29.2-build || error_exit "Failed to change directory to cmake-3.29.2-build"
 
    cmake -DCMAKE_BUILD_QtDialog=ON -DQT_QMAKE_EXECUTABLE=/usr/lib/qt5/bin/qmake ../Src/cmake-3.29.2 || error_exit "Failed to configure CMake"
 
    make -j $(nproc) || error_exit "Failed to build CMake"
    sudo make install || error_exit "Failed to install CMake"

    echo "export CMAKE_ROOT=/usr/local/share/cmake-3.29" >> ~/.bashrc || error_exit "Failed to set CMAKE_ROOT environment variable"
    source ~/.bashrc || error_exit "Failed to source ~/.bashrc"

    # Clean up
    change_directory
    rm -rf ~/cmake-3.29.2 || error_exit "Failed to delete CMake source directory"
 
    echo "cmake update completed successfully."
}
 
function install_pyqt6 {
    change_directory
 
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100 || error_exit "Failed to set gcc-10 as default gcc"
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100 || error_exit "Failed to set g++-10 as default g++"
    gcc --version || error_exit "Failed to verify gcc installation"
    g++ --version || error_exit "Failed to verify g++ installation"
 
    export LLVM_INSTALL_DIR=/usr/lib/llvm-15
    export CMAKE_PREFIX_PATH=/usr/lib/llvm-15
    export Clang_DIR=/usr/lib/llvm-15/lib/cmake/clang
    export Qt6_DIR=/usr/local/Qt-6.6.1
 
    wget https://master.qt.io/archive/qt/6.6/6.6.1/single/qt-everywhere-src-6.6.1.tar.xz || error_exit "Failed to download Qt source"
    tar xf qt-everywhere-src-6.6.1.tar.xz || error_exit "Failed to extract Qt source"
    rm qt-everywhere-src-6.6.1.tar.xz || error_exit "Failed to delete Qt source tar file"
 
    mkdir build-release
    cd build-release
 
    cmake -Wno-dev -GNinja -DQT_BUILD_TESTS=ON -DFEATURE_xcb=ON -DFEATURE_xkbcommon_x11=ON -DBUILD_qtwebengine=ON -DLLVM_DIR=/usr/lib/llvm-15/lib/ -DClang_DIR=/usr/lib/cmake/clang-15 -DCMAKE_INSTALL_PREFIX=$Qt6_DIR ../qt-everywhere-src-6.6.1
    build_cores=`expr $(nproc) - 1`
    cmake --build . -j$build_cores
    sudo cmake --install .
    export PATH=$Qt6_DIR/bin:$PATH
    export LD_LIBRARY_PATH=$Qt6_DIR/lib:$LD_LIBRARY_PATH
 
    # Clean up
    change_directory
    rm -rf qt-everywhere-src-6.6.1 || error_exit "Failed to delete Qt source directory"
 
    # If ok so far, add environment to your user's .bashrc (to be done only once)
    echo export PATH=$Qt6_DIR/bin:$PATH >> ~/.bashrc
    echo export PATH=$Qt6_DIR/tools/bin:$PATH >> ./bashrc
    echo export LD_LIBRARY_PATH=$Qt6_DIR/lib:$LD_LIBRARY_PATH >> ~/.bashrc
    echo export LD_LIBRARY_PATH=$Qt6_DIR/tools/lib:$LD_LIBRARY_PATH >> ./bashrc
    source ~/.bashrc
 
    echo "pyqt6 installation completed successfully."
}
 
function install_pyside6 {
    git clone --recursive -b 6.6.1 https://code.qt.io/pyside/pyside-setup.git || error_exit "Failed to clone PySide6 repository"
    cd pyside-setup/ || error_exit "Failed to change directory to pyside-setup"
    python3 setup.py bdist_wheel --parallel=6 --ignore-git --standalone --limited-api=yes --skip-modules=WebEngineCore,WebEngineWidgets --qtpaths=$Qt6_DIR/bin/qtpaths6 --reuse-build || error_exit "Failed to build PySide6 wheels"
    cd dist/ || error_exit "Failed to change directory to dist"
    pip3 install shiboken6_generator-6.6.1-6.6.1-cp37-abi3-linux_aarch64.whl shiboken6-6.6.1-6.6.1-cp37-abi3-linux_aarch64.whl PySide6-6.6.1-6.6.1-cp37-abi3-linux_aarch64.whl || error_exit "Failed to install PySide6 wheels"
 
    # Clean up
    change_directory
    rm -rf pyside-setup || error_exit "Failed to delete PySide6 source directory"
 
    echo "pyside6 installation completed successfully."
}
 
sudo jetson_clocks
install_package
echo "============================================================================="
update_cmake
echo "============================================================================="
install_pyqt6
echo "============================================================================="
install_pyside6
echo "============================================================================="
echo "All installations completed successfully."
