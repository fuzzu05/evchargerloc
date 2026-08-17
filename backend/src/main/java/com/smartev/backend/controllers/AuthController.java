package com.smartev.backend.controllers;

import com.smartev.backend.config.JwtUtil;
import com.smartev.backend.models.User;
import com.smartev.backend.repositories.UserRepository;
import com.smartev.backend.security.CustomUserDetails;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.Authentication;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.util.HashMap;
import java.util.List;
import java.util.Map;

@RestController
@RequestMapping("/api/auth")
public class AuthController {

    @Autowired
    private AuthenticationManager authenticationManager;

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private PasswordEncoder passwordEncoder;

    @Autowired
    private JwtUtil jwtUtil;

    // Secret Key for Demo Approval
    private final String SECRET_DEMO_KEY = "SIH2026";

    @PostMapping("/register")
    public ResponseEntity<?> registerUser(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String password = request.get("password");
        String secretKey = request.get("secretKey");

        if (userRepository.findByEmail(email) != null) {
            return ResponseEntity.badRequest().body("Email already exists");
        }

        User user = new User();
        user.setEmail(email);
        user.setPassword(passwordEncoder.encode(password));
        
        // Only OPERATOR or USER roles. No ADMIN via API.
        String role = request.getOrDefault("role", "OPERATOR");
        if (role.equalsIgnoreCase("ADMIN")) {
            return ResponseEntity.badRequest().body("Cannot register as ADMIN");
        }
        user.setRole(role.toUpperCase());

        if (role.equalsIgnoreCase("USER")) {
            user.setStatus("APPROVED");
        } else if (role.equalsIgnoreCase("OPERATOR")) {
            if (SECRET_DEMO_KEY.equals(secretKey)) {
                user.setStatus("APPROVED");
            } else {
                user.setStatus("PENDING");
            }
        }

        userRepository.save(user);
        return ResponseEntity.ok("User registered successfully with status: " + user.getStatus());
    }

    @PostMapping("/login")
    public ResponseEntity<?> login(@RequestBody Map<String, String> request) {
        String email = request.get("email");
        String password = request.get("password");

        try {
            Authentication authentication = authenticationManager.authenticate(
                    new UsernamePasswordAuthenticationToken(email, password)
            );

            CustomUserDetails userDetails = (CustomUserDetails) authentication.getPrincipal();
            User user = userDetails.getUser();

            String token = jwtUtil.generateToken(user.getEmail(), user.getRole(), user.getStatus(), user.getId());

            Map<String, Object> response = new HashMap<>();
            response.put("token", token);
            response.put("user", user);
            
            return ResponseEntity.ok(response);

        } catch (Exception e) {
            return ResponseEntity.badRequest().body("Invalid email or password");
        }
    }

    @PostMapping("/approve/{email}")
    public ResponseEntity<?> approveOperator(@PathVariable String email) {
        User user = userRepository.findByEmail(email);
        if (user == null) {
            return ResponseEntity.notFound().build();
        }
        user.setStatus("APPROVED");
        userRepository.save(user);
        return ResponseEntity.ok("Operator approved successfully");
    }

    @GetMapping("/pending-operators")
    public ResponseEntity<List<User>> getPendingOperators() {
        List<User> pendingUsers = userRepository.findByStatus("PENDING");
        return ResponseEntity.ok(pendingUsers);
    }
}
