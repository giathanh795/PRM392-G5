package com.liverpool.pms.repository.jpa;

import com.liverpool.pms.entity.PlayerEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

import java.util.List;

@Repository
public interface PlayerJpaRepository extends JpaRepository<PlayerEntity, String> {
    List<PlayerEntity> findAllByOrderByNumberAsc();
}
