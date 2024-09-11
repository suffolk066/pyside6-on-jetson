#!/bin/bash
set -e
export Qt6_DIR=/usr/local/Qt-6.6.1

function change_directory {
    DOWNLOAD_DIR="/home/$USER/Downloads"
    cd "$DOWNLOAD_DIR"
    echo "Change directory to: $DOWNLOAD_DIR"
}
 
function install_package {
    sudo apt-get update
    sudo apt-get install -y clang-15 clang-tools-15 libclang-15-dev llvm-15-dev llvm-15-tools build-essential libfontconfig1-dev \
                            libdbus-1-dev libfreetype6-dev libicu-dev libinput-dev libxkbcommon-dev libsqlite3-dev libssl-dev libpng-dev \
                            libjpeg-dev libglib2.0-dev libpulse-dev libasound2-dev libcups2-dev libegl1-mesa-dev libxcb1-dev libx11-xcb-dev \
                            libglu1-mesa-dev libxrender-dev libxi-dev libxkbcommon-x11-dev '^libxcb.*-dev' libvulkan-dev libnss3-dev libxshmfence-dev \
                            libxkbfile-dev python3-html5lib cmake curl libopenblas-base libopenmpi-dev zlib1g-dev gcc-10 g++-10 patchelf \
                            python3-pip git-lfs ninja-build
                            
    # Qt6 + PySide6 requirements
    pip3 install --upgrade pip
    pip3 install --upgrade setuptools==69.3.1 wheel==0.35 build
    pip3 install patchelf pkginfo jinja2 buildozer gitpython
}
 
function update_cmake {
    change_directory
    if [ -d "cmake-3.29.2" ]; then
        echo "cmake folder already exist"
        rm -rf "cmake-3.29.2"
    fi
    mkdir -p cmake-3.29.2/Src && cd cmake-3.29.2/Src
    wget -c --show-progress https://github.com/Kitware/CMake/releases/download/v3.29.2/cmake-3.29.2.tar.gz
    tar xvf cmake-3.29.2.tar.gz

    cd ..
    mkdir -p cmake-3.29.2-build && cd cmake-3.29.2-build
    cmake ../Src/cmake-3.29.2

    # make
    make -j $(nproc)
    sudo make install

    echo "export CMAKE_ROOT=/usr/local/share/cmake-3.29" >> ~/.bashrc
    source ~/.bashrc

    echo "cmake update completed successfully."
}
 
function install_pyqt6 {
    change_directory
 
    sudo update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-10 100
    sudo update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-10 100
    gcc --version
    g++ --version
 
    export LLVM_INSTALL_DIR=/usr/lib/llvm-15
    export CMAKE_PREFIX_PATH=/usr/lib/llvm-15
    export Clang_DIR=/usr/lib/llvm-15/lib/cmake/clang
    export Qt6_DIR=/usr/local/Qt-6.6.1
 
    wget https://master.qt.io/archive/qt/6.6/6.6.1/single/qt-everywhere-src-6.6.1.tar.xz
    tar xf qt-everywhere-src-6.6.1.tar.xz
    cd qt-everywhere-src-6.6.1
    if [ -d "build-release" ]; then
        rm -r "build-release"
    fi
    mkdir build-release && cd build-release
    
    ../configure -opensource -confirm-license -platform linux-g++ -prefix $Qt6_DIR -make tools -make tests -xcb -- -Wno-dev
    build_cores=`expr $(nproc) - 1`
    cmake --build . -j$build_cores
    sudo cmake --install .
    
    echo export Qt6_DIR=/usr/local/Qt-6.6.1 >> ~/.bashrc
    echo export PATH=$Qt6_DIR/bin:$PATH >> ~/.bashrc
    echo export PATH=$Qt6_DIR/tools/bin:$PATH >> ~/.bashrc
    echo export LD_LIBRARY_PATH=$Qt6_DIR/lib:$LD_LIBRARY_PATH >> ~/.bashrc
    echo export LD_LIBRARY_PATH=$Qt6_DIR/tools/lib:$LD_LIBRARY_PATH >> ~/.bashrc
    source ~/.bashrc
 
    echo "pyqt6 installation completed successfully."
}
 
function install_pyside6 {
    git clone --recursive -b 6.6.1 https://code.qt.io/pyside/pyside-setup.git
    cd pyside-setup/
    python3 setup.py bdist_wheel --parallel=6 --ignore-git --standalone --limited-api=yes --skip-modules=WebEngineCore,WebEngineWidgets --qtpaths=$Qt6_DIR/bin/qtpaths6 --reuse-build
    cd dist/
    pip3 install shiboken6_generator-6.6.1-6.6.1-cp37-abi3-linux_aarch64.whl shiboken6-6.6.1-6.6.1-cp37-abi3-linux_aarch64.whl PySide6-6.6.1-6.6.1-cp37-abi3-linux_aarch64.whl
 
    # Clean up
    change_directory
    rm -rf pyside-setup
 
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
