package com.liverpool.pms.model;

import java.util.ArrayList;
import java.util.List;

public class SponsorCampaign {

    private String id;
    private String name;
    private String sponsorName;
    private String startDate;
    private String endDate;
    private String status;
    private String reach;
    private String engagement;
    private String description;
    private String category;
    private double budgetMillions;
    private List<String> featuredPlayerNames = new ArrayList<>();

    public SponsorCampaign() {
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }
    public String getName() { return name; }
    public void setName(String name) { this.name = name; }
    public String getSponsorName() { return sponsorName; }
    public void setSponsorName(String sponsorName) { this.sponsorName = sponsorName; }
    public String getStartDate() { return startDate; }
    public void setStartDate(String startDate) { this.startDate = startDate; }
    public String getEndDate() { return endDate; }
    public void setEndDate(String endDate) { this.endDate = endDate; }
    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }
    public String getReach() { return reach; }
    public void setReach(String reach) { this.reach = reach; }
    public String getEngagement() { return engagement; }
    public void setEngagement(String engagement) { this.engagement = engagement; }
    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }
    public String getCategory() { return category; }
    public void setCategory(String category) { this.category = category; }
    public double getBudgetMillions() { return budgetMillions; }
    public void setBudgetMillions(double budgetMillions) { this.budgetMillions = budgetMillions; }
    public List<String> getFeaturedPlayerNames() { return featuredPlayerNames; }
    public void setFeaturedPlayerNames(List<String> featuredPlayerNames) {
        this.featuredPlayerNames = featuredPlayerNames == null ? new ArrayList<>() : featuredPlayerNames;
    }
}