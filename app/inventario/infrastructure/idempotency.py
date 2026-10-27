import asyncio
from collections.abc import Awaitable, Callable
from dataclasses import dataclass
from typing import Any, TypeVar, cast


T = TypeVar("T")


class IdempotencyConflictError(ValueError):
    """La misma clave identifica comandos incompatibles."""


@dataclass(frozen=True)
class IdempotentResult:
    value: T
    replayed: bool


class InMemoryIdempotencyStore:
    """Guarda resultados de comandos durante la vida del proceso."""

    def __init__(self) -> None:
        self._results: dict[str, tuple[tuple[str, ...], object]] = {}
        self._locks: dict[str, asyncio.Lock] = {}

    async def execute(
        self,
        key: str | None,
        fingerprint: tuple[str, ...],
        operation: Callable[[], Awaitable[T]],
    ) -> IdempotentResult:
        if key is None:
            return IdempotentResult(await operation(), replayed=False)

        lock = self._locks.setdefault(key, asyncio.Lock())
        async with lock:
            previous = self._results.get(key)
            if previous is not None:
                previous_fingerprint, previous_value = previous
                if previous_fingerprint != fingerprint:
                    raise IdempotencyConflictError(
                        "La clave de idempotencia ya fue usada con otro comando"
                    )
                return IdempotentResult(cast(T, previous_value), replayed=True)

            value = await operation()
            self._results[key] = (fingerprint, value)
            return IdempotentResult(value, replayed=False)

    def clear(self) -> None:
        self._results.clear()
        self._locks.clear()
