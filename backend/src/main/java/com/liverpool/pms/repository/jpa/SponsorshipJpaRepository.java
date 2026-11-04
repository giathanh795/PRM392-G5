package com.liverpool.pms.repository.jpa;

import com.liverpool.pms.entity.SponsorshipEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface SponsorshipJpaRepository extends JpaRepository<SponsorshipEntity, String> {
}
