@testset "Utils" begin
    @test moving_average([1, 2, 3], 3) == [1.5, 2.0, 2.5]
    @test length(cosine_taper(8; fraction=0.25)) == 8
    @test linear_interpolate([10, 20], 1.5) == 15.0
    @test round(analytic_envelope([0.0, 1.0, 0.0])[2]; digits=3) == 1.0
    @test padded_length(33) == 64
    @test length(frequency_axis(0.001, 8)) == 5
    @test round(rms([1.0, -1.0]); digits=6) == 1.0
    @test twtt_to_depth(0.02, 1500.0) == 15.0
end
