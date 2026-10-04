from app.main import _p95_latency


def test_p95_latency_uses_nearest_rank():
    durations = [0.010, 0.020, 0.030, 0.040]

    assert _p95_latency(durations) == 0.040
