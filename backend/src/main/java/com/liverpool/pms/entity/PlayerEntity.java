package com.liverpool.pms.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "players")
public class PlayerEntity {

    @Id
    @Column(name = "id", length = 64)
    private String id;

    @Column(name = "name", nullable = false, length = 128)
    private String name;

    @Column(name = "jersey_number")
    private int number;

    @Column(name = "position", length = 32)
    private String position;

    @Column(name = "nationality", length = 64)
    private String nationality;

    @Column(name = "date_of_birth", length = 32)
    private String dateOfBirth;

    @Column(name = "height")
    private int height;

    @Column(name = "weight")
    private int weight;

    @Column(name = "preferred_foot", length = 32)
    private String preferredFoot;

    @Column(name = "current_market_value")
    private double currentMarketValue;

    @Column(name = "previous_market_value")
    private double previousMarketValue;

    @Column(name = "contract_until", length = 32)
    private String contractUntil;

    @Column(name = "status", length = 32)
    private String status;

    @Lob
    @Column(name = "avatar_url")
    private String avatarUrl;

    @Lob
    @Column(name = "attributes_json")
    private String attributesJson;

    @Lob
    @Column(name = "media_list_json")
    private String mediaListJson;

    public PlayerEntity() {
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getName() { return name; }
    public void setName(String name) { this.name = name; }

    public int getNumber() { return number; }
    public void setNumber(int number) { this.number = number; }

    public String getPosition() { return position; }
    public void setPosition(String position) { this.position = position; }

    public String getNationality() { return nationality; }
    public void setNationality(String nationality) { this.nationality = nationality; }

    public String getDateOfBirth() { return dateOfBirth; }
    public void setDateOfBirth(String dateOfBirth) { this.dateOfBirth = dateOfBirth; }

    public int getHeight() { return height; }
    public void setHeight(int height) { this.height = height; }

    public int getWeight() { return weight; }
    public void setWeight(int weight) { this.weight = weight; }

    public String getPreferredFoot() { return preferredFoot; }
    public void setPreferredFoot(String preferredFoot) { this.preferredFoot = preferredFoot; }

    public double getCurrentMarketValue() { return currentMarketValue; }
    public void setCurrentMarketValue(double currentMarketValue) { this.currentMarketValue = currentMarketValue; }

    public double getPreviousMarketValue() { return previousMarketValue; }
    public void setPreviousMarketValue(double previousMarketValue) { this.previousMarketValue = previousMarketValue; }

    public String getContractUntil() { return contractUntil; }
    public void setContractUntil(String contractUntil) { this.contractUntil = contractUntil; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getAvatarUrl() { return avatarUrl; }
    public void setAvatarUrl(String avatarUrl) { this.avatarUrl = avatarUrl; }

    public String getAttributesJson() { return attributesJson; }
    public void setAttributesJson(String attributesJson) { this.attributesJson = attributesJson; }

    public String getMediaListJson() { return mediaListJson; }
    public void setMediaListJson(String mediaListJson) { this.mediaListJson = mediaListJson; }
}
