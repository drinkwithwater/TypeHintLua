
rm -rf build
mkdir build
cd build
# asm build:
#FLAG=" -s SUPPORT_LONGJMP=emscripten -s TOTAL_MEMORY=512mb -s INITIAL_MEMORY=64mb -s TOTAL_STACK=512mb -sALLOW_MEMORY_GROWTH -s STACK_SIZE=5mb -s EXIT_RUNTIME=0 -s INVOKE_RUN=0 "
#cmake ../ -DWASM=1 -DCMAKE_CXX_FLAGS="$FLAG" -DCMAKE_C_FLAGS="$FLAG"
#linux build:
cmake -DCMAKE_BUILD_TYPE=Release ../
cd ..
cmake --build build --config Release
