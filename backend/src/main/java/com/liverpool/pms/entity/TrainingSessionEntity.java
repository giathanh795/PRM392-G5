package com.liverpool.pms.entity;

import jakarta.persistence.*;

@Entity
@Table(name = "training_sessions")
public class TrainingSessionEntity {

    @Id
    @Column(name = "id", length = 64)
    private String id;

    @Column(name = "title", nullable = false, length = 128)
    private String title;

    @Column(name = "session_date", length = 32)
    private String date;

    @Column(name = "start_time", length = 32)
    private String startTime;

    @Column(name = "end_time", length = 32)
    private String endTime;

    @Column(name = "type", length = 32)
    private String type;

    @Column(name = "location", length = 128)
    private String location;

    @Column(name = "coach", length = 128)
    private String coach;

    @Column(name = "description", length = 1000)
    private String description;

    @Column(name = "status", length = 32)
    private String status;

    @Lob
    @Column(name = "player_ids_json")
    private String playerIdsJson;

    public TrainingSessionEntity() {
    }

    public String getId() { return id; }
    public void setId(String id) { this.id = id; }

    public String getTitle() { return title; }
    public void setTitle(String title) { this.title = title; }

    public String getDate() { return date; }
    public void setDate(String date) { this.date = date; }

    public String getStartTime() { return startTime; }
    public void setStartTime(String startTime) { this.startTime = startTime; }

    public String getEndTime() { return endTime; }
    public void setEndTime(String endTime) { this.endTime = endTime; }

    public String getType() { return type; }
    public void setType(String type) { this.type = type; }

    public String getLocation() { return location; }
    public void setLocation(String location) { this.location = location; }

    public String getCoach() { return coach; }
    public void setCoach(String coach) { this.coach = coach; }

    public String getDescription() { return description; }
    public void setDescription(String description) { this.description = description; }

    public String getStatus() { return status; }
    public void setStatus(String status) { this.status = status; }

    public String getPlayerIdsJson() { return playerIdsJson; }
    public void setPlayerIdsJson(String playerIdsJson) { this.playerIdsJson = playerIdsJson; }
}
