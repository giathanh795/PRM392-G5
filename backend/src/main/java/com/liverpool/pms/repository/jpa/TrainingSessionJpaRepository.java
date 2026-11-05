package com.liverpool.pms.repository.jpa;

import com.liverpool.pms.entity.TrainingSessionEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface TrainingSessionJpaRepository extends JpaRepository<TrainingSessionEntity, String> {
    List<TrainingSessionEntity> findAllByOrderByDateAscStartTimeAsc();
}
