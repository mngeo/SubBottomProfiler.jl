"""
    ibm2ieee(word::UInt32) -> Float64

Convert a 32-bit IBM 360 floating-point word to IEEE `Float64`.

Example: `ibm2ieee(0x41100000)`
"""
function ibm2ieee(word::UInt32)::Float64
    word == 0x00000000 && return 0.0
    sign = (word >> 31) == 0x01 ? -1.0 : 1.0
    exponent = Int((word >> 24) & 0x7f) - 64
    fraction = Float64(word & 0x00ff_ffff) / Float64(0x0100_0000)
    return sign * fraction * 16.0^exponent
end

"""
    ieee2ibm(value::Real) -> UInt32

Convert an IEEE floating-point value to a 32-bit IBM 360 representation.

Example: `ieee2ibm(1.0)`
"""
function ieee2ibm(value::Real)::UInt32
    x = Float64(value)
    x == 0.0 && return 0x00000000
    sign_bit = x < 0 ? UInt32(0x8000_0000) : UInt32(0)
    x = abs(x)
    exponent = 64
    while x < 1.0 / 16.0
        x *= 16.0
        exponent -= 1
    end
    while x >= 1.0
        x /= 16.0
        exponent += 1
    end
    fraction = UInt32(round(Int, x * Float64(0x0100_0000)))
    return sign_bit | (UInt32(exponent) << 24) | (fraction & 0x00ff_ffff)
end
