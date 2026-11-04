package com.liverpool.pms.service;

import com.liverpool.pms.model.SponsorCampaign;
import com.liverpool.pms.repository.CampaignRepository;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;

@Service
public class CampaignService {

    private final CampaignRepository campaignRepository;

    public CampaignService(CampaignRepository campaignRepository) {
        this.campaignRepository = campaignRepository;
    }

    public List<SponsorCampaign> getAllCampaigns() {
        return campaignRepository.findAll();
    }

    public SponsorCampaign getCampaignById(String id) {
        return campaignRepository.findById(id)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Campaign not found"));
    }

    public SponsorCampaign createCampaign(SponsorCampaign campaign) {
        validate(campaign);
        if (campaign.getId() == null || campaign.getId().isBlank()) {
            campaign.setId("camp_" + System.currentTimeMillis());
        }
        if (campaignRepository.findById(campaign.getId()).isPresent()) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Campaign ID already exists");
        }
        return campaignRepository.save(campaign);
    }

    public SponsorCampaign updateCampaign(String id, SponsorCampaign campaign) {
        validate(campaign);
        getCampaignById(id);
        campaign.setId(id);
        return campaignRepository.save(campaign);
    }

    public void deleteCampaign(String id) {
        if (!campaignRepository.deleteById(id)) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND, "Campaign not found");
        }
    }

    private void validate(SponsorCampaign campaign) {
        if (campaign == null || campaign.getName() == null || campaign.getName().isBlank()) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Campaign name is required");
        }
        if (campaign.getBudgetMillions() < 0) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Campaign budget cannot be negative");
        }
    }
}