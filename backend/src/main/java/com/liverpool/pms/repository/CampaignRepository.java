package com.liverpool.pms.repository;

import com.liverpool.pms.model.SponsorCampaign;

import java.util.List;
import java.util.Optional;

public interface CampaignRepository {

    List<SponsorCampaign> findAll();

    Optional<SponsorCampaign> findById(String id);

    SponsorCampaign save(SponsorCampaign campaign);

    boolean deleteById(String id);
}