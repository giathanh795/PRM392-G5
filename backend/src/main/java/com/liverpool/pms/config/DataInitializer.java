package com.liverpool.pms.config;

import com.liverpool.pms.entity.UserEntity;
import com.liverpool.pms.repository.jpa.UserJpaRepository;
import org.springframework.boot.CommandLineRunner;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

import java.time.LocalDateTime;

@Configuration
public class DataInitializer {

    @Bean
    public CommandLineRunner initDatabase(UserJpaRepository userRepository) {
        return args -> {
            if (userRepository.count() == 0) {
                UserEntity owner = new UserEntity(
                        "usr_owner_01",
                        "admin",
                        "123",
                        "John W. Henry",
                        "john.henry@liverpoolfc.com",
                        "+1 (617) 226-6000",
                        "Principal Owner & Club Chairman",
                        "Board of Directors & Club Ownership (FSG)",
                        "https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=400&q=80",
                        "Principal Owner of Liverpool Football Club & Fenway Sports Group (FSG). Overseeing strategic club investments, stadium development, commercial growth, and executive leadership."
                );
                owner.setUpdatedAt(LocalDateTime.now());
                userRepository.save(owner);
                System.out.println("[Backend-SQL] Đã khởi tạo User Profile Chủ tịch CLB (John W. Henry) trong SQL Table 'users'!");
            }
        };
    }
}
