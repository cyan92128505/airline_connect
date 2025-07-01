zip -r compressed_libs.zip \
    ./build/app/intermediates/merged_native_libs/release/out/lib/arm64-v8a \
    ./build/app/intermediates/merged_native_libs/release/out/lib/armeabi-v7a \
    ./build/app/intermediates/merged_native_libs/release/out/lib/x86_64
mv ./compressed_libs.zip ./build/app/outputs/bundle/release/compressed_libs.zip
echo 'pack ./build/app/outputs/bundle/release/compressed_libs.zip'

