package com.smartev.backend.config;

import com.smartev.backend.models.User;
import com.smartev.backend.repositories.UserRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.CommandLineRunner;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Component;

@Component
public class AdminSeeder implements CommandLineRunner {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Override
    public void run(String... args) throws Exception {
        if (userRepository.findByEmail("admin@evway.com") == null) {
            User admin = new User();
            admin.setEmail("admin@evway.com");
            admin.setPassword(passwordEncoder.encode("admin123"));
            admin.setRole("ADMIN");
            admin.setStatus("APPROVED");
            userRepository.save(admin);
            System.out.println("Admin user created successfully: admin@evway.com / admin123");
        }
    }
}
