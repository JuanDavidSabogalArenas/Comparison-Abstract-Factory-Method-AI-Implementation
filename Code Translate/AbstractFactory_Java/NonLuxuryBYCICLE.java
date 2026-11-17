public class NonLuxuryBYCICLE implements NonLuxury {
  private String name;
  public NonLuxuryBYCICLE(String bName) {
    name = bName;
  }
  public String getNLName() {
    return name;
  }
  public String getNLFeatures() {
    return "Non-Luxury Bycicle Features ";
  };

} // End of class
