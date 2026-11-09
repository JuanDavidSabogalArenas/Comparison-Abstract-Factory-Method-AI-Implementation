# Abstract Factory – Python port

Python replica of the Java `AbstractFactoryReverseExample` project. It keeps the
same goal (search for a vehicle by category and type and show its name and
features) and the same **Abstract Factory** design pattern.

## Design pattern mapping (Java → Python)

| Java                                   | Python                                   | Role                         |
|----------------------------------------|------------------------------------------|------------------------------|
| `Luxury` / `NonLuxury` interfaces      | `Luxury` / `NonLuxury` (ABCs)            | Abstract products            |
| `LuxuryCAR`, `LuxurySUV`, `NonLuxuryCAR`, `NonLuxurySUV` | same class names in `products.py` | Concrete products |
| `VehicleFactory` (abstract class)      | `VehicleFactory` (ABC) in `factories.py` | Abstract factory             |
| `CARVehicleFactory`, `SUVVehicleFactory` | same class names in `factories.py`     | Concrete factories           |
| `VehicleFactory.getVehicleFactory`     | `VehicleFactory.get_vehicle_factory`     | Static factory selector      |
| `AutoSearchUI` (Swing `JFrame`)        | `AutoSearchUI` (`tkinter.Tk`)            | GUI                          |
| `ButtonHandler` (`ActionListener`)     | `_on_search` / `_on_exit` methods        | Event handling               |

## Files

- `products.py`   – abstract product interfaces and concrete products.
- `factories.py`  – abstract factory, concrete factories and the static selector.
- `auto_search_ui.py` – tkinter GUI and application entry point.

## Run

```bash
python auto_search_ui.py
```

Pick a **Vehicle Category** (Luxury / Non-Luxury) and a **VehicleType**
(Car / Suv), then click **Search** to see the resulting vehicle's name and
features. **Exit** closes the window.

Requires Python 3 with `tkinter` (bundled with the standard CPython installer).
