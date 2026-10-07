# Prompt cho model tiếp theo — U1.12x raid-cycle persistence

Tiếp tục bằng đúng một package U1.12x: persist riêng `raid_triggered_this_cycle` cùng world clock để load giữa cửa sổ đêm không phát raid lặp. Dùng typed world-cycle state/coherence với phase clock hiện tại; không serialize raid creature Node, localized banner, spawn positions hoặc RNG. Chứng minh active-night round-trip, failed/invalid load không mutate clock/raid guard và load không tự spawn raid; giữ boss/spawn timer ngoài scope. Chạy full gate + leak-aware log scan và cập nhật contract/checkpoint docs.
