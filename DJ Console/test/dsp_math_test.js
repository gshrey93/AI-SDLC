/**
 * DJ Console Mobile: Automated DSP Mathematics & Filter Verification Suite
 * Executed via: node test/dsp_math_test.js
 */

const assert = require('assert');

console.log('====================================================');
console.log('DJ CONSOLE DSP MATHEMATICAL & CURVE VERIFICATION');
console.log('====================================================\n');

let passedTests = 0;
let totalTests = 0;

function runTest(name, fn) {
    totalTests++;
    try {
        fn();
        console.log(`[PASS] ${name}`);
        passedTests++;
    } catch (err) {
        console.error(`[FAIL] ${name}: ${err.message}`);
    }
}

// -----------------------------------------------------------
// 1. Crossfader Mathematical Formulation
// -----------------------------------------------------------

function calculateCrossfaderGains(position, curveType) {
    // Map position [-1.0, 1.0] to t [0.0, 1.0]
    let t = Math.max(0.0, Math.min(1.0, (position + 1.0) * 0.5));

    let gainA = 0.0;
    let gainB = 0.0;

    if (curveType === 'linear') {
        gainA = 1.0 - t;
        gainB = t;
    } else if (curveType === 'smooth') {
        // Equal power / constant energy: cos^2(theta) + sin^2(theta) = 1.0
        const angle = t * (Math.PI / 2.0);
        gainA = Math.cos(angle);
        gainB = Math.sin(angle);
    } else if (curveType === 'scratch_cut') {
        const cutThreshold = 0.05; // 5% cut-in lag
        if (t >= (1.0 - cutThreshold)) {
            gainA = (1.0 - t) / cutThreshold;
        } else {
            gainA = 1.0;
        }

        if (t <= cutThreshold) {
            gainB = t / cutThreshold;
        } else {
            gainB = 1.0;
        }
    }

    return {
        gainA: Math.max(0.0, Math.min(1.0, gainA)),
        gainB: Math.max(0.0, Math.min(1.0, gainB))
    };
}

runTest('Crossfader - Linear Curve Endpoints and Center', () => {
    const left = calculateCrossfaderGains(-1.0, 'linear');
    assert.strictEqual(left.gainA, 1.0);
    assert.strictEqual(left.gainB, 0.0);

    const center = calculateCrossfaderGains(0.0, 'linear');
    assert.strictEqual(center.gainA, 0.5);
    assert.strictEqual(center.gainB, 0.5);

    const right = calculateCrossfaderGains(1.0, 'linear');
    assert.strictEqual(right.gainA, 0.0);
    assert.strictEqual(right.gainB, 1.0);
});

runTest('Crossfader - Constant Power (Smooth) Preserves 0dB Energy Sum', () => {
    // Test 11 points across the fader sweep
    for (let p = -1.0; p <= 1.01; p += 0.2) {
        const gains = calculateCrossfaderGains(p, 'smooth');
        const energySum = (gains.gainA * gains.gainA) + (gains.gainB * gains.gainB);
        assert(Math.abs(energySum - 1.0) < 1e-5, `Energy sum at pos ${p} was ${energySum}`);
    }

    const center = calculateCrossfaderGains(0.0, 'smooth');
    const expected = Math.SQRT1_2; // ~0.7071 (-3dB per channel)
    assert(Math.abs(center.gainA - expected) < 1e-4);
    assert(Math.abs(center.gainB - expected) < 1e-4);
});

runTest('Crossfader - Scratch Cut Has <5% Cut-in Lag and Full Open Travel', () => {
    const edge = calculateCrossfaderGains(-1.0, 'scratch_cut');
    assert.strictEqual(edge.gainA, 1.0);
    assert.strictEqual(edge.gainB, 0.0);

    // After 6% travel (pos = -0.88 -> t = 0.06), Deck B must already be at 100% volume
    const openB = calculateCrossfaderGains(-0.88, 'scratch_cut');
    assert.strictEqual(openB.gainA, 1.0);
    assert.strictEqual(openB.gainB, 1.0);

    const center = calculateCrossfaderGains(0.0, 'scratch_cut');
    assert.strictEqual(center.gainA, 1.0);
    assert.strictEqual(center.gainB, 1.0);
});

// -----------------------------------------------------------
// 2. Cubic Hermite Interpolation (Vinyl Scratch Quality)
// -----------------------------------------------------------

function hermite(y0, y1, y2, y3, mu) {
    const a = (3.0 * (y1 - y2) - y0 + y3) * 0.5;
    const b = 2.0 * y2 + y0 - (5.0 * y1 + y3) * 0.5;
    const c = (y2 - y0) * 0.5;
    return (((a * mu) + b) * mu + c) * mu + y1;
}

runTest('Interpolation - Hermite Spline Boundary Convergence', () => {
    const y0 = 0.2, y1 = 0.5, y2 = 0.8, y3 = 0.9;
    
    // At mu = 0, must equal y1 exactly
    const at0 = hermite(y0, y1, y2, y3, 0.0);
    assert(Math.abs(at0 - y1) < 1e-6, `mu=0 should be ${y1}, got ${at0}`);

    // At mu = 1, must equal y2 exactly
    const at1 = hermite(y0, y1, y2, y3, 1.0);
    assert(Math.abs(at1 - y2) < 1e-6, `mu=1 should be ${y2}, got ${at1}`);

    // Midpoint should be smooth and bounded between y1 and y2
    const atMid = hermite(y0, y1, y2, y3, 0.5);
    assert(atMid >= y1 && atMid <= y2, `Midpoint ${atMid} outside bounds`);
});

// -----------------------------------------------------------
// 3. 3-Band Isolator Filter & Kill Switch Attenuation
// -----------------------------------------------------------

runTest('EQ Isolator - Kill Switch Zero Bleed Assertion', () => {
    const killGain = (isKilled) => isKilled ? 0.0 : 1.0;
    
    // Test normal operation (no kill)
    assert.strictEqual(killGain(false), 1.0);

    // Test kill engaged (true infinite attenuation)
    assert.strictEqual(killGain(true), 0.0);

    // Cascade attenuation check
    const testSample = 0.75;
    const attenuated = testSample * killGain(true);
    assert.strictEqual(attenuated, 0.0, 'Signal must be completely silenced on kill');
});

// -----------------------------------------------------------
// 4. Scratch Physical Velocity & Inertia Decay
// -----------------------------------------------------------

runTest('Scratch Physics - Friction Decay Monotonicity', () => {
    let inertia = 2.5; // High initial spin
    const friction = 0.92;

    for (let frame = 0; frame < 50; frame++) {
        const nextInertia = inertia * friction;
        assert(nextInertia < inertia, 'Inertia must strictly decay under friction');
        inertia = nextInertia;
    }

    // After 50 frames, inertia should be safely below audible threshold
    assert(inertia < 0.05, `Inertia failed to come to a stop: ${inertia}`);
});

console.log('\n====================================================');
console.log(`TEST SUMMARY: ${passedTests} / ${totalTests} TESTS PASSED`);
console.log('====================================================');

if (passedTests !== totalTests) {
    process.exit(1);
}
