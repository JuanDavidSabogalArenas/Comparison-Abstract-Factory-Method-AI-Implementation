# Work Summary — Java to Python Port (Abstract Factory)

## Objective

Following the instructions in `code_generation.md`, replicate the Java
application in `AbstractFactoryReverseExample/` as a Python program that
accomplishes the **same goal** and uses the **same design pattern**.

- **Goal of the app:** let the user search for a vehicle by *category*
  (Luxury / Non-Luxury) and *type* (Car / Suv), then display the resulting
  vehicle's name and features.
- **Design pattern:** Abstract Factory.

## What the original Java program does

The Java project is a textbook Abstract Factory example with a Swing GUI:

- `Luxury` and `NonLuxury` are product **interfaces**.
- `LuxuryCAR`, `LuxurySUV`, `NonLuxuryCAR`, `NonLuxurySUV` are the **concrete products**.
- `VehicleFactory` is the **abstract factory**, with a static
  `getVehicleFactory(type)` selector.
- `CARVehicleFactory` and `SUVVehicleFactory` are the **concrete factories**.
- `AutoSearchUI` (a `JFrame`) plus its inner `ButtonHandler` (`ActionListener`)
  provide the GUI and the search behaviour.

## What I built

A Python package in the `PythonAbstractFactory/` folder:

| File                | Purpose                                                            |
|---------------------|--------------------------------------------------------------------|
| `products.py`       | Abstract product interfaces (`abc.ABC`) + the 4 concrete products  |
| `factories.py`      | Abstract factory + concrete factories + static selector            |
| `auto_search_ui.py` | `tkinter` GUI and application entry point                          |
| `README.md`         | Mapping table and run instructions                                 |
| `SUMMARY.md`        | This document                                                      |

## Design pattern mapping (Java → Python)

| Java                                       | Python                                   | Role                     |
|--------------------------------------------|------------------------------------------|--------------------------|
| `Luxury` / `NonLuxury` interfaces          | `Luxury` / `NonLuxury` (`abc.ABC`)       | Abstract products        |
| `LuxuryCAR`, `LuxurySUV`, `NonLuxuryCAR`, `NonLuxurySUV` | same class names in `products.py` | Concrete products |
| `VehicleFactory` (abstract class)          | `VehicleFactory` (`abc.ABC`)             | Abstract factory         |
| `CARVehicleFactory`, `SUVVehicleFactory`   | same class names in `factories.py`       | Concrete factories       |
| `VehicleFactory.getVehicleFactory`         | `VehicleFactory.get_vehicle_factory`     | Static factory selector  |
| `AutoSearchUI` (Swing `JFrame`)            | `AutoSearchUI` (`tkinter.Tk`)            | GUI                      |
| `ButtonHandler` (`ActionListener`)         | `_on_search` / `_on_exit` methods        | Event handling           |

### Key translation decisions

- **Interfaces → abstract base classes.** Java interfaces became `abc.ABC`
  classes with `@abstractmethod` methods, the idiomatic Python equivalent.
- **Swing → tkinter.** `tkinter` is Python's standard-library GUI toolkit and
  the closest analog to Swing, so no third-party dependency is required.
- **Static selector preserved.** `get_vehicle_factory` keeps the same logic,
  including defaulting to the car factory for unknown types.
- **Behaviour kept identical**, including original quirks such as the
  `"NonLuxuryL-Car"` product name from the Java source.

## Verification performed

- Confirmed Python 3.14.7 is available.
- Ran the factory/product logic and confirmed the output values match the Java
  original exactly:
  - Car factory → `Luxury-Car` / `Luxury Car Features `, `NonLuxuryL-Car` / `Non-Luxury CAR Features `
  - SUV factory → `Luxury-SUV`, `Non-Luxury-SUV`
  - Unknown type defaults to `CARVehicleFactory`
- Confirmed all three modules import cleanly.
- The GUI requires a desktop session to display its window; the import and
  factory logic were verified in the terminal, but the window itself was not
  opened in this headless environment.

## How to run

```bash
cd PythonAbstractFactory
python auto_search_ui.py
```

Pick a **Vehicle Category** and a **VehicleType**, click **Search** to see the
vehicle's name and features, and **Exit** to close.
