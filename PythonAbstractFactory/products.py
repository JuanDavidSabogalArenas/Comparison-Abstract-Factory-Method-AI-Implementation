"""
Abstract product interfaces and their concrete implementations.

This mirrors the Java example:
    - Luxury       (interface)        -> LuxuryCAR, LuxurySUV
    - NonLuxury    (interface)        -> NonLuxuryCAR, NonLuxurySUV

In Python we use the `abc` module to declare the "interfaces" as abstract
base classes with abstract methods, which is the idiomatic equivalent of a
Java interface.
"""

from abc import ABC, abstractmethod


# ---------------------------------------------------------------------------
# Abstract products (equivalent to the Java `Luxury` and `NonLuxury` interfaces)
# ---------------------------------------------------------------------------
class Luxury(ABC):
    """Abstract product representing a luxury vehicle."""

    @abstractmethod
    def get_luxury_name(self) -> str:
        """Return the name of the luxury vehicle."""
        raise NotImplementedError

    @abstractmethod
    def get_luxury_features(self) -> str:
        """Return a description of the luxury vehicle's features."""
        raise NotImplementedError


class NonLuxury(ABC):
    """Abstract product representing a non-luxury vehicle."""

    @abstractmethod
    def get_nl_name(self) -> str:
        """Return the name of the non-luxury vehicle."""
        raise NotImplementedError

    @abstractmethod
    def get_nl_features(self) -> str:
        """Return a description of the non-luxury vehicle's features."""
        raise NotImplementedError


# ---------------------------------------------------------------------------
# Concrete products
# ---------------------------------------------------------------------------
class LuxuryCAR(Luxury):
    """Concrete luxury product: a car."""

    def __init__(self, name: str) -> None:
        self._name = name

    def get_luxury_name(self) -> str:
        return self._name

    def get_luxury_features(self) -> str:
        return "Luxury Car Features "


class LuxurySUV(Luxury):
    """Concrete luxury product: an SUV."""

    def __init__(self, name: str) -> None:
        self._name = name

    def get_luxury_name(self) -> str:
        return self._name

    def get_luxury_features(self) -> str:
        return "Luxury SUV Features "


class NonLuxuryCAR(NonLuxury):
    """Concrete non-luxury product: a car."""

    def __init__(self, name: str) -> None:
        self._name = name

    def get_nl_name(self) -> str:
        return self._name

    def get_nl_features(self) -> str:
        return "Non-Luxury CAR Features "


class NonLuxurySUV(NonLuxury):
    """Concrete non-luxury product: an SUV."""

    def __init__(self, name: str) -> None:
        self._name = name

    def get_nl_name(self) -> str:
        return self._name

    def get_nl_features(self) -> str:
        return "Non-Luxury SUV Features "
