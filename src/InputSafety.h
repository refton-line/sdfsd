#pragma once
// Independent of Win32: movement is not an error; unsafe pointer positions pause input.
namespace InputSafety {
constexpr bool contains(int x, int y, int left, int top, int right, int bottom) {
    return x >= left && x < right && y >= top && y < bottom;
}
constexpr bool mayClick(bool insideTarget, bool hitsTarget, bool hitsPassiveOverlay) {
    return insideTarget && (hitsTarget || hitsPassiveOverlay);
}
} // namespace InputSafety
