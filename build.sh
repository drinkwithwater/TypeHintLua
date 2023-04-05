
rm -rf build
mkdir build
cd build
# for emcc build : cmake ../ -DWASM=true
cmake ../
cd ..
cmake --build build
