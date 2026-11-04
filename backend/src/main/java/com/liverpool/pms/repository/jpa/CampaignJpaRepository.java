package com.liverpool.pms.repository.jpa;

import com.liverpool.pms.entity.CampaignEntity;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.stereotype.Repository;

@Repository
public interface CampaignJpaRepository extends JpaRepository<CampaignEntity, String> {
}
