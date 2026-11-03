package com.liverpool.pms;

import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.context.ConfigurableApplicationContext;

@SpringBootApplication
public class Prm2BackendApplication {

    public static void main(String[] args) {
        ConfigurableApplicationContext context =
                SpringApplication.run(Prm2BackendApplication.class, args);
        String port = context.getEnvironment().getProperty(
                "local.server.port",
                context.getEnvironment().getProperty("server.port", "8080"));
        System.out.println("==================================================");
        System.out.println("  LIVERPOOL PMS BACKEND RUNNING ON http://localhost:" + port);
        System.out.println("  API Player Endpoint: http://localhost:" + port + "/api/players");
        System.out.println("  API Campaign Endpoint: http://localhost:" + port + "/api/campaigns");
        System.out.println("  API Sponsorship Endpoint: http://localhost:" + port + "/api/sponsorships");
        System.out.println("==================================================");
    }
}
