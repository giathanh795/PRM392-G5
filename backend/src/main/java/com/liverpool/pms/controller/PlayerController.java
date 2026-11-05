package com.liverpool.pms.controller;

import com.liverpool.pms.service.PlayerService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/players")
@CrossOrigin(origins = "*") // Cho phép Flutter Web, Android Emulator và thiết bị thật kết nối không bị chặn CORS
public class PlayerController {

    private final PlayerService playerService;

    public PlayerController(PlayerService playerService) {
        this.playerService = playerService;
    }

    // GET /api/players - Lấy danh sách toàn bộ cầu thủ
    @GetMapping
    public ResponseEntity<List<Map<String, Object>>> getAllPlayers() {
        return ResponseEntity.ok(playerService.getAllPlayers());
    }

    // GET /api/players/{id} - Lấy chi tiết 1 cầu thủ
    @GetMapping("/{id}")
    public ResponseEntity<Map<String, Object>> getPlayerById(@PathVariable String id) {
        return playerService.getPlayerById(id)
                .map(ResponseEntity::ok)
                .orElse(ResponseEntity.notFound().build());
    }

    // PUT /api/players/{id} - Cập nhật thông tin cầu thủ (đổi avatar, thêm video PR, sửa chỉ số)
    @PutMapping("/{id}")
    public ResponseEntity<Map<String, Object>> updatePlayer(
            @PathVariable String id,
            @RequestBody Map<String, Object> updatedData) {
        return ResponseEntity.ok(playerService.updatePlayer(id, updatedData));
    }

    // POST /api/players - Thêm cầu thủ mới
    @PostMapping
    public ResponseEntity<Map<String, Object>> addPlayer(@RequestBody Map<String, Object> newPlayer) {
        return ResponseEntity.ok(playerService.addPlayer(newPlayer));
    }

    // DELETE /api/players/{id} - Xóa cầu thủ
    @DeleteMapping("/{id}")
    public ResponseEntity<Void> deletePlayer(@PathVariable String id) {
        boolean deleted = playerService.deletePlayer(id);
        if (deleted) {
            return ResponseEntity.noContent().build();
        }
        return ResponseEntity.notFound().build();
    }

    // POST /api/players/reset - Khôi phục danh sách Liverpool gốc ban đầu
    @PostMapping("/reset")
    public ResponseEntity<List<Map<String, Object>>> resetToDefault() {
        return ResponseEntity.ok(playerService.resetToDefault());
    }
}
