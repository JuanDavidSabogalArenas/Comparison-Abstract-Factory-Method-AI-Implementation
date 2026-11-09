"""
Graphical user interface that drives the Abstract Factory example.

This mirrors the Java `AutoSearchUI` (a Swing `JFrame`) and its inner
`ButtonHandler` class. Here we use `tkinter`, Python's standard-library GUI
toolkit, which is the closest equivalent to Java Swing.

Behaviour reproduced from the Java program:
    * A combo box to pick the vehicle category: Luxury / Non-Luxury.
    * A combo box to pick the vehicle type: Car / Suv.
    * A "Search" button that uses the Abstract Factory to build the chosen
      product and shows its name and features.
    * An "Exit" button that closes the application.
"""

import tkinter as tk
from tkinter import ttk

from factories import VehicleFactory


class AutoSearchUI(tk.Tk):
    """Main application window (equivalent to the Java JFrame)."""

    # UI string constants, reproducing the Java `public static final` fields.
    SEARCH = "Search"
    EXIT = "Exit"
    LUXURY = "Luxury"
    NON_LUXURY = "Non-Luxury"

    def __init__(self) -> None:
        super().__init__()
        self.title("Abstract Factory - Example")
        self.geometry("1050x600")

        # --- Widgets -------------------------------------------------------
        # Vehicle category combo box (Luxury / Non-Luxury).
        self._category_var = tk.StringVar(value=AutoSearchUI.LUXURY)
        self._cmb_category = ttk.Combobox(
            self,
            textvariable=self._category_var,
            state="readonly",
            values=[AutoSearchUI.LUXURY, AutoSearchUI.NON_LUXURY],
        )

        # Vehicle type combo box (Car / Suv).
        self._type_var = tk.StringVar(value=VehicleFactory.CAR)
        self._cmb_type = ttk.Combobox(
            self,
            textvariable=self._type_var,
            state="readonly",
            values=[VehicleFactory.CAR, VehicleFactory.SUV],
        )

        # Labels.
        lbl_category = ttk.Label(self, text="Vehicle Category:")
        lbl_type = ttk.Label(self, text="VehicleType:")
        lbl_result = ttk.Label(self, text="Search Result:")
        self._lbl_result_value = ttk.Label(
            self, text=" Please click on Search button"
        )

        # Buttons.
        btn_search = ttk.Button(
            self, text=AutoSearchUI.SEARCH, command=self._on_search
        )
        btn_exit = ttk.Button(
            self, text=AutoSearchUI.EXIT, command=self._on_exit
        )

        # --- Layout (grid, analogous to the Java GridBagLayout) ------------
        pad = {"padx": 5, "pady": 5}
        lbl_category.grid(row=0, column=0, sticky="e", **pad)
        self._cmb_category.grid(row=0, column=1, sticky="w", **pad)
        lbl_type.grid(row=1, column=0, sticky="e", **pad)
        self._cmb_type.grid(row=1, column=1, sticky="w", **pad)
        lbl_result.grid(row=2, column=0, sticky="e", **pad)
        self._lbl_result_value.grid(row=2, column=1, sticky="w", **pad)

        btn_search.grid(row=5, column=0, sticky="e", padx=2, pady=(40, 5))
        btn_exit.grid(row=5, column=1, sticky="w", padx=2, pady=(40, 5))

    # ----------------------------------------------------------------------
    # Accessors mirroring the Java getters/setters.
    # ----------------------------------------------------------------------
    def get_selected_category(self) -> str:
        return self._category_var.get()

    def get_selected_type(self) -> str:
        return self._type_var.get()

    def set_result(self, search_result: str) -> None:
        self._lbl_result_value.config(text=search_result)

    # ----------------------------------------------------------------------
    # Event handlers (the equivalent of Java's ButtonHandler.actionPerformed).
    # ----------------------------------------------------------------------
    def _on_exit(self) -> None:
        """Close the application (Java called System.exit)."""
        self.destroy()

    def _on_search(self) -> None:
        """
        Build the requested product using the Abstract Factory and display
        its name and features, exactly as the Java handler did.
        """
        vh_category = self.get_selected_category()
        vh_type = self.get_selected_type()

        # Get one of the Luxury or Non-Luxury capable vehicle factories.
        factory = VehicleFactory.get_vehicle_factory(vh_type)

        search_result = ""
        if vh_category == AutoSearchUI.LUXURY:
            product = factory.get_luxury()
            search_result = (
                "Name: " + product.get_luxury_name()
                + "  Features: " + product.get_luxury_features()
            )
        elif vh_category == AutoSearchUI.NON_LUXURY:
            product = factory.get_non_luxury()
            search_result = (
                "Name: " + product.get_nl_name()
                + "  Features: " + product.get_nl_features()
            )

        self.set_result(search_result)


def main() -> None:
    """Entry point, equivalent to the Java `main` method."""
    app = AutoSearchUI()
    app.mainloop()


if __name__ == "__main__":
    main()
