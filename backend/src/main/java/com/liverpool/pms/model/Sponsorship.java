package com.liverpool.pms.model;

public class Sponsorship {

    private String id;
    private String name;
    private String logo;
    private String description;
    private String contractFileName;
    private String contractStorageKey;
    private double value;
    private String startDate;
    private String endDate;
    private String status;
    private String phone;
    private String email;
    private String contactPerson;
    private boolean removeContract;

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getLogo() { return logo; }
    public void setLogo(String logo) { this.logo = logo; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getContractFileName() { return contractFileName; }
    public void setContractFileName(String contractFileName) { this.contractFileName = contractFileName; }
    public String getContractStorageKey() { return contractStorageKey; }
    public void setContractStorageKey(String contractStorageKey) { this.contractStorageKey = contractStorageKey; }
    public double getValue() { return value; }
    public void setValue(double value) { this.value = value; }
    public String getStartDate() { return startDate; }
    public void setStartDate(String startDate) { this.startDate = startDate; }
    public String getEndDate() { return endDate; }
    public void setEndDate(String endDate) { this.endDate = endDate; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getContactPerson() { return contactPerson; }
    public void setContactPerson(String contactPerson) { this.contactPerson = contactPerson; }
    public boolean isRemoveContract() { return removeContract; }
    public void setRemoveContract(boolean removeContract) { this.removeContract = removeContract; }
}
