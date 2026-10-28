#pragma once
#include <QtGlobal>
#include <chrono>
namespace Timing {
inline qint64 nowNs() {
    return std::chrono::duration_cast<std::chrono::nanoseconds>(
               std::chrono::steady_clock::now().time_since_epoch())
        .count();
}
// Measured rate over a window; -1 until the window is long enough to be meaningful.
inline double rate(quint64 count, qint64 spanNs) {
    return spanNs >= 250000000 ? double(count) * 1e9 / double(spanNs) : -1;
}
} // namespace Timing
