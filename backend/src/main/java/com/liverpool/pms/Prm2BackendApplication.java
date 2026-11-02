package com.liverpool.pms;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;

@SpringBootApplication
public class Prm2BackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(Prm2BackendApplication.class, args);
        System.out.println("==================================================");
        System.out.println("  LIVERPOOL PMS BACKEND RUNNING ON http://localhost:8080");
        System.out.println("  API Player Endpoint: http://localhost:8080/api/players");
        System.out.println("==================================================");
    }
}
