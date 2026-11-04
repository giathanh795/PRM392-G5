package com.liverpool.pms.service;

import com.liverpool.pms.entity.UserEntity;
import com.liverpool.pms.repository.jpa.UserJpaRepository;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.util.Optional;

@Service
public class UserService {

    private final UserJpaRepository userRepository;

    public UserService(UserJpaRepository userRepository) {
        this.userRepository = userRepository;
    }

    public UserEntity getCurrentUser() {
        return userRepository.findAll().stream().findFirst().orElseGet(() -> {
            UserEntity defaultOwner = new UserEntity(
                    "usr_owner_01",
                    "admin",
                    "123",
                    "John W. Henry",
                    "john.henry@liverpoolfc.com",
                    "+1 (617) 226-6000",
                    "Principal Owner & Club Chairman",
                    "Board of Directors & Club Ownership (FSG)",
                    "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80",
                    "Principal Owner of Liverpool Football Club & Fenway Sports Group (FSG). Overseeing global club investments, Anfield stadium expansions, commercial deals with Adidas, and championship pursuits."
            );
            return userRepository.save(defaultOwner);
        });
    }

    public UserEntity updateProfile(UserEntity updated) {
        UserEntity current = getCurrentUser();
        if (updated.getFullName() != null && !updated.getFullName().trim().isEmpty()) {
            current.setFullName(updated.getFullName().trim());
        }
        if (updated.getEmail() != null) {
            current.setEmail(updated.getEmail().trim());
        }
        if (updated.getPhone() != null) {
            current.setPhone(updated.getPhone().trim());
        }
        if (updated.getRole() != null) {
            current.setRole(updated.getRole().trim());
        }
        if (updated.getDepartment() != null) {
            current.setDepartment(updated.getDepartment().trim());
        }
        if (updated.getBio() != null) {
            current.setBio(updated.getBio().trim());
        }
        if (updated.getAvatarUrl() != null && !updated.getAvatarUrl().trim().isEmpty()) {
            current.setAvatarUrl(updated.getAvatarUrl().trim());
        }
        current.setUpdatedAt(LocalDateTime.now());
        return userRepository.save(current);
    }

    public boolean changePassword(String currentPassword, String newPassword) {
        UserEntity current = getCurrentUser();
        if (current.getPassword().equals(currentPassword)) {
            current.setPassword(newPassword);
            current.setUpdatedAt(LocalDateTime.now());
            userRepository.save(current);
            return true;
        }
        return false;
    }

    public UserEntity registerUser(String fullName, String email, String password, String role, String department) {
        String id = "usr_" + System.currentTimeMillis();
        String username = email.contains("@") ? email.split("@")[0] : ("user_" + System.currentTimeMillis() % 10000);
        UserEntity newUser = new UserEntity(
                id,
                username,
                password.isEmpty() ? "123456" : password,
                fullName.isEmpty() ? "Club Executive" : fullName,
                email,
                "+44 151 263 2361",
                role.isEmpty() ? "Club Official / Board Member" : role,
                department.isEmpty() ? "Liverpool FC Leadership" : department,
                "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80",
                "Official Registered Member of Liverpool Football Club Management."
        );
        newUser.setUpdatedAt(LocalDateTime.now());
        return userRepository.save(newUser);
    }

    public UserEntity googleLoginOrRegister(String email, String fullName, String avatarUrl) {
        Optional<UserEntity> existing = userRepository.findAll().stream()
                .filter(u -> email.equalsIgnoreCase(u.getEmail()))
                .findFirst();
        if (existing.isPresent()) {
            return existing.get();
        }
        String id = "usr_google_" + System.currentTimeMillis();
        String username = email.contains("@") ? email.split("@")[0] : ("google_" + System.currentTimeMillis() % 10000);
        UserEntity googleUser = new UserEntity(
                id,
                username,
                "google_oauth_pass",
                fullName.isEmpty() ? "Google User" : fullName,
                email,
                "+1 (617) 226-6000",
                "Club Official / Stakeholder",
                "Liverpool FC Management",
                avatarUrl.isEmpty() ? "https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=400&q=80" : avatarUrl,
                "Authenticated via Google / Gmail Account."
        );
        googleUser.setUpdatedAt(LocalDateTime.now());
        return userRepository.save(googleUser);
    }
}
