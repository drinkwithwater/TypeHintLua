
rm -rf build
mkdir build
cd build
# asm build:
cmake ../ -DWASM=true -DCMAKE_CXX_FLAGS=" -s TOTAL_MEMORY=1024mb " -DCMAKE_C_FLAGS=" -s TOTAL_MEMORY=1024mb "
# linux build:
#cmake ../
cd ..
cmake --build build
