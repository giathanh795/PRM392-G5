package com.liverpool.pms.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "sponsorships")
public class SponsorshipEntity {

    @Id
    @Column(name = "id", length = 64)
    private String id;

    @Column(name = "partner_name", nullable = false, length = 128)
    private String partnerName;

    @Column(name = "brand_category", length = 64)
    private String brandCategory;

    @Column(name = "annual_value")
    private double annualValue;

    @Column(name = "start_date", length = 32)
    private String startDate;

    @Column(name = "end_date", length = 32)
    private String endDate;

    @Column(name = "status", length = 32)
    private String status;

    @Column(name = "contact_email", length = 128)
    private String contactEmail;

    @Column(name = "contact_person", length = 128)
    private String contactPerson;

    @Column(name = "benefits", length = 1000)
    private String benefits;

    @Column(name = "contract_file_name", length = 256)
    private String contractFileName;

    @Column(name = "contract_content_type", length = 64)
    private String contractContentType;

    @Column(name = "contract_file_size")
    private long contractFileSize;

    public SponsorshipEntity() {
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getPartnerName() { return partnerName; }
    public void setPartnerName(String partnerName) { this.partnerName = partnerName; }

    public String getBrandCategory() { return brandCategory; }
    public void setBrandCategory(String brandCategory) { this.brandCategory = brandCategory; }

    public double getAnnualValue() { return annualValue; }
    public void setAnnualValue(double annualValue) { this.annualValue = annualValue; }

    public String getStartDate() { return startDate; }
    public void setStartDate(String startDate) { this.startDate = startDate; }

    public String getEndDate() { return endDate; }
    public void setEndDate(String endDate) { this.endDate = endDate; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getContactEmail() { return contactEmail; }
    public void setContactEmail(String contactEmail) { this.contactEmail = contactEmail; }

    public String getContactPerson() { return contactPerson; }
    public void setContactPerson(String contactPerson) { this.contactPerson = contactPerson; }

    public String getBenefits() { return benefits; }
    public void setBenefits(String benefits) { this.benefits = benefits; }

    public String getContractFileName() { return contractFileName; }
    public void setContractFileName(String contractFileName) { this.contractFileName = contractFileName; }

    public String getContractContentType() { return contractContentType; }
    public void setContractContentType(String contractContentType) { this.contractContentType = contractContentType; }

    public long getContractFileSize() { return contractFileSize; }
    public void setContractFileSize(long contractFileSize) { this.contractFileSize = contractFileSize; }
}
