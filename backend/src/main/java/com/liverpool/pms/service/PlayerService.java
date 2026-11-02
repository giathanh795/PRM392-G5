package com.liverpool.pms.service;

import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.SerializationFeature;
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
    private File persistentFile;

    @PostConstruct
    public void init() {
        try {
            // Lưu file lưu trữ bên ngoài thư mục target/build để không bao giờ bị xóa khi build lại
            File dataDir = new File("data");
            if (!dataDir.exists()) {
                dataDir.mkdirs();
            }
            persistentFile = new File(dataDir, "players.json");

            if (persistentFile.exists() && persistentFile.length() > 0) {
                System.out.println("[Backend] Đang nạp dữ liệu từ: " + persistentFile.getAbsolutePath());
                List<Map<String, Object>> loaded = objectMapper.readValue(persistentFile, new TypeReference<>() {});
                players.addAll(loaded);
            } else {
                System.out.println("[Backend] Khởi tạo dữ liệu ban đầu từ resources...");
                try (InputStream is = defaultPlayersResource.getInputStream()) {
                    List<Map<String, Object>> loaded = objectMapper.readValue(is, new TypeReference<>() {});
                    players.addAll(loaded);
                    saveToFile();
                }
            }
            System.out.println("[Backend] Đã nạp thành công " + players.size() + " cầu thủ!");
        } catch (Exception e) {
            System.err.println("[Backend] Lỗi khi khởi tạo PlayerService: " + e.getMessage());
            e.printStackTrace();
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
            System.out.println("[Backend] Đã lưu " + players.size() + " cầu thủ vào file: " + persistentFile.getAbsolutePath());
        } catch (Exception e) {
            System.err.println("[Backend] Lỗi khi ghi file players.json: " + e.getMessage());
            e.printStackTrace();
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
                merged.put("id", id); // Đảm bảo ID không bị đổi
                players.set(i, merged);
                saveToFile();
                return merged;
            }
        }
        // Nếu chưa tồn tại thì thêm mới
        updatedData.put("id", id);
        players.add(updatedData);
        saveToFile();
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
        return newPlayer;
    }

    public boolean deletePlayer(String id) {
        boolean removed = players.removeIf(p -> id.equals(p.get("id")));
        if (removed) {
            saveToFile();
        }
        return removed;
    }

    public List<Map<String, Object>> resetToDefault() {
        try {
            players.clear();
            try (InputStream is = defaultPlayersResource.getInputStream()) {
                List<Map<String, Object>> loaded = objectMapper.readValue(is, new TypeReference<>() {});
                players.addAll(loaded);
                saveToFile();
            }
            System.out.println("[Backend] Đã khôi phục dữ liệu gốc Liverpool thành công!");
        } catch (Exception e) {
            e.printStackTrace();
        }
        return new ArrayList<>(players);
    }
}
