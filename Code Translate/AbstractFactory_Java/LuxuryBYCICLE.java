public class LuxuryBYCICLE implements Luxury {
  private String name;
  public LuxuryBYCICLE(String bName) {
    name = bName;
  }
  public String getLuxuryName() {
    return name;
  }
  public String getLuxuryFeatures() {
    return "Luxury Bycicle Features ";
  };

} // End of class
