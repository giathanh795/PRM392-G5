package com.liverpool.pms.controller;

import com.liverpool.pms.entity.TrainingSessionEntity;
import com.liverpool.pms.service.TrainingService;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/api/trainings")
@CrossOrigin(origins = "*")
public class TrainingController {

    private final TrainingService trainingService;

    public TrainingController(TrainingService trainingService) {
        this.trainingService = trainingService;
    }

    @GetMapping
    public ResponseEntity<List<TrainingSessionEntity>> getAll() {
        return ResponseEntity.ok(trainingService.getAllSessions());
    }

    @PostMapping
    public ResponseEntity<TrainingSessionEntity> create(@RequestBody TrainingSessionEntity session) {
        return ResponseEntity.ok(trainingService.save(session));
    }

    @PutMapping("/{id}/complete")
    public ResponseEntity<Void> complete(@PathVariable String id) {
        boolean success = trainingService.complete(id);
        return success ? ResponseEntity.ok().build() : ResponseEntity.notFound().build();
    }

    @DeleteMapping("/{id}")
    public ResponseEntity<Void> delete(@PathVariable String id) {
        boolean success = trainingService.delete(id);
        return success ? ResponseEntity.noContent().build() : ResponseEntity.notFound().build();
    }
}
