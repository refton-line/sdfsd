#pragma once
#include "Configuration.h"
#include <QtGlobal>
#include <algorithm>
#include <cmath>
#include <random>
// Platform-independent click schedule. The Windows worker asks it for gaps and holds;
// tests drive it directly, so timing behaviour is verified without SendInput.
namespace Planner {
struct Step {
    qint64 gapNs;  // press-to-press distance to the next click
    qint64 holdNs; // press-to-release time of this click (0 = press and release together)
};

// Exact grid for Blatant mode: slot n is due at origin + n * period, with no accumulated drift.
class Grid {
    double m_period;

  public:
    explicit Grid(double cps) : m_period(1e9 / cps) {}
    double periodNs() const { return m_period; }
    qint64 at(quint64 slot) const { return qint64(std::llround(double(slot) * m_period)); }
    // Slots due at elapsed time `now` (inclusive), counted from slot 0. Corrected against at()
    // so rounding can never make a deadline look due-but-not-counted or vice versa.
    quint64 dueThrough(qint64 nowNs) const {
        if (nowNs < 0)
            return 0;
        quint64 k = quint64(std::floor(double(nowNs) / m_period)) + 1;
        while (at(k) <= nowNs)
            ++k;
        while (k > 0 && at(k - 1) > nowNs)
            --k;
        return k;
    }
};

// Legit mode: a human-like rhythm around the requested mean rate.
//  - log-normal jitter on each gap (people rarely click faster than they intend for long),
//  - a slow Ornstein–Uhlenbeck drift so the tempo breathes instead of being pure noise,
//  - rare hesitations and quick doubles, a short warm-up, and a mean correction that keeps
//    the long-run average on target.
class Humanizer {
    std::mt19937_64 m_rng;
    double m_mean;
    double m_sigma, m_driftStep, m_hesitate, m_double;
    double m_drift = 0;
    double m_elapsed = 0, m_ideal = 0;
    std::normal_distribution<double> m_normal{0.0, 1.0};
    std::uniform_real_distribution<double> m_unit{0.0, 1.0};

  public:
    static constexpr double WarmupNs = 400e6;
    Humanizer(double cps, int variance, quint64 seed) : m_rng(seed), m_mean(1e9 / cps) {
        static constexpr double sigma[] = {0.07, 0.13, 0.21};
        static constexpr double drift[] = {0.012, 0.022, 0.035};
        static constexpr double hesitate[] = {0.006, 0.015, 0.03};
        static constexpr double quick[] = {0.006, 0.015, 0.03};
        const int v = std::clamp(variance, 0, 2);
        m_sigma = sigma[v];
        m_driftStep = drift[v];
        m_hesitate = hesitate[v];
        m_double = quick[v];
    }
    double meanNs() const { return m_mean; }
    Step next() {
        const double z = std::clamp(m_normal(m_rng), -3.0, 3.0);
        double factor = std::exp(m_sigma * z - m_sigma * m_sigma / 2);
        m_drift = m_drift * 0.94 + m_driftStep * std::clamp(m_normal(m_rng), -3.0, 3.0);
        factor *= std::exp(std::clamp(m_drift, -0.18, 0.18));
        const double roll = m_unit(m_rng);
        if (roll < m_hesitate)
            factor *= 1.35 + 0.6 * m_unit(m_rng);
        else if (roll < m_hesitate + m_double)
            factor *= 0.55 + 0.2 * m_unit(m_rng);
        // Warm-up: the first presses are a little slower, as when a hand settles on the mouse.
        const double warm = m_elapsed < WarmupNs ? 1 + 0.3 * (1 - m_elapsed / WarmupNs) : 1;
        factor *= warm;
        // Pull the realised average back toward the target without making the gap regular.
        const double error = (m_elapsed - m_ideal) / std::max(m_mean * 8, 1.0);
        factor *= std::clamp(1 - 0.12 * error, 0.85, 1.15);
        const double gap = std::clamp(m_mean * factor, m_mean * 0.4, m_mean * 3.0 * warm);
        m_elapsed += gap;
        m_ideal += m_mean * warm;
        if (m_elapsed - m_ideal > m_mean * 64)
            m_ideal = m_elapsed - m_mean * 64;
        // Finger contact time: ~55–95 ms at relaxed rates, shrinking with fast clicking and
        // always well inside the gap so the button is up before the next press.
        const double typical = std::min(78e6, 0.42 * gap);
        double hold = typical * (1 + 0.18 * std::clamp(m_normal(m_rng), -2.5, 2.5));
        hold = std::clamp(hold, std::min(6e6, 0.2 * gap), 0.6 * gap);
        return {std::max<qint64>(1, qint64(gap)), qint64(hold)};
    }
};
} // namespace Planner
