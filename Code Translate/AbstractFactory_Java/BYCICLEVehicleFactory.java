public class BYCICLEVehicleFactory extends VehicleFactory {

  public LuxuryBYCICLE getLuxury() {
    return new LuxuryBYCICLE("Luxury-Bycicle");
  }
  public NonLuxuryBYCICLE getNonLuxury() {
    return new NonLuxuryBYCICLE("Non-Luxury-Bycicle");
  }
} // End of class
