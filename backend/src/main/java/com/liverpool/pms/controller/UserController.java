package com.liverpool.pms.controller;

import com.liverpool.pms.entity.UserEntity;
import com.liverpool.pms.service.UserService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.Map;

@RestController
@RequestMapping("/api/user")
@CrossOrigin(origins = "*")
public class UserController {

    private final UserService userService;

    public UserController(UserService userService) {
        this.userService = userService;
    }

    @GetMapping("/profile")
    public ResponseEntity<UserEntity> getProfile() {
        return ResponseEntity.ok(userService.getCurrentUser());
    }

    @PutMapping("/profile")
    public ResponseEntity<UserEntity> updateProfile(@RequestBody UserEntity user) {
        return ResponseEntity.ok(userService.updateProfile(user));
    }

    @PostMapping("/change-password")
    public ResponseEntity<Map<String, Object>> changePassword(@RequestBody Map<String, String> body) {
        String currentPassword = body.getOrDefault("currentPassword", "");
        String newPassword = body.getOrDefault("newPassword", "");
        boolean success = userService.changePassword(currentPassword, newPassword);

        Map<String, Object> resp = new HashMap<>();
        resp.put("success", success);
        resp.put("message", success ? "Password changed successfully" : "Incorrect current password");
        if (success) {
            return ResponseEntity.ok(resp);
        } else {
            return ResponseEntity.badRequest().body(resp);
        }
    }

    @PostMapping("/login")
    public ResponseEntity<Map<String, Object>> login(@RequestBody Map<String, String> creds) {
        String username = creds.getOrDefault("username", "");
        String password = creds.getOrDefault("password", "");
        UserEntity user = userService.getCurrentUser();

        Map<String, Object> resp = new HashMap<>();
        if ((user.getUsername().equalsIgnoreCase(username) || user.getEmail().equalsIgnoreCase(username)) 
                && user.getPassword().equals(password)) {
            resp.put("success", true);
            resp.put("user", user);
            return ResponseEntity.ok(resp);
        } else {
            resp.put("success", false);
            resp.put("message", "Invalid username/email or password");
            return ResponseEntity.status(401).body(resp);
        }
    }

    @PostMapping("/register")
    public ResponseEntity<Map<String, Object>> register(@RequestBody Map<String, String> body) {
        String fullName = body.getOrDefault("fullName", "");
        String email = body.getOrDefault("email", "");
        String password = body.getOrDefault("password", "");
        String role = body.getOrDefault("role", "Club Official");
        String department = body.getOrDefault("department", "Executive Leadership");

        UserEntity user = userService.registerUser(fullName, email, password, role, department);
        Map<String, Object> resp = new HashMap<>();
        resp.put("success", true);
        resp.put("user", user);
        resp.put("message", "Account registered successfully");
        return ResponseEntity.ok(resp);
    }

    @PostMapping("/google-login")
    public ResponseEntity<Map<String, Object>> googleLogin(@RequestBody Map<String, String> body) {
        String email = body.getOrDefault("email", "");
        String fullName = body.getOrDefault("fullName", "");
        String avatarUrl = body.getOrDefault("avatarUrl", "");

        UserEntity user = userService.googleLoginOrRegister(email, fullName, avatarUrl);
        Map<String, Object> resp = new HashMap<>();
        resp.put("success", true);
        resp.put("user", user);
        return ResponseEntity.ok(resp);
    }
}
