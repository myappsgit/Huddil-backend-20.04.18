package myapps.solutions.huddil.model;

import java.util.Date;

import com.fasterxml.jackson.annotation.JsonFormat;

public class UserDetails {

	private Integer id;
	private String addressingName;
	private String emailId;
	private String companyName;
	private String mobileNo;
	private String address;
	private String city;
	private String country;
	private String pincode;
	private String website;
	private int isActive;
	private Date signedUp;

	public UserDetails(Integer id) {
		this.id = id;
	}

	public UserDetails(Integer id, String addressingName, String emailId, String companyName, String mobileNo,
			String address, String city, String country, String pincode, String website, int isActive, Date signedUp) {
		this.id = id;
		this.addressingName = addressingName;
		this.emailId = emailId;
		this.companyName = companyName;
		this.mobileNo = mobileNo;
		this.address = address;
		this.city = city;
		this.country = country;
		this.pincode = pincode;
		this.website = website;
		this.isActive = isActive;
		this.signedUp = signedUp;
	}

	public Integer getId() {
		return id;
	}

	public void setId(Integer id) {
		this.id = id;
	}

	public String getAddressingName() {
		return addressingName;
	}

	public void setAddressingName(String addressingName) {
		this.addressingName = addressingName;
	}

	public String getEmailId() {
		return emailId;
	}

	public void setEmailId(String emailId) {
		this.emailId = emailId;
	}

	public String getCompanyName() {
		return companyName;
	}

	public void setCompanyName(String companyName) {
		this.companyName = companyName;
	}

	public String getMobileNo() {
		return mobileNo;
	}

	public void setMobileNo(String mobileNo) {
		this.mobileNo = mobileNo;
	}

	public String getAddress() {
		return address;
	}

	public void setAddress(String address) {
		this.address = address;
	}

	public String getCity() {
		return city;
	}

	public void setCity(String city) {
		this.city = city;
	}

	public String getCountry() {
		return country;
	}

	public void setCountry(String country) {
		this.country = country;
	}

	public String getPincode() {
		return pincode;
	}

	public void setPincode(String pincode) {
		this.pincode = pincode;
	}

	public String getWebsite() {
		return website;
	}

	public void setWebsite(String website) {
		this.website = website;
	}

	public int getIsActive() {
		return isActive;
	}

	public void setIsActive(int isActive) {
		this.isActive = isActive;
	}

	public Date getSignedUp() {
		return signedUp;
	}

	@JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss", timezone = "GMT+5:30")
	public void setSignedUp(Date signedUp) {
		this.signedUp = signedUp;
	}

}
