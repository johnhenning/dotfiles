# Pinned upstream release archives. Source only from tools.sh.
uv_version=0.13.5
nvim_version=0.12.6
case $platform in
  Darwin-arm64|Darwin-aarch64)
    uv_asset=uv-aarch64-apple-darwin; uv_sha=743f85035a1996ecb350659e01cd9faea9709829be09b1b4b03c73eaf3c9cd73
    nvim_asset=nvim-macos-arm64; nvim_sha=1dbd148222b051ba6c307c4d17a318ed083df018a4f6a5a0ce46955ffc9ab87b ;;
  Darwin-x86_64)
    uv_asset=uv-x86_64-apple-darwin; uv_sha=b0f52b0e3945b4107d89024ea38e625683011fbfc05a0d98f9fa2d6dcee28c66
    nvim_asset=nvim-macos-x86_64; nvim_sha=481424f1dbc85f637d57e47d27d042aa9c883e5a4fe9ee64fc4ee9573b221998 ;;
  Linux-arm64|Linux-aarch64)
    uv_asset=uv-aarch64-unknown-linux-musl; uv_sha=7906c79adb21c81abd559841ba76bb1d9af9d791acac7a041b2972e03ae16538
    nvim_asset=nvim-linux-arm64; nvim_sha=8f1f64a0bdb97247034038c3823c6cbad5bdf9ecd5751b85494b71c3ee04c815 ;;
  Linux-x86_64)
    uv_asset=uv-x86_64-unknown-linux-musl; uv_sha=57ef9d9ccb01fb1bd998df995b0dd221b52f7d7841fbea93f2d4463bf61fb7a9
    nvim_asset=nvim-linux-x86_64; nvim_sha=474430d53e6264f6d6dd18db42d6dc9df3a1b56ca9e88a325bbf860e1a811d87 ;;
  *) printf 'Unsupported tool platform: %s\n' "$platform" >&2; exit 1 ;;
esac
