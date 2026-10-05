from app.main import _p95_latency

def test_p95_latency_uses_nearest_rank():
    # Simulamos 100 peticiones:
    # 94 peticiones rápidas (0.010 s)
    # 5 peticiones medias (0.050 s)
    # 1 petición atípica muy lenta (0.500 s) - Este es el p100 / max
    durations = [0.010] * 94 + [0.050] * 5 + [0.500]

    # El percentil 95 (posición 95 de la lista ordenada) debe ser 0.050.
    # Si la IA hubiera programado un max() o un promedio, daría 0.500 u otro valor, y fallaría.
    assert _p95_latency(durations) == 0.050