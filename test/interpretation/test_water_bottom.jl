@testset "Water Bottom" begin
    dataset = synthetic_dataset()
    picks = pick_water_bottom(dataset.traces, WaterBottomPickerParams(search_end_sample=24))
    @test all(pick.sample_index <= 24 for pick in picks)
end
