package com.smartev.backend.repositories;

import com.smartev.backend.models.User;
import org.springframework.data.mongodb.repository.MongoRepository;

public interface UserRepository extends MongoRepository<User, String> {
    User findByEmail(String email);
    java.util.List<User> findByStatus(String status);
    java.util.List<User> findByRole(String role);
}
