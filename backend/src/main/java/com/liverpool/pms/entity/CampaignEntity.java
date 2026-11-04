package com.liverpool.pms.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "campaigns")
public class CampaignEntity {

    @Id
    @Column(name = "id", length = 64)
    private String id;

    @Column(name = "name", nullable = false, length = 128)
    private String name;

    @Column(name = "partner", length = 64)
    private String partner;

    @Column(name = "status", length = 32)
    private String status;

    @Column(name = "reach", length = 32)
    private String reach;

    @Column(name = "engagement", length = 32)
    private String engagement;

    @Column(name = "spend", length = 32)
    private String spend;

    @Column(name = "start_date", length = 32)
    private String startDate;

    @Column(name = "end_date", length = 32)
    private String endDate;

    @Column(name = "description", length = 1000)
    private String description;

    @Lob
    @Column(name = "image_url")
    private String imageUrl;

    @Lob
    @Column(name = "player_ids_json")
    private String playerIdsJson;

    public CampaignEntity() {
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public String getPartner() { return partner; }
    public void setPartner(String partner) { this.partner = partner; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getReach() { return reach; }
    public void setReach(String reach) { this.reach = reach; }

    public String getEngagement() { return engagement; }
    public void setEngagement(String engagement) { this.engagement = engagement; }

    public String getSpend() { return spend; }
    public void setSpend(String spend) { this.spend = spend; }

    public String getStartDate() { return startDate; }
    public void setStartDate(String startDate) { this.startDate = startDate; }

    public String getEndDate() { return endDate; }
    public void setEndDate(String endDate) { this.endDate = endDate; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getImageUrl() { return imageUrl; }
    public void setImageUrl(String imageUrl) { this.imageUrl = imageUrl; }

    public String getPlayerIdsJson() { return playerIdsJson; }
    public void setPlayerIdsJson(String playerIdsJson) { this.playerIdsJson = playerIdsJson; }
}
