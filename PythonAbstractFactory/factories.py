"""
Abstract Factory and its concrete factories.

This mirrors the Java example:
    - VehicleFactory        (abstract class + static selector)
    - CARVehicleFactory     (concrete factory -> car products)
    - SUVVehicleFactory     (concrete factory -> SUV products)

The abstract factory declares the operations that create the family of
related products (a `Luxury` and a `NonLuxury` vehicle). Each concrete
factory produces products of a single variant (Car or SUV), keeping the
created products consistent with each other.
"""

from abc import ABC, abstractmethod

from products import (
    Luxury,
    NonLuxury,
    LuxuryCAR,
    LuxurySUV,
    NonLuxuryCAR,
    NonLuxurySUV,
)


class VehicleFactory(ABC):
    """
    Abstract factory declaring the creation methods for the product family.

    The `CAR` and `SUV` constants reproduce the public static final fields
    used in the Java `VehicleFactory` class.
    """

    # Class-level constants, equivalent to Java's `public static final`.
    CAR = "Car"
    SUV = "Suv"

    @abstractmethod
    def get_luxury(self) -> Luxury:
        """Create a luxury vehicle for this factory's variant."""
        raise NotImplementedError

    @abstractmethod
    def get_non_luxury(self) -> NonLuxury:
        """Create a non-luxury vehicle for this factory's variant."""
        raise NotImplementedError

    @staticmethod
    def get_vehicle_factory(vehicle_type: str) -> "VehicleFactory":
        """
        Static factory method that returns the proper concrete factory.

        Mirrors the Java `getVehicleFactory` method: returns an SUV factory
        for the SUV type and defaults to the car factory otherwise.
        """
        if vehicle_type == VehicleFactory.SUV:
            return SUVVehicleFactory()
        # Default (and explicit CAR) case returns the car factory.
        return CARVehicleFactory()


class CARVehicleFactory(VehicleFactory):
    """Concrete factory that produces the family of car products."""

    def get_luxury(self) -> Luxury:
        return LuxuryCAR("Luxury-Car")

    def get_non_luxury(self) -> NonLuxury:
        return NonLuxuryCAR("NonLuxuryL-Car")


class SUVVehicleFactory(VehicleFactory):
    """Concrete factory that produces the family of SUV products."""

    def get_luxury(self) -> Luxury:
        return LuxurySUV("Luxury-SUV")

    def get_non_luxury(self) -> NonLuxury:
        return NonLuxurySUV("Non-Luxury-SUV")
