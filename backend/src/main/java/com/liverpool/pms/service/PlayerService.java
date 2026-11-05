package com.liverpool.pms.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.liverpool.pms.entity.PlayerEntity;
import com.liverpool.pms.repository.jpa.PlayerJpaRepository;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.core.io.Resource;
import org.springframework.stereotype.Service;

import jakarta.annotation.PostConstruct;
import java.io.File;
import java.io.InputStream;
import java.util.*;
import java.util.concurrent.CopyOnWriteArrayList;

@Service
public class PlayerService {

    @Value("classpath:data/players.json")
    private Resource defaultPlayersResource;

    private final ObjectMapper objectMapper = new ObjectMapper().enable(SerializationFeature.INDENT_OUTPUT);
    private final List<Map<String, Object>> players = new CopyOnWriteArrayList<>();
    private final PlayerJpaRepository playerJpaRepository;
    private File persistentFile;

    public PlayerService(PlayerJpaRepository playerJpaRepository) {
        this.playerJpaRepository = playerJpaRepository;
    }

    @PostConstruct
    public void init() {
        try {
            File dataDir = new File("data");
            if (!dataDir.exists()) {
                dataDir.mkdirs();
            }
            persistentFile = new File(dataDir, "players.json");

            if (persistentFile.exists() && persistentFile.length() > 0) {
                System.out.println("[Backend-SQL] Đang nạp dữ liệu từ: " + persistentFile.getAbsolutePath());
                List<Map<String, Object>> loaded = objectMapper.readValue(persistentFile, new TypeReference<>() {});
                players.addAll(loaded);
            } else {
                System.out.println("[Backend-SQL] Khởi tạo dữ liệu ban đầu từ resources...");
                try (InputStream is = defaultPlayersResource.getInputStream()) {
                    List<Map<String, Object>> loaded = objectMapper.readValue(is, new TypeReference<>() {});
                    players.addAll(loaded);
                    saveToFile();
                }
            }

            // Đồng bộ dữ liệu sang Cơ sở dữ liệu SQL (Table: PLAYERS)
            syncAllToSql();

            System.out.println("[Backend-SQL] Đã nạp và đồng bộ vào SQL Database thành công " + players.size() + " cầu thủ!");
        } catch (Exception e) {
            System.err.println("[Backend-SQL] Lỗi khi khởi tạo PlayerService: " + e.getMessage());
            e.printStackTrace();
        }
    }

    private void syncAllToSql() {
        try {
            for (Map<String, Object> map : players) {
                saveEntityToSql(map);
            }
            System.out.println("[Backend-SQL] Đồng bộ " + players.size() + " records vào SQL Table 'players' hoàn tất.");
        } catch (Exception e) {
            System.err.println("[Backend-SQL] Lỗi khi đồng bộ SQL Table: " + e.getMessage());
        }
    }

    private void saveEntityToSql(Map<String, Object> map) {
        try {
            String id = (String) map.get("id");
            if (id == null) return;

            PlayerEntity entity = playerJpaRepository.findById(id).orElse(new PlayerEntity());
            entity.setId(id);
            entity.setName((String) map.getOrDefault("name", ""));
            
            Object numObj = map.get("number");
            if (numObj instanceof Number) entity.setNumber(((Number) numObj).intValue());
            
            entity.setPosition((String) map.getOrDefault("position", ""));
            entity.setNationality((String) map.getOrDefault("nationality", ""));
            entity.setDateOfBirth((String) map.getOrDefault("dateOfBirth", ""));
            
            Object hObj = map.get("height");
            if (hObj instanceof Number) entity.setHeight(((Number) hObj).intValue());
            
            Object wObj = map.get("weight");
            if (wObj instanceof Number) entity.setWeight(((Number) wObj).intValue());
            
            entity.setPreferredFoot((String) map.getOrDefault("preferredFoot", ""));
            
            Object valObj = map.get("currentMarketValue");
            if (valObj instanceof Number) entity.setCurrentMarketValue(((Number) valObj).doubleValue());
            
            Object prevObj = map.get("previousMarketValue");
            if (prevObj instanceof Number) entity.setPreviousMarketValue(((Number) prevObj).doubleValue());
            
            entity.setContractUntil((String) map.getOrDefault("contractUntil", ""));
            entity.setStatus((String) map.getOrDefault("status", "Active"));
            entity.setAvatarUrl((String) map.getOrDefault("avatarUrl", ""));

            if (map.containsKey("attributes")) {
                entity.setAttributesJson(objectMapper.writeValueAsString(map.get("attributes")));
            }
            if (map.containsKey("mediaList")) {
                entity.setMediaListJson(objectMapper.writeValueAsString(map.get("mediaList")));
            }

            playerJpaRepository.save(entity);
        } catch (Exception e) {
            System.err.println("[Backend-SQL] Lỗi lưu entity SQL: " + e.getMessage());
        }
    }

    private synchronized void saveToFile() {
        try {
            if (persistentFile == null) {
                File dataDir = new File("data");
                if (!dataDir.exists()) dataDir.mkdirs();
                persistentFile = new File(dataDir, "players.json");
            }
            objectMapper.writeValue(persistentFile, players);
        } catch (Exception e) {
            System.err.println("[Backend-SQL] Lỗi khi ghi file players.json: " + e.getMessage());
        }
    }

    public List<Map<String, Object>> getAllPlayers() {
        return new ArrayList<>(players);
    }

    public Optional<Map<String, Object>> getPlayerById(String id) {
        return players.stream().filter(p -> id.equals(p.get("id"))).findFirst();
    }

    public Map<String, Object> updatePlayer(String id, Map<String, Object> updatedData) {
        for (int i = 0; i < players.size(); i++) {
            Map<String, Object> current = players.get(i);
            if (id.equals(current.get("id"))) {
                Map<String, Object> merged = new LinkedHashMap<>(current);
                merged.putAll(updatedData);
                merged.put("id", id);
                players.set(i, merged);
                saveToFile();
                saveEntityToSql(merged);
                return merged;
            }
        }
        updatedData.put("id", id);
        players.add(updatedData);
        saveToFile();
        saveEntityToSql(updatedData);
        return updatedData;
    }

    public Map<String, Object> addPlayer(Map<String, Object> newPlayer) {
        String id = (String) newPlayer.get("id");
        if (id == null || id.isEmpty()) {
            id = "p_" + System.currentTimeMillis();
            newPlayer.put("id", id);
        }
        players.add(newPlayer);
        saveToFile();
        saveEntityToSql(newPlayer);
        return newPlayer;
    }

    public boolean deletePlayer(String id) {
        boolean removed = players.removeIf(p -> id.equals(p.get("id")));
        if (removed) {
            saveToFile();
            try {
                playerJpaRepository.deleteById(id);
                System.out.println("[Backend-SQL] Đã xóa player khỏi SQL Database table: " + id);
            } catch (Exception e) {
                System.err.println("[Backend-SQL] Lỗi xóa record khỏi SQL: " + e.getMessage());
            }
        }
        return removed;
    }

    public List<Map<String, Object>> resetToDefault() {
        try {
            players.clear();
            playerJpaRepository.deleteAll();
            try (InputStream is = defaultPlayersResource.getInputStream()) {
                List<Map<String, Object>> loaded = objectMapper.readValue(is, new TypeReference<>() {});
                players.addAll(loaded);
                saveToFile();
                syncAllToSql();
            }
            System.out.println("[Backend-SQL] Đã khôi phục dữ liệu gốc và reset SQL Database!");
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new ArrayList<>(players);
    }
}
