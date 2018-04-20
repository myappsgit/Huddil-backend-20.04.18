package myapps.solutions.huddil.model;

public class SiteMap {

	Integer id;
	String facilityDetails;

	public SiteMap(Integer id, String facilityDetails) {
		this.id = id;
		this.facilityDetails = facilityDetails.replaceAll("\\s+", "-").toLowerCase();
	}

	public Integer getId() {
		return id;
	}

	public void setId(Integer id) {
		this.id = id;
	}

	public String getFacilityDetails() {
		return facilityDetails;
	}

	public void setFacilityDetails(String facilityDetails) {
		this.facilityDetails = facilityDetails;
	}

}
