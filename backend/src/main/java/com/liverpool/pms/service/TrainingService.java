package com.liverpool.pms.service;

import com.liverpool.pms.entity.TrainingSessionEntity;
import com.liverpool.pms.repository.jpa.TrainingSessionJpaRepository;
import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Optional;

@Service
public class TrainingService {

    private final TrainingSessionJpaRepository repository;

    public TrainingService(TrainingSessionJpaRepository repository) {
        this.repository = repository;
    }

    public List<TrainingSessionEntity> getAllSessions() {
        return repository.findAllByOrderByDateAscStartTimeAsc();
    }

    public Optional<TrainingSessionEntity> getById(String id) {
        return repository.findById(id);
    }

    public TrainingSessionEntity save(TrainingSessionEntity entity) {
        if (entity.getId() == null || entity.getId().trim().isEmpty()) {
            entity.setId("training_" + System.currentTimeMillis());
        }
        return repository.save(entity);
    }

    public boolean complete(String id) {
        Optional<TrainingSessionEntity> opt = repository.findById(id);
        if (opt.isPresent()) {
            TrainingSessionEntity session = opt.get();
            session.setStatus("Completed");
            repository.save(session);
            return true;
        }
        return false;
    }

    public boolean delete(String id) {
        if (repository.existsById(id)) {
            repository.deleteById(id);
            return true;
        }
        return false;
    }
}
